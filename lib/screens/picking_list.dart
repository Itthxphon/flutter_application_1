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

  void _navigateToScanScreen(Map<String, dynamic> item) {
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
        'F_Location': item['F_Location'] ?? '',
      },
    ).then((_) => _loadItems());
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
                    ? const Center(child: Text('ไม่พบข้อมูลในใบสั่ง'))
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
                        final isComplete = remaining <= 0;

                        return GestureDetector(
                          onTap: () => _navigateToScanScreen(item),
                          child: Container(
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
                                const SizedBox(height: 14),
                                Text('จำนวนที่ต้องสแกน : $qty'),
                                const SizedBox(height: 4),
                                Text('แสกน SN แล้ว : $scanned'),
                                const SizedBox(height: 4),
                                Text('ยังไม่ได้สแกน : $remaining'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('สถานะ :  '),
                                    Text(
                                      isComplete ? '✅ ตรวจครบแล้ว' : '⌛ รอสแกน',
                                      style: TextStyle(
                                        color:
                                            isComplete
                                                ? Colors.green
                                                : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed:
                                        () => _navigateToScanScreen(item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isComplete
                                              ? Colors.grey
                                              : (isSelected
                                                  ? Colors.green
                                                  : const Color(0xFF1A1A2E)),
                                    ),
                                    child: Text(
                                      isComplete
                                          ? '✅ แสกนครบแล้ว'
                                          : (isSelected
                                              ? '✅ กำลังสแกน...'
                                              : 'เลือกสแกน'),
                                    ),
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
    );
  }
}
