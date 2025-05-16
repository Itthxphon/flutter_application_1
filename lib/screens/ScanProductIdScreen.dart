import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ScanProductIdScreen extends StatefulWidget {
  const ScanProductIdScreen({Key? key}) : super(key: key);

  @override
  State<ScanProductIdScreen> createState() => _ScanProductIdScreenState();
}

class _ScanProductIdScreenState extends State<ScanProductIdScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _resultList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedScans();
  }

  Future<void> _loadSavedScans() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('scannedProducts');
    if (saved != null) {
      final decoded = jsonDecode(saved) as List<dynamic>;
      setState(() {
        _resultList.addAll(decoded.cast<Map<String, dynamic>>());
      });
    }
  }

  Future<void> _saveScannedList() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_resultList);
    await prefs.setString('scannedProducts', encoded);
  }

  Future<void> _scanProduct() async {
    final productId = _controller.text.trim();
    if (productId.isEmpty) return;

    final alreadyScanned = _resultList.any((item) => item['F_ProductId'] == productId);
    if (alreadyScanned) {
      setState(() {
        _error = 'สแกนซ้ำ: $productId';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.scanProductId(productId);
      if (data.isNotEmpty) {
        final casted = data.cast<Map<String, dynamic>>();
        setState(() {
          _resultList.addAll(casted);
        });
        await _saveScannedList();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
        _controller.clear();
      });
    }
  }

  Future<void> _clearScans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scannedProducts');
    setState(() {
      _resultList.clear();
    });
  }

  void _showChangeLocationDialog(String productId) {
    final TextEditingController _locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เปลี่ยน Location'),
        content: TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location ใหม่ (ยิง Barcode ได้)',
          ),
          autofocus: true,
          onSubmitted: (value) => _confirmLocation(productId, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => _confirmLocation(productId, _locationController.text),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  void _confirmLocation(String productId, String location) async {
    final newLocation = location.trim();
    if (newLocation.isEmpty) return;

    Navigator.pop(context);

    try {
      final result = await ApiService.changeLocation(
        productId: productId,
        newLocation: newLocation,
        employeeId: 'EMP001', // 🔁 ปรับให้ใช้จากระบบ login
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'เปลี่ยน Location สำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildResultList() {
    if (_resultList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Text('ยังไม่มีรายการที่สแกน'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _resultList.length,
      itemBuilder: (context, index) {
        final item = _resultList[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['F_ProductName'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('รหัสสินค้า: ${item['F_ProductId'] ?? '-'}'),
                Text('ยี่ห้อ: ${item['F_ProductBrandName'] ?? '-'}'),
                Text('กลุ่มสินค้า: ${item['F_ProductGroupName'] ?? '-'}'),
                Text('จำนวนคงเหลือ: ${item['F_StockBalance'] ?? '-'} ${item['F_UnitName'] ?? ''}'),
                Text('ที่เก็บ: ${item['F_Location'] ?? '-'}'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showChangeLocationDialog(item['F_ProductId']),
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text('เปลี่ยน Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0FF),
      appBar: AppBar(
        title: const Text('สแกนหลาย ProductID'),
        backgroundColor: Colors.deepPurple.shade400,
        actions: [
          IconButton(
            onPressed: _clearScans,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'ล้างรายการทั้งหมด',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'ProductID',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _scanProduct(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _scanProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade300,
              ),
              child: const Text('สแกน / ค้นหา'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            _buildResultList(),
          ],
        ),
      ),
    );
  }
}
