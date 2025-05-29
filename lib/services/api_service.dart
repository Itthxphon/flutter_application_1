import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://192.168.31.180:3000/api';
  // static const baseUrl = 'http://172.16.102.242:3000/api';
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
      body: jsonEncode({'userID': userID, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // มี key: success, user
    } else if (response.statusCode == 401) {
      throw Exception('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
    } else {
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อ: ${response.body}');
    }
  }

  static Future<List<dynamic>> scanProductId(String keyword) async {
    final uri = Uri.parse('$baseUrl/scan-product-id');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'productId': keyword,
        'productName': keyword, // ✅ ค้นหาเฉพาะชื่อสินค้า
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลสินค้า');
    } else {
      throw Exception('เกิดข้อผิดพลาด: ${response.body}');
    }
  }

  static Future<List<dynamic>> getAllRFG() async {
    final response = await http.get(Uri.parse('$baseUrl/get-all-rfg'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('ไม่สามารถโหลดรายการ RFG ได้');
    }
  }

  static Future<Map<String, dynamic>> updateLocation({
    required String processOrderId,
    required String newLocation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-location'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'processOrderId': processOrderId,
        'newLocation': newLocation,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('ไม่สามารถอัปเดตสถานที่ได้: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> confirmStockCheckedRFG({
    required String processOrderId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/confirm-stock-checked-rfg'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'processOrderId': processOrderId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // message + receiveFGNo
    } else {
      throw Exception('ยืนยันการรับ FG ล้มเหลว: ${response.body}');
    }
  }

  static Future<List<dynamic>> searchProductChangeLocation(
    String keyword,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/search-product-changelocation?keyword=$keyword',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('ค้นหาสินค้าในสต็อกล้มเหลว: ${response.body}');
    }
  }

  static Future<List<dynamic>> getProcessOrderDetail(
    String processOrderId,
  ) async {
    final uri = Uri.parse('$baseUrl/scan-state?processOrderId=$processOrderId');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลคำสั่งผลิต');
    } else {
      throw Exception('เกิดข้อผิดพลาด: ${response.body}');
    }
  }

  static Future<List<dynamic>> getProductsByLocation(String location) async {
    final uri = Uri.parse('$baseUrl/scan-location?location=$location');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลสินค้าใน Location นี้');
    } else {
      throw Exception('เกิดข้อผิดพลาด: ${response.body}');
    }
  }
}
