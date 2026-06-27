
enum GuestStatus {
  pending,
  accepted,
  declined;

  static GuestStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return GuestStatus.accepted;
      case 'declined':
        return GuestStatus.declined;
      case 'pending':
      default:
        return GuestStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case GuestStatus.accepted:
        return 'accepted';
      case GuestStatus.declined:
        return 'declined';
      case GuestStatus.pending:
        return 'pending';
    }
  }
}

class Guest {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final GuestStatus status;
  final String? tableNumber;
  final int? plusOnes;
  final String? plusOneName; // NEW: Plus one name
  final String? dietaryRestrictions; // NEW: Dietary restrictions
  final String? notes; // NEW: Notes
  final bool invitationSent; // NEW: Track if invitation was sent
  final String? invitationSentAt; // NEW: When invitation was sent
  final String? checkInTime; // NEW: Check-in time
  final String? rsvpToken; // NEW: RSVP token

  Guest({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.status,
    this.tableNumber,
    this.plusOnes,
    this.plusOneName,
    this.dietaryRestrictions,
    this.notes,
    this.invitationSent = false,
    this.invitationSentAt,
    this.checkInTime,
    this.rsvpToken,
  });

  // Convert from API JSON to Guest object
  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone'] ?? '',
      status: GuestStatus.fromString(json['rsvp_status'] ?? 'pending'),
      tableNumber: json['table_number'],
      plusOnes: json['plus_one_allowed'] == true
          ? (json['plus_one_name'] != null ? 1 : 1)
          : 0,
      plusOneName: json['plus_one_name'],
      dietaryRestrictions: json['dietary_restrictions'],
      notes: json['notes'],
      invitationSent: json['invitation_sent'] ?? false,
      invitationSentAt: json['invitation_sent_at'],
      checkInTime: json['check_in_time'],
      rsvpToken: json['rsvp_token'],
    );
  }

  // Convert Guest object to API JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phoneNumber,
      'plus_one_allowed': (plusOnes != null && plusOnes! > 0),
      'plus_one_name': plusOneName,
      'dietary_restrictions': dietaryRestrictions,
      'notes': notes,
    };
  }

  // Create a copy with updated fields
  Guest copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    GuestStatus? status,
    String? tableNumber,
    int? plusOnes,
    String? plusOneName,
    String? dietaryRestrictions,
    String? notes,
    bool? invitationSent,
    String? invitationSentAt,
    String? checkInTime,
    String? rsvpToken,
  }) {
    return Guest(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      tableNumber: tableNumber ?? this.tableNumber,
      plusOnes: plusOnes ?? this.plusOnes,
      plusOneName: plusOneName ?? this.plusOneName,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      notes: notes ?? this.notes,
      invitationSent: invitationSent ?? this.invitationSent,
      invitationSentAt: invitationSentAt ?? this.invitationSentAt,
      checkInTime: checkInTime ?? this.checkInTime,
      rsvpToken: rsvpToken ?? this.rsvpToken,
    );
  }

  // Add these methods to your Guest model in lib/models/Guest.dart

  // Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'status': status.apiValue,
      'tableNumber': tableNumber,
      'plusOnes': plusOnes,
      'plusOneName': plusOneName,
      'dietaryRestrictions': dietaryRestrictions,
      'notes': notes,
      'invitationSent': invitationSent ? 1 : 0,
      'invitationSentAt': invitationSentAt,
      'checkInTime': checkInTime,
      'rsvpToken': rsvpToken,
    };
  }

  // Create from Map (SQLite)
  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      status: GuestStatus.fromString(map['status'] ?? 'pending'),
      tableNumber: map['tableNumber'],
      plusOnes: map['plusOnes'],
      plusOneName: map['plusOneName'],
      dietaryRestrictions: map['dietaryRestrictions'],
      notes: map['notes'],
      invitationSent: map['invitationSent'] == 1,
      invitationSentAt: map['invitationSentAt'],
      checkInTime: map['checkInTime'],
      rsvpToken: map['rsvpToken'],
    );
  }
}
