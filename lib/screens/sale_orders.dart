import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'picking_list.dart';

class SaleOrdersScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const SaleOrdersScreen({super.key, this.scaffoldKey});

  @override
  State<SaleOrdersScreen> createState() => _SaleOrdersScreenState();
}

class _SaleOrdersScreenState extends State<SaleOrdersScreen> {
  List<dynamic> allOrders = [];
  List<dynamic> filteredOrders = [];
  String searchText = '';
  bool _isLoading = true;
  int pendingCount = 0;
  String? selectedColor;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getOrders(color: selectedColor);
      final pending = data.where((o) => o['F_CheckSNStatus'] != 1).length;
      data.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['F_SendDate'] ?? '') ?? DateTime(2100);
        final dateB =
            DateTime.tryParse(b['F_SendDate'] ?? '') ?? DateTime(2100);
        return dateA.compareTo(dateB);
      });

      final filteredByColor =
          selectedColor == null
              ? data
              : data.where((o) => o['color'] == selectedColor).toList();

      setState(() {
        allOrders = filteredByColor;
        pendingCount = pending;
        _filterOrdersByColor();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  void _filterOrders(String query) {
    searchText = query;
    _filterOrdersByColor();
  }

  void _filterOrdersByColor() {
    setState(() {
      if (searchText.isEmpty) {
        filteredOrders =
            selectedColor == null
                ? allOrders
                : allOrders
                    .where((order) => order['color'] == selectedColor)
                    .toList();
      } else {
        filteredOrders =
            allOrders.where((order) {
              final orderNo =
                  (order['F_SaleOrderNo'] ?? '').toString().toLowerCase();
              final customer =
                  (order['F_CustomerName'] ?? '').toString().toLowerCase();
              final colorMatch =
                  selectedColor == null || order['color'] == selectedColor;
              final textMatch =
                  orderNo.contains(searchText.toLowerCase()) ||
                  customer.contains(searchText.toLowerCase());
              return colorMatch && textMatch;
            }).toList();
      }
    });
  }

  void _navigateToPickingList(String saleOrderNo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickingListScreen(orderNo: saleOrderNo),
      ),
    ).then((_) => _fetchOrders());
  }

  void _showColorFilterMenu() {
    final Map<String?, String> colors = {
      null: 'ทั้งหมด',
      'red': 'แดง',
      'yellow': 'เหลือง',
      'pink': 'ชมพู',
      'blue': 'น้ำเงิน',
      'purple': 'ม่วง',
      'lightsky': 'ฟ้า',
      'brown': 'น้ำตาล',
      'lightgreen': 'เขียวอ่อน',
      'green': 'เขียว',
    };

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                colors.entries.map((entry) {
                  final isSelected = selectedColor == entry.key;
                  final colorDot = _mapColor(entry.key);
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        selectedColor = entry.key;
                      });
                      _fetchOrders();
                    },
                    child: Container(
                      width: 104,
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.lightBlue
                                  : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (entry.key != null)
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: colorDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      },
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
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'เช็ค Serial Number',
            style: TextStyle(
              fontSize: 30, // 🔽 ขนาดพอดีกับ AppBar
              fontWeight: FontWeight.normal, // ✅ ตัวบาง
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, size: 28),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คุณมีงานค้างที่ยังไม่ตรวจ SN'),
                    ),
                  );
                },
              ),
              if (pendingCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      pendingCount > 99 ? '99+' : '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 28),
            onPressed: _showColorFilterMenu,
          ),
        ],
      ),
      body: Container(
        color: Colors.white, //พื้นหลัง
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
              child: TextField(
                onChanged: _filterOrders,
                decoration: InputDecoration(
                  hintText: 'ค้นหารหัสใบสั่งขาย หรือชื่อของลูกค้า',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredOrders.isEmpty
                      ? const Center(child: Text('ไม่พบข้อมูลคำสั่งขาย'))
                      : RefreshIndicator(
                        onRefresh: _fetchOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            final orderNo = order['F_SaleOrderNo'] ?? '-';
                            final customer = order['F_CustomerName'] ?? '-';
                            final sendDate =
                                (order['F_SendDate'] ?? '')
                                    .toString()
                                    .split('T')
                                    .first;
                            final checkStatus = order['F_CheckSNStatus'];
                            final isChecked =
                                checkStatus == 1 || checkStatus == '1';
                            final color = order['color'] ?? '';
                            final itemCount = order['itemCount'] ?? 0;

                            return GestureDetector(
                              onTap: () => _navigateToPickingList(orderNo),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(
                                    left: BorderSide(
                                      width: 5,
                                      color: _mapColor(color),
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$orderNo',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(sendDate),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _mapColor(color),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ชื่อลูกค้า : $customer',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    Text(
                                      'จำนวนสินค้า : $itemCount',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (order['F_CheckSNStatus'] == 1
                                                    ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                    : const Color(
                                                      0xFFFFC1C1,
                                                    ).withOpacity(0.3)),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            order['F_CheckSNStatus'] == 1
                                                ? '✅ ตรวจสอบ SN ครบแล้ว'
                                                : '⏳ รอตรวจสอบ SN',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  order['F_CheckSNStatus'] == 1
                                                      ? Colors.green
                                                      : const Color.fromARGB(
                                                        255,
                                                        243,
                                                        78,
                                                        66,
                                                      ),
                                            ),
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
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
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
}
