import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snow_trading_cool/models/passbook_product_model.dart';
import 'package:snow_trading_cool/utils/api_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:snow_trading_cool/utils/api_utils.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';

class PassbookApi {
  final String baseUrl;
  final TokenManager _tokenManager = TokenManager();

  PassbookApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> _getHeaders() {
    final token = _tokenManager.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  final _headers = ApiUtils.getAuthenticatedHeaders();

  static List<Map<String, dynamic>> fetchedResponse = [];

  String? _formatDate(dynamic date) {
    if (date == null) return null;
    if (date is String) return date.isNotEmpty ? date : null;
    if (date is DateTime) return DateFormat('yyyy-MM-dd').format(date);
    return null;
  }

  /// Fetches paginated challans for Passbook using appropriate endpoint based on filters
  Future<Map<String, dynamic>> fetchPassbookPage({
    required BuildContext context,
    int? customerId,
    required int page,
    required int size,
    String? search,
    String? poSearch,
    String? fromDate,
    String? toDate,
  }) async {
    int effectiveCustomerId = customerId ?? 0;
    if (effectiveCustomerId <= 0) {
      effectiveCustomerId = 0;
    }

    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      if (effectiveCustomerId > 0) 'customerId': effectiveCustomerId.toString(),
      if (_formatDate(fromDate) != null) 'fromDate': _formatDate(fromDate)!,
      if (_formatDate(toDate) != null) 'toDate': _formatDate(toDate)!,
    };

    String endpoint = '/passbook';

    if (poSearch != null && poSearch.trim().isNotEmpty) {
      endpoint = '/searchByPoNumber/${Uri.encodeComponent(poSearch.trim())}';
    } else if (search != null && search.trim().isNotEmpty) {
      endpoint = '/searchPassbook';
      final trimmed = search.trim();
      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        queryParams['contactNumber'] = trimmed;
      } else if (RegExp(r'^[A-Za-z0-9/-]+$').hasMatch(trimmed)) {
        queryParams['srNo'] = trimmed;
      } else {
        queryParams['name'] = trimmed;
      }
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/challans$endpoint',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List content = json['content'] ?? [];
        fetchedResponse = content.cast<Map<String, dynamic>>();

        log("Fetched Passbook Data: $fetchedResponse");

        final transformed = content.map<Map<String, dynamic>>((item) {
          final itemsList = (item['items'] as List?) ?? [];
          final totalDelivered = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['deliveredQty'] as num?)?.toInt() ?? 0),
          );
          final totalReceived = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['receivedQty'] as num?)?.toInt() ?? 0),
          );

          final List<Map<String, dynamic>> productSrList = itemsList.map((i) {
            final List<String> srList =
                (i['srNo'] as List?)?.cast<String>() ?? [];
            final String productName =
                i['productName']?.toString() ??
                i['name']?.toString() ??
                'Unknown Product';
            return {
              'productName': productName,
              'srNos': srList,
              'srNoJoined': srList.join('/'),
            };
          }).toList();

          final productType = itemsList.map((i) {
            final String productName =
                i['name']?.toString() ?? 'Unknown Product';
            return {'productName': productName};
          }).toList();
          log("product type : $productType");

          return {
            'id': item['id'] ?? '',
            'customerId': item['customerId'] ?? '',
            'challanNumber': item['challanNumber'] ?? 'CH-${item['id']}',
            'productType': productSrList
                .map((p) => p['productName'] as String)
                .toSet() // optional: remove duplicates
                .toList(),
            'purchaseOrderNo': item['purchaseOrderNo'] ?? '',
            'siteLocation': item['siteLocation'] ?? '',
            'customerName': item['customerName'] ?? 'Unknown',
            'receivedChallanNos': item['receivedChallanNos'] ?? '',
            'srNo': productSrList
                .expand((p) => p['srNos'] as List<String>)
                .join('/'),
            'product_sr_details': productSrList,
            'date': item['date'] ?? '',
            'delivered': totalDelivered,
            'received': totalReceived,
            'deposite': (item['deposite'] as num?)?.toDouble() ?? 0.0,
            'returnedAmount':
                (item['returnedAmount'] as num?)?.toDouble() ?? 0.0,
            'raw': item,
          };
        }).toList();

        return {
          'content': transformed,
          'totalPages': json['totalPages'] ?? 1,
          'totalElements': json['totalElements'] ?? 0,
          'number': json['number'] ?? page,
          'size': json['size'] ?? size,
          'last': json['last'] ?? true,
        };
      }

      if (response.statusCode == 404) {
        return {
          'content': [],
          'totalPages': 0,
          'totalElements': 0,
          'number': page,
          'size': size,
          'last': true,
        };
      }

      final errorMsg = response.body.isNotEmpty
          ? response.body
          : "Server error ${response.statusCode}";
      if (context.mounted) showErrorToast(context, errorMsg);
      return {
        'content': [],
        'totalPages': 0,
        'totalElements': 0,
        'number': page,
        'size': size,
        'last': true,
      };
    } catch (e) {
      debugPrint("Passbook API Error: $e");
      if (context.mounted) showErrorToast(context, "Network error");
      return {
        'content': [],
        'totalPages': 0,
        'totalElements': 0,
        'number': page,
        'size': size,
        'last': true,
      };
    }
  }

  Future<Map<String, dynamic>> searchUnified({
    required BuildContext context,
    String? name,
    String? contactNumber,
    String? srNo,
    String? poNumber,
    String? siteLocation,
    String? itemName,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    required int size,
  }) async {
    // ──────────────────────────────────────
    // Build query parameters
    // ──────────────────────────────────────
    final Map<String, String> params = {
      'page': page.toString(),
      'size': size.toString(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (contactNumber != null && contactNumber.trim().isNotEmpty)
        'contactNumber': contactNumber.trim(),
      if (srNo != null && srNo.trim().isNotEmpty) 'srNo': srNo.trim(),
      if (poNumber != null && poNumber.trim().isNotEmpty)
        'poNumber': poNumber.trim(),
      if (siteLocation != null && siteLocation.trim().isNotEmpty)
        'siteLocation': siteLocation.trim(),
      if (itemName != null && itemName.trim().isNotEmpty)
        'itemName': itemName.trim(),
      if (fromDate != null)
        'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),
      if (toDate != null) 'toDate': DateFormat('yyyy-MM-dd').format(toDate),
    };

    final uri = Uri.parse(
      '$baseUrl/api/v1/challans/passbook',
    ).replace(queryParameters: params);

    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 25));

      // ──────────────────────── SUCCESS ────────────────────────
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        final List<dynamic> content = json['content'] ?? [];

        fetchedResponse = content.cast<Map<String, dynamic>>();

        // ───── Your existing transformation (copy-paste from old code) ─────
        final List<Map<String, dynamic>> transformed = content.map((item) {
          final itemsList = (item['items'] as List?) ?? [];
          final totalDelivered = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['deliveredQty'] as num?)?.toInt() ?? 0),
          );
          final totalReceived = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['receivedQty'] as num?)?.toInt() ?? 0),
          );

          final List<Map<String, dynamic>> productSrList = itemsList.map((i) {
            final List<String> srList =
                (i['srNo'] as List?)?.cast<String>() ?? [];
            final String productName =
                i['productName']?.toString() ??
                i['name']?.toString() ??
                'Unknown Product';
            return {
              'productName': productName,
              'srNos': srList,
              'srNoJoined': srList.join('/'),
            };
          }).toList();

          return {
            'id': item['id'] ?? '',
            'customerId': item['customerId'] ?? '',
            'challanNumber': item['challanNumber'] ?? 'CH-${item['id']}',
            'productType': productSrList
                .map((p) => p['productName'] as String)
                .toSet() // optional: remove duplicates
                .toList(),
            'purchaseOrderNo': item['purchaseOrderNo'] ?? '',
            'siteLocation': item['siteLocation'] ?? '',
            'customerName': item['customerName'] ?? 'Unknown',
            'receivedChallanNos': item['receivedChallanNos'] ?? '',
            'srNo': productSrList
                .expand((p) => p['srNos'] as List<String>)
                .join('/'),
            'product_sr_details': productSrList,
            'date': item['date'] ?? '',
            'delivered': totalDelivered,
            'received': totalReceived,
            'deposite': (item['deposite'] as num?)?.toDouble() ?? 0.0,
            'returnedAmount':
                (item['returnedAmount'] as num?)?.toDouble() ?? 0.0,
            'raw': item,
          };
        }).toList();

        return {
          'content': transformed,
          'totalPages': json['totalPages'] ?? 1,
          'totalElements': json['totalElements'] ?? 0,
          'number': json['number'] ?? page,
          'size': json['size'] ?? size,
          'last': json['last'] ?? true,
        };
      }

      // ──────────────────────── ERROR RESPONSE ────────────────────────
      String errorMsg = 'Server error ${response.statusCode}';
      if (response.body.isNotEmpty) {
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic> && body['message'] != null) {
            errorMsg = body['message'].toString();
          }
        } catch (_) {}
      }

      if (context.mounted) {
        showErrorToast(context, errorMsg);
      }

      return _emptyPage(page, size); // ← always return
    } catch (e) {
      // ──────────────────────── NETWORK / TIMEOUT ERROR ────────────────────────
      debugPrint('searchUnified error: $e');
      if (context.mounted) {
        showErrorToast(context, 'Network error');
      }
      return _emptyPage(page, size); // ← always return here too
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Helper – guarantees a non-null Map is always returned
  // ──────────────────────────────────────────────────────────────
  Map<String, dynamic> _emptyPage(int page, int size) {
    return {
      'content': <Map<String, dynamic>>[],
      'totalPages': 0,
      'totalElements': 0,
      'number': page,
      'size': size,
      'last': true,
    };
  }

  /// Smart Search - Name / Mobile / SR No.
  Future<Map<String, dynamic>> searchPassbook({
    required BuildContext context,
    required String query,
    required page,
    required int size,
  }) async {
    final trimmedQuery = query.trim();

    // If empty query → show all (fallback to normal fetch)
    if (trimmedQuery.isEmpty) {
      return fetchPassbookPage(
        context: context,
        customerId: 0,
        page: page,
        size: size,
      );
    }

    // Smart detection
    final bool onlyLetters = RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmedQuery);
    final bool onlyDigits = RegExp(r'^\d+$').hasMatch(trimmedQuery);

    String? name;
    String? contactNumber;
    String? srNo;

    if (onlyLetters) {
      name = trimmedQuery;
    } else if (onlyDigits && trimmedQuery.length >= 3) {
      contactNumber = trimmedQuery;
    } else {
      srNo = trimmedQuery; // anything with letters + numbers = SR No.
    }

    final uri = Uri.parse('$baseUrl/api/v1/challans/searchPassbook').replace(
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
        if (name != null) 'name': name,
        if (contactNumber != null) 'contactNumber': contactNumber,
        if (srNo != null) 'srNo': srNo,
      }..removeWhere((key, value) => value == null),
    );

    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List content = json['content'] ?? [];

        fetchedResponse = content.cast<Map<String, dynamic>>();
        log("Searched Passbook Fetched Passbook Data: $fetchedResponse");

        final transformed = content.map((item) {
          final itemsList = (item['items'] as List?) ?? [];
          final totalDelivered = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['deliveredQty'] as num?)?.toInt() ?? 0),
          );
          final totalReceived = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['receivedQty'] as num?)?.toInt() ?? 0),
          );

          final List<Map<String, dynamic>> productSrList = itemsList.map((i) {
            final List<String> srList =
                (i['srNo'] as List?)?.cast<String>() ?? [];
            final String productName =
                i['productName']?.toString() ??
                i['name']?.toString() ??
                'Unknown Product';
            return {
              'productName': productName,
              'srNos': srList,
              'srNoJoined': srList.join('/'),
            };
          }).toList();

          // final productType = itemsList.map((i) {
          //   final String productName =
          //       i['name']?.toString() ?? 'Unknown Product';
          //   return {'productName': productName};
          // }).toList();

          final List<String> productType = itemsList
              .map(
                (i) =>
                    i['productName']?.toString() ??
                    i['name']?.toString() ??
                    'Unknown',
              )
              .where((name) => name != 'Unknown')
              .toSet() // optional: unique
              .toList();
          log("product type : $productType");

          return {
            'id': item['id'] ?? '',
            'customerId': item['customerId'] ?? '',
            'challanNumber': item['challanNumber'] ?? 'CH-${item['id']}',
            'productType': productSrList
                .map((p) => p['productName'] as String)
                .toSet() // optional: remove duplicates
                .toList(),
            'purchaseOrderNo': item['purchaseOrderNo'] ?? '',
            'siteLocation': item['siteLocation'] ?? '',
            'customerName': item['customerName'] ?? 'Unknown',
            'receivedChallanNos': item['receivedChallanNos'] ?? '',
            'srNo': productSrList
                .expand((p) => p['srNos'] as List<String>)
                .join('/'),
            'product_sr_details': productSrList,
            'date': item['date'] ?? '',
            'delivered': totalDelivered,
            'received': totalReceived,
            'deposite': (item['deposite'] as num?)?.toDouble() ?? 0.0,
            'returnedAmount':
                (item['returnedAmount'] as num?)?.toDouble() ?? 0.0,
            'raw': item,
          };
        }).toList();

        return {
          'content': transformed,
          'totalPages': json['totalPages'] ?? 1,
          'totalElements': json['totalElements'] ?? 0,
          'number': json['number'] ?? page,
          'size': json['size'] ?? size,
          'last': json['last'] ?? true,
        };
      }

      // Handle 404 or error
      final errorMsg = response.body.isNotEmpty
          ? jsonDecode(response.body)['message'] ?? response.body
          : "No results";
      if (context.mounted) showErrorToast(context, errorMsg);

      return {
        'content': [],
        'totalPages': 0,
        'totalElements': 0,
        'number': page,
        'size': size,
        'last': true,
      };
    } catch (e) {
      debugPrint("searchPassbook error: $e");
      if (context.mounted) showErrorToast(context, "Network error");
      return {
        'content': [],
        'totalPages': 0,
        'totalElements': 0,
        'number': page,
        'size': size,
        'last': true,
      };
    }
  }

  Future<Map<String, dynamic>> searchByPoOrSite({
    required BuildContext context,
    required String query,
    required int page,
    required int size,
  }) async {
    final trimmedQuery = query.trim();

    // If empty → show all
    if (trimmedQuery.isEmpty) {
      return fetchPassbookPage(
        context: context,
        customerId: 0,
        page: page,
        size: size,
      );
    }

    // Smart detection: PO usually starts with "PO", "po", or has numbers + letters
    final bool looksLikePo =
        RegExp(r'^(po|PO)?\d', caseSensitive: false).hasMatch(trimmedQuery) ||
        (trimmedQuery.contains(RegExp(r'[0-9]')) && trimmedQuery.length >= 3);

    final String paramName = looksLikePo ? 'po' : 'site';

    final uri = Uri.parse('$baseUrl/api/v1/challans/search/PoOrSite').replace(
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
        paramName: trimmedQuery,
      },
    );

    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List content = json['content'] ?? [];
        fetchedResponse = content.cast<Map<String, dynamic>>();

        log("Searched Po/Site Fetched Passbook Data: $fetchedResponse");

        // EXACT SAME TRANSFORMATION as searchPassbook — 100% DRY
        final transformed = content.map((item) {
          final itemsList = (item['items'] as List?) ?? [];
          final totalDelivered = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['deliveredQty'] as num?)?.toInt() ?? 0),
          );
          final totalReceived = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['receivedQty'] as num?)?.toInt() ?? 0),
          );

          final List<Map<String, dynamic>> productSrList = itemsList.map((i) {
            final List<String> srList =
                (i['srNo'] as List?)?.cast<String>() ?? [];
            final String productName =
                i['productName']?.toString() ??
                i['name']?.toString() ??
                'Unknown Product';
            return {
              'productName': productName,
              'srNos': srList,
              'srNoJoined': srList.join('/'),
            };
          }).toList();
          final productType = itemsList.map((i) {
            final String productName =
                i['name']?.toString() ?? 'Unknown Product';
            return {'productName': productName};
          }).toList();
          log("product type : $productType");

          return {
            'id': item['id'] ?? '',
            'customerId': item['customerId'] ?? '',
            'challanNumber': item['challanNumber'] ?? 'CH-${item['id']}',
            'productType': productSrList
                .map((p) => p['productName'] as String)
                .toSet() // optional: remove duplicates
                .toList(),
            'purchaseOrderNo': item['purchaseOrderNo'] ?? '',
            'siteLocation': item['siteLocation'] ?? '',
            'customerName': item['customerName'] ?? 'Unknown',
            'receivedChallanNos': item['receivedChallanNos'] ?? '',
            'srNo': productSrList
                .expand((p) => p['srNos'] as List<String>)
                .join('/'),
            'product_sr_details': productSrList,
            'date': item['date'] ?? '',
            'delivered': totalDelivered,
            'received': totalReceived,
            'deposite': (item['deposite'] as num?)?.toDouble() ?? 0.0,
            'returnedAmount':
                (item['returnedAmount'] as num?)?.toDouble() ?? 0.0,
            'raw': item,
          };
        }).toList();

        return {
          'content': transformed,
          'totalPages': json['totalPages'] ?? 1,
          'totalElements': json['totalElements'] ?? 0,
          'number': json['number'] ?? page,
          'size': json['size'] ?? size,
          'last': json['last'] ?? true,
        };
      }

      // Error handling — same as searchPassbook
      final errorMsg = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map)['message'] ?? 'No results found'
          : 'Server error';

      if (context.mounted) showErrorToast(context, errorMsg);

      return {
        'content': [],
        'totalPages': 0,
        'totalElements': 0,
        'number': page,
        'size': size,
        'last': true,
      };
    } catch (e) {
      debugPrint("searchByPoOrSite error: $e");
      if (context.mounted) showErrorToast(context, "Network error");
      return {
        'content': [],
        'totalPages': 0,
        'totalElements': 0,
        'number': page,
        'size': size,
        'last': true,
      };
    }
  }

  /// Get total count of all delivered challans
  Future<int> getTotalDeliveredCount({required BuildContext context}) async {
    final uri = Uri.parse('$baseUrl/api/v1/challans/count/delivered');
    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return int.tryParse(response.body) ?? 0;
      }
    } catch (e) {
      debugPrint("Count API error: $e");
    }
    return 0;
  }

  Future<Map<String, dynamic>> fetchDeliveredByDateRange({
    required BuildContext context,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 7,
  }) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final Map<String, String> params = {
      'page': page.toString(),
      'size': size.toString(),
    };

    // Smart date logic: only add params if at least one date is selected
    if (fromDate != null || toDate != null) {
      final from = fromDate ?? DateTime(2005, 1, 1); // far past if only toDate
      final to = toDate ?? today;

      params['fromDate'] = DateFormat('yyyy-MM-dd').format(from);
      params['toDate'] = DateFormat('yyyy-MM-dd').format(to);
    }
    // If both dates are null → no date params → backend returns ALL delivered

    final uri = Uri.parse(
      '$baseUrl/api/v1/challans/delivered/date',
    ).replace(queryParameters: params);

    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List items = json['content'] ?? [];

        fetchedResponse = items.cast<Map<String, dynamic>>();

        log("fetch Delivered by date range : $fetchedResponse");

        // Transform items exactly like your other methods
        final transformed = items.map((item) {
          final itemsList = (item['items'] as List?) ?? [];
          final totalDelivered = itemsList.fold<int>(
            0,
            (sum, i) => sum + ((i['deliveredQty'] as num?)?.toInt() ?? 0),
          );
          final totalReceived = itemsList.fold<int>(
            0,
            (sum, i) => sum + ((i['receivedQty'] as num?)?.toInt() ?? 0),
          );

          final List<Map<String, dynamic>> productSrList = itemsList.map((i) {
            final List<String> srList =
                (i['srNo'] as List?)?.cast<String>() ?? [];
            final String productName =
                i['productName']?.toString() ??
                i['name']?.toString() ??
                'Unknown Product';
            return {
              'productName': productName,
              'srNos': srList,
              'srNoJoined': srList.join('/'),
            };
          }).toList();

          final productType = itemsList.map((i) {
            final String productName =
                i['name']?.toString() ?? 'Unknown Product';
            return {'productName': productName};
          }).toList();
          log("product type : $productType");

          return {
            'id': item['id'] ?? '',
            'customerId': item['customerId'] ?? '',
            'challanNumber': item['challanNumber'] ?? 'CH-${item['id']}',
            'productType': productSrList
                .map((p) => p['productName'] as String)
                .toSet() // optional: remove duplicates
                .toList(),
            'purchaseOrderNo': item['purchaseOrderNo'] ?? '',
            'siteLocation': item['siteLocation'] ?? '',
            'customerName': item['customerName'] ?? 'Unknown',
            'receivedChallanNos': item['receivedChallanNos'] ?? '',
            'srNo': productSrList
                .expand((p) => p['srNos'] as List<String>)
                .join('/'),
            'product_sr_details': productSrList,
            'date': item['date'] ?? '',
            'delivered': totalDelivered,
            'received': totalReceived,
            'deposite': (item['deposite'] as num?)?.toDouble() ?? 0.0,
            'returnedAmount':
                (item['returnedAmount'] as num?)?.toDouble() ?? 0.0,
            'raw': item,
          };
        }).toList();

        return {
          'content': transformed,
          'totalPages': json['totalPages'] ?? 1,
          'totalElements': json['totalElements'] ?? 0,
          'number': json['number'] ?? page,
          'size': json['size'] ?? size,
          'last': json['last'] ?? true,
        };
      }

      // Handle error responses
      String errorMsg = "Server error";
      if (response.statusCode == 401) {
        errorMsg = "Session expired. Please login again.";
      } else if (response.body.isNotEmpty) {
        try {
          final errorBody = jsonDecode(response.body);
          errorMsg = errorBody['message'] ?? errorMsg;
        } catch (_) {}
      }

      if (context.mounted) {
        showErrorToast(context, errorMsg);
      }
    } catch (e) {
      debugPrint("fetchDeliveredByDateRange error: $e");
      if (context.mounted) {
        showErrorToast(context, "Network error");
      }
    }

    // Return empty page on failure
    return {
      'content': <Map<String, dynamic>>[],
      'totalPages': 0,
      'totalElements': 0,
      'number': page,
      'size': size,
      'last': true,
    };
  }

  Future<Map<String, dynamic>> getPassbookByCustomerId({
    required BuildContext context,
    required int customerId,
    required int page,
    required int size,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/challans/getChallansByCustomerId')
        .replace(
          queryParameters: {
            'customerId': customerId.toString(),
            'page': page.toString(),
            'size': size.toString(),
          },
        );

    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List content = json['content'] ?? [];

        fetchedResponse = content.cast<Map<String, dynamic>>();
        log("Fetched Passbook Data: $fetchedResponse");

        // Transform exactly like searchUnified
        final transformed = content.map<Map<String, dynamic>>((item) {
          final itemsList = (item['items'] as List?) ?? [];
          final totalDelivered = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['deliveredQty'] as num?)?.toInt() ?? 0),
          );
          final totalReceived = itemsList.fold<int>(
            0,
            (s, i) => s + ((i['receivedQty'] as num?)?.toInt() ?? 0),
          );

          final productSrList = itemsList.map((i) {
            final srList = (i['srNo'] as List?)?.cast<String>() ?? [];
            final productName =
                i['productName']?.toString() ??
                i['name']?.toString() ??
                'Unknown';
            return {
              'productName': productName,
              'srNos': srList,
              'srNoJoined': srList.join('/'),
            };
          }).toList();

          final productType = itemsList.map((i) {
            final String productName =
                i['name']?.toString() ?? 'Unknown Product';
            return {'productName': productName};
          }).toList();
          log("product type : $productType");

          return {
            'id': item['id'],
            'challanNumber': item['challanNumber'] ?? 'CH-${item['id']}',
            'productType': productSrList
                .map((p) => p['productName'] as String)
                .toSet() // optional: remove duplicates
                .toList(),
            'customerName': item['customerName'] ?? 'Unknown',
            'date': item['date'] ?? '',
            'delivered': totalDelivered,
            'received': totalReceived,
            'deposite': (item['deposite'] as num?)?.toDouble() ?? 0.0,
            'returnedAmount':
                (item['returnedAmount'] as num?)?.toDouble() ?? 0.0,
            'receivedChallanNos': item['receivedChallanNos'] ?? '',
            'srNo': productSrList
                .expand((p) => p['srNos'] as List<String>)
                .join('/'),
            'product_sr_details': productSrList,
            'purchaseOrderNo': item['purchaseOrderNo'] ?? '',
            'siteLocation': item['siteLocation'] ?? '',
          };
        }).toList();

        return {
          'content': transformed,
          'totalPages': json['totalPages'] ?? 1,
          'totalElements': json['totalElements'] ?? 0,
          'number': json['number'] ?? page,
          'size': json['size'] ?? size,
          'last': json['last'] ?? true,
        };
      }

      if (context.mounted) showErrorToast(context, "No entries found");
      return _emptyPage(page, size);
    } catch (e) {
      debugPrint("getPassbookByCustomerId error: $e");
      if (context.mounted) showErrorToast(context, "Network error");
      return _emptyPage(page, size);
    }
  }

  Future<List<PassbookProduct>> getPassbookSummary({
    required int customerId,
    String? fromDate,
    String? toDate,
  }) async {
    // Validate customerId early
    if (customerId <= 0) {
      throw Exception("Invalid customer ID");
    }

    final Map<String, String> queryParams = {
      'id': customerId.toString(),
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    };

    // Only add dates if they are valid and non-empty
    if (fromDate != null && fromDate.trim().isNotEmpty) {
      queryParams['fromDate'] = fromDate.trim();
    }
    if (toDate != null && toDate.trim().isNotEmpty) {
      queryParams['toDate'] = toDate.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/challans/getPassbookSummary',
    ).replace(queryParameters: queryParams);

    debugPrint('Fetching passbook summary: $uri');
    debugPrint('Headers: ${_getHeaders()}'); // Helpful for debugging 401

    try {
      final response = await http
          .get(
            uri,
            headers: _getHeaders(), // ← This is correct! Uses fresh token
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);

        // Backend might return [] or {} — handle both safely
        if (body is List) {
          return body.map((e) => PassbookProduct.fromJson(e)).toList();
        } else {
          // In case backend returns { data: [...] } or something unexpected
          debugPrint('Unexpected response format: $body');
          return [];
        }
      }

      // Handle specific status codes
      if (response.statusCode == 401) {
        throw Exception("Unauthorized: Session expired. Please login again.");
      } else if (response.statusCode == 404) {
        throw Exception("No summary found for this customer");
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? "Bad request");
      }

      // Generic error
      throw Exception(
        "Failed to fetch passbook summary: ${response.statusCode}",
      );
    } on TimeoutException {
      throw Exception("Request timed out. Check your internet connection.");
    } on SocketException {
      throw Exception("No internet connection");
    } catch (e) {
      debugPrint('getPassbookSummary error: $e');
      rethrow; // Preserve original exception for caller to handle
    }
  }

  Future<void> showAllPDF({
    required BuildContext context,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['fromDate'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['toDate'] = toDate;
      }

      final uri = Uri.parse(
        '$baseUrl/api/v1/challans/getAllDeliveredChallansStatement',
      ).replace(queryParameters: queryParams);

      debugPrint("Requesting PDF from: $uri");

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 60));

      // Handle non-200 responses
      if (response.statusCode != 200) {
        showErrorToast(context, "Failed to generate PDF");
        debugPrint(
          "PDF download failed: ${response.statusCode} ${response.body}",
        );
        return;
      }

      final bytes = response.bodyBytes;

      if (bytes.length < 1000) {
        String responseText = utf8.decode(bytes);
        debugPrint("Small response (possibly error): $responseText");
        showErrorToast(context, "No challans found for the selected period");
        return;
      }

      // Save and open PDF
      final String safeFileName = fromDate != null && toDate != null
          ? "SnowCool_PassBook_${fromDate}_to_${toDate}"
          : "SnowCool_PassBook";

      final String fileName = '$safeFileName.pdf';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(bytes);
      debugPrint("PDF saved at: ${file.path}");

      final result = await OpenFilex.open(file.path);

      switch (result.type) {
        case ResultType.done:
          // Success
          break;
        case ResultType.noAppToOpen:
          showErrorToast(context, "No PDF viewer installed");
          break;
        case ResultType.permissionDenied:
          showErrorToast(context, "Permission denied");
          break;
        case ResultType.fileNotFound:
          showErrorToast(context, "Downloaded file not found");
          break;
        default:
          showErrorToast(context, "Cannot open PDF: ${result.message}");
          debugPrint("OpenFilex error: ${result.message}");
      }
    } on TimeoutException {
      showErrorToast(context, "Download timed out. Try again.");
    } on SocketException {
      showErrorToast(context, "No internet connection");
    } on FileSystemException catch (e) {
      showErrorToast(context, "Failed to save file");
      debugPrint("File system error: $e");
    } catch (e, s) {
      showErrorToast(context, "Something went wrong");
      debugPrint("showAllPDF error: $e\n$s");
    }
  }

  Future<void> showCurrentPDF({
    required BuildContext context,
    // required Map<String, dynamic> data,
  }) async {
    if (PassbookApi.fetchedResponse.isEmpty) {
      showErrorToast(context, "No challans to generate PDF");
      return;
    }
    // final body = fetchedResponse;

    // var body = body;
    log("show current pdf = ${fetchedResponse}");
    debugPrint("show current pdf = ${fetchedResponse}");
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/challans/statementMultiple/pdf'),
            headers: _headers,
            body: jsonEncode(fetchedResponse),
          )
          .timeout(const Duration(seconds: 40));

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

      final fileName = 'SnowCool_PassBook_Page.pdf';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(bytes);
      debugPrint("PDF saved at: ${file.path}");

      final result = await OpenFilex.open(file.path);

      if (result.type == ResultType.done) {
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

  Future<void> showCurrentExcel({
    required BuildContext context,
    required List<Map<String, dynamic>> data,
  }) async {
    if (data.isEmpty) {
      showErrorToast(context, "No data to export");
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/v1/challans/ ', // TO-DO: Update endpoint for Excel export
            ),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        showErrorToast(context, "Excel file not generated");
        debugPrint(
          "Excel download failed: ${response.statusCode} ${response.body}",
        );
        return;
      }

      final bytes = response.bodyBytes;

      if (bytes.isEmpty || bytes.length < 5000) {
        showErrorToast(context, "No data available to export");
        return;
      }

      String fileName =
          'SnowCool_PassBook_${DateFormat('dd-MMM-yyyy_HHmm').format(DateTime.now())}.xlsx';

      String filePath;
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        filePath = '${downloadsDir.path}/$fileName';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        showErrorToast(
          context,
          result.type == ResultType.noAppToOpen
              ? "No app found to open Excel files (try Google Sheets or Microsoft Excel)"
              : "Cannot open file: ${result.message}",
        );
      }
    } on TimeoutException {
      showErrorToast(context, "Excel generation timed out. Try again.");
    } on SocketException {
      showErrorToast(context, "No internet connection");
    } on FileSystemException catch (e) {
      showErrorToast(context, "Failed to save Excel file");
      debugPrint("File save error: $e");
    } catch (e, s) {
      debugPrint("showCurrentExcel error: $e\n$s");
      showErrorToast(context, "Failed to generate Excel");
    }
  }

  void exportToExcel({
    required BuildContext context,
    DateTime? fromDate,
    DateTime? toDate,
    bool isAll = false,
  }) {
    showErrorToast(context, 'Failed To Detect');
    // showSuccessToast(context, "Excel Export in progress...");
    // Your Excel logic here
  }

  Future<void> shareSingleChallanPassbookPdf({
    required BuildContext context,
    required String challanNumber,
  }) async {
    if (challanNumber.isEmpty || challanNumber == 'N/A') {
      showErrorToast(context, "Invalid challan number");
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/v1/challans/getSingleChallanStatement/pdf?challanNumber=$challanNumber',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 40));

      // Handle non-200 responses
      if (response.statusCode != 200) {
        showErrorToast(context, "PDF not available for this challan");
        debugPrint("PDF Error ${response.statusCode}: ${response.body}");
        return;
      }

      final bytes = response.bodyBytes;

      // Safety check: empty or corrupted PDF
      if (bytes.isEmpty || bytes.length < 1000) {
        showErrorToast(context, "No PDF generated for this challan yet");
        return;
      }

      // Create safe filename
      final safeName = challanNumber.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final fileName = 'PassBook_Statement_$safeName.pdf';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      debugPrint("PDF saved: ${file.path}");

      // final result = await OpenFilex.open(file.path);
      await Share.shareXFiles(
        [XFile(file.path)], // share path, not bytes
        text: 'PassBook $challanNumber - Snow Trading Cool',
        subject: 'PassBook - $challanNumber',
      );
    } catch (e, s) {
      debugPrint("share failed error: $e\n$s");
      showErrorToast(context, "Failed to share PDF");
    }
  }

  Future<void> showSingleChallanPassbookPdf({
    required BuildContext context,
    required String challanNumber,
  }) async {
    if (challanNumber.isEmpty || challanNumber == 'N/A') {
      showErrorToast(context, "Invalid challan number");
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/v1/challans/getSingleChallanStatement/pdf?challanNumber=$challanNumber',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 40));

      // Handle non-200 responses
      if (response.statusCode != 200) {
        showErrorToast(context, "PDF not available for this challan");
        debugPrint("PDF Error ${response.statusCode}: ${response.body}");
        return;
      }

      final bytes = response.bodyBytes;

      // Safety check: empty or corrupted PDF
      if (bytes.isEmpty || bytes.length < 1000) {
        showErrorToast(context, "No PDF generated for this challan yet");
        return;
      }

      // Create safe filename
      final safeName = challanNumber.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final fileName = 'PassBook_Statement_$safeName.pdf';

      String? filePath;

      if (Platform.isAndroid) {
        // Android: Save to Downloads folder (visible in File Manager)
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        filePath = '${downloadsDir.path}/$fileName';
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
      }

      final file = File(filePath!);
      await file.writeAsBytes(bytes);

      // final dir = await getTemporaryDirectory();
      // final file = File('${dir.path}/$fileName');
      // await file.writeAsBytes(bytes);

      debugPrint("PDF saved: ${file.path}");

      final result = await OpenFilex.open(file.path);

      switch (result.type) {
        case ResultType.done:
          // Optional: showSuccessToast(context, "PDF opened");
          break;
        case ResultType.noAppToOpen:
          showErrorToast(context, "No PDF viewer installed");
          break;
        case ResultType.fileNotFound:
          showErrorToast(context, "Downloaded file not found");
          break;
        case ResultType.permissionDenied:
          showErrorToast(context, "Storage permission denied");
          break;
        default:
          showErrorToast(context, "Cannot open PDF: ${result.message}");
      }
    } on TimeoutException {
      showErrorToast(context, "Request timed out. Try again.");
    } on SocketException {
      showErrorToast(context, "No internet connection");
    } on FileSystemException {
      showErrorToast(context, "Failed to save PDF");
    } catch (e, s) {
      debugPrint("showSingleChallanPassbookPdf error: $e\n$s");
      showErrorToast(context, "Failed to load PDF");
    }
  }

  Future<void> sharePassBookByGoods({
    required BuildContext context,
    required int customerId,
    required String customerName,
    required String itemName,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/v1/challans/pdf/item?customerId=$customerId&itemName=${Uri.encodeComponent(itemName)}',
      );

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 40));

      if (response.statusCode != 200) {
        showErrorToast(context, "PDF not available for this item");
        debugPrint("PDF Error ${response.statusCode}: ${response.body}");
        return;
      }

      final bytes = response.bodyBytes;

      if (bytes.isEmpty || bytes.length < 1000) {
        showErrorToast(context, "No PDF generated for this item yet");
        return;
      }

      // Safe filename using only itemName
      final safeItemName = itemName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final fileName = 'SnowCool_${customerName}_$safeItemName.pdf';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      debugPrint("PDF saved: ${file.path}");

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Item Passbook - $itemName - Snow Cool Trading',
        subject: 'Item Passbook - $itemName',
      );
    } catch (e, s) {
      debugPrint("Share failed: $e\n$s");
      showErrorToast(context, "Failed to share PDF");
    }
  }

  Future<void> shareExcelByGoods({
    required BuildContext context,
    required int customerId,
    required String customerName,
    required String itemName,
    String? authToken, // Optional Bearer token if your API requires it
  }) async {
    try {
      // Build the URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/api/v1/challans/excel/item?customerId=$customerId&itemName=${Uri.encodeComponent(itemName)}',
      );

      // Headers (same as your PDF function)
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        ..._headers, // Reuse your existing _headers map if it already contains common headers
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      // Make the GET request using http (consistent with PDF version)
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 40));

      // Check status
      if (response.statusCode != 200) {
        showErrorToast(context, "Excel not available for this item");
        debugPrint("Excel Error ${response.statusCode}: ${response.body}");
        return;
      }

      final bytes = response.bodyBytes;

      // Basic validation – Excel files are usually > 5KB
      if (bytes.isEmpty || bytes.length < 1000) {
        showErrorToast(context, "No Excel data generated for this item yet");
        return;
      }

      // Safe filename (remove invalid characters)
      final safeCustomerName = customerName.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final safeItemName = itemName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      final fileName = 'SnowCool_${safeCustomerName}_$safeItemName.xlsx';

      // Save to temporary directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      debugPrint("Excel saved: ${file.path}");

      // Share using share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Challan Statement - $itemName - Snow Cool Trading',
        subject: 'Challan Excel Report - $itemName',
      );
    } catch (e, s) {
      debugPrint("Excel share failed: $e\n$s");
      showErrorToast(context, "Failed to share Excel file");
    }
  }
}
