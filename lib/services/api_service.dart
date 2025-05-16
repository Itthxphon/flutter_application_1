import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://192.168.31.180:3000/api';

  static Future<List<dynamic>> getOrders({String? color}) async {
    final uri = Uri.parse(
      '$baseUrl/orders${color != null ? '?color=$color' : ''}',
    );
    final response = await http.get(uri);
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
      Uri.parse('$baseUrl/delete-scanned'),
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

  static Future<Map<String, dynamic>> changeLocation({
    required String productId,
    required String newLocation,
    required String employeeId,
  }) async {
    final uri = Uri.parse('$baseUrl/change-location');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'productId': productId,
        'newLocation': newLocation,
        'employeeId': employeeId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('ไม่สามารถเปลี่ยน Location ได้: ${response.body}');
    }
  }


  static Future<Map<String, dynamic>> login({
    required String userID,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userID': userID,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // มี key: success, user
    } else if (response.statusCode == 401) {
      throw Exception('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
    } else {
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อ: ${response.body}');
    }
  }

  static Future<List<dynamic>> scanProductId(String productId) async {
    final uri = Uri.parse('$baseUrl/scan-product-id');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'productId': productId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // return รายการสินค้า (recordset)
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลสินค้า');
    } else {
      throw Exception('เกิดข้อผิดพลาด: ${response.body}');
    }
  }


}
