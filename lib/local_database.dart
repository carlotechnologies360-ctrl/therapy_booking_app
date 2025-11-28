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
      version: 2,   // increase version when schema changes
      onCreate: _createDB,
    );
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
}
