import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'ScanProductIdScreen.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchProductScreen extends StatefulWidget {
  const SearchProductScreen({super.key});

  @override
  State<SearchProductScreen> createState() => _SearchProductScreenState();
}

class _SearchProductScreenState extends State<SearchProductScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _employeeId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _employeeId = prefs.getString('employeeId') ?? 'UNKNOWN';
    });
  }

  void _onSearchChanged(String keyword) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (keyword.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _results = []);
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final data = await ApiService.searchProductChangeLocation(
          keyword.trim(),
        );
        if (!mounted) return;
        setState(() {
          _results = data.cast<Map<String, dynamic>>();
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _results = []);
      } finally {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _confirmLocation(String productId, String newLocation) async {
    try {
      await ApiService.changeLocation(
        productId: productId,
        newLocation: newLocation,
        employeeId: _employeeId ?? 'UNKNOWN',
      );
      setState(() {
        final index = _results.indexWhere(
          (item) => item['F_ProductId'] == productId,
        );
        if (index != -1) {
          _results[index]['F_Location'] = newLocation;
        }
      });
      _showAlertDialog(
        '✅ สำเร็จ',
        'เปลี่ยนสถานที่เรียบร้อยแล้ว',
        autoClose: true,
      );
    } catch (_) {
      _showAlertDialog('❌ ผิดพลาด', 'ไม่สามารถเปลี่ยนสถานที่ได้');
    }
  }

  void _showChangeLocationDialog(String productId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return BarcodeKeyboardListener(
          onBarcodeScanned: (barcode) {
            Navigator.pop(context);
            _confirmLocation(productId, barcode);
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('เปลี่ยนสถานที่'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'กรอกหรือสแกนสถานที่ใหม่',
              ),
              onSubmitted: (value) {
                Navigator.pop(context);
                _confirmLocation(productId, value.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmLocation(productId, controller.text.trim());
                },
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAlertDialog(
    String title,
    String message, {
    bool autoClose = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(title), content: Text(message)),
    );
    if (autoClose) {
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
  }

  void _selectProduct(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scannedProducts', jsonEncode([product]));

    if (mounted) {
      Navigator.pop(context); // ✅ ใช้แบบนี้พอ
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeKeyboardListener(
      bufferDuration: const Duration(milliseconds: 200),
      onBarcodeScanned: (barcode) => _onSearchChanged(barcode),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B1F2B),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('เปลี่ยนสถานที่'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
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
                        decoration: InputDecoration(
                          hintText: 'ค้นหาชื่อสินค้า หรือสแกน ProductID',
                          hintStyle: const TextStyle(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(
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
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _onSearchChanged(_controller.text),
                      tooltip: 'ค้นหา',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const CircularProgressIndicator()
              else if (_results.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    'ไม่พบข้อมูล',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _results.take(100).length, // ✅ จำกัดผลลัพธ์
                    itemBuilder: (_, index) {
                      final item = _results.take(100).toList()[index];
                      final imagePath = item['imagePath']?.toString() ?? '';

                      return GestureDetector(
                        onTap: () => _selectProduct(item),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  width: 90,
                                  height: 60,
                                  child:
                                      imagePath.isNotEmpty
                                          ? CachedNetworkImage(
                                            imageUrl: imagePath,
                                            fit: BoxFit.cover,
                                            placeholder:
                                                (context, url) => const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Image.asset(
                                                      'assets/images/pp.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                          )
                                          : Image.asset(
                                            'assets/images/products.png',
                                            fit: BoxFit.cover,
                                          ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item['F_ProductId'] ?? '-'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    AutoSizeText(
                                      item['F_ProductName'] ?? '-',
                                      style: const TextStyle(fontSize: 11),
                                      maxLines: 2,
                                      minFontSize: 9,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'จำนวน',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                AutoSizeText(
                                                  '${NumberFormat('#,###').format(item['F_StockBalance'] ?? 0)} ${item['F_UnitName'] ?? ''}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                  maxLines: 1,
                                                  minFontSize: 8,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Location',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                AutoSizeText(
                                                  item['F_Location'] ?? '-',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1B1F2B),
                                                  ),
                                                  maxLines: 1,
                                                  minFontSize: 8,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
