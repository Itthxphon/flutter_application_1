import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import '../services/api_service.dart';

class ScanProductIdScreen extends StatefulWidget {
  const ScanProductIdScreen({Key? key}) : super(key: key);

  @override
  State<ScanProductIdScreen> createState() => _ScanProductIdScreenState();
}

class _ScanProductIdScreenState extends State<ScanProductIdScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _resultList = [];
  bool _isLoading = false;
  String? _employeeId; // ✅ เพิ่มตัวแปรเก็บ employeeId

  @override
  void initState() {
    super.initState();
    _loadSavedScans();
    _loadEmployeeId(); // ✅ โหลด employeeId ตอนเริ่มต้น
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedId = prefs.getString('employeeId') ?? 'UNKNOWN';
    print('Loaded employeeId: $loadedId');
    setState(() {
      _employeeId = loadedId;
    });
  }


  Future<void> _loadSavedScans() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('scannedProducts');
    if (saved != null) {
      final decoded = jsonDecode(saved) as List<dynamic>;
      setState(() {
        _resultList.addAll(decoded.cast<Map<String, dynamic>>());
      });
    }
  }

  Future<void> _saveScannedList() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_resultList);
    await prefs.setString('scannedProducts', encoded);
  }

  Future<void> _scanProduct([String? manualId]) async {
    final productId = manualId?.trim() ?? _controller.text.trim();
    if (productId.isEmpty) return;

    final alreadyScanned = _resultList.any(
          (item) => item['F_ProductId'] == productId,
    );
    if (alreadyScanned) {
      _showAlertDialog(
        title: '⚠️ แจ้งเตือน',
        message: 'สินค้านี้ถูกสแกนไปแล้ว',
      );
      _controller.clear();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.scanProductId(productId);
      if (data.isNotEmpty) {
        final casted = data.cast<Map<String, dynamic>>();
        setState(() {
          _resultList.addAll(casted);
        });
        await _saveScannedList();
      } else {
        _showAlertDialog(
          title: '⚠️ ไม่พบสินค้า',
          message: 'ไม่พบข้อมูลสินค้าสำหรับรหัส: $productId',
        );
      }
    } catch (_) {
      _showAlertDialog(
        title: '⚠️ เกิดข้อผิดพลาด',
        message: 'ไม่พบข้อมูลสินค้า',
      );
    } finally {
      setState(() {
        _isLoading = false;
        _controller.clear();
      });
    }
  }

  void _showAlertDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF8F0FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1F2B),
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearScans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scannedProducts');
    setState(() => _resultList.clear());
  }

  void _showChangeLocationDialog(String productId) {
    final TextEditingController _locationController = TextEditingController();
    final FocusNode _focusNode = FocusNode();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BarcodeKeyboardListener(
          onBarcodeScanned: (barcode) {
            _confirmLocation(productId, barcode);
            Navigator.pop(context);
          },
          bufferDuration: const Duration(milliseconds: 200),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'เปลี่ยน Location',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1B1F2B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  focusNode: _focusNode,
                  autofocus: false,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Location ใหม่ (ยิง Barcode หรือพิมพ์)',
                    hintStyle: const TextStyle(fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    suffixIcon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.grey,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    Navigator.pop(context);
                    _confirmLocation(productId, value);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmLocation(
                          productId,
                          _locationController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B1F2B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('ยืนยัน'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLocation(String productId, String location) async {
    final newLocation = location.trim();
    if (newLocation.isEmpty) return;
    // Navigator.pop(context);

    try {
      final result = await ApiService.changeLocation(
        productId: productId,
        newLocation: newLocation,
        employeeId: _employeeId ?? 'UNKNOWN', // ✅ ใช้ค่าโหลดจาก SharedPreferences
      );

      if (mounted) {
        _showAlertDialog(
          title: 'แจ้งเตือน',
          message: result['message'] ?? 'เปลี่ยน Location สำเร็จ',
        );
      }
    } catch (_) {
      if (mounted) {
        _showAlertDialog(
          title: 'แจ้งเตือน',
          message: 'เกิดข้อผิดพลาดในการเปลี่ยน Location',
        );
      }
    }
  }

  Widget _buildResultList() {
    if (_resultList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Text('ยังไม่มีรายการที่สแกน'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _resultList.length,
      itemBuilder: (context, index) {
        final item = _resultList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['F_ProductName'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('รหัสสินค้า : ${item['F_ProductId'] ?? '-'}'),
                Text('ยี่ห้อ : ${item['F_ProductBrandName'] ?? '-'}'),
                Text('กลุ่มสินค้า : ${item['F_ProductGroupName'] ?? '-'}'),
                Text(
                  'จำนวนคงเหลือ : ${item['F_StockBalance'] ?? '-'} ${item['F_UnitName'] ?? ''}',
                ),
                Text('ที่เก็บ : ${item['F_Location'] ?? '-'}'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed:
                        () => _showChangeLocationDialog(item['F_ProductId']),
                    icon: const Icon(Icons.edit_location_alt),
                    label: const Text('เปลี่ยน Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeKeyboardListener(
      bufferDuration: const Duration(milliseconds: 200),
      onBarcodeScanned: _scanProduct,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F0FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B1F2B),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'เปลี่ยนสถานที่',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: _clearScans,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'ล้างรายการทั้งหมด',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: false,
                      onSubmitted: (_) => _scanProduct(),
                      decoration: InputDecoration(
                        hintText: 'กรอก/สแกน ProductID',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1F2B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                      ),
                      onPressed: _scanProduct,
                      tooltip: 'สแกน / ค้นหา',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading) const CircularProgressIndicator(),
              _buildResultList(),
            ],
          ),
        ),
      ),
    );
  }
}
