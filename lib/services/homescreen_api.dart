// lib/services/homescreen_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:snow_trading_cool/utils/api_config.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';

class DashboardSummary {
  final int totalCustomers;
  final int totalDeliveredChallans;
  final int totalReceivedChallans;
  final List<ProductSummary> productSummaries;

  DashboardSummary({
    required this.totalCustomers,
    required this.totalDeliveredChallans,
    required this.totalReceivedChallans,
    required this.productSummaries,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    var list = json['productSummaries'] as List;
    List<ProductSummary> products =
        list.map((i) => ProductSummary.fromJson(i)).toList();

    return DashboardSummary(
      totalCustomers: json['totalCustomers'] ?? 0,
      totalDeliveredChallans: json['totalDeliveredChallans'] ?? 0,
      totalReceivedChallans: json['totalReceivedChallans'] ?? 0,
      productSummaries: products,
    );
  }
}

class ProductSummary {
  final String productName;
  final int totalDelivered;
  final int totalReceived;

  ProductSummary({
    required this.productName,
    required this.totalDelivered,
    required this.totalReceived,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      productName: json['productName'] ?? '',
      totalDelivered: json['totalDelivered'] ?? 0,
      totalReceived: json['totalReceived'] ?? 0,
    );
  }
}

class HomeScreenApi {
  static final HomeScreenApi _instance = HomeScreenApi._internal();
  factory HomeScreenApi() => _instance;
  HomeScreenApi._internal();

  Future<DashboardSummary?> getDashboardData() async {
    final token = TokenManager().getToken();
    if (token == null || token.isEmpty) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/challans/getDashboardData');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DashboardSummary.fromJson(json);
      } else {
        print('Dashboard API error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching dashboard data: $e');
      return null;
    }
  }
}