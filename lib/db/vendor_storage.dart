import 'package:event_planner/db/database.dart';
import 'package:event_planner/models/vendor.dart';


Future<void> insertVendor(Vendor vendor) async {
  final db = await EventDatabase().getDatabase();
  await db.insert('vendors', vendor.toMap());
}


Future<List<Vendor>> loadVendors() async {
  final db = await EventDatabase().getDatabase();
  final List<Map<String, dynamic>> maps = await db.query('vendors');
  return List.generate(maps.length, (i) => Vendor.fromMap(maps[i]));
}


Future<List<Vendor>> loadVendorsByCategory(String category) async {
  final db = await EventDatabase().getDatabase();
  final List<Map<String, dynamic>> maps = await db.query(
    'vendors',
    where: 'category = ?',
    whereArgs: [category],
  );
  return List.generate(maps.length, (i) => Vendor.fromMap(maps[i]));
}


Future<List<Vendor>> searchVendors(String query) async {
  final db = await EventDatabase().getDatabase();
  final List<Map<String, dynamic>> maps = await db.query(
    'vendors',
    where: 'name LIKE ?',
    whereArgs: ['%$query%'],
  );
  return List.generate(maps.length, (i) => Vendor.fromMap(maps[i]));
}


Future<void> updateVendor(Vendor vendor) async {
  final db = await EventDatabase().getDatabase();
  await db.update(
    'vendors',
    vendor.toMap(),
    where: 'id = ?',
    whereArgs: [vendor.id],
  );
}


Future<void> deleteVendor(Vendor vendor) async {
  final db = await EventDatabase().getDatabase();
  await db.delete('vendors', where: 'id = ?', whereArgs: [vendor.id]);
}

Future<void> seedSampleVendors() async {
  final db = await EventDatabase().getDatabase();

  final count = await db.rawQuery('SELECT COUNT(*) as count FROM vendors');
  if (count[0]['count'] as int > 0) {
    return; // Already seeded, don't add more
  }
  final sampleVendors = [
    Vendor(
      id: '1',
      name: 'THE FLOWER SHOP',
      category: 'Decoration',
      rating: 4.8,

      imageIcon: '💐',
      phoneNumber: '03795481',
      description: 'Professional flower decoration for all events',
    ),
    Vendor(
      id: '2',
      name: 'Cremino',
      category: 'Catering',
      rating: 4.6,

      imageIcon: '🍰',
      phoneNumber: '01 453 800',
      description:
          'High-end dessert shop offering specialty & custom cakes,ice cream % chocolates',
    ),
    Vendor(
      id: '3',
      name: 'Aljawad Dining',
      category: 'catering',
      rating: 4.3,

      imageIcon: '🍴',
      phoneNumber: '03 456 854',
      description: 'Outdoor seating . Great cocktails . Vegan options',
    ),

    Vendor(
      id: '4',
      name: 'Planto',
      category: 'Decoration',
      rating: 2.5,

      imageIcon: '💐',
      phoneNumber: '03  921 490',
      description:
          'Planto is a modern flower shop in Beirut ,Lebanon,known for its artistic and elegant floral arrangements.They offer fresh stylish bouquets perfect for any occasion ,blending creativity with natural beauty',
    ),
    Vendor(
      id: '5',
      name: 'Lancaster Eden Bay',
      category: 'Venue',
      rating: 3.3,

      imageIcon: '🎆',
      phoneNumber: '01 838 000',
      description:
          "Dreams become reality in Lancaster Eden Bay's Ballroom, Beirut's most luxurious venue and most sought-after locations for fairytale.The room gathers your 600 guests in a magnificently designed ballroom that suits your festive occasion",
    ),
  ];
  for (var vendor in sampleVendors) {
    final existing = await db.query(
      'vendors',
      where: 'id=?',
      whereArgs: [vendor.id],
    );
    if (existing.isEmpty) {
      await insertVendor(vendor);
    }
  }
}
