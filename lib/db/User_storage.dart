import 'package:event_planner/db/database.dart';
import 'package:uuid/uuid.dart';

class User_storage {
  final EventDatabase _db = EventDatabase();

  Future<String?> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final db = await _db.getDatabase();
    final id = const Uuid().v4();
    try {
      await db.insert('users', {
        'id': id,
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      });
      return id;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await _db.getDatabase();
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await _db.getDatabase();

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isEmpty) {
      return {'status': 'no_user'};
    }

    final user = result.first;

    if (user['password'] != password) {
      return {'status': 'wrong_password'};
    }

    return {'status': 'success', 'user': user};
  }
}
