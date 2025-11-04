
class User {
  final String id;
  final String username;
  final String password;
  final String role;
  bool active;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.active,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'], // Support both _id and id
      username: json['username'],
      password: json['password'] ?? '',
      role: json['role'],
      active: json['active'] ?? false,
    );
  }
}
