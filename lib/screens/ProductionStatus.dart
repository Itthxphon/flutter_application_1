import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductionStatusScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ProductionStatusScreen({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  State<ProductionStatusScreen> createState() => _ProductionStatusScreenState();
}

class _ProductionStatusScreenState extends State<ProductionStatusScreen> {
  List<Map<String, dynamic>> _filteredData = [];
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadByProcessOrderId(String id) async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('F_ProcessOrderId', id); // <-- เพิ่มตรงนี้
      final results = await ApiService.getProcessOrderDetail(id);
      final casted = results.cast<Map<String, dynamic>>();

      setState(() {
        _barcodeController.clear();
        _filteredData = casted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลคำสั่งผลิต')));
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
                      imageUrl.startsWith('http')
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

  Color _mapColor(String? color) {
    switch (color) {
      case 'red':
        return const Color(0xFFFE0000);
      case 'yellow':
        return const Color(0xFFDAA521);
      case 'pink':
        return const Color(0xFFFF00FE);
      case 'blue':
        return const Color(0xFF0100F7);
      case 'purple':
        return const Color(0xFF81007F);
      case 'lightsky':
        return const Color(0xFF87CEEA);
      case 'brown':
        return const Color(0xFFB3440B);
      case 'lightgreen':
        return const Color(0xFF90EE90);
      case 'green':
        return const Color(0xFF008001);
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'black':
        return Colors.black;

      case 'gray':
        return Colors.grey;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      default:
        return const Color(0xFF00008B);
    }
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final formatter = DateFormat('dd/MM/yyyy');
    final imagePath = item['imagePath'] ?? '';
    final sendDate =
        item['F_SendDate'] != null
            ? formatter.format(DateTime.parse(item['F_SendDate']))
            : '-';
    final color = _mapColor(item['Color']?.toString().toLowerCase() ?? '');
    final stationColor = _statusColor(item['statusColor']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        border: Border(
          left: BorderSide(color: stationColor, width: 4),
        ), // << ใช้ stationColor แทน
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ใบกำกับการผลิต',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                sendDate,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          Text(
            item['F_ProcessOrderId'] ?? '-',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            item['F_ProductName'] ?? '-',
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            'ประเภทพิมพ์ : ${item['F_Product_PrintTypeName'] ?? '-'}',
            style: const TextStyle(fontSize: 13),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เครื่อง : ${item['F_McName'] ?? '-'}',
                style: const TextStyle(fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: stationColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item['F_StationName'] ?? '-',
                  style: TextStyle(color: stationColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imagePath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 150,
                  maxHeight: 250,
                ),
                color: Colors.grey[100],
                child:
                    imagePath.isNotEmpty && imagePath.startsWith('http')
                        ? CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
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
        ],
      ),
    );
  }

  void _showAlert(
    String title,
    String message,
    IconData icon,
    Color color, {
    bool autoClose = true,
  }) {
    bool isDialogOpen = true;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true, // ✅ แตะนอกจอเพื่อปิดได้
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            OutlinedButton(
              onPressed: () {
                if (isDialogOpen && mounted && Navigator.of(context).canPop()) {
                  isDialogOpen = false;
                  Navigator.of(context).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: const BorderSide(color: Colors.deepPurple),
              ),
              child: const Text(
                'ตกลง',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );

    if (autoClose) {
      Future.delayed(const Duration(seconds: 2), () {
        if (isDialogOpen && mounted && Navigator.of(context).canPop()) {
          isDialogOpen = false;
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1F2B),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('สถานะการผลิต'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              FocusScope.of(context).unfocus();

              setState(() {
                _barcodeController.clear();
                _filteredData.clear();
                _isLoading = false;
              });

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('F_ProcessOrderId');
            },
          ),
        ],
      ),
      body: BarcodeKeyboardListener(
        bufferDuration: const Duration(milliseconds: 200),
        onBarcodeScanned: (barcode) {
          final trimmed = barcode.trim();
          if (trimmed.isNotEmpty) {
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            FocusScope.of(context).unfocus();
            _barcodeController.text = trimmed;
            _loadByProcessOrderId(trimmed);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ยิงบาร์โค้ด ProcessOrderId',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      final text = _barcodeController.text.trim();
                      if (text.isNotEmpty) {
                        _loadByProcessOrderId(text);
                        _barcodeFocusNode.unfocus();
                      }
                    },
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1F2B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredData.isEmpty
                        ? const Center(child: Text('ไม่พบข้อมูล'))
                        : ListView.builder(
                          itemCount: _filteredData.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildCard(_filteredData[index]),
                        ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('พิมพ์'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B1F2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();

              final employeeName = prefs.getString('employeeName') ?? '';
              final processOrderId = prefs.getString('F_ProcessOrderId') ?? '';

              if (processOrderId.isEmpty || employeeName.isEmpty) {
                _showAlert(
                  'ไม่พบข้อมูล',
                  'ไม่พบข้อมูล ProcessOrderId หรือชื่อพนักงาน',
                  Icons.warning_amber_rounded,
                  Colors.orange,
                );
                return;
              }

              // final printedList =
              //     prefs.getStringList('printedProcessOrders') ?? [];

              // if (printedList.contains(processOrderId)) {
              //   _showAlert(
              //     'เคยพิมพ์ไปแล้ว',
              //     'ProcessOrderId "$processOrderId"\nเคยถูกสั่งพิมพ์ไปแล้ว',
              //     Icons.info_outline,
              //     Colors.orange,
              //   );
              //   return;
              // }

              try {
                final result = await ApiService.printAndLog(
                  processOrderId,
                  employeeName,
                );

                if (result['alreadyPrinted'] == true) {
                  _showAlert(
                    'เคยพิมพ์ไปแล้ว',
                    'ProcessOrderId "$processOrderId"\nเคยถูกสั่งพิมพ์ไปแล้ว',
                    Icons.info_outline,
                    Colors.orange,
                  );
                } else {
                  _showAlert(
                    'พิมพ์สำเร็จ',
                    'พิมพ์สำเร็จสำหรับ\nProcessOrderId "$processOrderId"',
                    Icons.check_circle_outline,
                    Colors.green,
                  );
                }
              } catch (e) {
                _showAlert(
                  'เกิดข้อผิดพลาด',
                  e.toString(),
                  Icons.error_outline,
                  Colors.orange,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
