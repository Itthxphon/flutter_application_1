import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import 'WPRDetailScreen.dart';

class WPRHeadScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const WPRHeadScreen({super.key, this.scaffoldKey});

  @override
  State<WPRHeadScreen> createState() => _WPRHeadScreenState();
}

class _WPRHeadScreenState extends State<WPRHeadScreen> {
  List<dynamic> wprData = [];
  bool _isLoading = true;
  String _searchText = '';
  String docDate = '-';
  String sendDate = '-';

  Future<void> _fetchWprData() async {
    try {
      final data = await ApiService.getWprHead();
      setState(() {
        wprData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> get filteredWpr => _searchText.isEmpty
      ? wprData
      : wprData.where((item) {
    final search = _searchText.toLowerCase();
    return (item['F_WdProcessReqNo'] ?? '').toLowerCase().contains(search) ||
        (item['F_CompanyName'] ?? '').toLowerCase().contains(search);
  }).toList();

  @override
  void initState() {
    super.initState();
    _fetchWprData();
  }

  void _pushWprID(String reqNo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WPRDetailScreen(reqNo: reqNo),
      ),
    ).then((_) => _fetchWprData());
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
            'รายการขอเบิกเพื่อผลิต',
            style: TextStyle(
              fontSize: 20, // 🔽 ขนาดพอดีกับ AppBar
              fontWeight: FontWeight.normal, // ✅ ตัวบาง
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) => setState(() => _searchText = val),
              decoration: InputDecoration(
                hintText: 'ค้นหาเลขเบิก หรือชื่อบริษัท',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredWpr.isEmpty
                ? const Center(child: Text('ไม่พบข้อมูลรายการขอเบิก'))
                : RefreshIndicator(
              onRefresh: _fetchWprData,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredWpr.length,
                itemBuilder: (context, index) {
                  final item = filteredWpr[index];
                  final reqNo = item['F_WdProcessReqNo'] ?? '';
                  final rawDocDate = item['F_DocDate'] ?? '';
                  final rawSendDate = item['F_SendDate'] ?? '';
                  final soNo = item['F_SaleOrderNo'] ?? '';
                  final customerID = item['F_CustomerId'] ?? '';
                  final prefix = item['F_Prefix'] ?? '';
                  final company = item['F_CompanyName'] ?? '';
                  final soQtyRaw = item['F_QtySo'] ?? 0;
                  final soQty = NumberFormat('#,###').format(soQtyRaw);
                  final saleID = item['F_SalemanId'] ?? '';
                  final saleName = item['F_SalemanName'] ?? '';


                  if (rawDocDate != null) {
                    try {
                      final parsed = DateTime.parse(rawDocDate);
                      docDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(parsed);
                    } catch (e) {
                      print('Error parsing date: $e');
                    }
                  }
                  if (rawSendDate != null) {
                    try {
                      final parsed = DateTime.parse(rawDocDate);
                      sendDate = DateFormat('dd/MM/yyyy').format(parsed);
                    } catch (e) {
                      print('Error parsing date: $e');
                    }
                  }
                  return GestureDetector(
                    onTap: () => _pushWprID(item['F_WdProcessReqNo']),
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
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เลขใบขอเบิก : $reqNo',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'วันที่ออกเอกสาร : $docDate',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Row(
                            children: [
                              Text(
                                'ผู้ออกเอกสาร : $saleID : ',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$saleName',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            'รหัสลูกค้า : $customerID',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            'ชื่อลูกค้า : $prefix $company',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            'วันที่ต้องการ : $sendDate',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Row(
                            children: [
                              Text(
                                'SO : $soNo',
                                style: const TextStyle(fontSize: 13,fontWeight: FontWeight.bold),
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: 60,
                                height: 20,
                                color: Colors.black,
                                margin:  EdgeInsets.only(left: 10),
                                child: Text(
                                  soQty,
                                  style: const TextStyle(fontSize: 13,color: Colors.yellow),
                                ),
                              ),
                            ],
                          ),
                          // Text(
                          //   'จำนวนที่เบิก : $qty',
                          //   style: const TextStyle(fontSize: 13),
                          // ),
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