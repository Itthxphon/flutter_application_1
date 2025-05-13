import 'package:flutter/material.dart';
import '../screens/sale_orders.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String? selectedColor; // ✅ เก็บค่าสีที่เลือก

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            // ✅ ปุ่มกรอง (กดแล้วแสดง PopupMenu ด้านล่าง)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'กรองตามสีวันจัดส่ง',
              onPressed: () {
                _showColorFilterMenu(context); // ✅ เปิดเมนูกรอง
              },
            ),

            // ✅ ชื่ออยู่ตรงกลาง
            const Expanded(
              child: Center(
                child: Text(
                  'เช็ค Serial Number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ✅ ปุ่มแจ้งเตือน (ไว้เพิ่มฟีเจอร์ในอนาคต)
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'งานวันนี้ที่ยังไม่ทำ',
              onPressed: () {
                // Future: แสดงรายการงานวันนี้
              },
            ),
          ],
        ),
      ),

      // ✅ ส่ง selectedColor ไปให้ SaleOrdersScreen ใช้งานจริง
      body: SaleOrdersScreen(key: ValueKey(selectedColor),
          colorFilter: selectedColor),
    );
  }

  // ✅ เมนู Popup สำหรับเลือกสี
  void _showColorFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'กรองตามสีวันจัดส่ง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorBox(context, null, 'ทั้งหมด'),
                  ...[
                    'red',
                    'yellow',
                    'pink',
                    'blue',
                    'purple',
                    'lightsky',
                    'brown',
                    'lightgreen',
                    'green',
                  ].map(
                    (color) =>
                        _buildColorBox(context, color, _colorLabel(color)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ ปุ่มกรองแต่ละสี (ขนาดเท่ากัน + วงกลมสี)
  Widget _buildColorBox(BuildContext context, String? colorCode, String label) {
    final isSelected = selectedColor == colorCode;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          selectedColor = colorCode; // ✅ เปลี่ยนค่า filter
        });
      },
      child: Container(
        width: 100,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (colorCode != null)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _mapColor(colorCode),
                  shape: BoxShape.circle,
                ),
              ),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ แปลงรหัสสีเป็นชื่อไทย
  String _colorLabel(String color) {
    switch (color) {
      case 'red':
        return 'แดง';
      case 'yellow':
        return 'เหลือง';
      case 'pink':
        return 'ชมพู';
      case 'blue':
        return 'น้ำเงิน';
      case 'purple':
        return 'ม่วง';
      case 'lightsky':
        return 'ฟ้า';
      case 'brown':
        return 'น้ำตาล';
      case 'lightgreen':
        return 'เขียวอ่อน';
      case 'green':
        return 'เขียว';
      default:
        return color;
    }
  }

  // ✅ แปลงรหัสสีเป็น Color จริง (จากภาพตัวอย่างของคุณ)
  Color _mapColor(String color) {
    switch (color) {
      case 'red':
        return const Color(0xFFFF3D3D);
      case 'yellow':
        return const Color(0xFFFFC107);
      case 'pink':
        return const Color(0xFFFF3DF5);
      case 'blue':
        return const Color(0xFF0051FF);
      case 'purple':
        return const Color(0xFF9900CC);
      case 'lightsky':
        return const Color(0xFF90CAF9);
      case 'brown':
        return const Color(0xFF8D6E63);
      case 'lightgreen':
        return const Color(0xFFB2FF59);
      case 'green':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }
}
