import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/scan_stock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/scan') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => ScanStockScreen(
                  saleOrderNo: args['F_SaleOrderNo'],
                  productId: args['F_ProductId'],
                  index: args['F_Index'],
                  qty:
                      args['F_Qty'] is int
                          ? args['F_Qty']
                          : int.tryParse(args['F_Qty'].toString()) ?? 0,
                  location: args['F_Location'] ?? '', // ✅ location (optional)
                ),
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
