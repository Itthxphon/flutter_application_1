import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/WPRHeadScreen.dart';
import '../screens/sale_orders.dart';
import '../screens/login_screen.dart';
import '../screens/ScanProductIdScreen.dart';
import '../screens/ScanLocation.dart';
import '../screens/ProductionStatus.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String? _employeeName;

  final List<String> _titles = [
    'เช็ค Serial Number',
    'เปลี่ยนสถานที่',
    'ตรวจ Location',
    'สถานะการผลิต',
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadEmployeeInfo();
    _screens = [
      SaleOrdersScreen(scaffoldKey: _scaffoldKey),
      ScanProductIdScreen(scaffoldKey: _scaffoldKey),
      ScanLocationScreen(scaffoldKey: _scaffoldKey),
      ProductionStatusScreen(scaffoldKey: _scaffoldKey),
      WPRHeadScreen(scaffoldKey: _scaffoldKey),
    ];
  }

  Future<void> _loadEmployeeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('employeeName');
    if (!mounted) return;
    setState(() {
      _employeeName = name ?? 'ไม่พบชื่อพนักงาน';
    });
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
                  Navigator.pop(context);
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

          ExpansionTile(
            leading: const Icon(Icons.warehouse),
            title: const Text('Warehouse'),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32),
                leading: const Icon(Icons.list_alt),
                title: const Text('เช็ค Serial Number'),
                selected: _selectedIndex == 0,
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _selectedIndex = 0);
                  });
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32),
                leading: const Icon(Icons.edit_location_alt),
                title: const Text('เปลี่ยนสถานที่'),
                selected: _selectedIndex == 1,
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _selectedIndex = 1);
                  });
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32),
                leading: const Icon(Icons.location_searching),
                title: const Text('เช็คสินค้าในสถานที่'),
                selected: _selectedIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _selectedIndex = 2);
                  });
                },
              ),
            ],
          ),

          ExpansionTile(
            leading: const Icon(Icons.precision_manufacturing),
            title: const Text('Production'),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32),
                leading: const Icon(Icons.inventory_2_rounded),
                title: const Text('รายการขอเบิกเพื่อผลิต'),
                selected: _selectedIndex == 4,
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _selectedIndex = 4);
                  });
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32),
                leading: const Icon(Icons.factory_outlined),
                title: const Text('สถานะการผลิต'),
                selected: _selectedIndex == 3,
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _selectedIndex = 3);
                  });
                },
              ),
            ],
          ),

          const Divider(),

          // ออกจากระบบ
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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
    );
  }
}
