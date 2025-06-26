import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
      if (mounted) {
        setState(() {
          detailList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black,
      builder: (context) {
        return Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 5,
              child: SizedBox.expand(
                child:
                    imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/images/pp.png',
                                fit: BoxFit.contain,
                              ),
                        )
                        : Image.asset(
                          'assets/images/pp.png',
                          fit: BoxFit.contain,
                        ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
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
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        centerTitle: true,
        foregroundColor: Colors.white,
        title: AutoSizeText(
          'เลขที่ขอเบิก ${widget.reqNo}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          minFontSize: 14, // ตัวเล็กสุด
          maxFontSize: 22, // ตัวใหญ่สุด
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : detailList.isEmpty
                    ? const Center(child: Text('ไม่พบข้อมูลรายการขอเบิก'))
                    : RefreshIndicator(
                      onRefresh: fetchWprDetail,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
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
                          final imagePath = item['imagePath'] ?? '';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
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
                                Text(
                                  'รหัสสินค้า $productId',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'ชื่อสินค้า : ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: description,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Row(
                                //   children: [
                                //     Text(
                                //       'จำนวน : ',
                                //       style: const TextStyle(
                                //         fontSize: 13,
                                //         fontWeight: FontWeight.bold,
                                //       ),
                                //     ),
                                //     Container(
                                //       alignment: Alignment.center,
                                //       width: 60,
                                //       height: 20,
                                //       color: Colors.black,
                                //       margin: EdgeInsets.only(left: 10),
                                //       child: Text(
                                //         qty,
                                //         style: const TextStyle(
                                //           fontSize: 13,
                                //           color: Colors.yellow,
                                //           fontWeight: FontWeight.bold,
                                //         ),
                                //       ),
                                //     ),
                                //     Text(
                                //       '  $unit',
                                //       style: const TextStyle(
                                //         fontSize: 13,
                                //         fontWeight: FontWeight.bold,
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                // Text(
                                //   'จำนวน : $qty $unit',
                                //   style: const TextStyle(
                                //     fontWeight: FontWeight.bold,
                                //   ),
                                // ),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'หมายเหตุ : ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: remark,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Flexible(
                                      fit: FlexFit.tight,
                                      child: _buildInfoBox(
                                        'Location',
                                        location,
                                        Color(0xFF00008B),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      fit: FlexFit.tight,
                                      child: _buildInfoBox(
                                        'จำนวน',
                                        '$qty $unit',
                                        Colors.green,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap:
                                      () => _showFullScreenImage(
                                        context,
                                        imagePath,
                                      ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(
                                        minHeight: 150,
                                        maxHeight: 250,
                                      ),
                                      color: Colors.grey[100],
                                      child:
                                          imagePath.isNotEmpty &&
                                                  imagePath.startsWith('http')
                                              ? CachedNetworkImage(
                                                imageUrl: imagePath,
                                                fit: BoxFit.contain,
                                                placeholder:
                                                    (
                                                      context,
                                                      url,
                                                    ) => const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Image.asset(
                                                      'assets/images/pp.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                              )
                                              : Image.asset(
                                                'assets/images/pp.png',
                                                fit: BoxFit.contain,
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
