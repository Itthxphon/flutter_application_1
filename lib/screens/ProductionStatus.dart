import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductionStatusScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ProductionStatusScreen({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  State<ProductionStatusScreen> createState() => _ProductionStatusScreenState();
}

class _ProductionStatusScreenState extends State<ProductionStatusScreen> {
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _barcodeController.clear();
      });
      final results = await ApiService.getProcessOrderDetail('ALL');
      final casted = results.cast<Map<String, dynamic>>();
      setState(() {
        _allData = casted;
        _filteredData = casted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
            // ปุ่มกากบาทขวาบนสุดแบบ LINE
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

  Future<void> _loadByProcessOrderId(String id) async {
    try {
      setState(() => _isLoading = true);
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
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      default:
        return const Color(0xFF00008B); // fallback สีเดิม
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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),

          const SizedBox(height: 2),

          Text(
            item['F_ProductName'] ?? '-',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 1),

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
                  style: TextStyle(
                    color: stationColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: () {
              _showFullScreenImage(context, imagePath);
            },
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
                    (imagePath.isNotEmpty && imagePath.startsWith('http'))
                        ? CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.contain, // <- ปรับให้ไม่ crop
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

  Widget _buildQtyBox(String label, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              '${NumberFormat('#,###').format(value ?? 0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
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
            tooltip: 'ล้างข้อมูล',
            onPressed: () {
              FocusScope.of(context).unfocus();
              _barcodeController.clear();
              setState(() {
                _filteredData.clear();
                _isLoading = false;
              });
            },
          ),
        ],
      ),
      body: BarcodeKeyboardListener(
        bufferDuration: const Duration(milliseconds: 200),
        onBarcodeScanned: (barcode) {
          final trimmed = barcode.trim();
          if (trimmed.isNotEmpty) {
            _loadByProcessOrderId(trimmed);
            _barcodeFocusNode.unfocus();
          }
        },
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _barcodeController,
                        focusNode: _barcodeFocusNode,
                        readOnly: false,
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _loadByProcessOrderId(text.trim());
                            _barcodeFocusNode.unfocus();
                          }
                        },
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'ยิงบาร์โค้ด ProcessOrderId',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black26),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black87),
                          ),
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
                        size: 22,
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
    );
  }
}
