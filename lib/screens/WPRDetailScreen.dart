import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class WPRDetailScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final String reqNo;

  const WPRDetailScreen({super.key, this.scaffoldKey, required this.reqNo});

  @override
  State<WPRDetailScreen> createState() => _WPRDetailScreenState();
}

class _WPRDetailScreenState extends State<WPRDetailScreen> {
  List<dynamic> detailList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWprDetail();
  }

  Future<void> fetchWprDetail() async {
    try {
      final data = await ApiService.getWprDetail(widget.reqNo);
      setState(() {
        detailList = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  String formatDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        centerTitle: true,
        foregroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'เลขที่ขอเบิก ${widget.reqNo}',
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : detailList.isEmpty
                ? const Center(child: Text('ไม่พบข้อมูลรายการขอเบิก'))
                : RefreshIndicator(
              onRefresh: fetchWprDetail,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: detailList.length,
                itemBuilder: (context, index) {
                  final item = detailList[index];
                  final productId = item['F_ProductId'] ?? '';
                  final description = item['F_Desciption'] ?? '';
                  final qtyRaw = item['F_Qty'] ?? 0;
                  final unit = item['F_UnitName'] ?? '';
                  final remark = item['F_Remark'] ?? '-';
                  final location = item['F_Location'] ?? '-';
                  final qty = NumberFormat('#,###').format(qtyRaw);

                  return Container(
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
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('รหัสสินค้า $productId',
                        style: TextStyle(
                          fontWeight: FontWeight.bold
                        ),),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                            children: [
                              const TextSpan(
                                text: 'ชื่อสินค้า : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: description,
                                style: const TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'จำนวน : $qty $unit',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),Text(
                          'ตำแหน่ง : $location',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                            children: [
                              const TextSpan(
                                text: 'หมายเหตุ : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: remark,
                                style: const TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        // Text('จำนวน : $qty $unit'),
                        // Text('ตำแหน่ง : $location'),
                        // Text('หมายเหตุ : $remark'),
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
