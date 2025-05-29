import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/ScanProductIdScreen.dart';
import 'screens/scan_stock.dart';
import 'widgets/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.containsKey('userID');
    return isLoggedIn ? const MainNavigationScreen() : const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScanPro',
      theme: ThemeData(primarySwatch: Colors.deepPurple),

      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),

      onGenerateRoute: (settings) {
        if (settings.name == '/scan') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => ScanStockScreen(
                  saleOrderNo: args['F_SaleOrderNo'] ?? '',
                  productId: args['F_ProductId'] ?? '',
                  index:
                      args['F_Index'] is int
                          ? args['F_Index']
                          : int.tryParse(args['F_Index'].toString()) ?? 0,
                  qty:
                      args['F_Qty'] is int
                          ? args['F_Qty']
                          : int.tryParse(args['F_Qty'].toString()) ?? 0,
                  location: args['F_Location'] ?? '',
                ),
            settings: settings,
          );
        }

        if (settings.name == '/change-location') {
          return MaterialPageRoute(
            builder: (context) => const ScanProductIdScreen(),
            settings: settings,
          );
        }

        if (settings.name == '/main') {
          return MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder:
              (context) =>
                  const Scaffold(body: Center(child: Text('ไม่พบหน้า'))),
        );
      },
    );
  }
}
