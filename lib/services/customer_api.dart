import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snow_trading_cool/screens/view_customer_screen.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

/// Customer DTO
class CustomerDTO {
  final int id;
  final String name;
  final String? address;
  final String contactNumber;
  final String? email;
  final String? reminder;
  final double? deposite;
  final double? runningBalance;
  final List<Map<String, dynamic>>? items;

  CustomerDTO({
    required this.id,
    required this.name,
    this.address,
    required this.contactNumber,
    this.email,
    this.reminder,
    this.deposite,
    this.runningBalance,
    this.items,
  });

  factory CustomerDTO.fromJson(Map<String, dynamic> json) {
    return CustomerDTO(
      id: _parseInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      address: json['address']?.toString().trim(),
      contactNumber: (json['contactNumber'] ?? '').toString().trim(),
      email: json['email']?.toString().trim(),
      reminder: json['reminder']?.toString().trim(),
      deposite: _parseDouble(json['deposite']),
      runningBalance: _parseDouble(json['runningBalance']),
      items: json['items'] is List
          ? List<Map<String, dynamic>>.from(json['items'])
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

// class CustomerResponse {
//   final bool success;
//   final String? message;
//   final CustomerDTO? data;

//   CustomerResponse({required this.success, this.message, this.data});

//   factory CustomerResponse.fromJson(Map<String, dynamic> json) {
//     return CustomerResponse(
//       success: json['success'] == true || json['data'] != null,
//       message: json['message']?.toString(),
//       data: json['data'] != null ? CustomerDTO.fromJson(json['data']) : null,
//     );
//   }
// }

class CustomerResponse {
  final bool success;
  final String? message;
  final CustomerDTO? data;

  CustomerResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    // Check if response has wrapper fields
    if (json.containsKey('success') || json.containsKey('data')) {
      return CustomerResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String?,
        data: json['data'] != null ? CustomerDTO.fromJson(json['data']) : null,
      );
    } else {
      // Direct customer object → treat as success with data
      return CustomerResponse(
        success: true,
        message: null,
        data: CustomerDTO.fromJson(json),
      );
    }
  }
}

class CustomerPageResponse {
  final List<CustomerDTO> content;
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;

  CustomerPageResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
  });

  factory CustomerPageResponse.fromJson(Map<String, dynamic> json) {
    final contentList =
        (json['content'] as List<dynamic>?)
            ?.map((e) => CustomerDTO.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <CustomerDTO>[];
    return CustomerPageResponse(
      content: contentList,
      totalPages: json['totalPages'] ?? 1,
      totalElements: json['totalElements'] ?? contentList.length,
      size: json['size'] ?? 10,
      number: json['number'] ?? 0,
    );
  }
}

/// MAIN CUSTOMER API – FULLY FIXED
class CustomerApi {
  final String baseUrl;
  final TokenManager _tokenManager = TokenManager();

  CustomerApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> _getHeaders() {
    final token = _tokenManager.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _normalize() => baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  String _extractErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        return json['message']?.toString() ?? 'Server error';
      }
    } catch (_) {}
    return 'Server error (HTTP ${response.statusCode})';
  }

  /// REQUIRED BY CHALLAN SCREEN
  Future<List<CustomerDTO>> getAllCustomers() async {
    final url = Uri.parse('${_normalize()}/api/v1/customers/all');
    final headers = _getHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final List<dynamic> list = jsonDecode(resp.body);
        return list
            .map((e) => CustomerDTO.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// NEW: Dedicated clean paginated endpoint (no search params)
  Future<CustomerPageResponse> getCustomersPageClean({
    int page = 0,
    int size = 10,
  }) async {
    final url = Uri.parse(
      '${_normalize()}/api/v1/customers/page',
    ).replace(queryParameters: {'page': '$page', 'size': '$size'});

    final headers = _getHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        return CustomerPageResponse.fromJson(jsonDecode(resp.body));
      } else {
        throw Exception(_extractErrorMessage(resp));
      }
    } catch (e) {
      debugPrint("Clean page API error: $e");
      rethrow;
    }
  }

  /// UNIFIED SMART SEARCH + PAGINATION (Replaces getCustomersPage & getCustomersPageClean)
  Future<CustomerPageResponse> searchCustomersUnified({
    required int page,
    required int size,
    String? query, // Single optional search string
  }) async {
    const base = '/api/v1/customers/search'; // Your new backend endpoint

    Map<String, String> params = {
      'page': page.toString(),
      'size': size.toString(),
    };

    // Smart detection — exactly like your backend expects
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      final cleaned = q.replaceAll(' ', '');

      if (q.contains('@') ||
          (cleaned.contains('.') &&
              RegExp(r'\.(com|in|co|org|net)$').hasMatch(cleaned))) {
        params['email'] = q;
      } else if (RegExp(r'^\+?\d+$').hasMatch(cleaned)) {
        params['contactNumber'] = q;
      } else {
        params['name'] = q;
      }
    }

    final uri = Uri.parse('$baseUrl$base').replace(queryParameters: params);
    final headers = _getHeaders();

    try {
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        return CustomerPageResponse.fromJson(jsonDecode(resp.body));
      } else {
        throw Exception('Server error ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('searchCustomersUnified error: $e');
      rethrow;
    }
  }

  Future<List<CustomerDTO>> getCustomers({String? searchQuery}) async {
    final String base = '${_normalize()}/api/v1/customers/searchCustomers';
    final String? query = searchQuery?.trim();

    // No query → fetch all customers
    if (query == null || query.isEmpty) {
      return _fetch(Uri.parse(base));
    }

    Map<String, String> params = {};

    // Remove spaces for accurate detection
    final cleanedQuery = query.replaceAll(' ', '');

    // 1. Looks like email (contains @ or common domain dots)
    if (query.contains('@') ||
        cleanedQuery.contains('.') &&
            (cleanedQuery.endsWith('.com') ||
                cleanedQuery.endsWith('.pk') ||
                cleanedQuery.endsWith('.net') ||
                cleanedQuery.endsWith('.org'))) {
      params['email'] = query;
    }
    // 2. Only digits and optional leading + → phone number
    else if (RegExp(r'^\+?\d+$').hasMatch(cleanedQuery)) {
      params['contactNumber'] = query;
    }
    // 3. Everything else → name search by name
    else {
      params['name'] = query;
    }

    final uri = Uri.parse(base).replace(queryParameters: params);
    return _fetch(uri);
  }

  // Private helper – pure API call, no UI
  Future<List<CustomerDTO>> _fetch(Uri uri) async {
    final headers = _getHeaders();

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list
            .map((e) => CustomerDTO.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Non-200 → return empty list (caller decides what to do)
      return [];
    } on TimeoutException catch (_) {
      return [];
    } on SocketException catch (_) {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// PAGINATED (for customer list screen)
  /// PAGINATED + SMART SEARCH (matches your backend logic)
  Future<CustomerPageResponse> getCustomersPage({
    int page = 0,
    int size = 10,
    String? searchQuery,
  }) async {
    final String base = '${_normalize()}/api/v1/customers/search';

    Map<String, String> params = {'page': '$page', 'size': '$size'};

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim();
      final cleaned = query.replaceAll(
        RegExp(r'\s+'),
        '',
      ); // Remove all whitespace

      // 1. Contains @ or common email patterns → treat as email
      if (query.contains('@') ||
          (cleaned.contains('.') &&
              (cleaned.endsWith('.com') ||
                  cleaned.endsWith('.in') ||
                  cleaned.endsWith('.co') ||
                  cleaned.endsWith('.org') ||
                  cleaned.endsWith('.net')))) {
        params['email'] = query;
      }
      // 2. Only digits (and optional + at start) → phone number
      else if (RegExp(r'^\+?\d+$').hasMatch(cleaned)) {
        params['contactNumber'] = query;
      }
      // 3. Contains letters or mixed → search by name
      else if (RegExp(r'[a-zA-Z]').hasMatch(query)) {
        params['name'] = query;
      }
      // 4. Fallback: if somehow none match, try name
      else {
        params['name'] = query;
      }
    }

    final url = Uri.parse(base).replace(queryParameters: params);
    final headers = _getHeaders();

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        return CustomerPageResponse.fromJson(jsonDecode(resp.body));
      } else {
        throw Exception(_extractErrorMessage(resp));
      }
    } catch (e) {
      debugPrint("Search API error: $e");
      rethrow;
    }
  }

  /// CREATE CUSTOMER – shows real backend message
  ///
  Future<void> createCustomer({
    required BuildContext context,
    required String name,
    required String contactNumber,
    required String email,
    required String address,
    String? reminder,
    double? deposite,
    List<Map<String, dynamic>>? items,
  }) async {
    final url = Uri.parse('${_normalize()}/api/v1/customers/save');

    final body = jsonEncode({
      'name': name.trim(),
      'contactNumber': contactNumber.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'reminder': reminder,
      'deposite': deposite ?? 0.0,
      'items': items,
    });

    final headers = _getHeaders();

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      // Parse response body (backend usually returns JSON even on error)
      final Map<String, dynamic> jsonBody = response.body.isEmpty
          ? {}
          : jsonDecode(response.body) as Map<String, dynamic>;

      final String message =
          jsonBody['message']?.toString() ??
          jsonBody['error']?.toString() ??
          'Unknown error occurred';

      // Success: only 200 or 201
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Show success toast directly
        showSuccessToast(context, "Customer created successfully!");

        // Navigate after success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ViewCustomerScreenFixed()),
        );
        return;
      }

      // Any other status code = error
      final errorMsg = response.statusCode >= 400 && response.statusCode < 500
          ? message // validation errors, duplicate, etc.
          : "Server error (${response.statusCode})";

      showErrorToast(context, errorMsg);
    } on TimeoutException {
      showErrorToast(context, "Request timed out. Please try again.");
    } catch (e) {
      showErrorToast(context, "Network error. Check your connection.");
    }
  }

  Future<CustomerResponse> getCustomerById(String id) async {
    final url = Uri.parse('${_normalize()}/api/v1/customers/getById/$id');
    final headers = _getHeaders();

    log("headers for customer api: $headers");

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        return CustomerResponse.fromJson(jsonDecode(resp.body));
      }
      return CustomerResponse(
        success: false,
        message: _extractErrorMessage(resp),
      );
    } catch (e) {
      return CustomerResponse(success: false, message: 'Network error');
    }
  }

  Future<CustomerResponse> updateCustomer({
    required String name,
    required String contactNumber,
    required String address,
    required String email,
    required String reminder,
    required int id,
    double? deposite,
    List<Map<String, dynamic>>? items,
  }) async {
    final url = Uri.parse('${_normalize()}/api/v1/customers/update/$id');
    final body = jsonEncode({
      'name': name.trim(),
      'contactNumber': contactNumber.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'deposite': deposite,
      'reminder': reminder,
      'items': items,
    });
    final headers = _getHeaders();

    try {
      final resp = await http
          .put(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return CustomerResponse(success: true, message: 'Customer updated');
      }
      return CustomerResponse(
        success: false,
        message: _extractErrorMessage(resp),
      );
    } catch (e) {
      return CustomerResponse(success: false, message: 'Network error');
    }
  }

  Future<CustomerResponse> deleteCustomer(int id) async {
    final url = Uri.parse('${_normalize()}/api/v1/customers/deleteById/$id');
    final headers = _getHeaders();

    try {
      final resp = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return CustomerResponse(success: true, message: 'Customer deleted');
      }
      return CustomerResponse(
        success: false,
        message: _extractErrorMessage(resp),
      );
    } catch (e) {
      return CustomerResponse(success: false, message: 'Network error');
    }
  }

  Future<void> downloadAndShowPdf(
    row, {
    required int customerId,
    required String customerName,
    required BuildContext context,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/v1/challans/statement/pdf?customerId=$customerId',
            ),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 40));

      // Server error or empty/invalid response
      if (response.statusCode != 200) {
        showErrorToast(context, "PDF not found on server");
        debugPrint(
          "PDF download failed: ${response.statusCode} ${response.body}",
        );
        return;
      }

      if (response.bodyBytes.length < 1000) {
        showErrorToast(context, "Create Challan to view PDF");
        debugPrint("PDF too small: ${response.bodyBytes.length} bytes");
        return;
      }

      final bytes = response.bodyBytes;

      // Safe filename
      String safeFileName = (customerName ?? customerId.toString())
          .replaceAll(RegExp(r'[<>:"/\\|?*%]'), '_')
          .replaceAll('/', '_')
          .replaceAll(' ', '_');

      final fileName = 'PassBook_$safeFileName.pdf';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(bytes);
      debugPrint("PDF saved at: ${file.path}");

      final result = await OpenFilex.open(file.path);

      if (result.type == ResultType.done) {
        // showSuccessToast(context, "PDF opened successfully");
      } else if (result.type == ResultType.noAppToOpen) {
        showErrorToast(context, "No PDF viewer app found");
      } else if (result.type == ResultType.fileNotFound) {
        showErrorToast(context, "File not found after download");
      } else if (result.type == ResultType.permissionDenied) {
        showErrorToast(context, "Permission denied to open file");
      } else {
        showErrorToast(context, "Failed to open PDF: ${result.message}");
        debugPrint("OpenFilex error: ${result.message}");
      }
    } on TimeoutException {
      showErrorToast(context, "Download timed out. Check your internet.");
    } on SocketException {
      showErrorToast(context, "No internet connection");
    } on FileSystemException catch (e) {
      showErrorToast(context, "Failed to save PDF file");
      debugPrint("FileSystem error: $e");
    } catch (e, s) {
      showErrorToast(context, "Something went wrong. Try again.");
      debugPrint("downloadAndShowPdf failed: $e\n$s");
    }
  }

  // GET /getPreviousBalance/{customerId}
  Future<double?> getCustomerPreviousBalance(
    int customerId,
    BuildContext context,
  ) async {
    final url = Uri.parse('${_normalize()}/api/v1/challans/getPreviousBalance/$customerId');
    final headers = _getHeaders();

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final String body = response.body.trim();
        final double? balance = double.tryParse(body);
        return balance ?? 0.0;
      } else {
        debugPrint(
            "Previous balance API failed: ${response.statusCode} ${response.body}");
        return 0.0;
      }
    } on TimeoutException {
      debugPrint("getCustomerPreviousBalance timeout for customer $customerId");
      return 0.0;
    } on SocketException {
      debugPrint("No internet for previous balance API");
      return 0.0;
    } catch (e) {
      debugPrint("Unexpected error in getCustomerPreviousBalance: $e");
      return 0.0;
    }
  }
}
