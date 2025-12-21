import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class EventDatabase {
  // this method returns a Future<Database> object, so it should be an async method
  Future<Database> getDatabase() async {
    // get the default databases location
    String dbPath = await getDatabasesPath();
    // If the database is already created, get an instance of it.
    // If it is not there, onCreate is executed
    Database db = await openDatabase(
      // to avoid errors in the database path use join method
      // the database name should always end with .db
      join(dbPath, 'eventflow.db'),
      // executed only when the database is not there or when the version is incremented
      onCreate: (db, version) => db.execute(
        'CREATE TABLE events(id TEXT PRIMARY KEY, title TEXT, date INT, location TEXT, guests INT, budget DOUBLE, progress DOUBLE, status TEXT)',
      ),
      // increment version number only when the database scheme changes: add/drop table, add/drop column, add/drop relation
      version: 1,
    );
    return db;
  }
}
