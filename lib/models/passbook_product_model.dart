class PassbookProduct {
  final String name;
  final double openingBalance;
  final double closingBalance;

  PassbookProduct({
    required this.name,
    required this.openingBalance,
    required this.closingBalance,
  });

  factory PassbookProduct.fromJson(Map<String, dynamic> json) {
    return PassbookProduct(
      name: json['name'] ?? '',
      openingBalance: (json['openingBalance'] ?? 0).toDouble(),
      closingBalance: (json['closingBalance'] ?? 0).toDouble(),
    );
  }
}
