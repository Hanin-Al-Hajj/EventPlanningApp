import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Vendor {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String imageIcon;
  final String phoneNumber;
  final String? email;
  final String? website;
  final String? description;
  final List<String> locations;
  final String? instagram;
  bool isFavorite;

  Vendor({
    String? id,
    required this.name,
    required this.category,
    required this.rating,
    required this.imageIcon,
    required this.phoneNumber,
    this.email,
    this.website,
    this.description,
    required this.locations,
    this.isFavorite = false,
    this.instagram,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rating': rating,
      'imageIcon': imageIcon,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'description': description,
      'isFavorite': isFavorite ? 1 : 0,
      'location': locations.join('|'),
      'instagram': instagram,
    };
  }

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      rating: map['rating'],
      imageIcon: map['imageIcon'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      website: map['website'],
      description: map['description'],
      isFavorite: map['isFavorite'] == 1,
      locations:
          map['location'] != null && (map['location'] as String).isNotEmpty
          ? (map['location'] as String).split('|')
          : [],
      instagram: map['instagram'],
    );
  }
}
