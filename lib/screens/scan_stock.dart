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
      scannedSNs = filtered.reversed.toList(); // SN ล่าสุดอยู่บนสุด
    });
  }

  Future<void> _submitSN() async {
    final sn = _snController.text.trim();
    if (sn.isEmpty) return;

    if (scannedSNs.contains(sn)) {
      _showAlert('⚠️ SN ซ้ำ', 'SN นี้ถูกสแกนไปแล้ว');
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

    if (result['success'] == true) {
      setState(() {
        scannedSNs.insert(0, sn); // เพิ่มบนสุด
        _snController.clear();
      });
    } else {
      _showAlert('❌ ผิดพลาด', result['message'] ?? 'ไม่สามารถสแกนได้');
    }
  }

  Future<void> _deleteSN(String sn) async {
    setState(() => isLoading = true);

    final result = await ApiService.deleteScannedSN(
      saleOrderNo: widget.saleOrderNo,
      productId: widget.productId,
      index: widget.index,
      productSN: sn,
    );

    if (result['success'] == true) {
      await _loadScannedSNs(); // โหลดจากฐานข้อมูลจริง
      _showAlert('✅ ลบสำเร็จ', 'ลบ SN เรียบร้อยแล้ว');
    } else {
      _showAlert('❌ ผิดพลาด', result['message'] ?? 'ไม่สามารถลบได้');
    }

    setState(() => isLoading = false);
  }

  void _confirmDeleteSN(String sn) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('⚠️ ยืนยันการลบ'),
            content: Text('คุณต้องการลบ SN นี้หรือไม่?\n\n$sn'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('กลับ'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteSN(sn);
                },
                child: const Text('ลบ', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
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
    final isComplete = remaining <= 0;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('รายการสินค้า'),
            centerTitle: true,
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(scanned, remaining, isComplete),
                const SizedBox(height: 16),
                if (!isComplete) _buildSNInput(),
                const SizedBox(height: 16),
                Expanded(child: _buildScannedList()),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildInfoCard(int scanned, int remaining, bool isComplete) {
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
            'รหัสสินค้า : ${widget.productId}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('จำนวน : ${widget.qty}'),
          Text('สแกนแล้ว : $scanned'),
          Text('ยังไม่ได้สแกน : $remaining'),
          const SizedBox(height: 8),
          isComplete
              ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBF2),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_box, color: Color(0xFF00C853), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'สแกนครบแล้ว',
                      style: TextStyle(color: Color(0xFF4A148C), fontSize: 14),
                    ),
                  ],
                ),
              )
              : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 248, 235, 236),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '⌛ รอสแกน SN',
                  style: TextStyle(
                    color: Color.fromARGB(255, 238, 86, 75),
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _buildScannedList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SN ที่สแกนแล้ว:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              scannedSNs.isEmpty
                  ? const Center(child: Text('ไม่มีรายการที่สแกน'))
                  : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      itemCount: scannedSNs.length,
                      itemBuilder: (context, index) {
                        final sn = scannedSNs[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[50],
                                ),
                                child: Text(sn),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteSN(sn),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}
