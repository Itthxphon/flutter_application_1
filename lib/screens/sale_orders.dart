import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'picking_list.dart';

class SaleOrdersScreen extends StatefulWidget {
  const SaleOrdersScreen({super.key});

  @override
  State<SaleOrdersScreen> createState() => _SaleOrdersScreenState();
}

class _SaleOrdersScreenState extends State<SaleOrdersScreen> {
  late Future<List<dynamic>> _orders;
  List<dynamic> allOrders = [];
  List<dynamic> filteredOrders = [];
  String searchText = '';
  String? selectedColor;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    _orders = ApiService.getOrders(color: selectedColor);
    _orders.then((data) {
      setState(() {
        allOrders = data;
        _filterOrders(searchText);
      });
    });
  }

  void _filterOrders(String query) {
    setState(() {
      searchText = query;
      filteredOrders = allOrders.where((order) {
        final orderNo = (order['F_SaleOrderNo'] ?? '').toString().toLowerCase();
        final customer = (order['F_CustomerName'] ?? '').toString().toLowerCase();
        return orderNo.contains(query.toLowerCase()) || customer.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _navigateToPickingList(String saleOrderNo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickingListScreen(orderNo: saleOrderNo),
      ),
    ).then((_) {
      _fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: selectedColor,
              decoration: InputDecoration(
                labelText: 'กรองตามสีวันที่จัดส่ง',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: <String?>[
                null,
                'red',
                'yellow',
                'pink',
                'blue',
                'purple',
                'lightsky',
                'brown',
                'lightgreen',
                'green'
              ].map((color) => DropdownMenuItem(
                value: color,
                child: Text(color == null ? 'ทั้งหมด' : color),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedColor = value;
                  _fetchOrders();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }

                final orders = filteredOrders;

                if (orders.isEmpty) {
                  return const Center(child: Text('ไม่พบข้อมูลคำสั่งขาย'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderNo = order['F_SaleOrderNo'] ?? '-';
                    final customer = order['F_CustomerName'] ?? '-';
                    final sendDate = (order['F_SendDate'] ?? '').toString().split('T').first;
                    final checkStatus = order['F_CheckSNStatus'];
                    final isChecked = checkStatus == 1 || checkStatus == '1';
                    final color = order['color'] ?? '';

                    return GestureDetector(
                      onTap: () => _navigateToPickingList(orderNo),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
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
                            Text(
                              '$orderNo',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ชื่อลูกค้า : $customer',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'วันที่ต้องจัดส่ง',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                ),
                                Text(
                                  sendDate,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? Colors.green.withOpacity(0.1)
                                    : const Color(0xFFFFC1C1).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                isChecked ? '✅ ตรวจสอบ SN ครบแล้ว' : '⏳ รอตรวจสอบ SN',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isChecked ? Colors.green : const Color.fromARGB(255, 243, 78, 66),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _mapColor(String color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'pink':
        return Colors.pink;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'lightsky':
        return Colors.lightBlueAccent;
      case 'brown':
        return Colors.brown;
      case 'lightgreen':
        return Colors.lightGreen;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
