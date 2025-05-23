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
  String? _employeeId;
  bool _isInDialogMode = false;

  @override
  void initState() {
    super.initState();
    _loadSavedScans();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedId = prefs.getString('employeeId') ?? 'UNKNOWN';
    setState(() => _employeeId = loadedId);
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

  Future<void> _scanProduct([String? manualId]) async {
    if (_isInDialogMode) return;

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
          _resultList
            ..clear()
            ..add(casted.first);
        });
        await _saveScannedList();
      } else if (_resultList.isEmpty) {
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

  Future<void> _saveScannedList() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_resultList);
    await prefs.setString('scannedProducts', encoded);
  }

  void _showAlertDialog({
    required String title,
    required String message,
    bool autoClose = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    showDialog(
      context: context,
      barrierDismissible: !autoClose,
      builder:
          (_) => AlertDialog(
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
            actions:
                autoClose
                    ? null
                    : [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ตกลง'),
                      ),
                    ],
          ),
    );

    if (autoClose) {
      Future.delayed(duration, () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _showChangeLocationDialog(String productId) {
    final TextEditingController _locationController = TextEditingController();
    final FocusNode _focusNode = FocusNode();
    _isInDialogMode = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BarcodeKeyboardListener(
          onBarcodeScanned: (barcode) {
            Navigator.pop(context);
            _confirmLocation(productId, barcode);
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
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'เปลี่ยนสถานที่',
                    style: TextStyle(
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
                  decoration: InputDecoration(
                    hintText: 'กรอก/สแกน สถานที่ใหม่',
                    hintStyle: const TextStyle(fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    suffixIcon: const Icon(Icons.qr_code_scanner, size: 20),
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
                      child: const Text('ยืนยัน'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isInDialogMode = false;
    });
  }

  Future<void> _confirmLocation(String productId, String location) async {
    final newLocation = location.trim();
    if (newLocation.isEmpty) return;

    try {
      final result = await ApiService.changeLocation(
        productId: productId,
        newLocation: newLocation,
        employeeId: _employeeId ?? 'UNKNOWN',
      );

      setState(() {
        final index = _resultList.indexWhere(
          (item) => item['F_ProductId'] == productId,
        );
        if (index != -1) {
          _resultList[index]['F_Location'] = newLocation;
        }
      });

      if (mounted) {
        _showAlertDialog(
          title: '✅ แจ้งเตือน',
          message: result['message'] ?? 'เปลี่ยนสถานที่สำเร็จ',
          autoClose: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showAlertDialog(
          title: '⚠️แจ้งเตือน',
          message: 'เกิดข้อผิดพลาดในการเปลี่ยนสถานที่',
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
        final imagePath = item['imagePath']?.toString() ?? '';

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
                const SizedBox(height: 12),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 300,
                      height: 220,
                      child:
                          imagePath.isNotEmpty
                              ? Image.network(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/pp.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                              : Image.asset(
                                'assets/images/products.png',
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('รหัสสินค้า : ${item['F_ProductId'] ?? '-'}'),
                Text('ยี่ห้อ : ${item['F_ProductBrandName'] ?? '-'}'),
                Text('กลุ่มสินค้า : ${item['F_ProductGroupName'] ?? '-'}'),
                Text(
                  'จำนวนคงเหลือ : ${item['F_StockBalance'] ?? '-'} ${item['F_UnitName'] ?? ''}',
                ),
                Text('ที่เก็บ : ${item['F_Location'] ?? '-'}'),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed:
                        () => _showChangeLocationDialog(item['F_ProductId']),
                    icon: const Icon(Icons.edit_location_alt),
                    label: const Text('เปลี่ยนสถานที่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1F2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
      child: Builder(
        builder:
            (context) => Scaffold(
              backgroundColor: const Color(0xFFF8F0FF),
              appBar: AppBar(
                backgroundColor: const Color(0xFF1B1F2B),
                foregroundColor: Colors.white,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                title: const Text(
                  'เปลี่ยนสถานที่',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'รีเฟรชข้อมูล',
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('scannedProducts');
                      setState(() {
                        _resultList.clear();
                      });
                    },
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
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onSubmitted: (_) => _scanProduct(),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'กรอก/สแกน ProductID',
                                hintStyle: const TextStyle(fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1F2B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              size: 20,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: _scanProduct,
                            tooltip: 'สแกน / ค้นหา',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoading) const CircularProgressIndicator(),
                    _buildResultList(),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
