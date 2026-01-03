import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

/// Structured response from the profile API.
class ProfileResponse {
  final bool success;
  final String? message; // human readable message
  final Map<String, dynamic>?
  data; // profile data {name, email, phone, address, company, photoUrl?}

  ProfileResponse({required this.success, this.message, this.data});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    // If backend returns the profile object directly (no 'data' wrapper)
    if (!json.containsKey('data')) {
      return ProfileResponse(success: true, message: null, data: json);
    }
    // Standard wrapped response
    return ProfileResponse(
      success: json['success'] == true || json['data'] != null,
      message: json['message']?.toString(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Simple profile API wrapper.
class ProfileApi {
  /// Global id variable
  static int id = 1;

  /// Compute only the changed fields between [oldData] and [newData].
  /// - Trims strings before comparison
  /// - Excludes null/empty-string values
  Map<String, dynamic> _diffProfileData(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    final Map<String, dynamic> diff = {};
    for (final entry in newData.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;
      final valStr = value is String ? value.trim() : value;
      if (valStr is String && valStr.isEmpty) continue;

      final oldVal = oldData[key];
      final oldStr = oldVal is String ? oldVal.trim() : oldVal;
      if (oldStr != valStr) {
        diff[key] = value;
      }
    }
    return diff;
  }

  Future<ProfileResponse> updateProfile(
    int id,
    Map<String, dynamic> changedFields, {
    Map<String, dynamic>? oldProfile,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/profiles/updateById/$id');
    final headers = ApiUtils.getAuthenticatedHeaders();
    // Send only changed fields when oldProfile is provided; otherwise send
    // only non-null, non-empty fields from changedFields.
    Map<String, dynamic> bodyData;
    if (oldProfile != null) {
      bodyData = _diffProfileData(oldProfile, changedFields);
    } else {
      bodyData = {
        for (final e in changedFields.entries)
          if (e.value != null &&
              (!(e.value is String) || (e.value as String).trim().isNotEmpty))
            e.key: e.value,
      };
    }

    if (bodyData.isEmpty) {
      // Nothing changed — treat as success no-op
      return ProfileResponse(success: true, message: 'No changes to update');
    }
    final body = jsonEncode(bodyData);
    log('ProfileApi update: PUT $url');
    log('ProfileApi update: body=$body');
    try {
      final resp = await http
          .put(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      log('ProfileApi update: status=${resp.statusCode}');
      log('ProfileApi update: response=${resp.body}');
      if (resp.statusCode == 200) {
        final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
        return ProfileResponse.fromJson(jsonResp);
      } else if (resp.statusCode == 401) {
        return ProfileResponse(
          success: false,
          message: 'Unauthorized. Please log in again.',
        );
      } else {
        return ProfileResponse(
          success: false,
          message: 'Failed to update profile.',
        );
      }
    } catch (e) {
      log('ProfileApi update: network error: $e');
      return ProfileResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Global default profileId for all profile API calls
  static const int defaultProfileId = 1;
  final String baseUrl;

  ProfileApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Creates a new profile with the given details and returns a [ProfileResponse].
  Future<ProfileResponse> createProfile(
    String name,
    String email,
    String phone,
    String address,
    String company,
  ) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/profiles/save',
    ); // Assuming endpoint
    final body = jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'company': company,
    });

    // Debug prints (ok during development)
    log('ProfileApi create: POST $url');
    log('ProfileApi create: body=$body');

    // Get authenticated headers (token internally from TokenManager)
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ProfileApi create: headers=$headers');

    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      log('ProfileApi create: status=${resp.statusCode}');
      log('ProfileApi create: response=${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          return ProfileResponse.fromJson(jsonResp);
        } catch (e) {
          log('ProfileApi create: failed to decode JSON: $e');
          return ProfileResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        // Handle errors with proper user-friendly messages
        if (resp.statusCode == 400 || resp.statusCode == 401) {
          // Try to parse error message from body first
          try {
            final Map<String, dynamic> jsonResp =
                jsonDecode(resp.body) as Map<String, dynamic>;
            final response = ProfileResponse.fromJson(jsonResp);
            return ProfileResponse(
              success: false,
              message:
                  response.message ??
                  'Failed to create profile. Please check your details.',
            );
          } catch (_) {
            // If can't parse response, return default error
            return ProfileResponse(
              success: false,
              message: 'Failed to create profile. Please check your details.',
            );
          }
        } else {
          // For other status codes, try to parse error or show generic message
          try {
            final Map<String, dynamic> jsonResp =
                jsonDecode(resp.body) as Map<String, dynamic>;
            return ProfileResponse.fromJson(jsonResp);
          } catch (_) {
            return ProfileResponse(
              success: false,
              message: 'Unable to connect to server. Please try again later.',
            );
          }
        }
      }
    } catch (e) {
      log('ProfileApi create: network error: $e');
      return ProfileResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Fetches the current user's profile and returns a [ProfileResponse].
  /// If [profileId] is not provided, uses [defaultProfileId].
  Future<ProfileResponse> getProfile([int? profileId]) async {
    final int id = profileId ?? defaultProfileId;
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/profiles/getById/$id',
    ); // Assuming endpoint

    // Debug prints (ok during development)
    log('ProfileApi get: GET $url');

    // Get authenticated headers (token internally from TokenManager)
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ProfileApi get: headers=$headers');

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      print(resp);

      log('ProfileApi get: status=${resp.statusCode}');
      log('ProfileApi get: response=${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          return ProfileResponse.fromJson(jsonResp);
        } catch (e) {
          log('ProfileApi get: failed to decode JSON: $e');
          return ProfileResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        // Handle errors with proper user-friendly messages
        if (resp.statusCode == 401) {
          return ProfileResponse(
            success: false,
            message: 'Unauthorized. Please log in again.',
          );
        } else if (resp.statusCode == 404) {
          return ProfileResponse(
            success: false,
            message: 'Profile not found. Please create your profile first.',
          );
        } else {
          // For other status codes, try to parse error or show generic message
          try {
            final Map<String, dynamic> jsonResp =
                jsonDecode(resp.body) as Map<String, dynamic>;
            return ProfileResponse.fromJson(jsonResp);
          } catch (_) {
            return ProfileResponse(
              success: false,
              message: 'Unable to load profile. Please try again later.',
            );
          }
        }
      }
    } catch (e) {
      log('ProfileApi get: network error: $e');
      return ProfileResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Uploads profile photo and returns a [ProfileResponse].
  Future<ProfileResponse> uploadProfilePhoto(File imageFile) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/profile/photo',
    ); // Assuming endpoint for photo upload

    // Multipart request for image
    var request = http.MultipartRequest('POST', url);
    request.files.add(
      await http.MultipartFile.fromPath('photo', imageFile.path),
    );

    // Add auth headers
    final headers = ApiUtils.getAuthenticatedHeaders();
    request.headers.addAll(headers);

    log('ProfileApi uploadPhoto: POST $url');

    try {
      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);

      log('ProfileApi uploadPhoto: status=${resp.statusCode}');
      log('ProfileApi uploadPhoto: response=${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          return ProfileResponse.fromJson(jsonResp);
        } catch (e) {
          log('ProfileApi uploadPhoto: failed to decode JSON: $e');
          return ProfileResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        return ProfileResponse(
          success: false,
          message: 'Failed to upload photo. Please try again.',
        );
      }
    } catch (e) {
      log('ProfileApi uploadPhoto: network error: $e');
      return ProfileResponse(success: false, message: 'Network error: $e');
    }
  }
}
