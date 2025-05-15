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

  Widget _buildInfoBox(String title, String value, Color numberColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), // ✅ สีพื้น: เทาอ่อนมินิมอล
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: numberColor, // ✅ สีตัวเลขตามสถานะ
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('สินค้าในใบสั่ง ${widget.orderNo}'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหารหัสสินค้า หรือชื่อสินค้า',
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
                        final imagePath = item['imagePath'] ?? '';

                        return GestureDetector(
                          onTap: () => _navigateToScanScreen(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10), // ปรับลด padding
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 3),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            imagePath,
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Image.asset(
                                                'assets/images/no_image.png',
                                                height: 100,
                                                width: 100,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$productId - $description',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '📍 สถานที่: ${item['F_Location'] ?? "-"}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _buildInfoBox(
                                                    'จำนวนเบิก',
                                                    qty.toString(),
                                                    Colors.yellow.shade100,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _buildInfoBox(
                                                    'ยิง SN แล้ว',
                                                    scanned.toString(),
                                                    Colors.green.shade100,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _buildInfoBox(
                                                    'ยังไม่ได้ยิง',
                                                    remaining.toString(),
                                                    Colors.red.shade100,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'สถานะ: ',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          isComplete
                                              ? '✅ ตรวจครบแล้ว'
                                              : '⌛ รอสแกน',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                isComplete
                                                    ? Colors.green
                                                    : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => _navigateToScanScreen(item),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        backgroundColor:
                                            isComplete
                                                ? Colors.grey[200]
                                                : (isSelected
                                                    ? Colors.green[100]
                                                    : Colors.white),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.black12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isComplete
                                            ? '✅ ครบแล้ว'
                                            : (isSelected
                                                ? '✅ กำลังสแกน'
                                                : 'เลือกสแกน'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
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
