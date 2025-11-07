// Updated customer_api.dart - Added createCustomer, getCustomerById, getAllCustomers, updateCustomer, deleteCustomer methods
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

/// Customer DTO – used by CustomerApi and ChallanScreen
class CustomerDTO {
  final int id;
  final String name;
  final String? address;
  final String contactNumber;
  final String? email;

  CustomerDTO({
    required this.id,
    required this.name,
    this.address,
    required this.contactNumber,
    this.email,
  });

  factory CustomerDTO.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return CustomerDTO(
      id: parseId(json['id']),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      contactNumber: json['contactNumber']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
    };
  }
}

class CustomerApi {
  final String baseUrl;

  CustomerApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<List<CustomerDTO>> searchCustomers(String? nameQuery) async {
    // Removed empty check - backend should handle empty as partial/full search
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final queryParams = <String, String>{
      if (nameQuery != null && nameQuery.isNotEmpty) 'name': nameQuery,
    };

    final url = Uri.parse('$normalizedBase/api/v1/customers/search')
        .replace(queryParameters: queryParams);

    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;
        return jsonList
            .map((json) => CustomerDTO.fromJson(json))
            .toList();
      } else if (resp.statusCode == 401) {
        throw Exception('Unauthorized - Please log in again');
      } else {
        throw Exception('Failed to search customers');
      }
    } catch (e) {
      throw Exception('Error searching customers: $e');
    }
  }

  // New: Get all customers (GET /api/v1/customers)
  Future<List<CustomerDTO>> getAllCustomers() async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/customers');

    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;
        return jsonList
            .map((json) => CustomerDTO.fromJson(json))
            .toList();
      } else if (resp.statusCode == 401) {
        throw Exception('Unauthorized - Please log in again');
      } else {
        throw Exception('Failed to fetch all customers');
      }
    } catch (e) {
      throw Exception('Error fetching all customers: $e');
    }
  }

  // New method for creating customer
  Future<CustomerResponse> createCustomer({
    required String name,
    required String mobile,
    required String email,
    required String address,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/customers');
    final body = jsonEncode({
      'name': name,
      'contactNumber': mobile,
      'email': email,
      'address': address,
    });

    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
        return CustomerResponse.fromJson(jsonResp);
      } else {
        throw Exception('Failed to create customer');
      }
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  // New method for getting customer by ID
  Future<CustomerResponse> getCustomerById(String customerId) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/customers/$customerId');

    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
        return CustomerResponse.fromJson(jsonResp);
      } else {
        throw Exception('Customer not found');
      }
    } catch (e) {
      throw Exception('Error fetching customer: $e');
    }
  }

  // New: Update customer (PUT /api/v1/customers/{id})
  Future<CustomerResponse> updateCustomer(
    int id,
    String name,
    String mobile,
    String email,
    String address,
  ) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/customers/$id');
    final body = jsonEncode({
      'name': name,
      'contactNumber': mobile,
      'email': email,
      'address': address,
    });

    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .put(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        final Map<String, dynamic> jsonResp = resp.body.isNotEmpty
            ? jsonDecode(resp.body)
            : {'success': true, 'message': 'Customer updated successfully'};
        return CustomerResponse.fromJson(jsonResp);
      } else {
        throw Exception('Failed to update customer');
      }
    } catch (e) {
      throw Exception('Error updating customer: $e');
    }
  }

  // New: Delete customer (DELETE /api/v1/customers/{id})
  Future<CustomerResponse> deleteCustomer(int id) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/customers/$id');

    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return CustomerResponse(
          success: true,
          message: 'Customer deleted successfully',
        );
      } else {
        throw Exception('Failed to delete customer');
      }
    } catch (e) {
      throw Exception('Error deleting customer: $e');
    }
  }
}

/// Response for customer operations
class CustomerResponse {
  final bool success;
  final String? message;
  final CustomerDTO? data;

  CustomerResponse({required this.success, this.message, this.data});

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      success: json['success'] == true || json['data'] != null,
      message: json['message']?.toString(),
      data: json['data'] != null ? CustomerDTO.fromJson(json['data']) : null,
    );
  }
}