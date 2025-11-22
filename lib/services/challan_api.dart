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
    String challanDate,
    String location,
    String transporter,
    String vehicleDriverDetails,
    String vehicleNumber,
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
      'date': challanDate,
      'location': location,
      'transporter': transporter,
      'vehicleDriverDetails': vehicleDriverDetails,
      'vehicleNumber': vehicleNumber,
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
    log(challanDate);
    log(location);
    log(transporter);
    log(vehicleDriverDetails);
    log(vehicleNumber);
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


  //-----------FETCH CHALLAN DATA-----------//

  Future<List<Map<String, dynamic>>> fetchChallanData({
    String? customerName,
    String? challanType,
    String? challanDate,
    String? location,
    String? transporter,
    String? vehicleDriverDetails,
    String? vehicleNumber,
    String? mobileNumber,
    String? smallRegularQty,
    String? smallRegularSrNo,
    String? smallFloronQty,
    String? smallFloronSrNo,
    String? bigRegularQty,
    String? bigRegularSrNo,
    String? bigFloronQty,
    String? bigFloronSrNo,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // Build query parameters (only add if not null or empty)
    final queryParams = {
      if (customerName != null && customerName.isNotEmpty)
        'customerName': customerName,
      if (challanType != null && challanType.isNotEmpty)
        'challanType': challanType,
      if (challanDate != null && challanDate.isNotEmpty)
        'challanDate': challanDate,
      if (location != null && location.isNotEmpty) 'location': location,
      if (transporter != null && transporter.isNotEmpty)
        'transporter': transporter,
      if (vehicleDriverDetails != null && vehicleDriverDetails.isNotEmpty)
        'vehicleDriverDetails': vehicleDriverDetails,
      if (mobileNumber != null && mobileNumber.isNotEmpty)
        'mobileNumber': mobileNumber,
      if (vehicleNumber != null && vehicleNumber.isNotEmpty)
        'vehicleNumber': vehicleNumber,
      if (smallRegularQty != null && smallRegularQty.isNotEmpty)
        'smallRegularQty': smallRegularQty,
      if (smallRegularSrNo != null && smallRegularSrNo.isNotEmpty)
        'smallRegularSrNo': smallRegularSrNo,
      if (smallFloronQty != null && smallFloronQty.isNotEmpty)
        'smallFloronQty': smallFloronQty,
      if (smallFloronSrNo != null && smallFloronSrNo.isNotEmpty)
        'smallFloronSrNo': smallFloronSrNo,
      if (bigRegularQty != null && bigRegularQty.isNotEmpty)
        'bigRegularQty': bigRegularQty,
      if (bigRegularSrNo != null && bigRegularSrNo.isNotEmpty)
        'bigRegularSrNo': bigRegularSrNo,
      if (bigFloronQty != null && bigFloronQty.isNotEmpty)
        'bigFloronQty': bigFloronQty,
      if (bigFloronSrNo != null && bigFloronSrNo.isNotEmpty)
        'bigFloronSrNo': bigFloronSrNo,
    };

    final uri = Uri.parse(
      '$normalizedBase/getChallanData',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    log('fetchChallanData (GET): URL=$uri');

    final headers = ApiUtils.getAuthenticatedHeaders();
    log('fetchChallanData: headers=$headers');

    try {
      final resp = await http.get(uri, headers: headers);
      // .timeout(const Duration(seconds: 10));

      log('fetchChallanData: status=${resp.statusCode}');
      log('fetchChallanData: response=${resp.body}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);

        // Expected backend response formats:
        // Option 1: {"success": true, "data": [...]}
        // Option 2: just a list [...]
        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == true && decoded['data'] is List) {
            return List<Map<String, dynamic>>.from(decoded['data']);
          }
        } else if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        return [];
      } else {
        log('fetchChallanData: Failed with ${resp.statusCode}');
        return [];
      }
    } catch (e) {
      log('fetchChallanData: Exception - $e');
      return [];
    }
  }

  //-----------------------Delete challan--------------------//

   Future<bool> deleteChallanData(String challanId) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/deleteChallan/$challanId');
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('deleteChallanData (DELETE): URL=$uri');
    log('deleteChallanData: headers=$headers');

    try {
      final resp = await http.delete(uri, headers: headers);
      log('deleteChallanData: status=${resp.statusCode}');
      log('deleteChallanData: response=${resp.body}');

      if (resp.statusCode == 200) {
        final jsonResp = jsonDecode(resp.body);
        return jsonResp['success'] == true;
      } else {
        log('deleteChallanData: Failed with ${resp.statusCode}');
        return false;
      }
    } catch (e) {
      log('deleteChallanData: Exception - $e');
      return false;
    }
  }

  //---------------------- EDIT / UPDATE challan --------------------//
  
  Future<bool> editChallanData(
    String challanId, {
    String? customerName,
    String? challanType,
    String? challanDate,
    String? location,
    String? transporter,
    String? vehicleDriverDetails,
    String? vehicleNumber,
    String? mobileNumber,
    String? smallRegularQty,
    String? smallRegularSrNo,
    String? smallFloronQty,
    String? smallFloronSrNo,
    String? bigRegularQty,
    String? bigRegularSrNo,
    String? bigFloronQty,
    String? bigFloronSrNo,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/updateChallan/$challanId');
    final headers = ApiUtils.getAuthenticatedHeaders();

    final Map<String, dynamic> body = {
      if (customerName != null) 'customerName': customerName,
      if (challanType != null) 'challanType': challanType,
      if (challanDate != null) 'date': challanDate,
      if (location != null) 'location': location,
      if (transporter != null) 'transporter': transporter,
      if (vehicleDriverDetails != null)
        'vehicleDriverDetails': vehicleDriverDetails,
        if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      if (smallRegularQty != null) 'smallRegularQty': smallRegularQty,
      if (smallRegularSrNo != null) 'smallRegularSrNo': smallRegularSrNo,
      if (smallFloronQty != null) 'smallFloronQty': smallFloronQty,
      if (smallFloronSrNo != null) 'smallFloronSrNo': smallFloronSrNo,
      if (bigRegularQty != null) 'bigRegularQty': bigRegularQty,
      if (bigRegularSrNo != null) 'bigRegularSrNo': bigRegularSrNo,
      if (bigFloronQty != null) 'bigFloronQty': bigFloronQty,
      if (bigFloronSrNo != null) 'bigFloronSrNo': bigFloronSrNo,
    };

    log('editChallanData (PUT): URL=$uri');
    log('editChallanData: body=$body');

    try {
      final resp = await http.put(uri,
          headers: headers, body: jsonEncode(body));
      log('editChallanData: status=${resp.statusCode}');
      log('editChallanData: response=${resp.body}');

      if (resp.statusCode == 200) {
        final jsonResp = jsonDecode(resp.body);
        return jsonResp['success'] == true;
      } else {
        log('editChallanData: Failed with ${resp.statusCode}');
        return false;
      }
    } catch (e) {
      log('editChallanData: Exception - $e');
      return false;
    }
  }
}
