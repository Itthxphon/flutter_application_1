import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

class StockDetailScreen extends StatefulWidget {
  final String orderNo;

  const StockDetailScreen({super.key, required this.orderNo});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
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
      _loadItems();
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
      item['isPicked'] = item['F_Pickup'] == 1;
    }

    if (!mounted) return;

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

  void _handlePickup(Map<String, dynamic> item) async {
    final saleOrderNo = item['F_SaleOrderNo'];
    final index = int.tryParse(item['F_Index'].toString()) ?? 0;

    if (item['isPicked'] == true) {
      // ยืนยันก่อนยกเลิกการจัดของ
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('ยืนยันการยกเลิก'),
                ],
              ),
              content: const Text(
                'ท่านต้องการยกเลิกการจัดสินค้านี้ใช่หรือไม่?',
              ),
              actions: [
                TextButton(
                  child: const Text('ยกเลิก'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                ElevatedButton(
                  child: const Text('ตกลง'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      setState(() {
        item['isPicked'] = false;
      });

      await ApiService.cancelPickupStatus(
        saleOrderNo: saleOrderNo,
        index: index,
      );

      if (!mounted) return;
      await _loadItems();
    } else {
      setState(() {
        item['isPicked'] = true;
      });

      await ApiService.updatePickupStatus(
        saleOrderNo: saleOrderNo,
        index: index,
      );
    }
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

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
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
                          final isComplete = remaining <= 0;
                          final imagePath = item['imagePath'] ?? '';

                          return Container(
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
                            child: Stack(
                              children: [
                                // ✅ เนื้อหาทั้งหมด
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // รูป + Stock
                                    Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: SizedBox(
                                            width: 90,
                                            height: 90,
                                            child:
                                                imagePath.isNotEmpty
                                                    ? Image.network(
                                                      imagePath,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        _,
                                                        __,
                                                        ___,
                                                      ) {
                                                        return Image.asset(
                                                          'assets/images/no_image.png',
                                                          fit: BoxFit.cover,
                                                        );
                                                      },
                                                    )
                                                    : Image.asset(
                                                      'assets/images/no_image.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 90,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                                  color: Color(0xFF006400),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),

                                    // ข้อมูลสินค้า
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AutoSizeText(
                                            '$productId - $description',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            minFontSize: 10,
                                            overflow: TextOverflow.visible,
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
                                                  'สถานที่',
                                                  item['F_Location']
                                                          ?.toString() ??
                                                      '-',
                                                  const Color(0xFF1E90FF),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 36,
                                          ), // เพื่อให้ไม่ชนปุ่ม
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // ✅ ปุ่มล่างขวา
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _handlePickup(item),
                                    child: Container(
                                      width: 90,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            (item['isPicked'] ?? false)
                                                ? Colors.green
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(0, -1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        (item['isPicked'] ?? false)
                                            ? '✅ จัดของแล้ว'
                                            : '📦 จัดของ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              (item['isPicked'] ?? false)
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
