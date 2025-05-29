import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems(); // เรียกหลัง build เสร็จ
    });
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
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
      _isLoading = false;
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
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
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

  Widget _buildInfoBox(String title, String value, Color numberColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              color: numberColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        centerTitle: true,
        foregroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'เลขที่ใบสั่ง ${widget.orderNo}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
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
            child: RefreshIndicator(
              onRefresh: _loadItems,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredItems.isEmpty
                      ? const Center(child: Text('ไม่พบข้อมูลในใบสั่ง'))
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.network(
                                              imagePath,
                                              height: 90,
                                              width: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stack,
                                              ) {
                                                return Image.asset(
                                                  'assets/images/no_image.png',
                                                  height: 90,
                                                  width: 90,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          Container(
                                            width:
                                                90, // 👈 กำหนดให้ไม่เกิน 90px ของรูป
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                              horizontal: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Stock',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.black87,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  '${item['F_StockBalance'] ?? '-'}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(
                                                      0xFF006400,
                                                    ), // เขียวเข้ม
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$productId - $description',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'สถานที่ : ${item['F_Location'] ?? "-"}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildInfoBox(
                                                    'จำนวนเบิก',
                                                    qty.toString(),
                                                    const Color(0xFFFFA500),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: _buildInfoBox(
                                                    'ยิง SN แล้ว',
                                                    scanned.toString(),
                                                    const Color(0xFF3CB043),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: _buildInfoBox(
                                                    'ยังไม่ได้ยิง',
                                                    remaining.toString(),
                                                    const Color(0xFFFF0000),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'สถานะ : ',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    Text(
                                                      isComplete
                                                          ? '✅ ตรวจครบแล้ว'
                                                          : '⌛ รอสแกน',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            isComplete
                                                                ? Colors.green
                                                                : Colors.orange,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: 90,
                                                  height: 30,
                                                  child: TextButton(
                                                    onPressed:
                                                        () =>
                                                            _navigateToScanScreen(
                                                              item,
                                                            ),
                                                    style: TextButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      backgroundColor:
                                                          isComplete
                                                              ? Colors.white
                                                              : (isSelected
                                                                  ? Colors
                                                                      .green[100]
                                                                  : Colors
                                                                      .white),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                        side: const BorderSide(
                                                          color: Colors.black12,
                                                        ),
                                                      ),
                                                    ),
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        isComplete
                                                            ? '✅ สแกนครบแล้ว'
                                                            : (isSelected
                                                                ? '✅ กำลังสแกน'
                                                                : 'เลือกสแกน'),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      ),
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
