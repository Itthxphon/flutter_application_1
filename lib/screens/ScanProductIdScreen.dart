import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import '../services/api_service.dart';
import 'package:flutter_application_1/widgets/navigation.dart';
import 'package:flutter_application_1/screens/login_screen.dart';

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
  bool _shouldShowAlertInThisScreen = true; // ✅ เพิ่มตรงนี้

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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยันการออกจากระบบ'),
            content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // ปิด dialog ก่อน

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear(); // ล้างข้อมูลทั้งหมดอย่างแน่นอน

                  if (!mounted) return;

                  // รอให้ async จบแล้วค่อยเปลี่ยนหน้าแบบไม่ย้อนกลับ
                  Future.microtask(() {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ตกลง'),
              ),
            ],
          ),
    );
  }

  void _showAlertOnlyInThisScreen({
    required String title,
    required String message,
  }) {
    final isInScanProductIdScreen =
        ModalRoute.of(context)?.settings.name == '/change-location';

    if (isInScanProductIdScreen && mounted) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text(title),
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
  }

  Future<void> _saveScannedList() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_resultList);
    await prefs.setString('scannedProducts', encoded);
  }

  Future<void> _scanProduct([String? manualId]) async {
    if (_isInDialogMode) return;

    final productId = manualId?.trim() ?? _controller.text.trim();
    if (productId.isEmpty) return;

    final alreadyScanned = _resultList.any(
      (item) => item['F_ProductId'] == productId,
    );
    if (alreadyScanned) {
      _showAlertOnlyInThisScreen(
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
      } else {
        if (_resultList.isEmpty) {
          _showAlertOnlyInThisScreen(
            title: '⚠️ ไม่พบสินค้า',
            message: 'ไม่พบข้อมูลสินค้าสำหรับรหัส: $productId',
          );
        }
      }
    } catch (_) {
      if (!_isInDialogMode) {
        _showAlertOnlyInThisScreen(
          title: '⚠️ เกิดข้อผิดพลาด',
          message: 'ไม่พบข้อมูลสินค้า',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _controller.clear();
      });
    }
  }

  Future<void> _clearScans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scannedProducts');
    setState(() => _resultList.clear());
  }

  void _showAlertDialog({required String title, required String message}) {
    showDialog(
      context: context,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
    );
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
                    'เปลี่ยน Location',
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
                    hintText: 'กรอก/สแกน Location ใหม่',
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
          message: result['message'] ?? 'เปลี่ยน Location สำเร็จ',
        );
      }
    } catch (_) {
      if (mounted) {
        _showAlertDialog(
          title: '⚠️แจ้งเตือน',
          message: 'เกิดข้อผิดพลาดในการเปลี่ยน Location',
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
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
          automaticallyImplyLeading: false, // ❌ ไม่มีปุ่ม back
          centerTitle: true,
          title: const Text(
            'เปลี่ยนสถานที่',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('ยืนยันการลบ'),
                      content: const Text(
                        'คุณต้องการลบสินค้าที่สแกนทั้งหมดหรือไม่?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('ยกเลิก'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearScans();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('ตกลง'),
                        ),
                      ],
                    ),
              );
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'ล้างรายการทั้งหมด',
          ),
          actions: [
            IconButton(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
              tooltip: 'ออกจากระบบ',
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

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            }
          },
          backgroundColor: const Color(0xFF1B1F2B),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          iconSize: 22,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'เช็ค SN',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_location_alt),
              label: 'เปลี่ยนสถานที่',
            ),
          ],
        ),
      ),
    );
  }
}
