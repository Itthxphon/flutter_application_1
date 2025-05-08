import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ScanStockScreen extends StatefulWidget {
  final String saleOrderNo;
  final String productId;
  final int index;
  final int qty;
  final String location;

  const ScanStockScreen({
    super.key,
    required this.saleOrderNo,
    required this.productId,
    required this.index,
    required this.qty,
    this.location = '',
  });

  @override
  State<ScanStockScreen> createState() => _ScanStockScreenState();
}

class _ScanStockScreenState extends State<ScanStockScreen> {
  final TextEditingController _snController = TextEditingController();
  List<String> scannedSNs = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadScannedSNs();
  }

  Future<void> _loadScannedSNs() async {
    final allSNs = await ApiService.getAllScannedSNs();
    final filtered =
        allSNs
            .where(
              (sn) =>
                  sn['F_SaleOrderNo'] == widget.saleOrderNo &&
                  sn['F_ProductId'] == widget.productId &&
                  sn['F_Index'].toString() == widget.index.toString(),
            )
            .map((e) => e['F_ProductSN'].toString())
            .toList();

    setState(() {
      scannedSNs = filtered;
    });
  }

  Future<void> _submitSN() async {
    final sn = _snController.text.trim();
    if (sn.isEmpty) return;

    if (scannedSNs.contains(sn)) {
      _showAlert('⚠️ Serial Number ซ้ำ', 'SN นี้ถูกสแกนไปแล้ว');
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.scanSN(
      saleOrderNo: widget.saleOrderNo,
      productId: widget.productId,
      index: widget.index,
      productSN: sn,
    );

    setState(() => isLoading = false);

    debugPrint(result.toString()); // ✅ เพิ่มดูค่าจาก API

    final success = result['success'].toString().toLowerCase() == 'true';

    if (success) {
      _snController.clear();
      await _loadScannedSNs();
      _showAlert('✅ สำเร็จ', result['message'] ?? 'สแกน SN สำเร็จแล้ว');
    } else {
      final message = result['message'] ?? 'ไม่สามารถสแกนได้';
      final isDuplicate = message.toString().toLowerCase().contains(
        'duplicate',
      );
      final title = isDuplicate ? '⚠️ Serial Number ซ้ำ' : '❌ ผิดพลาด';
      _showAlert(title, message);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanned = scannedSNs.length;
    final remaining = widget.qty - scanned;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text(
          'รายการสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(scanned, remaining),
            const SizedBox(height: 24),
            _buildSNInput(),
            const SizedBox(height: 12),
            _buildScannedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(int scanned, int remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รหัสสินค้า: ${widget.productId}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('จำนวน: ${widget.qty}'),
          const SizedBox(height: 8),
          Text('ยิงแล้ว: $scanned'),
          Text('ยังไม่ได้ยิง: $remaining'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '⏳ รอเช็ค SN',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSNInput() {
    return Column(
      children: [
        TextField(
          controller: _snController,
          decoration: InputDecoration(
            hintText: 'กรอกหรือสแกน Serial Number',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _submitSN(),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: isLoading ? null : _submitSN,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('สแกน / ยืนยัน SN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildScannedBox() {
    if (scannedSNs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SN ที่สแกนแล้ว:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...scannedSNs.map(
                (sn) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Text(sn),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
