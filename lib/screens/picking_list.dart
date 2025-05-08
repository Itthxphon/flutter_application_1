import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PickingListScreen extends StatefulWidget {
  final String orderNo;

  const PickingListScreen({super.key, required this.orderNo});

  @override
  State<PickingListScreen> createState() => _PickingListScreenState();
}

class _PickingListScreenState extends State<PickingListScreen> {
  List<dynamic> allItems = [];
  List<dynamic> filteredItems = [];
  String selectedProductId = '';
  String selectedIndex = '';
  String searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await ApiService.getOrderDetails(widget.orderNo);
    final scanned = await ApiService.getAllScannedSNs();

    for (var item in items) {
      final count =
          scanned
              .where(
                (s) =>
                    s['F_SaleOrderNo'] == item['F_SaleOrderNo'] &&
                    s['F_ProductId'] == item['F_ProductId'] &&
                    s['F_Index'].toString() == item['F_Index'].toString(),
              )
              .length;
      item['scannedCount'] = count;
    }

    setState(() {
      allItems = items;
      filteredItems = items;
    });
  }

  void _filterItems(String keyword) {
    setState(() {
      searchKeyword = keyword;
      filteredItems =
          allItems.where((item) {
            final id = item['F_ProductId'].toString().toLowerCase();
            final desc = item['F_Desciption'].toString().toLowerCase();
            return id.contains(keyword.toLowerCase()) ||
                desc.contains(keyword.toLowerCase());
          }).toList();
    });
  }

  void _selectItemAndNavigate(Map<String, dynamic> item) {
    setState(() {
      selectedProductId = item['F_ProductId'];
      selectedIndex = item['F_Index'].toString();
    });

    Navigator.pushNamed(
      context,
      '/scan',
      arguments: {
        'F_SaleOrderNo': item['F_SaleOrderNo'],
        'F_ProductId': item['F_ProductId'],
        'F_Index': item['F_Index'],
        'F_Qty': item['F_Qty'],
      },
    ).then((_) {
      _loadItems(); // Refresh ข้อมูลหลังจากกลับมา
    });
  }

  bool _isSelected(String productId, String index) {
    return productId == selectedProductId && index == selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('สินค้าในใบสั่ง ${widget.orderNo}'),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้าหรือคำอธิบาย',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterItems,
            ),
          ),
          Expanded(
            child:
                filteredItems.isEmpty
                    ? const Center(
                      child: Text(
                        'ไม่พบข้อมูลในใบสั่ง',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final productId = item['F_ProductId'] ?? '-';
                        final description = item['F_Desciption'] ?? '-';
                        final qty = item['F_Qty'] ?? 0;
                        final scanned = item['scannedCount'] ?? 0;
                        final remaining =
                            (qty is int
                                ? qty
                                : int.tryParse(qty.toString()) ?? 0) -
                            scanned;
                        final isSelected = _isSelected(
                          productId,
                          item['F_Index'].toString(),
                        );
                        final statusText =
                            item['F_CheckSNStatus'] == 1
                                ? '✅ ตรวจครบแล้ว'
                                : '⏳ รอสแกน';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$productId - $description',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('จำนวนที่ต้องสแกน: $qty'),
                              Text('ยิง SN แล้ว: $scanned'),
                              Text('ยังไม่ได้ยิง: $remaining'),
                              Text('สถานะ: $statusText'),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => _selectItemAndNavigate(item),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isSelected
                                            ? Colors.green
                                            : const Color(0xFF1A1A2E),
                                  ),
                                  child: Text(
                                    isSelected ? '✅ กำลังสแกน...' : 'เลือกสแกน',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
