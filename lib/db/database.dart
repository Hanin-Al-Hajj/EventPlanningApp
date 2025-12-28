import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class EventDatabase {
  // Singleton pattern to ensure only one database instance
  static final EventDatabase _instance = EventDatabase._internal();
  static Database? _database;

  // Factory constructor returns the same instance every time
  factory EventDatabase() {
    return _instance;
  }

  // Private constructor
  EventDatabase._internal();

  // Get database instance
  Future<Database> getDatabase() async {
    // If database already exists, return it
    if (_database != null) return _database!;
    // Otherwise, initialize it
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();

    Database db = await openDatabase(
      join(dbPath, 'eventflow.db'),
      onCreate: (db, version) async {
        // Create events table (your existing table)
        await db.execute(
          'CREATE TABLE events(id TEXT PRIMARY KEY, title TEXT, date INT, location TEXT, guests INT, budget DOUBLE, progress DOUBLE, status TEXT)',
        );

        // Create guests table (NEW!)
        await db.execute('''
          CREATE TABLE guests(
            id TEXT PRIMARY KEY,
            eventId TEXT NOT NULL,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            tableNumber TEXT,
            status TEXT NOT NULL,
            phoneNumber TEXT,
            plusOnes INTEGER,
            FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // This runs when you upgrade from version 1 to version 2
        if (oldVersion < 2) {
          // Add guests table for existing users
          await db.execute('''
            CREATE TABLE IF NOT EXISTS guests(
              id TEXT PRIMARY KEY,
              eventId TEXT NOT NULL,
              name TEXT NOT NULL,
              email TEXT NOT NULL,
              tableNumber TEXT,
              status TEXT NOT NULL,
              phoneNumber TEXT,
              plusOnes INTEGER,
              FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
            )
          ''');
        }
      },
      version: 2, // CHANGED from 1 to 2!
    );

    return db;
  }

  // Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
