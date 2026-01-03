// goods_api.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../utils/api_config.dart';
import '../utils/api_utils.dart';

class GoodsDTO {
  final String name;
  final int? id;

  GoodsDTO({required this.name, this.id});

  factory GoodsDTO.fromJson(Map<String, dynamic> json) {
    return GoodsDTO(
      name: json['name'] as String,
      id: json['id'] as int?,
    );
  }
}

class GoodsApi {
  final String baseUrl = ApiConfig.baseUrl;

  // Safely builds URL (removes double slashes)
  Uri _buildUri(String path) {
    String cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  // Extract real message from your backend error format
  String _getErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final String? msg = json['message'] as String?;
      return msg?.isNotEmpty == true ? msg! : 'Operation failed';
    } catch (e) {
      return 'Server error (${response.statusCode})';
    }
  }

  // CREATE - Save new product
  Future<bool> goods(String productName) async {
    final uri = _buildUri('/api/v1/goods/save');
    final headers = ApiUtils.getAuthenticatedHeaders();
    final body = jsonEncode({'name': productName});

    try {
      final resp = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true;
      }
      throw _getErrorMessage(resp);
    } on TimeoutException {
      throw "Connection timeout. Please try again.";
    } on SocketException {
      throw "No internet connection";
    } catch (e) {
      rethrow;
    }
  }

  // READ - Load all goods
  Future<List<GoodsDTO>> getAllGoods() async {
    final uri = _buildUri('/api/v1/goods/getAllGoods');
    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http.get(uri, headers: headers).timeout(Duration(seconds: 20));

      developer.log('getAllGoods → ${resp.statusCode} | ${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final dynamic decoded = jsonDecode(resp.body);

        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list = (decoded['data'] as List?) ??
                 (decoded['goods'] as List?) ??
                 (decoded['list'] as List?) ??
                 [];
        }

        return list
            .map((e) => GoodsDTO.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw _getErrorMessage(resp);
    } on TimeoutException {
      throw "Failed to load items – timeout";
    } on SocketException {
      throw "No internet connection";
    } on FormatException {
      throw "Failed to load items – invalid response from server";
    } catch (e) {
      throw "Failed to load items";
    }
  }

  // UPDATE - Edit existing product
  Future<bool> updateGood(int id, String name) async {
    final uri = _buildUri('/api/v1/goods/updateById/$id');
    final headers = ApiUtils.getAuthenticatedHeaders();
    final body = jsonEncode({'name': name});

    try {
      final resp = await http.put(uri, headers: headers, body: body).timeout(Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true; // SUCCESS - returns true, no toast
      }

      throw _getErrorMessage(resp); // e.g. "Another goods item with same name already exists"
    } on TimeoutException {
      throw "Update failed – timeout";
    } on SocketException {
      throw "No internet connection";
    } catch (e) {
      rethrow;
    }
  }

  // DELETE - Remove product
  Future<bool> deleteGood(int id) async {
    final uri = _buildUri('/api/v1/goods/deleteById/$id');
    final headers = ApiUtils.getAuthenticatedHeaders();

    try {
      final resp = await http.delete(uri, headers: headers).timeout(Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true; // SUCCESS
      }

      throw _getErrorMessage(resp);
    } on TimeoutException {
      throw "Delete failed – timeout";
    } on SocketException {
      throw "No internet connection";
    } catch (e) {
      rethrow;
    }
  }
}