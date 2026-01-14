import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:snow_trading_cool/utils/api_config.dart';
import '../utils/api_utils.dart';

class GoodsApi {
  final String baseUrl;

  GoodsApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<bool> goods(String productName) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/v1/goods/save');
    final body = jsonEncode({'name': productName});

    // Get authenticated headers
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('GoodsApi: POST $uri');
    log('GoodsApi: Sending product name: "$productName"');
    log('GoodsApi: body=$body');
    log('GoodsApi: headers=$headers');

    try {
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      // Print response for debugging
      log('GoodsApi: status=${resp.statusCode}');
      log('GoodsApi: response=${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          log('GoodsApi: Parsed response: $jsonResp');

          // Accept multiple success indicators
          if (jsonResp['success'] == true) return true;
          if (jsonResp['token'] != null) return true;
          if (jsonResp['message'] != null) return true;
          if (jsonResp['id'] != null) return true; // Product saved with ID
          if (jsonResp.containsKey('data')) return true;

          // If we get a 200 status, assume success even if format is unexpected
          log('GoodsApi: 200 status received, treating as success');
          return true;
        } catch (e) {
          // Could not parse JSON — but 200 status means success
          log('GoodsApi: JSON decode error but 200 status: $e');
          log('GoodsApi: Raw response body: ${resp.body}');
          return true; // Treat as success since we got 200
        }
      } else if (resp.statusCode == 401) {
        log('GoodsApi: 401 Unauthorized - Missing or invalid token');
        return false;
      } else {
        log('GoodsApi: HTTP ${resp.statusCode} - ${resp.body}');
        return false;
      }
    } catch (e) {
      // You may want to log the error in real app
      return false;
    }
  }
}
