import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://192.168.31.180:3000/api';

  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<List<dynamic>> getOrderDetails(String saleOrderNo) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orderdetails/$saleOrderNo'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load order details');
    }
  }

  static Future<Map<String, dynamic>> scanSN({
    required String saleOrderNo,
    required String productId,
    required int index,
    required String productSN,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan-sn'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'saleOrderNo': saleOrderNo,
        'productId': productId,
        'index': index,
        'productSN': productSN,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getAllScannedSNs() async {
    final response = await http.get(Uri.parse('$baseUrl/scanned-all'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load scanned SNs');
    }
  }

  static Future<List<dynamic>> getPickingList(String orderNo) async {
    final response = await http.get(Uri.parse('$baseUrl/scanned-all'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load picking list');
    }
  }

  static Future<Map<String, dynamic>> deleteScannedSN({
    required String saleOrderNo,
    required String productId,
    required int index,
    required String productSN,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl//delete-scanned'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'saleOrderNo': saleOrderNo,
        'productId': productId,
        'index': index,
        'productSN': productSN,
      }),
    );

    return jsonDecode(response.body);
  }
}
