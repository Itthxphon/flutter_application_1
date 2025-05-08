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

  @override
  void initState() {
    super.initState();
    _orders = ApiService.getOrders();
    _orders.then((data) {
      setState(() {
        allOrders = data;
        filteredOrders = data;
      });
    });
  }

  void _filterOrders(String query) {
    setState(() {
      searchText = query;
      filteredOrders =
          allOrders.where((order) {
            final orderNo =
                (order['F_SaleOrderNo'] ?? '').toString().toLowerCase();
            final customer =
                (order['F_CustomerName'] ?? '').toString().toLowerCase();
            return orderNo.contains(query.toLowerCase()) ||
                customer.contains(query.toLowerCase());
          }).toList();
    });
  }

  void _navigateToPickingList(String saleOrderNo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickingListScreen(orderNo: saleOrderNo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('คำสั่งขาย'),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _filterOrders,
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้าหรือคำอธิบาย',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderNo = order['F_SaleOrderNo'] ?? '-';
                    final customer = order['F_CustomerName'] ?? '-';
                    final date =
                        (order['F_Date'] ?? '').toString().split('T').first;
                    final sendDate =
                        (order['F_SendDate'] ?? '').toString().split('T').first;
                    final checkStatus = order['F_CheckSNStatus'];
                    final isChecked = checkStatus == 1 || checkStatus == '1';

                    return GestureDetector(
                      onTap: () => _navigateToPickingList(orderNo),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เลขที่คำสั่งขาย: $orderNo',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('วันที่: $date'),
                            Text('ชื่อลูกค้า: $customer'),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'วันที่จัดส่ง',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(sendDate),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isChecked
                                        ? Colors.green.withOpacity(0.1)
                                        : const Color(
                                          0xFFFFC1C1,
                                        ).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isChecked
                                    ? '✅ ตรวจสอบ SN ครบแล้ว'
                                    : '⏳ รอตรวจสอบ SN',
                                style: TextStyle(
                                  color: isChecked ? Colors.green : Colors.red,
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
}
