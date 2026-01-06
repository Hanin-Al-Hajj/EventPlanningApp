enum GuestStatus { accepted, declined, pending }

class Guest {
  final String id;
  final String name;
  final String? email; // 👈 Optional
  final String? tableNumber; // 👈 Optional
  final GuestStatus status;
  final String phoneNumber; // 👈 Optional
  final int? plusOnes; // 👈 Optional

  Guest({
    required this.id,
    required this.name,
    this.email, // 👈 NOT required
    this.tableNumber, // 👈 NOT required
    required this.status,
    required this.phoneNumber, // 👈 NOT required
    this.plusOnes, // 👈 NOT required
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email, // Can be null
      'tableNumber': tableNumber, // Can be null
      'phoneNumber': phoneNumber, // Can be null
      'plusOnes': plusOnes, // Can be null
      'status': status.toString().split('.').last,
    };
  }

  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      tableNumber: map['tableNumber'] as String?,
      status: GuestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => GuestStatus.pending,
      ),
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      plusOnes: map['plusOnes'] as int?,
    );
  }

  Guest copyWith({
    String? id,
    String? name,
    String? email,
    String? tableNumber,
    GuestStatus? status,
    String? phoneNumber,
    int? plusOnes,
  }) {
    return Guest(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      plusOnes: plusOnes ?? this.plusOnes,
    );
  }
}
