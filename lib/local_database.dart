import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;

  // Get database instance
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB("massage_app.db");
    return _db!;
  }

  // Initialize DB
  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,   // increase version when schema changes
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Handle database upgrades
  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bookings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          therapistCode TEXT,
          customerEmail TEXT,
          customerName TEXT,
          bookingDate TEXT,
          timeSlot TEXT,
          serviceNames TEXT,
          totalPrice REAL,
          totalDuration INTEGER,
          createdAt TEXT,
          status TEXT DEFAULT 'confirmed'
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recipientEmail TEXT,
          title TEXT,
          message TEXT,
          therapistCode TEXT,
          type TEXT,
          isRead INTEGER DEFAULT 0,
          createdAt TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS services (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          providerEmail TEXT,
          serviceName TEXT,
          price REAL,
          durationMinutes INTEGER,
          description TEXT,
          isActive INTEGER DEFAULT 1,
          createdAt TEXT
        )
      ''');
      
      // Add setupComplete flag to massagers table
      await db.execute('''
        ALTER TABLE massagers ADD COLUMN setupComplete INTEGER DEFAULT 0
      ''');
    }
  }

  // Create all tables
  static Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        password TEXT,
        assigned_code TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE massagers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        password TEXT,
        experience TEXT,
        location TEXT,
        code TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        experience TEXT,
        location TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        massager_id INTEGER,
        code TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        therapistCode TEXT,
        customerEmail TEXT,
        customerName TEXT,
        bookingDate TEXT,
        timeSlot TEXT,
        serviceNames TEXT,
        totalPrice REAL,
        totalDuration INTEGER,
        createdAt TEXT,
        status TEXT DEFAULT 'confirmed'
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipientEmail TEXT,
        title TEXT,
        message TEXT,
        therapistCode TEXT,
        type TEXT,
        isRead INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        providerEmail TEXT,
        serviceName TEXT,
        price REAL,
        durationMinutes INTEGER,
        description TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT
      )
    ''');
  }

  // Insert data
  static Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  // Get all records
  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  // Find by email helper
  static Future<Map<String, dynamic>?> findByEmail(
      String table, String email) async {
    final db = await database;
    final result =
        await db.query(table, where: "email = ?", whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }

  // Custom query: Find by code
  static Future<Map<String, dynamic>?> findByCode(
      String table, String code) async {
    final db = await database;
    final result =
        await db.query(table, where: "code = ?", whereArgs: [code]);
    return result.isNotEmpty ? result.first : null;
  }

  // Get bookings by therapist code
  static Future<List<Map<String, dynamic>>> getBookingsByTherapistCode(
      String therapistCode) async {
    final db = await database;
    return await db.query(
      'bookings',
      where: 'therapistCode = ?',
      whereArgs: [therapistCode],
      orderBy: 'bookingDate DESC, createdAt DESC',
    );
  }

  // Get unique customer count by therapist code
  static Future<int> getCustomerCountByTherapistCode(String therapistCode) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT customerEmail) as count
      FROM bookings
      WHERE therapistCode = ?
    ''', [therapistCode]);
    return result.first['count'] as int;
  }

  // Update booking status
  static Future<int> updateBookingStatus(int bookingId, String status) async {
    final db = await database;
    return await db.update(
      'bookings',
      {'status': status},
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  // ===== NOTIFICATIONS METHODS =====
  
  // Create notification
  static Future<int> createNotification({
    required String recipientEmail,
    required String title,
    required String message,
    String? therapistCode,
    String type = 'info',
  }) async {
    final db = await database;
    return await db.insert('notifications', {
      'recipientEmail': recipientEmail,
      'title': title,
      'message': message,
      'therapistCode': therapistCode,
      'type': type,
      'isRead': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Get notifications by email
  static Future<List<Map<String, dynamic>>> getNotificationsByEmail(
      String email) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'recipientEmail = ?',
      whereArgs: [email],
      orderBy: 'createdAt DESC',
    );
  }

  // Get unread notification count
  static Future<int> getUnreadNotificationCount(String email) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM notifications
      WHERE recipientEmail = ? AND isRead = 0
    ''', [email]);
    return result.first['count'] as int;
  }

  // Mark notification as read
  static Future<int> markNotificationAsRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // Mark all notifications as read for a user
  static Future<int> markAllNotificationsAsRead(String email) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'recipientEmail = ? AND isRead = 0',
      whereArgs: [email],
    );
  }

  // Delete notification
  static Future<int> deleteNotification(int notificationId) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // ===== SERVICES METHODS =====
  
  // Add service
  static Future<int> addService({
    required String providerEmail,
    required String serviceName,
    required double price,
    required int durationMinutes,
    String? description,
  }) async {
    final db = await database;
    return await db.insert('services', {
      'providerEmail': providerEmail,
      'serviceName': serviceName,
      'price': price,
      'durationMinutes': durationMinutes,
      'description': description ?? '',
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Get services by provider email
  static Future<List<Map<String, dynamic>>> getServicesByProvider(
      String providerEmail) async {
    final db = await database;
    return await db.query(
      'services',
      where: 'providerEmail = ? AND isActive = 1',
      whereArgs: [providerEmail],
      orderBy: 'createdAt DESC',
    );
  }

  // Update service
  static Future<int> updateService({
    required int serviceId,
    required String serviceName,
    required double price,
    required int durationMinutes,
    String? description,
  }) async {
    final db = await database;
    return await db.update(
      'services',
      {
        'serviceName': serviceName,
        'price': price,
        'durationMinutes': durationMinutes,
        'description': description ?? '',
      },
      where: 'id = ?',
      whereArgs: [serviceId],
    );
  }

  // Delete service (soft delete)
  static Future<int> deleteService(int serviceId) async {
    final db = await database;
    return await db.update(
      'services',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [serviceId],
    );
  }

  // Mark provider setup as complete
  static Future<int> markSetupComplete(String providerEmail) async {
    final db = await database;
    return await db.update(
      'massagers',
      {'setupComplete': 1},
      where: 'email = ?',
      whereArgs: [providerEmail],
    );
  }

  // Check if provider setup is complete
  static Future<bool> isSetupComplete(String providerEmail) async {
    final data = await findByEmail('massagers', providerEmail);
    if (data == null) return false;
    return (data['setupComplete'] as int?) == 1;
  }
}
