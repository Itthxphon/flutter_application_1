import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
  int pendingCount = 0;
  String? selectedColor;

  Future<void> _fetchWprData() async {
    try {
      final data = await ApiService.getWprHead(); // ← ✅ เพิ่มบรรทัดนี้

      final filtered =
          data
              .where(
                (e) =>
                    e['F_WdProcessReqNo'] != null &&
                    (selectedColor == null || e['color'] == selectedColor),
              )
              .toList();

      filtered.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['F_SendDate'] ?? '') ?? DateTime(1900);
        final bDate =
            DateTime.tryParse(b['F_SendDate'] ?? '') ?? DateTime(1900);
        return aDate.compareTo(bDate);
      });
      final pending = filtered.where((e) => e['F_IsChecked'] != 1).length;

      if (!mounted) return;
      setState(() {
        wprData = filtered;
        pendingCount = pending;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> get filteredWpr =>
      _searchText.isEmpty
          ? wprData
          : wprData.where((item) {
            final search = _searchText.toLowerCase();
            return (item['F_WdProcessReqNo'] ?? '').toLowerCase().contains(
                  search,
                ) ||
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
      MaterialPageRoute(builder: (context) => WPRDetailScreen(reqNo: reqNo)),
    ).then((_) => _fetchWprData());
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
                      _fetchWprData();
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

  String _formatDateTime(String? raw) {
    if (raw == null) return '-';
    try {
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(raw));
    } catch (e) {
      return '-';
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (e) {
      return '-';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1F2B),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const AutoSizeText(
          '[WPR] ใบขอเบิก สินค้าเพื่อผลิต',
          maxLines: 1,
          minFontSize: 12,
          maxFontSize: 22,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold),
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

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
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
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredWpr.isEmpty
                    ? const Center(child: Text('ไม่พบข้อมูลรายการขอเบิก'))
                    : RefreshIndicator(
                      onRefresh: _fetchWprData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredWpr.length,
                        itemBuilder: (context, index) {
                          final item = filteredWpr[index];
                          final reqNo = item['F_WdProcessReqNo'] ?? '';
                          final rawDocDate = item['F_DocDate'];
                          final rawSendDate = item['F_SendDate'];
                          final docDate = _formatDateTime(rawDocDate);
                          final sendDate = _formatDate(rawSendDate);
                          final soNo = item['F_SaleOrderNo'] ?? '';
                          final customerID = item['F_CustomerId'] ?? '';
                          final prefix = item['F_Prefix'] ?? '';
                          final company = item['F_CompanyName'] ?? '';
                          final soQtyRaw = item['F_QtySo'] ?? 0;
                          final soQty = NumberFormat('#,###').format(soQtyRaw);
                          final saleID = item['F_SalemanId'] ?? '';
                          final saleName = item['F_SalemanName'] ?? '';

                          return GestureDetector(
                            onTap: () => _pushWprID(reqNo),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(
                                    width: 5,
                                    color: _mapColor(item['color']),
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
                                        'เลขใบขอเบิก : $reqNo',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '$sendDate',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _mapColor(item['color']),
                                        ),
                                      ),
                                    ],
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
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoBox(
                                          'SO',
                                          soNo,
                                          Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildInfoBox(
                                          'จำนวน',
                                          soQty.toString(),
                                          Colors.green,
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
