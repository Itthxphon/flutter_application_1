import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'picking_list.dart';

class SaleOrdersScreen extends StatefulWidget {
  final String? colorFilter;
  final void Function(int)? onPendingCountChanged;

  const SaleOrdersScreen({
    super.key,
    this.colorFilter,
    this.onPendingCountChanged,
  });

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
  void didUpdateWidget(covariant SaleOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.colorFilter != widget.colorFilter) {
      selectedColor = widget.colorFilter;
      _fetchOrders(); // โหลดใหม่เมื่อ filter เปลี่ยน
    }
  }

  @override
  void initState() {
    super.initState();
    selectedColor = widget.colorFilter;
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

      widget.onPendingCountChanged?.call(pending);
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
    final filter = selectedColor;
    setState(() {
      if (searchText.isEmpty) {
        filteredOrders =
            filter == null
                ? allOrders
                : allOrders.where((order) => order['color'] == filter).toList();
      } else {
        filteredOrders =
            allOrders.where((order) {
              final orderNo =
                  (order['F_SaleOrderNo'] ?? '').toString().toLowerCase();
              final customer =
                  (order['F_CustomerName'] ?? '').toString().toLowerCase();
              final colorMatch = filter == null || order['color'] == filter;
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorChip(null, 'ทั้งหมด'),
              _buildColorChip('red', 'แดง'),
              _buildColorChip('yellow', 'เหลือง'),
              _buildColorChip('pink', 'ชมพู'),
              _buildColorChip('blue', 'น้ำเงิน'),
              _buildColorChip('purple', 'ม่วง'),
              _buildColorChip('lightsky', 'ฟ้า'),
              _buildColorChip('brown', 'น้ำตาล'),
              _buildColorChip('lightgreen', 'เขียวอ่อน'),
              _buildColorChip('green', 'เขียว'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorChip(String? colorCode, String label) {
    final isSelected = selectedColor == colorCode;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          selectedColor = colorCode;
        });
        _fetchOrders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (colorCode != null)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _mapColor(colorCode),
                  shape: BoxShape.circle,
                ),
              ),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Column(
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3), // เงาด้านล่าง
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: const Offset(0, -2), // เงาด้านบน
                                  ),
                                ],
                                border: Border(
                                  left: BorderSide(
                                    width: 5,
                                    color: _mapColor(color),
                                  ),
                                ),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isChecked
                                              ? Colors.green.withOpacity(0.1)
                                              : const Color(
                                                0xFFFFC1C1,
                                              ).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      isChecked
                                          ? '✅ ตรวจสอบ SN ครบแล้ว'
                                          : '⏳ รอตรวจสอบ SN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isChecked
                                                ? Colors.green
                                                : const Color.fromARGB(
                                                  255,
                                                  243,
                                                  78,
                                                  66,
                                                ),
                                        fontWeight: FontWeight.bold,
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
          ),
        ],
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
