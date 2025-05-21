import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/sale_orders.dart';
import '../screens/login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _pendingCount = 0;
  String? _colorFilter;

  void _updatePendingCount(int count) {
    setState(() {
      _pendingCount = count;
    });
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                colors.entries.map((entry) {
                  final isSelected = _colorFilter == entry.key;
                  final colorDot = _mapColor(entry.key);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _colorFilter = entry.key);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 110,
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          if (entry.key != null)
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยันการออกจากระบบ'),
            content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;

                  Navigator.pop(context); // ปิด dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ตกลง'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1F2B),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            // 🔍 ปุ่มกรองซ้าย
            IconButton(
              icon: const Icon(Icons.tune, size: 28),
              tooltip: 'กรองตามสีวันจัดส่ง',
              onPressed: _showColorFilterMenu,
            ),
            const Spacer(),

            // ตรงกลาง: ชื่อหน้าจอ
            const Text(
              'เช็ค Serial Number',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Spacer(),

            //ปุ่มกระดิ่ง
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, size: 28),
                  tooltip: 'งานวันนี้ที่ยังไม่ทำ',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('คุณมีงานค้างที่ยังไม่ตรวจ SN'),
                      ),
                    );
                  },
                ),
                if (_pendingCount > 0)
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
                        _pendingCount > 99 ? '99+' : '$_pendingCount',
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

            // 🚪 Logout
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'ออกจากระบบ',
              onPressed: _confirmLogout,
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),

      body: SaleOrdersScreen(
        key: ValueKey(_colorFilter),
        colorFilter: _colorFilter,
        onPendingCountChanged: _updatePendingCount,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() => _currentIndex = 0);
          } else if (index == 1) {
            Navigator.pushNamed(
              context,
              '/change-location',
            ); // ✅ ไปหน้าเปลี่ยนสถานที่
          }
        },
        backgroundColor: const Color(0xFF1B1F2B),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        iconSize: 22,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'เช็ค SN'),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_location_alt),
            label: 'เปลี่ยนสถานที่',
          ),
        ],
      ),
    );
  }
}
