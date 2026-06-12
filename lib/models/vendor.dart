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
    required this.id,
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
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      imageIcon: json['imageIcon'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      website: json['website'],
      description: json['description'],
      isFavorite: json['is_favorite'] ?? false,
      locations: (json['locations'] is List)
          ? List<String>.from(json['locations'])
          : (json['locations'] is String &&
                (json['locations'] as String).isNotEmpty)
          ? (json['locations'] as String).split('|')
          : [],
      instagram: json['instagram'],
    );
  }

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
      id: map['id'].toString(),
      name: map['name'],
      category: map['category'],
      rating: (map['rating'] as num).toDouble(),
      imageIcon: map['imageIcon'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
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
