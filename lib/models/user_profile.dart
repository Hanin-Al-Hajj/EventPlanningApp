class UserProfile {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime? createdAt;

  const UserProfile({
    this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'client',
    this.createdAt,
  });

  factory UserProfile.fromApiResponse(Map<String, dynamic> response) {
    final data = _map(response['data'] ?? response['user'] ?? response);
    final user = _map(data['user']).isNotEmpty ? _map(data['user']) : data;

    return UserProfile(
      id: _int(user['id']),
      name: _text(user['name']),
      email: _text(user['email']),
      phone: _text(user['phone']),
      role: _text(user['role'], 'client'),
      createdAt: _date(user['created_at']),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || name.trim().isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get roleLabel {
    if (role.isEmpty) return 'Client';
    return '${role[0].toUpperCase()}${role.substring(1)}';
  }

  String get memberSinceLabel {
    if (createdAt == null) return 'Member since recently';

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return 'Member since ${months[createdAt!.month - 1]} ${createdAt!.year}';
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static String _text(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
