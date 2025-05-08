import 'package:flutter/material.dart';
import 'sale_orders.dart';
import 'scan_history.dart'; // หน้าประวัติการสแกน

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [SaleOrdersScreen(), ScanHistoryScreen()];

  final List<String> _titles = ['คำสั่งขาย', 'ประวัติการสแกน'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onMenuSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // ปิด Drawer หลังเลือก
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'เมนู',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('คำสั่งขาย'),
              onTap: () => _onMenuSelected(0),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('ประวัติการสแกน'),
              onTap: () => _onMenuSelected(1),
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
    );
  }
}
