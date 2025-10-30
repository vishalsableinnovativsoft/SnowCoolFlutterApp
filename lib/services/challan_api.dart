import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

class ChallanApi {
  final String baseUrl;

  ChallanApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<bool> challanData(
    String customerName,
    String challanType,
    String location,
    String transporter,
    String vehicleDriverDetails,
    String mobileNumber,
    String smallRegularQty,
    String smallRegularSrNo,
    String smallFloronQty,
    String smallFloronSrNo,
    String bigRegularQty,
    String bigRegularSrNo,
    String bigFloronQty,
    String bigFloronSrNo,
  ) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/challanData');
    final body = jsonEncode({
      'customerName': customerName,
      'challanType': challanType,
      'location': location,
      'transporter': transporter,
      'vehicleDriverDetails': vehicleDriverDetails,
      'mobileNumber': mobileNumber,
      'smallRegularQty': smallRegularQty,
      'smallRegularSrNo': smallRegularSrNo,
      'smallFloronQty': smallFloronQty,
      'smallFloronSrNo': smallFloronSrNo,
      'bigRegularQty': bigRegularQty,
      'bigRegularSrNo': bigRegularSrNo,
      'bigFloronQty': bigFloronQty,
      'bigFloronSrNo': bigFloronSrNo,
    });

    log(customerName);
    log(challanType);
    log(location);
    log(transporter);
    log(vehicleDriverDetails);
    log(mobileNumber);
    log(smallRegularQty);
    log(smallRegularSrNo);
    log(smallFloronQty);
    log(smallFloronSrNo);
    log(bigRegularQty);
    log(bigRegularSrNo);
    log(bigFloronQty);
    log(bigFloronSrNo);

    // Get authenticated headers
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ChallanApi: headers=$headers');

    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      // Print response for debugging
      log('challanApi: status=${resp.statusCode}');
      log('challanApi: response=${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          // Accept either explicit success flag or presence of token
          if (jsonResp['success'] == true) return true;
          if (jsonResp['token'] != null) return true;
          return false;
        } catch (e) {
          // Could not parse JSON — log and treat as failure
          log('ChallanApi: JSON decode error: $e');
          return false;
        }
      } else if (resp.statusCode == 401) {
        log('ChallanApi: 401 Unauthorized - Missing or invalid token');
        return false;
      } else {
        log('ChallanApi: HTTP ${resp.statusCode} - ${resp.body}');
        return false;
      }
    } catch (e) {
      // You may want to log the error in real app
      return false;
    }
  }
}
