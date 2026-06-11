import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/smartwatch.dart';
import '../models/alarm.dart';
import '../models/report.dart';
import '../models/person.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tawfik.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Updated version for new table
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Smartwatches table
    await db.execute('''
      CREATE TABLE smartwatches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL
      )
    ''');

    // Alarms table
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        watch_id INTEGER NOT NULL,
        medicine_name TEXT NOT NULL,
        time TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (watch_id) REFERENCES smartwatches (id) ON DELETE CASCADE
      )
    ''');

    // Reports table
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        pdf_path TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Persons table
    await db.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add persons table for existing databases
      await db.execute('''
        CREATE TABLE persons (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          image_path TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // Smartwatch CRUD operations
  Future<int> createSmartwatch(Smartwatch smartwatch) async {
    final db = await database;
    return await db.insert('smartwatches', smartwatch.toMap());
  }

  Future<List<Smartwatch>> getAllSmartwatches() async {
    final db = await database;
    final maps = await db.query('smartwatches', orderBy: 'name ASC');
    return maps.map((map) => Smartwatch.fromMap(map)).toList();
  }

  Future<Smartwatch?> getSmartwatch(int id) async {
    final db = await database;
    final maps = await db.query(
      'smartwatches',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Smartwatch.fromMap(maps.first);
  }

  Future<int> updateSmartwatch(Smartwatch smartwatch) async {
    final db = await database;
    return await db.update(
      'smartwatches',
      smartwatch.toMap(),
      where: 'id = ?',
      whereArgs: [smartwatch.id],
    );
  }

  Future<int> deleteSmartwatch(int id) async {
    final db = await database;
    // Delete associated alarms first
    await db.delete('alarms', where: 'watch_id = ?', whereArgs: [id]);
    // Delete smartwatch
    return await db.delete('smartwatches', where: 'id = ?', whereArgs: [id]);
  }

  // Alarm CRUD operations
  Future<int> createAlarm(Alarm alarm) async {
    final db = await database;
    return await db.insert('alarms', alarm.toMap());
  }

  Future<List<Alarm>> getAlarmsForWatch(int watchId) async {
    final db = await database;
    final maps = await db.query(
      'alarms',
      where: 'watch_id = ?',
      whereArgs: [watchId],
      orderBy: 'time ASC',
    );
    return maps.map((map) => Alarm.fromMap(map)).toList();
  }

  Future<int> updateAlarm(Alarm alarm) async {
    final db = await database;
    return await db.update(
      'alarms',
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<int> deleteAlarm(int id) async {
    final db = await database;
    return await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }

  // Report CRUD operations
  Future<int> createReport(Report report) async {
    final db = await database;
    return await db.insert('reports', report.toMap());
  }

  Future<List<Report>> getAllReports() async {
    final db = await database;
    final maps = await db.query('reports', orderBy: 'created_at DESC');
    return maps.map((map) => Report.fromMap(map)).toList();
  }

  Future<int> deleteReport(int id) async {
    final db = await database;
    return await db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }

  // Person CRUD operations
  Future<int> createPerson(Person person) async {
    final db = await database;
    return await db.insert('persons', person.toMap());
  }

  Future<List<Person>> getAllPersons() async {
    final db = await database;
    final maps = await db.query('persons', orderBy: 'name ASC');
    return maps.map((map) => Person.fromMap(map)).toList();
  }

  Future<Person?> getPerson(int id) async {
    final db = await database;
    final maps = await db.query('persons', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Person.fromMap(maps.first);
  }

  Future<int> updatePerson(Person person) async {
    final db = await database;
    return await db.update(
      'persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> deletePerson(int id) async {
    final db = await database;
    return await db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
