import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Vendor {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String imageIcon;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? description;

  Vendor({
    String? id,
    required this.name,
    required this.category,
    required this.rating,
    required this.imageIcon,
    this.phoneNumber,
    this.email,
    this.website,
    this.description,
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
    );
  }
}
