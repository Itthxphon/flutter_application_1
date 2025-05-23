import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/sale_orders.dart';
import '../screens/login_screen.dart';
import '../screens/ScanProductIdScreen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  int _pendingCount = 0;
  String? _colorFilter;
  String? _employeeName;

  final List<Widget> _screens = [];
  final List<String> _titles = ['เช็ค Serial Number', 'เปลี่ยนสถานที่'];

  @override
  void initState() {
    super.initState();
    _loadEmployeeInfo();

    _screens.add(
      SaleOrdersScreen(
        key: ValueKey(_colorFilter),
        colorFilter: _colorFilter,
        onPendingCountChanged: _updatePendingCount,
      ),
    );
    _screens.add(const ScanProductIdScreen());
  }

  Future<void> _loadEmployeeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('employeeName');

    setState(() {
      _employeeName = name ?? 'ไม่พบชื่อพนักงาน';
    });
  }

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
      backgroundColor: const Color(0xFFF7F0FA), // สีพื้นหลังแบบในภาพ
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'กรองตามสีวันจัดส่ง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 346,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        colors.entries.map((entry) {
                          final isSelected = _colorFilter == entry.key;
                          final colorDot = _mapColor(entry.key);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _colorFilter = entry.key;
                                _screens[0] = SaleOrdersScreen(
                                  key: ValueKey(_colorFilter),
                                  colorFilter: _colorFilter,
                                  onPendingCountChanged: _updatePendingCount,
                                );
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 104,
                              height: 42,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
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
                ),
              ),
            ],
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
                onPressed: () => Navigator.pop(context), // ปิดกล่อง
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

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1B1F2B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_circle, size: 48, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  _employeeName ?? 'กำลังโหลด...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('เช็ค Serial Number'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_location_alt),
            title: const Text('เปลี่ยนสถานที่'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ออกจากระบบ'),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showAppBarInScaffold =
        _selectedIndex == 0; // ⬅ หน้าแรกเท่านั้นที่ใช้ AppBar จาก Scaffold

    return Scaffold(
      appBar:
          showAppBarInScaffold
              ? AppBar(
                backgroundColor: const Color(0xFF1B1F2B),
                foregroundColor: Colors.white,
                centerTitle: false, // ⬅️ ไม่จัดกลาง เพื่อควบคุมเอง
                title: Padding(
                  padding: const EdgeInsets.only(left: 8), // ⬅️ ขยับ title ซ้าย
                  child: Text(
                    _titles[_selectedIndex],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                actions: [
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
                  IconButton(
                    icon: const Icon(Icons.tune, size: 28),
                    tooltip: 'กรองตามสีวันจัดส่ง',
                    onPressed: _showColorFilterMenu,
                  ),
                ],
              )
              : null,

      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
    );
  }
}
