import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class EventDatabase {
  static final EventDatabase _instance = EventDatabase._internal();
  static Database? _database;

  factory EventDatabase() {
    return _instance;
  }

  EventDatabase._internal();

  Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();

    Database db = await openDatabase(
      join(dbPath, 'eventflow.db'),
      onCreate: (db, version) async {
        // Events table
        await db.execute(
          'CREATE TABLE events(id TEXT PRIMARY KEY, title TEXT, date INT, location TEXT, guests INT, budget DOUBLE, progress DOUBLE, status TEXT)',
        );

        // Guests table
        await db.execute('''
          CREATE TABLE guests(
            id TEXT PRIMARY KEY,
            eventId TEXT NOT NULL,
            name TEXT NOT NULL,
            email TEXT,
            tableNumber TEXT,
            status TEXT NOT NULL,
            phoneNumber TEXT,
            plusOnes INTEGER,
            FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
          )
        ''');

        // Budget expenses table
        await db.execute('''
          CREATE TABLE budget_expenses(
            id TEXT PRIMARY KEY,
            eventId TEXT NOT NULL,
            category TEXT NOT NULL,
            allocatedAmount DOUBLE NOT NULL,
            amountSpent DOUBLE NOT NULL,
            FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
          )
        ''');

        // Timeline tasks table
        await db.execute('''
          CREATE TABLE timeline_tasks(
            id TEXT PRIMARY KEY,
            eventId TEXT NOT NULL,
            title TEXT NOT NULL,
            timeframe TEXT NOT NULL,
            daysBeforeEvent INTEGER NOT NULL,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE vendors(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            rating DOUBLE NOT NULL,
            imageIcon TEXT NOT NULL,
            phoneNumber TEXT,
            email TEXT,
            website TEXT,
            description TEXT
          )
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS guests(
              id TEXT PRIMARY KEY,
              eventId TEXT NOT NULL,
              name TEXT NOT NULL,
              email TEXT,
              tableNumber TEXT,
              status TEXT NOT NULL,
              phoneNumber TEXT,
              plusOnes INTEGER,
              FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
            )
          ''');
        }

        // Version 3 - Recreate guests table with optional fields
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS guests');

          await db.execute('''
            CREATE TABLE guests(
              id TEXT PRIMARY KEY,
              eventId TEXT NOT NULL,
              name TEXT NOT NULL,
              email TEXT,
              tableNumber TEXT,
              status TEXT NOT NULL,
              phoneNumber TEXT,
              plusOnes INTEGER,
              FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
            )
          ''');
        }

        // Version 4 - Add budget expenses table
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS budget_expenses(
              id TEXT PRIMARY KEY,
              eventId TEXT NOT NULL,
              category TEXT NOT NULL,
              allocatedAmount DOUBLE NOT NULL,
              amountSpent DOUBLE NOT NULL,
              FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
            )
          ''');
        }

        // Version 5 - Add timeline tasks table
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS timeline_tasks(
              id TEXT PRIMARY KEY,
              eventId TEXT NOT NULL,
              title TEXT NOT NULL,
              timeframe TEXT NOT NULL,
              daysBeforeEvent INTEGER NOT NULL,
              isCompleted INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 10) {
          // Drop and recreate vendors table to remove duplicates
          await db.execute('DROP TABLE IF EXISTS vendors');
          await db.execute('''
    CREATE TABLE vendors(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      rating DOUBLE NOT NULL,
      imageIcon TEXT NOT NULL,
      phoneNumber TEXT,
      email TEXT,
      website TEXT,
      description TEXT
    )
  ''');
        }
      },
      version: 10,
    );

    return db;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
