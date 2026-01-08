enum GuestStatus { accepted, declined, pending }

class Guest {
  final String id;
  final String name;
  final String? email; 
  final String? tableNumber; 
  final GuestStatus status;
  final String phoneNumber; 
  final int? plusOnes; 

  Guest({
    required this.id,
    required this.name,
    this.email, 
    this.tableNumber, 
    required this.status,
    required this.phoneNumber, 
    this.plusOnes, 
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email, 
      'tableNumber': tableNumber, 
      'phoneNumber': phoneNumber, 
      'plusOnes': plusOnes, 
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
