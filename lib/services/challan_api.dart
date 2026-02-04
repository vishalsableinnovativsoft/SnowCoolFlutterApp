import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:snow_trading_cool/utils/api_utils.dart';
import 'package:snow_trading_cool/utils/errormessage.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../utils/api_config.dart';
import '../utils/token_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class ChallanDTO {
  final int id;
  final String customerName;
  final String challanType;
  final String siteLocation;
  final String qty;
  final String date;
  final String challanNumber;
  final String deliveryDetails;
  final String purchaseOrderNo;
  final double deposite;
  final double returnedAmount;
  final String depositeNarration;
  final String deliveredChallanNo;
  final String vehicleNumber;
  final String transporter;
  final String driverName;
  final String driverNumber;
  // final List<Map<String, dynamic>> items;

  ChallanDTO({
    required this.id,
    required this.customerName,
    required this.challanType,
    required this.siteLocation,
    required this.qty,
    required this.date,
    required this.challanNumber,
    required this.deliveryDetails,
    required this.purchaseOrderNo,
    required this.deposite,
    required this.returnedAmount,
    required this.depositeNarration,
    required this.deliveredChallanNo,
    required this.vehicleNumber,
    required this.transporter,
    required this.driverName,
    required this.driverNumber,
    // required this.items,
  });

  factory ChallanDTO.fromJson(Map<String, dynamic> json) {
    return ChallanDTO(
      id: json['id'],
      customerName: json['name'],
      challanType: json['challanType'],
      siteLocation: json['location'],
      qty: json['qty'].toString(),
      date: json['date'],
      challanNumber: json['challanNumber'],
      deliveryDetails: json['deliveryDetails'],
      purchaseOrderNo: json['purchaseOrderNo'] ?? 0.0,
      deposite: json['deposite'] ?? 0.0,
      returnedAmount: json['returnedAmount'] ?? 0.0,
      depositeNarration: json['depositeNarration'] ?? '',
      deliveredChallanNo: json['deliveredChallanNo'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      transporter: json['transporter'] ?? '',
      driverName: json['driverName'] ?? '',
      driverNumber: json['driverNumber'] ?? '',
      // items: (json['items'] as List<dynamic>?)?.map((item) {
      //   return {
      //     'name': item['name'],
      //     'type': item['type'],
      //     'deliveredQty': item['deliveredQty'],
      //     'receivedQty': item['receivedQty'],
      //     'srNo': item['srNo'],
      //     'batchRef': item['batchRef'],
      // }
      // };
    );
  }
}

class PaginatedChallanResponse {
  final List<ChallanDTO> content;
  final int totalPages;
  final int totalElements;
  final bool? last;
  final int size;
  final int number;

  PaginatedChallanResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    this.last,
    required this.size,
    required this.number,
  });

  factory PaginatedChallanResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedChallanResponse(
      content: (json['content'] as List<dynamic>)
          .map((e) => ChallanDTO.fromJson(e))
          .toList(),
      totalPages: json['totalPages'],
      totalElements: json['totalElements'],
      last: json['last'],
      size: json['size'],
      number: json['number'],
    );
  }
}

extension PaginatedChallanResponseExtension on PaginatedChallanResponse {
  static PaginatedChallanResponse empty() {
    return PaginatedChallanResponse(
      content: [],
      totalPages: 0,
      totalElements: 0,
      last: true,
      size: 0,
      number: 0,
    );
  }
}

String _extractErrorMessage(http.Response response) {
  try {
    final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
    return errorJson['message'] as String? ??
        'Server error ${response.statusCode}';
  } catch (_) {
    return response.body.isNotEmpty ? response.body : 'Unknown error';
  }
}

class ChallanApi {
  final String baseUrl;
  final TokenManager _tokenManager = TokenManager();

  ChallanApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // -------------------------------------------------------------------------
  // Headers with JWT
  // -------------------------------------------------------------------------
  Map<String, String> _getHeaders() {
    final token = _tokenManager.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _extractErrorMessage(http.Response response) {
    String errorMessage = "Failed to process request";
    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage =
          errorJson['message'] ??
          errorJson['error'] ??
          errorJson['detail'] ??
          errorJson['title'] ??
          errorJson.values.whereType<String>().firstOrNull ??
          response.body;
    } catch (_) {
      errorMessage = response.body.isNotEmpty
          ? response.body
          : "Server error ${response.statusCode}";
    }
    debugPrint(
      "API call failed: ${response.statusCode} → $errorMessage (URL: ${response.request?.url})",
    );
    return errorMessage;
  }

  // -------------------------------------------------------------------------
  // DOWNLOAD & SHOW PDF FROM BACKEND (Best & Final Method)
  // -------------------------------------------------------------------------

  Future<void> downloadAndShowPdf(
    int challanId, {
    String? challanNumber,
    required BuildContext context, // Add this parameter
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/challans/download/$challanId'),
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
        showErrorToast(context, "Invalid or empty PDF file");
        debugPrint("PDF too small: ${response.bodyBytes.length} bytes");
        return;
      }

      final bytes = response.bodyBytes;

      // Safe filename
      String safeFileName = (challanNumber ?? challanId.toString())
          .replaceAll(RegExp(r'[<>:"/\\|?*%]'), '_')
          .replaceAll('/', '_')
          .replaceAll(' ', '_');

      final fileName = 'Challan_$safeFileName.pdf';
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

  // -------------------------------------------------------------------------
  // CREATE CHALLAN
  // -------------------------------------------------------------------------

  Future<bool> createChallan({
    int? customerId,
    required String customerName,
    required String challanType,
    required String location,
    required String transporter,
    required String vehicleNumber,
    required String driverName,
    required String driverNumber,
    required List<Map<String, dynamic>> items,
    required String date,
    String? address,
    String? purchaseOrderNo,
    double? returnedAmount,
    double? deposite,
    required String deliveryDetails,
    String? depositeNarration,
    // String? deliveredChallanNo,
    // List<String>? receivedChallanNos,
    required BuildContext context,
  }) async {
    try {
      final Map<String, dynamic> body = {
        if (customerId != null) 'customerId': customerId,
        'customerName': customerName,
        'challanType': challanType,
        'siteLocation': location,
        'transporter': transporter,
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'driverNumber': driverNumber,
        'depositeNarration': depositeNarration,
        if (address != null && address.isNotEmpty) 'address': address,
        'date': date,
        'challanNumber': 'AUTO',
        if (purchaseOrderNo != null && purchaseOrderNo.isNotEmpty)
          'purchaseOrderNo': purchaseOrderNo,
        'deposite': deposite,
        'returnedAmount': returnedAmount,
        'deliveryDetails': deliveryDetails,
        // if (deliveredChallanNo != null && deliveredChallanNo.isNotEmpty)
        //   'deliveredChallanNo': deliveredChallanNo,
        //   'receivedChallanNos': receivedChallanNos ?? [],
        'items': items,
      };

      debugPrint("FINAL PAYLOAD: ${jsonEncode(body)}");

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/challans/create'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      // SUCCESS
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final message =
            jsonResponse['message'] ?? "Challan created successfully!";
        if (context.mounted) showSuccessToast(context, message);
        return true;
      }

      // FAILURE → Show real backend message
      final errorMsg = _extractErrorMessage(response);
      if (context.mounted) showErrorToast(context, errorMsg);
      return false;

      // The old SnowCoolErrorResponse parsing block was never running
    } on TimeoutException {
      if (context.mounted)
        showErrorToast(context, "Request timed out. Please try again later.");
      return false;
    } on http.ClientException {
      if (context.mounted) showErrorToast(context, "No internet connection");
      return false;
    } on FormatException {
      if (context.mounted)
        showErrorToast(context, "Invalid response from server");
      return false;
    } catch (e) {
      debugPrint("Unexpected error in createChallan: $e");
      if (context.mounted)
        showErrorToast(context, "Something went wrong. Please try again.");
      return false;
    }
  }

  Future<PaginatedChallanResponse> getChallanPaginated({
    int page = 0,
    int size = 10,
    String? type,
    String? search,
    String? fromDate,
    String? toDate,
    required BuildContext context,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (type != null && type != 'All') 'challanType': type.toUpperCase(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    };

    final uri = Uri.parse(
      '$baseUrl/api/v1/challans/paginated',
    ).replace(queryParameters: params);

    final response = await http
        .get(uri, headers: _getHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      return PaginatedChallanResponse.fromJson(json);
    } else {
      final error = _extractErrorMessage(response);
      showErrorToast(context, error);
      // return PaginatedChallanResponse.empty();
      throw Exception(error);
    }
  }

  // -------------------------------------------------------------------------
  // FETCH ALL CHALLANS
  // -------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchAllChallans(
    BuildContext context,
  ) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/getAllChallan');

    try {
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      // SUCCESS: 200–299
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        return jsonList.map((j) {
          final String rawType = (j['challanType'] ?? 'RECEIVE').toString();
          final String typeStr = rawType.toUpperCase();

          final List<dynamic>? itemsList = j['items'] as List<dynamic>?;

          final int totalDeliveredQty =
              itemsList?.fold<int>(0, (sum, item) {
                final qty = item['deliveredQty'];
                return sum + ((qty is num) ? qty.toInt() : 0);
              }) ??
              0;

          final int totalReceivedQty =
              itemsList?.fold<int>(0, (sum, item) {
                final qty = item['receivedQty'];
                return sum + ((qty is num) ? qty.toInt() : 0);
              }) ??
              0;

          return {
            'id': j['id'],
            'name': j['customerName']?.toString() ?? 'Unknown',
            'challanType': typeStr,
            'location': j['siteLocation']?.toString() ?? '',
            'qty': totalDeliveredQty + totalReceivedQty,
            'date': j['date']?.toString() ?? '',
            'rawData': j,
          };
        }).toList();
      }

      // ERROR: Non-2xx status code → Parse SnowCoolErrorResponse
      String errorMessage = "Failed to load challans";

      if (response.body.isNotEmpty) {
        try {
          final Map<String, dynamic> errorJson = jsonDecode(response.body);
          final errorResponse = SnowCoolErrorResponse.fromJson(errorJson);

          errorMessage =
              errorResponse.message; // This is the real backend message!

          // Optional: Log full error for debugging
          debugPrint(
            "API Error ${errorResponse.status}: ${errorResponse.message}",
          );
        } catch (parseError) {
          debugPrint("Failed to parse error response: $parseError");
          errorMessage = response.body.length > 200
              ? "Server returned an error"
              : response.body;
        }
      } else {
        errorMessage = "Server error: ${response.statusCode}";
      }

      // Show clean, user-friendly message
      if (context.mounted) {
        showErrorToast(context, errorMessage);
      }

      return []; // Always safe to return empty list
    } on TimeoutException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "Request timed out. Please try again.");
      }
      return [];
    } on http.ClientException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "No internet connection");
      }
      return [];
    } on FormatException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "Invalid data received from server");
      }
      return [];
    } catch (e) {
      debugPrint("Unexpected error in fetchAllChallans: $e");
      if (context.mounted) {
        showErrorToast(context, "Something went wrong. Please try again.");
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getChallansByType(
    String type,
    BuildContext context,
  ) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    late final Uri url;
    if (type == 'all') {
      url = Uri.parse('$normalizedBase/api/v1/challans/page');
    } else if (type == 'received') {
      url = Uri.parse('$normalizedBase/api/v1/challans/getReceivedChallans');
    } else {
      url = Uri.parse('$normalizedBase/api/v1/challans/getPassbook');
    }

    try {
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseMap = jsonDecode(response.body);

        // Extract the actual list from "content" (Spring Page wrapper)
        // Also supports old direct List format for backward compatibility
        final List<dynamic> jsonList = responseMap['content'] is List
            ? responseMap['content']
            : (responseMap is List ? responseMap : []);

        return jsonList.map((j) {
          final String rawType = (j['challanType'] ?? 'DELIVERED').toString();
          final String typeStr = rawType.toUpperCase();

          final List<dynamic>? itemsList = j['items'] as List<dynamic>?;

          final int totalDeliveredQty =
              itemsList?.fold<int>(0, (sum, item) {
                final qty = item['deliveredQty'];
                return sum + ((qty is num) ? qty.toInt() : 0);
              }) ??
              0;

          final int totalReceivedQty =
              itemsList?.fold<int>(0, (sum, item) {
                final qty = item['receivedQty'];
                return sum + ((qty is num) ? qty.toInt() : 0);
              }) ??
              0;

          return {
            'id': j['id'],
            'name': j['customerName']?.toString() ?? 'Unknown',
            'challanType': typeStr,
            'location': j['siteLocation']?.toString() ?? '',
            'qty': totalDeliveredQty + totalReceivedQty,
            'date': j['date']?.toString() ?? '',
            'challanNumber': j['challanNumber']?.toString() ?? '',
            'purchaseOrderNo': j['purchaseOrderNo']?.toString() ?? '',
            'deposite': (j['deposite'] as num?)?.toDouble() ?? 0.0,
            'returnedAmount': (j['returnedAmount'] as num?)?.toDouble() ?? 0.0,
            'rawData': j, // Full original JSON for Edit, PDF, SrNo list, etc.
          };
        }).toList();
      }

      // ───── ERROR HANDLING (same as before) ─────
      String errorMessage = "Failed to load challans";

      if (response.body.isNotEmpty) {
        try {
          final Map<String, dynamic> errorJson = jsonDecode(response.body);
          final errorResponse = SnowCoolErrorResponse.fromJson(errorJson);
          errorMessage = errorResponse.message;
          debugPrint(
            "API Error ${errorResponse.status}: ${errorResponse.message}",
          );
        } catch (_) {
          errorMessage = response.body.length > 200
              ? "Server returned an error"
              : response.body;
        }
      } else {
        errorMessage = "Server error: ${response.statusCode}";
      }

      if (context.mounted) {
        showErrorToast(context, errorMessage);
      }

      return [];
    } on TimeoutException catch (_) {
      if (context.mounted)
        showErrorToast(context, "Request timed out. Please try again.");
      return [];
    } on http.ClientException catch (_) {
      if (context.mounted) showErrorToast(context, "No internet connection");
      return [];
    } on FormatException catch (_) {
      if (context.mounted)
        showErrorToast(context, "Invalid data received from server");
      return [];
    } catch (e) {
      debugPrint("Unexpected error in getChallansByType: $e");
      if (context.mounted)
        showErrorToast(context, "Something went wrong. Please try again.");
      return [];
    }
  }

  // -------------------------------------------------------------------------
  // GET SINGLE CHALLAN
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>?> getChallan(int id, BuildContext context) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/challans/getByChallanId/$id');

    try {
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'id': data['id'],
          'customerId': data['customerId'],
          'customerName': data['customerName'] ?? '',
          'siteLocation': data['siteLocation'] ?? '',
          'transporter': data['transporter'] ?? '',
          'vehicleNumber': data['vehicleNumber'] ?? '',
          'driverName': data['driverName'] ?? '',
          'driverNumber': data['driverNumber'] ?? '',
          'date': data['date'] ?? '',
          'challanType': data['challanType'],
          'items': data['items'] ?? [],
          'purchaseOrderNo': data['purchaseOrderNo'] ?? '',
          'deposite': data['runningBalance'] ?? '',
          'deliveryDetails': data['deliveryDetails'] ?? '',
          'depositeNarration': data['depositeNarration'] ?? '',
          'returnedAmount': data['returnedAmount'] ?? '',
          // 'deliveredChallanNo': data['deliveredChallanNo'] ?? '',
        };
      }

      String errorMessage = "Failed to load challans";

      if (response.body.isNotEmpty) {
        try {
          final Map<String, dynamic> errorJson = jsonDecode(response.body);
          final errorResponse = SnowCoolErrorResponse.fromJson(errorJson);

          errorMessage =
              errorResponse.message; // This is the real backend message!

          // Optional: Log full error for debugging
          debugPrint(
            "API Error ${errorResponse.status}: ${errorResponse.message}",
          );
        } catch (parseError) {
          debugPrint("Failed to parse error response: $parseError");
          errorMessage = response.body.length > 200
              ? "Server returned an error"
              : response.body;
        }
      } else {
        errorMessage = "Server error: ${response.statusCode}";
      }

      // Show clean, user-friendly message
      if (context.mounted) {
        showErrorToast(context, errorMessage);
      }

      return null; // Always safe to return empty list
    } on TimeoutException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "Request timed out. Please try again.");
      }
      return null;
    } on http.ClientException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "No internet connection");
      }
      return null;
    } on FormatException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "Invalid data received from server");
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching challan: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchChallansPage({
    required int page,
    required int size,
    String? search,
    String? type,
    String? fromDate,
    String? toDate,
  }) async {
    final Map<String, String> params = {
      'page': page.toString(),
      'size': size.toString(),
      if (search != null && search.trim().isNotEmpty)
        'searchQuery': search.trim(),
      if (type != null && type != 'All') 'challanType': type.toUpperCase(),
      if (fromDate != null) 'startDate': fromDate,
      if (toDate != null) 'endDate': toDate,
    };

    final uri = Uri.parse(
      '$baseUrl/api/v1/challans/page',
    ).replace(queryParameters: params);
    debugPrint("API URL: $uri");

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // This is the KEY fix – extract your CustomException message
      String errorMessage = "Something went wrong";

      try {
        final errorBody = jsonDecode(response.body);
        // Your backend returns { "message": "actual error here", ... }
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'] as String;
        } else if (errorBody['error'] != null) {
          errorMessage = errorBody['error'] as String;
        }
      } catch (_) {
        // If JSON parse fails, fallback to raw body
        errorMessage = response.body.isNotEmpty
            ? response.body
            : "Server error";
      }

      // Optional: include status code for debugging
      errorMessage = "[$response.statusCode] $errorMessage";

      throw Exception(errorMessage); // Now shows real message in toast
    }
  }

  // -------------------------------------------------------------------------
  // DELETE MULTIPLE CHALLANS
  // -------------------------------------------------------------------------
  Future<bool> deleteMultipleChallans(
    List<int> ids,
    BuildContext context,
  ) async {
    if (ids.isEmpty) {
      showErrorToast(context, "No challans selected to delete");
      return false;
    }

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/challans/deleteMultipleChallans',
    );

    try {
      final response = await http
          .post(
            url,
            headers: _getHeaders(),
            body: jsonEncode(ids), // Wrap in object (recommended)
          )
          .timeout(const Duration(seconds: 20));

      // Success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        String successMsg = "Successfully deleted ${ids.length} challan(s)";

        try {
          final json = jsonDecode(response.body);
          if (json is Map && json['message'] != null) {
            successMsg = json['message'].toString();
          }
        } catch (_) {
          // Ignore if body is not JSON
        }

        showSuccessToast(context, successMsg);
        return true;
      }

      // Handle error response
      String errorMessage = "Failed to delete challans";

      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] ??
            errorJson['error'] ??
            errorJson['detail'] ??
            errorJson.values.whereType<String>().firstOrNull ??
            response.body;
      } catch (_) {
        errorMessage = response.body.isNotEmpty
            ? response.body
            : "Server error ${response.statusCode}";
      }

      showErrorToast(context, errorMessage);
      debugPrint(
        "deleteMultipleChallans failed: ${response.statusCode} → $errorMessage",
      );
      return false;
    } on TimeoutException catch (_) {
      showErrorToast(context, "Request timed out. Please try again.");
      return false;
    } on http.ClientException catch (e) {
      showErrorToast(context, "Network error. Check your connection.");
      debugPrint("deleteMultipleChallans: Network error → $e");
      return false;
    } catch (e) {
      showErrorToast(context, "An unexpected error occurred");
      debugPrint("deleteMultipleChallans: Unexpected error → $e");
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // UPDATE CHALLAN
  // -------------------------------------------------------------------------

  Future<bool> updateChallan({
    required int challanId,
    int? customerId,
    required String customerName,
    required String challanType,
    required String location,
    required String transporter,
    required String vehicleNumber,
    required String driverName,
    required String driverNumber,
    required List<Map<String, dynamic>> items,
    required String date,
    required String deliveryDetails,
    String? purchaseOrderNo,
    double? deposite,
    String? depositeNarration,
    String? deliveredChallanNo,
    required BuildContext context,
    double? returnedAmount,
  }) async {
    if (challanId <= 0) {
      showErrorToast(context, "Invalid challan ID");
      return false;
    }

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/challans/updateChallanById/$challanId',
    );

    try {
      final Map<String, dynamic> body = {
        if (customerId != null) 'customerId': customerId,
        'customerName': customerName,
        'challanType': challanType,
        'siteLocation': location,
        'transporter': transporter,
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'driverNumber': driverNumber,
        'deliveryDetails': deliveryDetails,
        if (purchaseOrderNo != null && purchaseOrderNo.isNotEmpty)
          'purchaseOrderNo': purchaseOrderNo ?? '',
        'deposite': deposite ?? 0.0,
        'returnedAmount': returnedAmount ?? 0.0,
        'depositeNarration': depositeNarration ?? '',
        'date': date,
        if (deliveredChallanNo != null && deliveredChallanNo.isNotEmpty)
          'deliveredChallanNo': deliveredChallanNo,
        'items': items
            .map(
              (item) => {
                'id': item['id'],
                'goodsItemId': item['goodsItemId'],
                'name': item['name'],
                'type': item['type'] ?? '',
                'deliveredQty': item['deliveredQty'],
                'receivedQty': item['receivedQty'] ?? 0,
                'srNo': item['srNo'],
                'batchRef': item['srNo'],
              },
            )
            .toList(),
      };

      debugPrint("Update Challan Payload: ${jsonEncode(body)}");

      final response = await http
          .put(url, headers: _getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 25));

      // SUCCESS: 200–299
      if (response.statusCode >= 200 && response.statusCode < 300) {
        String successMsg = "Challan updated successfully!";

        if (response.body.isNotEmpty) {
          try {
            final json = jsonDecode(response.body);
            if (json is Map<String, dynamic> && json['message'] != null) {
              successMsg = json['message'] as String;
            }
          } catch (_) {
            // Ignore parsing error
          }
        }

        if (context.mounted) {
          showSuccessToast(context, successMsg);
        }
        return true;
      }

      // ERROR: Parse SnowCoolErrorResponse
      String errorMessage = "Failed to update challan";

      if (response.body.isNotEmpty) {
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final errorResponse = SnowCoolErrorResponse.fromJson(errorJson);
          errorMessage = errorResponse.message;

          debugPrint(
            "Update Challan Error ${errorResponse.status}: ${errorResponse.message}",
          );
        } catch (e) {
          debugPrint("Failed to parse error response: $e");
          errorMessage = response.body.length > 300
              ? "Server returned an error"
              : response.body;
        }
      } else {
        errorMessage = "Server error: ${response.statusCode}";
      }

      if (context.mounted) {
        showErrorToast(context, errorMessage);
      }

      return false;
    } on TimeoutException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "Request timed out. Please try again.");
      }
      return false;
    } on http.ClientException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "No internet connection");
      }
      return false;
    } on FormatException catch (_) {
      if (context.mounted) {
        showErrorToast(context, "Invalid response from server");
      }
      return false;
    } catch (e) {
      debugPrint("Unexpected error in updateChallan($challanId): $e");
      if (context.mounted) {
        showErrorToast(context, "Something went wrong. Please try again.");
      }
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // DELETE SINGLE CHALLAN
  // -------------------------------------------------------------------------
  /// SMART DELETE – chooses correct endpoint based on challan type
  Future<bool> deleteChallanSmart(int challanId, String challanType) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final String endpoint;
    if (challanType.trim().toUpperCase() == 'RECEIVED') {
      endpoint = '/api/v1/challans/deleteChallanById/$challanId';
    } else if (challanType.trim().toUpperCase() == 'DELIVERED') {
      endpoint = '/api/v1/challans/deleteChallanById/$challanId';
    } else {
      debugPrint(
        "Unknown challan type: $challanType, falling back to generic delete",
      );
      endpoint =
          '/api/v1/challans/deleteChallanById/$challanId'; // fallback (optional)
    }

    final url = Uri.parse('$normalizedBase$endpoint');

    try {
      final resp = await http
          .delete(url, headers: ApiUtils.getAuthenticatedHeaders())
          .timeout(const Duration(seconds: 15));

      final success = resp.statusCode >= 200 && resp.statusCode < 300;
      if (!success) {
        debugPrint("Delete failed: ${resp.statusCode} ${resp.body}");
      }
      return success;
    } catch (e, s) {
      debugPrint('Error deleting challan (smart): $e\n$s');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchDeliveredChallansPage({
    required int page,
    required int size,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/challans/getPassbook').replace(
      queryParameters: {'page': page.toString(), 'size': size.toString()},
    );
    final response = await http
        .get(uri, headers: _getHeaders())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<Map<String, dynamic>> fetchReceivedChallansPage({
    required int page,
    required int size,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/challans/getReceivedChallans')
        .replace(
          queryParameters: {'page': page.toString(), 'size': size.toString()},
        );
    final response = await http
        .get(uri, headers: _getHeaders())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  //------------- GET Pending Items Of Customer---------------------------

  Future<List<Map<String, dynamic>>?> getCustomerPendingInventoryItems(
    int customerId,
    BuildContext context,
  ) async {
    if (customerId <= 0) return [];

    final url = Uri.parse(
      '$baseUrl/api/v1/challans/getCustomersInventoryItems/$customerId',
    );

    try {
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 404 || response.statusCode == 204) {
        return [];
      } else {
        final error = _extractErrorMessage(response);
        if (context.mounted) showErrorToast(context, error);
        return null;
      }
    } catch (e) {
      debugPrint("getCustomerPendingInventoryItems error: $e");
      if (context.mounted) showErrorToast(context, "Failed to load items");
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // GET FULL CHALLAN DETAILS BY CHALLAN NUMBER (for auto-fill)
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>?> getChallanByChallanNumber(
    BuildContext context,
    String challanNumber,
  ) async {
    if (challanNumber.trim().isEmpty) {
      showErrorToast(context, "Challan number cannot be empty");
      return null;
    }

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final safeChallanNumber = challanNumber.trim().replaceAll("/", "_");
    final url = Uri.parse(
      '$normalizedBase/api/v1/challans/getCustomersChallan/$safeChallanNumber',
    );

    try {
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

      // Success: Challan found
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        return {
          'id': data['id'],
          'customerId': data['customerId'],
          'customerName': data['customerName']?.toString() ?? '',
          'siteLocation': data['siteLocation']?.toString() ?? '',
          'transporter': data['transporter']?.toString() ?? '',
          'vehicleNumber': data['vehicleNumber']?.toString() ?? '',
          'driverName': data['driverName']?.toString() ?? '',
          'driverNumber': data['driverNumber']?.toString() ?? '',
          'deliveryDetails': data['deliveryDetails']?.toString() ?? '',
          'purchaseOrderNo': data['purchaseOrderNo']?.toString() ?? '',
          'deposite': data['deposite'] ?? 0.0,
          'returnedAmount': data['returnedAmount'] ?? 0.0,
          'depositeNarration': data['depositeNarration']?.toString() ?? '',
          'items': data['items'] is List ? data['items'] : <dynamic>[],
          'date': data['date']?.toString() ?? '',
          'receivedChallanNos': data['receivedChallanNos'] ?? [],
          'challanNumber': challanNumber, // Optional: useful for UI
        };
      }

      // 404 → Not found (very common & expected)
      if (response.statusCode == 404) {
        return null; // Silent – UI can show "Not found"
      }

      // Any other error (400, 401, 500, etc.)
      String errorMessage = "Failed to load challan";

      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorJson['message'] ??
            errorJson['error'] ??
            errorJson['detail'] ??
            errorJson['title'] ??
            errorJson.values.whereType<String>().firstOrNull ??
            response.body;
      } catch (_) {
        errorMessage = response.body.isNotEmpty
            ? response.body
            : "Server error ${response.statusCode}";
      }

      showErrorToast(context, errorMessage);
      debugPrint(
        "getChallanByChallanNumber($challanNumber) failed: ${response.statusCode} → $errorMessage",
      );

      return null;
    } on TimeoutException catch (_) {
      showErrorToast(context, "Request timed out. Please try again.");
      debugPrint("getChallanByChallanNumber($challanNumber): Timeout");
      return null;
    } on http.ClientException catch (e) {
      showErrorToast(context, "Network error. Check your connection.");
      debugPrint(
        "getChallanByChallanNumber($challanNumber): Network error → $e",
      );
      return null;
    } on FormatException catch (_) {
      showErrorToast(context, "Invalid data received from server");
      debugPrint(
        "getChallanByChallanNumber($challanNumber): JSON parsing error",
      );
      return null;
    } catch (e) {
      showErrorToast(context, "An unexpected error occurred");
      debugPrint(
        "getChallanByChallanNumber($challanNumber): Unexpected error → $e",
      );
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // SERVER-SIDE SEARCH CHALLANS (by name, contact, email)
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> searchChallans({
    String? query,
    String? challanType,
    String? srNoSearch,
    String? poNoSearch,
    String? fromDate,
    String? toDate,
    required int page,
    required int size,
  }) async {
    final Map<String, String> params = {
      'page': page.toString(),
      'size': size.toString(),
    };

    // Add common filters
    if (challanType != null && challanType.trim().isNotEmpty) {
      params['challanType'] = challanType.trim().toUpperCase();
    }
    if (fromDate != null && fromDate.isNotEmpty) params['fromDate'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) params['toDate'] = toDate;

    // Independently set srNo if provided & valid (alphanumeric)
    if (srNoSearch != null &&
        srNoSearch.trim().isNotEmpty &&
        RegExp(r'^[a-zA-Z0-9]+$').hasMatch(srNoSearch.trim())) {
      params['srNo'] = srNoSearch.trim();
    }

    // Independently set poNumber if provided & valid (alphanumeric)
    if (poNoSearch != null &&
        poNoSearch.trim().isNotEmpty &&
        RegExp(r'^[a-zA-Z0-9]+$').hasMatch(poNoSearch.trim())) {
      params['poNumber'] = poNoSearch.trim();
    }

    // Smart detection for query (general search: name/email/phone)
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();

      // CASE 1: Valid email (full regex)
      if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(q)) {
        params['email'] = q;
      }
      // CASE 2: Only numbers → phone
      else if (RegExp(r'^\d+$').hasMatch(q)) {
        params['contactNumber'] = q;
      }
      // CASE 3: Only letters/spaces → name
      else if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(q)) {
        params['name'] = q;
      }
      // CASE 4: Mixed/weird input → search across text fields
      else {
        params['name'] = q;
        params['contactNumber'] = q;
        params['email'] = q;
      }
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/challans/searchChallans',
    ).replace(queryParameters: params);

    debugPrint("Search URL: $uri");

    try {
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.body;
        return body.isEmpty ? {} : jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception("Search timed out");
    } on http.ClientException {
      throw Exception("No internet connection");
    } catch (e) {
      debugPrint("searchChallans error: $e");
      rethrow;
    }
  }

   Future<Map<String, dynamic>> searchChallansSimple({
  required String query,
  required int page,
  required int size,
}) async {
  try {
    final token = await TokenManager().getToken();
    if (token == null || token.isEmpty) {
      throw Exception("No authentication token available. Please log in again.");
    }

    final uri = Uri.parse('${baseUrl}/api/v1/challans/search').replace(queryParameters: {
      'query': query,
      'page': page.toString(),
      'size': size.toString(),
    });

    debugPrint("→ Calling search: $uri");
    debugPrint("→ Token: ${token.substring(0, 20)}..."); // partial for security

    final response = await http
        .get(uri, headers: _getHeaders())
        .timeout(const Duration(seconds: 15));

    debugPrint("← Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      // Handle unauthorized specifically
      // You can trigger logout here later
      throw Exception("Session expired (401 Unauthorized). Please log in again.");
    } else {
      String errorBody;
      try {
        final err = jsonDecode(response.body);
        errorBody = err['message'] ?? response.body;
      } catch (_) {
        errorBody = response.body;
      }
      throw Exception(
          "Search failed: ${response.statusCode} - $errorBody");
    }
  } catch (e, stack) {
    debugPrint("searchChallansSimple failed: $e");
    debugPrint(stack.toString());
    rethrow; // let caller handle or show toast
  }
}


  // SHARE PDF

  Future<void> sharePdf(
    int challanId,
    BuildContext context,
    String? challanNumber,
  ) async {
    final bytes = await _downloadPdfBytes(challanId, context);
    if (bytes == null || !context.mounted) return;

    try {
      // Create safe & beautiful filename
      String namePart = challanNumber ?? challanId.toString();
      namePart = namePart
          .replaceAll('/', '-')
          .replaceAll(RegExp(r'[<>:"|?*\\]'), '')
          .trim();
      while (namePart.contains('--')) {
        namePart = namePart.replaceAll('--', '-');
      }

      final fileName = 'Challan_$namePart.pdf'; // Challan_SCT-25-26-4.pdf

      // Save to temporary directory (this is the magic step)
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Now share the actual file → Android respects the filename
      await Share.shareXFiles(
        [XFile(file.path)], // share path, not bytes
        text: 'Challan $challanNumber - Snow Trading Cool',
        subject: 'Delivery Challan',
      );

      showSuccessToast(context, "PDF shared successfully");
    } catch (e, s) {
      debugPrint("Share failed: $e\n$s");
      if (context.mounted) {
        showErrorToast(context, "Failed to share PDF");
      }
    }
  }

  Future<Uint8List?> _downloadPdfBytes(
    int challanId,
    BuildContext context,
  ) async {
    final urls = ['$baseUrl/api/v1/challans/download/$challanId'];

    for (final urlStr in urls) {
      final url = Uri.parse(urlStr);
      debugPrint('Trying → $url');
      try {
        final response = await http
            .get(url, headers: _getHeaders())
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
          debugPrint('PDF downloaded: ${response.bodyBytes.length} bytes');
          return response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Failed: $e');
      }
    }

    if (context.mounted) showErrorToast(context, "PDF not found on server");
    return null;
  }
}
