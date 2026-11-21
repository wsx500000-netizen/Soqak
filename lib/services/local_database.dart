import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final path = join(await getDatabasesPath(), 'soqak.db');
    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE listings (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            location TEXT NOT NULL,
            price INTEGER NOT NULL,
            imageUrl TEXT NOT NULL,
            description TEXT NOT NULL,
            isFeatured INTEGER NOT NULL,
            isMine INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'approved'
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites (
            listingId TEXT PRIMARY KEY
          )
        ''');
        await db.execute('''
          CREATE TABLE cart (
            listingId TEXT PRIMARY KEY,
            quantity INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE chats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            text TEXT NOT NULL,
            sentByMe INTEGER NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            total INTEGER NOT NULL
          )
        ''');
        await _createAdminTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE listings ADD COLUMN status TEXT NOT NULL DEFAULT 'approved'");
        }
        await _createAdminTables(db);
        if (oldVersion < 3) {
          final columns = await db.rawQuery('PRAGMA table_info(users)');
          final names = columns.map((column) => column['name']).toSet();
          if (!names.contains('passwordSalt')) {
            await db.execute(
                "ALTER TABLE users ADD COLUMN passwordSalt TEXT NOT NULL DEFAULT ''");
          }
          if (!names.contains('passwordHash')) {
            await db.execute(
                "ALTER TABLE users ADD COLUMN passwordHash TEXT NOT NULL DEFAULT ''");
          }
        }
      },
    );
    return _database!;
  }

  Future<void> _createAdminTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        email TEXT PRIMARY KEY COLLATE NOCASE,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        passwordSalt TEXT NOT NULL DEFAULT '',
        passwordHash TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS admin_credentials (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        salt TEXT NOT NULL,
        passwordHash TEXT NOT NULL
      )
    ''');
  }

  Future<bool> get hasAdminAccount async {
    final db = await database;
    final rows = await db.query('admin_credentials', limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> createAdminAccount(String password) async {
    final db = await database;
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final encodedSalt = base64Encode(salt);
    final hash = await _derivePasswordHash(password, salt);
    await db.insert('admin_credentials', {
      'id': 1,
      'salt': encodedSalt,
      'passwordHash': hash,
    });
  }

  Future<bool> verifyAdminPassword(String password) async {
    final db = await database;
    final rows = await db.query('admin_credentials', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return false;
    final row = rows.first;
    final salt = base64Decode(row['salt'] as String);
    final actual = await _derivePasswordHash(password, salt);
    final expected = row['passwordHash'] as String;
    return _constantTimeEquals(actual, expected);
  }

  Future<bool> registerLocalUser(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return false;
    final db = await database;
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    await db.insert('users', {
      'email': normalizedEmail,
      'isActive': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'passwordSalt': base64Encode(salt),
      'passwordHash': await _derivePasswordHash(password, salt),
    });
    return true;
  }

  Future<bool> authenticateLocalUser(String email, String password) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['isActive'] != 1) return false;
    final row = rows.first;
    final saltValue = row['passwordSalt'] as String;
    final expected = row['passwordHash'] as String;
    if (saltValue.isEmpty || expected.isEmpty) return false;
    final actual = await _derivePasswordHash(password, base64Decode(saltValue));
    return _constantTimeEquals(actual, expected);
  }

  Future<String> _derivePasswordHash(String password, List<int> salt) async {
    final passwordBytes = utf8.encode(password);
    var block =
        Hmac(sha256, passwordBytes).convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(block);
    for (var iteration = 1; iteration < 120000; iteration++) {
      block = Hmac(sha256, passwordBytes).convert(block).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= block[index];
      }
      if (iteration % 2048 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    return base64Encode(result);
  }

  bool _constantTimeEquals(String first, String second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first.codeUnitAt(index) ^ second.codeUnitAt(index);
    }
    return difference == 0;
  }
}
