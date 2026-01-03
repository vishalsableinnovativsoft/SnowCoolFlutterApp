class User {
  final int id;
  final String username;
  final String password;
  final String role;
  bool active;

  // ADD THESE PERMISSION FIELDS
  final bool? canCreateCustomer;
  final bool? canManageCustomer;
  final bool? canManageGoodsItem;
  final bool? canManageChallan;
  final bool? canManageProfile;
  final bool? canManageSetting;
  final bool? canManagePassbook;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.active,
    this.canCreateCustomer,
    this.canManageCustomer,
    this.canManageGoodsItem,
    this.canManageChallan,
    this.canManageProfile,
    this.canManageSetting,
    this.canManagePassbook,
  });

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    bool? active,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      active: active ?? this.active,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'] ?? '',
      role: json['role'],
      active: json['active'],
      canCreateCustomer: json['canCreateCustomer'],
      canManageCustomer: json['canManageCustomer'],
      canManageGoodsItem:
          json['canManageGoodsItem'] ?? json['canManageGood'],
      canManagePassbook: json['canManagePassbook'],
      canManageChallan: json['canManageChallan'],
      canManageProfile: json['canManageProfile'],
      canManageSetting: json['canManageSetting'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'active': active,
      'canCreateCustomer': canCreateCustomer,
      'canManageCustomer': canManageCustomer,
      'canManageGoodsItem': canManageGoodsItem,
      'canManagePassbook': canManagePassbook,
      'canManageChallan': canManageChallan,
      'canManageProfile': canManageProfile,
      'canManageSetting': canManageSetting,
    };
  }
}
