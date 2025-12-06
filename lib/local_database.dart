import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;

  // Sanitize input to prevent SQL injection
  static String _sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'''[<>"';]'''), '') // Remove dangerous characters
        .trim();
  }

  // Validate email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get database instance
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB("massage_app.db");
    return _db!;
  }

  // Create indexes for performance
  static Future<void> _createIndexes(Database db) async {
    // Index for email lookups (frequent)
    await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_massagers_email ON massagers(email)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_massagers_code ON massagers(code)');
    
    // Index for booking queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bookings_therapist ON bookings(therapistCode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bookings_customer ON bookings(customerEmail)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(bookingDate)');
    
    // Index for notifications
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_email ON notifications(recipientEmail)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(isRead)');
    
    // Index for services
    await db.execute('CREATE INDEX IF NOT EXISTS idx_services_provider ON services(providerEmail)');
    
    // Index for customer visits
    await db.execute('CREATE INDEX IF NOT EXISTS idx_visits_therapist ON customer_visits(therapistCode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_visits_customer ON customer_visits(customerEmail)');
  }

  // Initialize DB
  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8,   // increase version when schema changes
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Handle database upgrades
  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ensure customers table has referral_code for all prior versions
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN referral_code TEXT');
      } catch (e) {
        // Ignore if column already exists
      }
    }
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
    if (oldVersion < 6) {
      // Create customer visits table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customer_visits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          therapistCode TEXT,
          customerEmail TEXT,
          customerName TEXT,
          firstVisit TEXT,
          lastVisit TEXT,
          visitCount INTEGER DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 7) {
      // Create referrals table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS referrals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          referrer_email TEXT,
          referred_email TEXT,
          referral_code TEXT,
          referral_date TEXT,
          status TEXT DEFAULT 'active'
        )
      ''');
      
      // Create loyalty points table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS loyalty_points (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_email TEXT UNIQUE,
          points INTEGER DEFAULT 0,
          lifetime_points INTEGER DEFAULT 0,
          referral_code TEXT,
          last_updated TEXT
        )
      ''');
      
      // Create points history table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS points_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_email TEXT,
          points_earned INTEGER,
          reason TEXT,
          booking_id INTEGER,
          referred_customer TEXT,
          earned_date TEXT
        )
      ''');
      
      // Create indexes for referral tables
      await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_email)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_referred ON referrals(referred_email)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_loyalty_email ON loyalty_points(customer_email)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_points_history_email ON points_history(customer_email)');
    }
  }

  // Create all tables
  static Future _createDB(Database db, int version) async {
    // Create indexes for better query performance
    await _createIndexes(db);
    
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        password TEXT,
        assigned_code TEXT,
        referral_code TEXT
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

    await db.execute('''
      CREATE TABLE customer_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        therapistCode TEXT,
        customerEmail TEXT,
        customerName TEXT,
        firstVisit TEXT,
        lastVisit TEXT,
        visitCount INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE referrals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        referrer_email TEXT,
        referred_email TEXT,
        referral_code TEXT,
        referral_date TEXT,
        status TEXT DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE TABLE loyalty_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_email TEXT UNIQUE,
        points INTEGER DEFAULT 0,
        lifetime_points INTEGER DEFAULT 0,
        referral_code TEXT,
        last_updated TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE points_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_email TEXT,
        points_earned INTEGER,
        reason TEXT,
        booking_id INTEGER,
        referred_customer TEXT,
        earned_date TEXT
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
    if (!_isValidEmail(email)) {
      throw ArgumentError('Invalid email format');
    }
    final db = await database;
    final sanitizedEmail = _sanitizeInput(email);
    final result =
        await db.query(table, where: "email = ?", whereArgs: [sanitizedEmail]);
    return result.isNotEmpty ? result.first : null;
  }

  // Custom query: Find by code
  static Future<Map<String, dynamic>?> findByCode(
      String table, String code) async {
    if (code.isEmpty || code.length > 50) {
      throw ArgumentError('Invalid code format');
    }
    final db = await database;
    final sanitizedCode = _sanitizeInput(code);
    final result =
        await db.query(table, where: "code = ?", whereArgs: [sanitizedCode]);
    return result.isNotEmpty ? result.first : null;
  }

  // Get bookings by therapist code
  static Future<List<Map<String, dynamic>>> getBookingsByTherapistCode(
      String therapistCode) async {
    if (therapistCode.isEmpty) {
      throw ArgumentError('Therapist code cannot be empty');
    }
    final db = await database;
    final sanitizedCode = _sanitizeInput(therapistCode);
    return await db.query(
      'bookings',
      where: 'therapistCode = ?',
      whereArgs: [sanitizedCode],
      orderBy: 'bookingDate DESC, createdAt DESC',
      limit: 1000, // Prevent excessive data loading
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

  // ===== NOTIFICATIONS METHODS =====
  
  // Create notification
  static Future<int> createNotification({
    required String recipientEmail,
    required String title,
    required String message,
    String? therapistCode,
    String type = 'info',
  }) async {
    if (!_isValidEmail(recipientEmail)) {
      throw ArgumentError('Invalid email format');
    }
    if (title.isEmpty || message.isEmpty) {
      throw ArgumentError('Title and message cannot be empty');
    }
    final db = await database;
    return await db.insert('notifications', {
      'recipientEmail': _sanitizeInput(recipientEmail),
      'title': _sanitizeInput(title),
      'message': _sanitizeInput(message),
      'therapistCode': therapistCode != null ? _sanitizeInput(therapistCode) : null,
      'type': _sanitizeInput(type),
      'isRead': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Get notifications by email
  static Future<List<Map<String, dynamic>>> getNotificationsByEmail(
      String email) async {
    if (!_isValidEmail(email)) {
      throw ArgumentError('Invalid email format');
    }
    final db = await database;
    final sanitizedEmail = _sanitizeInput(email);
    return await db.query(
      'notifications',
      where: 'recipientEmail = ?',
      whereArgs: [sanitizedEmail],
      orderBy: 'createdAt DESC',
      limit: 100, // Limit notifications to prevent performance issues
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
    if (!_isValidEmail(providerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    if (serviceName.isEmpty) {
      throw ArgumentError('Service name cannot be empty');
    }
    if (price < 0 || durationMinutes <= 0) {
      throw ArgumentError('Invalid price or duration');
    }
    final db = await database;
    return await db.insert('services', {
      'providerEmail': _sanitizeInput(providerEmail),
      'serviceName': _sanitizeInput(serviceName),
      'price': price,
      'durationMinutes': durationMinutes,
      'description': description != null ? _sanitizeInput(description) : '',
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Get services by provider email
  static Future<List<Map<String, dynamic>>> getServicesByProvider(
      String providerEmail) async {
    if (!_isValidEmail(providerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    final db = await database;
    final sanitizedEmail = _sanitizeInput(providerEmail);
    return await db.query(
      'services',
      where: 'providerEmail = ? AND isActive = 1',
      whereArgs: [sanitizedEmail],
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
    if (!_isValidEmail(providerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    final db = await database;
    final sanitizedEmail = _sanitizeInput(providerEmail);
    return await db.update(
      'massagers',
      {'setupComplete': 1},
      where: 'email = ?',
      whereArgs: [sanitizedEmail],
    );
  }

  // Check if provider setup is complete
  static Future<bool> isSetupComplete(String providerEmail) async {
    final data = await findByEmail('massagers', providerEmail);
    if (data == null) return false;
    return (data['setupComplete'] as int?) == 1;
  }

  // Update massager code (sync from Firestore)
  static Future<int> updateMassagerCode({
    required String email,
    required String code,
  }) async {
    if (!_isValidEmail(email) || code.isEmpty) {
      throw ArgumentError('Invalid email or code');
    }
    final db = await database;
    final sanitizedEmail = _sanitizeInput(email);
    final sanitizedCode = _sanitizeInput(code);
    return await db.update(
      'massagers',
      {'code': sanitizedCode},
      where: 'email = ?',
      whereArgs: [sanitizedEmail],
    );
  }

  // Update booking status (approve/reject)
  static Future<int> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    if (bookingId <= 0) {
      throw ArgumentError('Invalid booking ID');
    }
    // Validate status is one of the allowed values
    final validStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
    if (!validStatuses.contains(status.toLowerCase())) {
      throw ArgumentError('Invalid status value');
    }
    final db = await database;
    return await db.update(
      'bookings',
      {'status': status},
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  // ===== CUSTOMER VISITS METHODS =====
  
  // Record customer visit (when they enter therapist code)
  static Future<void> recordCustomerVisit({
    required String therapistCode,
    required String customerEmail,
    required String customerName,
  }) async {
    if (therapistCode.isEmpty || customerEmail.isEmpty) {
      throw ArgumentError('Therapist code and customer email are required');
    }
    if (!_isValidEmail(customerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    final db = await database;
    final sanitizedCode = _sanitizeInput(therapistCode);
    final sanitizedEmail = _sanitizeInput(customerEmail);
    final sanitizedName = _sanitizeInput(customerName);
    final now = DateTime.now().toIso8601String();
    
    // Check if customer has visited before
    final existing = await db.query(
      'customer_visits',
      where: 'therapistCode = ? AND customerEmail = ?',
      whereArgs: [sanitizedCode, sanitizedEmail],
    );
    
    if (existing.isNotEmpty) {
      // Update existing record
      final visitCount = (existing.first['visitCount'] as int) + 1;
      await db.update(
        'customer_visits',
        {
          'lastVisit': now,
          'visitCount': visitCount,
        },
        where: 'therapistCode = ? AND customerEmail = ?',
        whereArgs: [sanitizedCode, sanitizedEmail],
      );
    } else {
      // Create new record
      await db.insert('customer_visits', {
        'therapistCode': sanitizedCode,
        'customerEmail': sanitizedEmail,
        'customerName': sanitizedName,
        'firstVisit': now,
        'lastVisit': now,
        'visitCount': 1,
      });
    }
  }
  
  // Get all customers who visited a therapist
  static Future<List<Map<String, dynamic>>> getCustomerVisitsByTherapistCode(
      String therapistCode) async {
    final db = await database;
    return await db.query(
      'customer_visits',
      where: 'therapistCode = ?',
      whereArgs: [therapistCode],
      orderBy: 'lastVisit DESC',
    );
  }

  // ===== REFERRAL & LOYALTY POINTS METHODS =====

  // Generate unique referral code for a customer
  static String generateReferralCode(String email) {
    final username = email.split('@')[0].toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return 'REF_${username}_$timestamp';
  }

  // Initialize loyalty points account for a customer
  static Future<int> initializeLoyaltyAccount(String customerEmail, {String? referralCode}) async {
    if (!_isValidEmail(customerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    
    final db = await database;
    final sanitizedEmail = _sanitizeInput(customerEmail);
    final code = referralCode ?? generateReferralCode(sanitizedEmail);
    
    // Check if account already exists
    final existing = await db.query(
      'loyalty_points',
      where: 'customer_email = ?',
      whereArgs: [sanitizedEmail],
    );
    
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    
    return await db.insert('loyalty_points', {
      'customer_email': sanitizedEmail,
      'points': 0,
      'lifetime_points': 0,
      'referral_code': code,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  // Get customer's loyalty points
  static Future<Map<String, dynamic>?> getLoyaltyPoints(String customerEmail) async {
    if (!_isValidEmail(customerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    
    final db = await database;
    final sanitizedEmail = _sanitizeInput(customerEmail);
    final result = await db.query(
      'loyalty_points',
      where: 'customer_email = ?',
      whereArgs: [sanitizedEmail],
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  // Get customer's referral code
  static Future<String?> getReferralCode(String customerEmail) async {
    final loyaltyData = await getLoyaltyPoints(customerEmail);
    return loyaltyData?['referral_code'] as String?;
  }

  // Save referral relationship
  static Future<int> saveReferral({
    required String referralCode,
    required String referredEmail,
  }) async {
    if (!_isValidEmail(referredEmail)) {
      throw ArgumentError('Invalid email format');
    }
    
    final db = await database;
    final sanitizedReferredEmail = _sanitizeInput(referredEmail);
    final sanitizedCode = _sanitizeInput(referralCode);
    
    // Find the referrer by their referral code
    final referrerData = await db.query(
      'loyalty_points',
      where: 'referral_code = ?',
      whereArgs: [sanitizedCode],
    );
    
    if (referrerData.isEmpty) {
      throw ArgumentError('Invalid referral code');
    }
    
    final referrerEmail = referrerData.first['customer_email'] as String;
    
    // Check if referral already exists
    final existing = await db.query(
      'referrals',
      where: 'referred_email = ?',
      whereArgs: [sanitizedReferredEmail],
    );
    
    if (existing.isNotEmpty) {
      // Customer was already referred
      return existing.first['id'] as int;
    }
    
    // Save the referral relationship
    final referralId = await db.insert('referrals', {
      'referrer_email': referrerEmail,
      'referred_email': sanitizedReferredEmail,
      'referral_code': sanitizedCode,
      'referral_date': DateTime.now().toIso8601String(),
      'status': 'active',
    });
    
    // Award signup bonus to referrer (50 points)
    await addPoints(
      customerEmail: referrerEmail,
      points: 50,
      reason: 'Referral signup bonus - ${sanitizedReferredEmail}',
    );
    
    // Award welcome bonus to new customer (25 points)
    await initializeLoyaltyAccount(sanitizedReferredEmail);
    await addPoints(
      customerEmail: sanitizedReferredEmail,
      points: 25,
      reason: 'Welcome bonus for using referral code',
    );
    
    return referralId;
  }

  // Get referral info for a customer (who referred them)
  static Future<Map<String, dynamic>?> getReferralInfo(String referredEmail) async {
    if (!_isValidEmail(referredEmail)) {
      throw ArgumentError('Invalid email format');
    }
    
    final db = await database;
    final sanitizedEmail = _sanitizeInput(referredEmail);
    final result = await db.query(
      'referrals',
      where: 'referred_email = ?',
      whereArgs: [sanitizedEmail],
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  // Get all customers referred by this customer
  static Future<List<Map<String, dynamic>>> getMyReferrals(String referrerEmail) async {
    if (!_isValidEmail(referrerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    
    final db = await database;
    final sanitizedEmail = _sanitizeInput(referrerEmail);
    return await db.query(
      'referrals',
      where: 'referrer_email = ?',
      whereArgs: [sanitizedEmail],
      orderBy: 'referral_date DESC',
    );
  }

  // Add points to customer account
  static Future<void> addPoints({
    required String customerEmail,
    required int points,
    required String reason,
    int? bookingId,
    String? referredCustomer,
  }) async {
    if (!_isValidEmail(customerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    if (points <= 0) {
      throw ArgumentError('Points must be positive');
    }
    
    final db = await database;
    final sanitizedEmail = _sanitizeInput(customerEmail);
    
    // Ensure loyalty account exists
    await initializeLoyaltyAccount(sanitizedEmail);
    
    // Update points balance
    await db.rawUpdate('''
      UPDATE loyalty_points 
      SET points = points + ?,
          lifetime_points = lifetime_points + ?,
          last_updated = ?
      WHERE customer_email = ?
    ''', [points, points, DateTime.now().toIso8601String(), sanitizedEmail]);
    
    // Record in points history
    await db.insert('points_history', {
      'customer_email': sanitizedEmail,
      'points_earned': points,
      'reason': _sanitizeInput(reason),
      'booking_id': bookingId,
      'referred_customer': referredCustomer != null ? _sanitizeInput(referredCustomer) : null,
      'earned_date': DateTime.now().toIso8601String(),
    });
  }

  // Deduct points (when customer redeems)
  static Future<bool> deductPoints({
    required String customerEmail,
    required int points,
    required String reason,
  }) async {
    if (!_isValidEmail(customerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    if (points <= 0) {
      throw ArgumentError('Points must be positive');
    }
    
    final db = await database;
    final sanitizedEmail = _sanitizeInput(customerEmail);
    
    // Check if customer has enough points
    final loyaltyData = await getLoyaltyPoints(sanitizedEmail);
    if (loyaltyData == null) {
      return false;
    }
    
    final currentPoints = loyaltyData['points'] as int;
    if (currentPoints < points) {
      return false; // Not enough points
    }
    
    // Deduct points
    await db.rawUpdate('''
      UPDATE loyalty_points 
      SET points = points - ?,
          last_updated = ?
      WHERE customer_email = ?
    ''', [points, DateTime.now().toIso8601String(), sanitizedEmail]);
    
    // Record in history as negative
    await db.insert('points_history', {
      'customer_email': sanitizedEmail,
      'points_earned': -points,
      'reason': _sanitizeInput(reason),
      'earned_date': DateTime.now().toIso8601String(),
    });
    
    return true;
  }

  // Get points history for a customer
  static Future<List<Map<String, dynamic>>> getPointsHistory(String customerEmail) async {
    if (!_isValidEmail(customerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    
    final db = await database;
    final sanitizedEmail = _sanitizeInput(customerEmail);
    return await db.query(
      'points_history',
      where: 'customer_email = ?',
      whereArgs: [sanitizedEmail],
      orderBy: 'earned_date DESC',
      limit: 50,
    );
  }

  // Award points when a referred customer makes a booking
  static Future<void> awardReferralPoints({
    required String customerEmail,
    required int bookingId,
    required double bookingAmount,
  }) async {
    if (!_isValidEmail(customerEmail)) {
      throw ArgumentError('Invalid email format');
    }
    
    // Check if this customer was referred by someone
    final referralInfo = await getReferralInfo(customerEmail);
    
    if (referralInfo != null && referralInfo['status'] == 'active') {
      final referrerEmail = referralInfo['referrer_email'] as String;
      
      // Calculate points (10% of booking amount)
      final points = (bookingAmount * 0.10).round();
      
      if (points > 0) {
        // Award points to referrer
        await addPoints(
          customerEmail: referrerEmail,
          points: points,
          reason: 'Referral booking reward',
          bookingId: bookingId,
          referredCustomer: customerEmail,
        );
        
        // Create notification for referrer
        await createNotification(
          recipientEmail: referrerEmail,
          title: '🎉 Points Earned!',
          message: 'You earned $points points from your referral\'s booking!',
          type: 'referral_reward',
        );
      }
    }
  }
}
