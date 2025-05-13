import 'package:flutter/material.dart';
import '../screens/sale_orders.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ❌ ไม่แสดงปุ่ม back/hamburger
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,

        // ✅ ใช้ Row + Expanded เพื่อจัด layout แบบ "กรอง - ชื่อ - กระดิ่ง"
        title: Row(
          children: [
            // ✅ [ซ้าย] ปุ่มกรอง
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'กรองตามสีวันจัดส่ง',
              onPressed: () {
                _showColorFilterMenu(context); // ฟังก์ชันแสดง popup กรองสี
              },
            ),

            // ✅ [กลาง] ชื่อ "เช็ค Serial Number"
            const Expanded(
              child: Center(
                child: Text(
                  'เช็ค Serial Number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ✅ [ขวา] ปุ่มแจ้งเตือน
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'งานวันนี้ที่ยังไม่ทำ',
              onPressed: () {
                // 🔔 ใส่ฟังก์ชันแสดงงานของวันนี้ที่ยังไม่ทำ
              },
            ),
          ],
        ),
      ),

      // ✅ [Body] เป็นหน้ารายการใบสั่งขาย
      body: const SaleOrdersScreen(),
    );
  }

  // ✅ เมนูกรองสี (แสดงเมื่อกดไอคอนกรอง)
  void _showColorFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              const Text(
                'กรองตามสีวันจัดส่ง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorFilterOption(context, null, 'ทั้งหมด'),
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
                    (color) => _buildColorFilterOption(context, color, color),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ ปุ่มตัวเลือกแต่ละสี
  Widget _buildColorFilterOption(
    BuildContext context,
    String? color,
    String label,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected:
          false, // ไม่แสดงสถานะเลือกในนี้ (คุณอาจจัดการใน state ที่ SaleOrdersScreen แทน)
      onSelected: (_) {
        Navigator.pop(context);

        // ✅ ส่งค่าที่เลือกไปยัง SaleOrdersScreen ผ่าน Event หรือ Callback
        // ในตัวอย่างนี้ยังไม่ได้เชื่อมต่อโดยตรง ต้องใช้ Provider หรือ callback หากต้องการให้ทำงานจริง
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue.shade100,
      avatar:
          color == null
              ? null
              : CircleAvatar(backgroundColor: _mapColor(color), radius: 6),
    );
  }

  // ✅ ฟังก์ชันแปลงชื่อสีเป็น Color
  Color _mapColor(String color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'pink':
        return Colors.pink;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'lightsky':
        return Colors.lightBlueAccent;
      case 'brown':
        return Colors.brown;
      case 'lightgreen':
        return Colors.lightGreen;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
