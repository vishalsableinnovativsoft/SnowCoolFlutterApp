
import 'package:flutter/material.dart';
import 'package:snow_trading_cool/services/user_api.dart';

class DevUtils {
  static Future<void> createDemoAdmin() async {
    final userApi = UserApi();
    try {
      final response = await userApi.createOrUpdateUser(
        username: 'admin',
        password: 'password',
        role: 'Admin',
        active: true,
        canCreateCustomer: true,
        canManageCustomer: true,
        canManageGoodsItem: true,
        canManageChallan: true,
        canManageProfile: true,
        canManageSetting: true,
        canManagePassbook: true,
      );
      if (response.success) {
        debugPrint('Demo admin created successfully');
      } else {
        debugPrint('Failed to create demo admin: ${response.message}');
      }
    } catch (e) {
      debugPrint('Error creating demo admin: $e');
    }
  }
}
