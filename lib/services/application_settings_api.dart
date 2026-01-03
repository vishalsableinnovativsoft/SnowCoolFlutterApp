// application_settings_api.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Conditional import for File (only on mobile, ignored on web)

import 'package:snow_trading_cool/utils/api_config.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';

/// ---------------------------------------------------------------------------
/// DTO – matches the JSON that the Spring controller returns
/// ---------------------------------------------------------------------------
class ApplicationSettingsDTO {
  final int? id;
  final String? logoBase64; // <-- Base64 string (sent to backend)
  final String? signatureBase64; // <-- Base64 string
  final String? invoicePrefix;
  final String? challanNumberFormat;
  final int? challanSequence;
  final String? challanSequenceResetPolicy;
  final String? sequenceLastResetDate;
  final String? createdAt;
  final String? updatedAt;
  final String? termsAndConditions;

  ApplicationSettingsDTO({
    this.id,
    this.logoBase64,
    this.signatureBase64,
    this.invoicePrefix,
    this.challanNumberFormat,
    this.challanSequence,
    this.challanSequenceResetPolicy,
    this.sequenceLastResetDate,
    this.createdAt,
    this.updatedAt,
    this.termsAndConditions,
  });

  /// -------------------------------------------------
  /// Convert JSON from backend → DTO
  /// Backend sends:
  ///   "logo": [137,80,78,71,...]   (byte array)
  ///   "signature": [...]
  /// -------------------------------------------------
  factory ApplicationSettingsDTO.fromJson(Map<String, dynamic> json) {
    return ApplicationSettingsDTO(
      id: json['id'] as int?,
      logoBase64: _encodeByteArray(json['logo']),
      signatureBase64: _encodeByteArray(json['signature']),
      invoicePrefix: json['invoicePrefix'] as String?,
      challanNumberFormat: json['challanNumberFormat'] as String?,
      challanSequence: json['challanSequence'] as int?,
      challanSequenceResetPolicy: json['challanSequenceResetPolicy'] as String?,
      sequenceLastResetDate: json['sequenceLastResetDate'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
    );
  }

  /// Helper: turn a JSON list of ints (byte array) → Base64 string
  static String? _encodeByteArray(dynamic data) {
    if (data == null) return null;
    if (data is List<int>) {
      return base64Encode(data);
    }
    // Some back‑ends send a string already – pass through
    if (data is String) return data;
    return null;
  }

  /// -------------------------------------------------
  /// Convert DTO → JSON for POST / PUT
  /// -------------------------------------------------
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (logoBase64 != null) map['logo'] = logoBase64;
    if (signatureBase64 != null) map['signature'] = signatureBase64;
    if (invoicePrefix != null) map['invoicePrefix'] = invoicePrefix;
    if (challanNumberFormat != null)
      map['challanNumberFormat'] = challanNumberFormat;
    if (challanSequence != null) map['challanSequence'] = challanSequence;
    if (challanSequenceResetPolicy != null)
      map['challanSequenceResetPolicy'] = challanSequenceResetPolicy;
    if (sequenceLastResetDate != null)
      map['sequenceLastResetDate'] = sequenceLastResetDate;
    if (termsAndConditions != null)
      map['termsAndConditions'] = termsAndConditions;
    return map;
  }
}

/// ---------------------------------------------------------------------------
/// API client
/// ---------------------------------------------------------------------------
class ApplicationSettingsApi {
  final String _baseUrl = ApiConfig.baseUrl;

  final String token;

  ApplicationSettingsApi({required this.token});

  /// GET /getSettings

Future<ApplicationSettingsDTO?> getSettings(BuildContext context) async {
  final uri = Uri.parse('$_baseUrl/api/v1/settings/getSettings');

  try {
    final response = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    // Success: Settings exist
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApplicationSettingsDTO.fromJson(json);
    }

    // No settings created yet
    if (response.statusCode == 204) {
      return null;
    }

    // Any error status (400, 401, 403, 500, etc.)
    String errorMessage = 'Failed to load settings';

    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;

      // Common backend error response patterns
      if (errorJson.containsKey('message')) {
        errorMessage = errorJson['message'] as String;
      } else if (errorJson.containsKey('error')) {
        errorMessage = errorJson['error'] as String;
      } else if (errorJson.containsKey('detail')) {
        errorMessage = errorJson['detail'] as String;
      } else if (errorJson.containsKey('title')) {
        errorMessage = errorJson['title'] as String;
      } else {
        errorMessage = errorJson.values
            .firstWhere((v) => v is String, orElse: () => response.body);
      }
    } catch (e) {
      // If JSON parsing fails, use raw body or status code
      errorMessage = response.body.isNotEmpty
          ? response.body
          : 'Error ${response.statusCode}';
    }

    // Show the actual backend message in toast
    showErrorToast(
      context,
      errorMessage.trim().isEmpty ? 'Failed to load settings' : errorMessage,
    );

    return null;

  } on http.ClientException catch (e) {
    showErrorToast(context, "Network error: Please check your connection");
    return null;
  } on TimeoutException catch (_) {
    showErrorToast(context, "Request timed out. Please try again.");
    return null;
  } catch (e) {
    showErrorToast(context, "An unexpected error occurred");
    return null;
  }
}

  /// POST /create  or  PUT /update
  

  Future<ApplicationSettingsDTO> _send(
    BuildContext context,
  String method,
  ApplicationSettingsDTO dto,
) async {
  final url = method == 'POST'
      ? '$_baseUrl/api/v1/settings/create'  // Fixed double slash
      : '$_baseUrl/api/v1/settings/update';

  final body = jsonEncode(dto.toJson());

  try {
    final request = http.Request(method, Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json'
      ..body = body;

    final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamedResponse);

    // Success
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApplicationSettingsDTO.fromJson(json);
    }

    // Handle all error cases (400, 401, 422, 500, etc.)
    String errorMessage = 'Operation failed';

    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;

      // Try common error message keys
      errorMessage = errorJson['message'] ??
          errorJson['error'] ??
          errorJson['detail'] ??
          errorJson['title'] ??
          errorJson.values.firstWhere((v) => v is String, orElse: () => '') ??
          'Unknown error occurred';
    } catch (e) {
      // If JSON is invalid, use raw body
      errorMessage = response.body.isNotEmpty
          ? response.body
          : 'Server error ${response.statusCode}';
    }

    // Show backend error message in toast
    showErrorToast(
      context,
      errorMessage.trim().isEmpty ? 'Failed to save settings' : errorMessage,
    );

    // Optionally rethrow if you want calling code to know it failed
    throw Exception('$method failed: $errorMessage');

  } on TimeoutException catch (_) {
    showErrorToast(context, "Request timed out. Please try again.");
    throw Exception("Request timeout");
  } on http.ClientException catch (e) {
    showErrorToast(context, "Network error: Check your connection");
    throw Exception("Network error: $e");
  } catch (e) {
    showErrorToast(context, "An unexpected error occurred");
    rethrow;
  }
}

  Future<ApplicationSettingsDTO> createSettings(ApplicationSettingsDTO dto, BuildContext context) =>
      _send(context, 'POST', dto);

  Future<ApplicationSettingsDTO> updateSettings(ApplicationSettingsDTO dto, BuildContext context) =>
      _send(context, 'PUT', dto);
}




