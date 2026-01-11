import 'package:event_planner/db/database.dart';
import 'package:event_planner/models/Guest.dart';
import 'package:sqflite/sqflite.dart';

class GuestStorage {
  static Future<Database> get _database async {
    final eventDb = EventDatabase();
    return await eventDb.getDatabase();
  }

  static Future<void> insertGuest(Guest guest, String eventId) async {
    final db = await _database;
    final guestMap = guest.toMap();
    guestMap['eventId'] = eventId;

    await db.insert(
      'guests',
      guestMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Guest>> loadGuestsForEvent(String eventId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'guests',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Guest.fromMap(maps[i]));
  }

  static Future<void> updateGuest(Guest guest, String eventId) async {
    final db = await _database;
    final guestMap = guest.toMap();
    guestMap['eventId'] = eventId;

    await db.update(
      'guests',
      guestMap,
      where: 'id = ? AND eventId = ?',
      whereArgs: [guest.id, eventId],
    );
  }

  static Future<void> deleteGuest(String guestId, String eventId) async {
    final db = await _database;
    await db.delete(
      'guests',
      where: 'id = ? AND eventId = ?',
      whereArgs: [guestId, eventId],
    );
  }

  static Future<void> deleteAllGuestsForEvent(String eventId) async {
    final db = await _database;
    await db.delete('guests', where: 'eventId = ?', whereArgs: [eventId]);
  }

  static Future<Map<String, int>> getGuestStatsByEvent(String eventId) async {
    final guests = await loadGuestsForEvent(eventId);

    return {
      'accepted': guests.where((g) => g.status == GuestStatus.accepted).length,
      'declined': guests.where((g) => g.status == GuestStatus.declined).length,
      'pending': guests.where((g) => g.status == GuestStatus.pending).length,
      'total': guests.length,
    };
  }

 
  static Future<List<Guest>> searchGuests(String eventId, String query) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'guests',
      where: 'eventId = ? AND (name LIKE ? OR email LIKE ?)',
      whereArgs: [eventId, '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Guest.fromMap(maps[i]));
  }

  
  static Future<int> getGuestCount(String eventId) async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM guests WHERE eventId = ?',
      [eventId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
