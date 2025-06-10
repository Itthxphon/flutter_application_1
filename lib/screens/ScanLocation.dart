import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import '../screens/sale_orders.dart';
import '../screens/ScanProductIdScreen.dart';

class ScanLocationScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ScanLocationScreen({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  State<ScanLocationScreen> createState() => _ScanLocationScreenState();
}

class _ScanLocationScreenState extends State<ScanLocationScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<dynamic> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // พับคีย์บอร์ดทันทีหลังหน้าจอถูกสร้าง
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _scanLocation(String location) async {
    if (location.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    if (!mounted) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _products.clear();
    });

    try {
      final result = await ApiService.getProductsByLocation(location);
      if (!mounted) return;

      if (result.isEmpty) {
        _showAlertDialog(
          title: '❌ ไม่พบสถานที่',
          message: 'ไม่พบ Location ที่สแกน',
          autoClose: true,
        );
      }

      if (!mounted) return; // ✅ เพิ่มเช็กอีกที
      setState(() => _products = result);
    } catch (_) {
      if (!mounted) return;
      _showAlertDialog(
        title: '❌ ไม่พบสถานที่',
        message: 'ไม่พบ Location ที่สแกน',
        autoClose: true,
      );
    } finally {
      if (!mounted) return; // ✅ เพิ่มตรงนี้อีก
      setState(() {
        _isLoading = false;
        _controller.clear();
      });
    }
  }

  void _showAlertDialog({
    required String title,
    required String message,
    bool autoClose = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    bool isDialogOpen = true;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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
              onPressed: () {
                if (isDialogOpen && mounted && Navigator.of(context).canPop()) {
                  isDialogOpen = false;
                  Navigator.of(context).pop();
                }
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );

    if (autoClose) {
      Future.delayed(duration, () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black.withOpacity(0.95),
                alignment: Alignment.center,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1,
                  maxScale: 4,
                  child:
                      (imageUrl.startsWith('http'))
                          ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            errorWidget:
                                (context, url, error) => Image.asset(
                                  'assets/images/pp.png',
                                  fit: BoxFit.contain,
                                ),
                          )
                          : Image.asset(
                            'assets/images/pp.png',
                            fit: BoxFit.contain,
                          ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final imagePath = item['imagePath']?.toString() ?? '';
    final stock = item['F_StockBalance'] ?? 0;
    final unit = item['F_UnitName'] ?? '';
    final location = item['F_Location'] ?? '-';

    return Container(
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
            child: GestureDetector(
              onTap: () => _showFullScreenImage(context, imagePath),
              child: SizedBox(
                width: 90,
                height: 60,
                child:
                    imagePath.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.cover,
                          placeholder:
                              (_, __) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (_, __, ___) => Image.asset(
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
                Text(
                  item['F_ProductName'] ?? '-',
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            const Text('จำนวน', style: TextStyle(fontSize: 10)),
                            Text(
                              '${NumberFormat('#,###').format(stock)} $unit',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Location',
                              style: TextStyle(fontSize: 10),
                            ),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00008B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1B1F2B)),
            child: Text('เมนู', style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('เช็ค Serial Number'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SaleOrdersScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_location_alt),
            title: const Text('เปลี่ยนสถานที่'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ScanProductIdScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('ตรวจ Location'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ออกจากระบบ'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeKeyboardListener(
      bufferDuration: const Duration(milliseconds: 200),
      onBarcodeScanned: (barcode) {
        if (barcode.trim().isEmpty) return;

        SystemChannels.textInput.invokeMethod('TextInput.hide'); // ✅ ปิดคีย์บอร์ดบังคับ


        FocusScope.of(context).unfocus();
        _controller.text = barcode;
        _scanLocation(barcode);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B1F2B),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('เช็คสินค้าใน Location'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _products.clear()),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _controller.text.isEmpty
                            ? 'ยิงบาร์โค้ด Location'
                            : _controller.text,
                        style: const TextStyle(fontSize: 13),
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
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {}, // ไม่ต้องทำอะไร
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_products.isEmpty)
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
                    itemCount: _products.length,
                    itemBuilder: (_, i) => _buildProductCard(_products[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
