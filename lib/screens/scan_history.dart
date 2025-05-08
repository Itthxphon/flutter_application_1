import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<dynamic> allScans = [];
  List<dynamic> filteredScans = [];
  String searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadScannedData();
  }

  Future<void> _loadScannedData() async {
    final data = await ApiService.getAllScannedSNs();
    setState(() {
      allScans = data;
      filteredScans = data;
    });
  }

  void _filterScans(String keyword) {
    setState(() {
      searchKeyword = keyword;
      filteredScans =
          allScans.where((scan) {
            final sn = (scan['F_ProductSN'] ?? '').toString().toLowerCase();
            final productId =
                (scan['F_ProductId'] ?? '').toString().toLowerCase();
            final orderNo =
                (scan['F_SaleOrderNo'] ?? '').toString().toLowerCase();
            return sn.contains(keyword.toLowerCase()) ||
                productId.contains(keyword.toLowerCase()) ||
                orderNo.contains(keyword.toLowerCase());
          }).toList();
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
              decoration: InputDecoration(
                hintText: 'ค้นหา SN, รหัสสินค้า หรือคำสั่งขาย',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterScans,
            ),
          ),
          Expanded(
            child:
                filteredScans.isEmpty
                    ? const Center(child: Text('ไม่มีข้อมูลการสแกน'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredScans.length,
                      itemBuilder: (context, index) {
                        final sn = filteredScans[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. SN: ${sn['F_ProductSN']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text('รหัสสินค้า: ${sn['F_ProductId']}'),
                              Text('เลขที่คำสั่งขาย: ${sn['F_SaleOrderNo']}'),
                              Text('ลำดับ: ${sn['F_Index']}'),
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
