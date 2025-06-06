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

  Widget _buildCard(Map<String, dynamic> item) {
    final formatter = DateFormat('dd/MM/yyyy');
    final imagePath = item['imagePath'] ?? '';
    final sendDate =
        item['F_SendDate'] != null
            ? formatter.format(DateTime.parse(item['F_SendDate']))
            : '-';
    final color = _mapColor(item['color']);

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
          // ✅ หัวข้อใบกำกับการผลิต + วันที่ส่ง
          // ✅ บรรทัดแรก: หัวข้อ + วันที่
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
          // ✅ บรรทัดที่สอง: รหัสใบกำกับ
          Text(
            item['F_ProcessOrderId'] ?? '-',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),

          const SizedBox(height: 2),

          // ✅ ชื่อสินค้า
          Text(
            item['F_ProductName'] ?? '-',
            style: const TextStyle(
              fontSize: 13, // เปลี่ยนจาก 15 → 13 ให้เท่ากับประเภทพิมพ์
            ),
          ),
          const SizedBox(height: 1),

          // ✅ ประเภทพิมพ์
          Text(
            'ประเภทพิมพ์ : ${item['F_Product_PrintTypeName'] ?? '-'}',
            style: const TextStyle(fontSize: 13),
          ),

          // ✅ เครื่อง + สถานี (จัดให้อยู่บรรทัดเดียวกัน และห่างกันพอดี)
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
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item['F_StationName'] ?? '-',
                  style: const TextStyle(
                    color: Color(0xFF00008B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ), // เว้นบรรทัดล่างให้ไม่ติดกับกล่องผลิต/จริง/เสีย
          // ✅ จำนวน
          // Row(
          //   children: [
          //     _buildQtyBox('ผลิต', item['F_TotalQtyProduction'], Colors.blue),
          //     const SizedBox(width: 6),
          //     _buildQtyBox('จริง', item['F_TotalQtyReal'], Colors.green),
          //     const SizedBox(width: 6),
          //     _buildQtyBox('เสีย', item['F_TotalQtyScrap'], Colors.red),
          //   ],
          // ),

          // const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: double.infinity,
              height: 220, // 🔼 เพิ่มความสูงให้พอดีกับภาพแนวตั้ง
              child:
                  (imagePath.isNotEmpty && imagePath.startsWith('http'))
                      ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) => Image.asset(
                              'assets/images/pp.png',
                              fit: BoxFit.cover,
                            ),
                      )
                      : Image.asset('assets/images/pp.png', fit: BoxFit.cover),
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
            onPressed: _loadAllOrders,
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
        child: Padding(
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
                          hintText: 'ยิงบาร์โค้ด Location',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
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
