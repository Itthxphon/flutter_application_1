import 'package:flutter/material.dart';
import '../screens/sale_orders.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String? selectedColor;
  int pendingCount = 0;

  final GlobalKey _notifyIconKey = GlobalKey();

  void _showTooltipBelowIcon(GlobalKey key, String message) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final position = renderBox.localToGlobal(Offset.zero);

    // คำนวณขนาด tooltip โดยประมาณ
    const tooltipWidth = 160.0;
    const tooltipHeight = 36.0;

    double left = position.dx;

    // ถ้า tooltip เลยขอบขวา ให้เลื่อนซ้าย
    if (left + tooltipWidth > screenSize.width - 8) {
      left = screenSize.width - tooltipWidth - 8;
    }

    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: position.dy + renderBox.size.height + 4,
            left: left,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: tooltipWidth,
                height: tooltipHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

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

  Widget _buildColorBox(BuildContext context, String? colorCode, String label) {
    final isSelected = selectedColor == colorCode;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          selectedColor = colorCode;
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

  Color _mapColor(String color) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'กรองตามสีวันจัดส่ง',
              onPressed: () => _showColorFilterMenu(context),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'เช็ค Serial Number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Stack(
              children: [
                IconButton(
                  key: _notifyIconKey,
                  icon: const Icon(Icons.notifications),
                  tooltip: 'งานวันนี้ที่ยังไม่ทำ',
                  onPressed: () {
                    _showTooltipBelowIcon(
                      _notifyIconKey,
                      'งานวันนี้ที่ยังไม่ได้ทำ',
                    );
                  },
                ),
                if (pendingCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pendingCount',
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
          ],
        ),
      ),
      body: SaleOrdersScreen(
        key: ValueKey(selectedColor),
        colorFilter: selectedColor,
        onPendingCountChanged: (count) {
          setState(() {
            pendingCount = count;
          });
        },
      ),
    );
  }
}
