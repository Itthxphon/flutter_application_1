import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProductionStatusScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ProductionStatusScreen({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  State<ProductionStatusScreen> createState() => _ProductionStatusScreenState();
}

class _ProductionStatusScreenState extends State<ProductionStatusScreen> {
  List<Map<String, dynamic>> _filteredData = [];
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  bool _isLoading = false;
  List<Map<String, dynamic>> _printerOptions = [];
  String? _selectedPrinterId;
  String _docTypeDisplay = 'ใบสั่งผลิต'; // ค่าเริ่มต้น

  @override
  void initState() {
    super.initState();
    _loadPrinters();
    _loadLastProcessOrderId(); // ✅ เรียกโหลดข้อมูลล่าสุดที่เคยใช้
  }

  Future<void> _loadLastProcessOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString('F_ProcessOrderId');
    if (lastId != null && lastId.trim().isNotEmpty) {
      _loadByProcessOrderId(lastId);
    }
  }

  Future<void> _loadPrinters() async {
    try {
      final apiService = ApiService();
      final printers = await apiService.fetchPrinters();

      if (printers.isEmpty) {
        _showAlert(
          'ไม่มีเครื่องพิมพ์',
          'ไม่พบเครื่องพิมพ์ที่ระบบส่งมา',
          Icons.print_disabled,
          Colors.orange,
        );
      } else {
        setState(() {
          _printerOptions = printers.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('🔥 โหลด printer ผิด: $e');
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadByProcessOrderId(String id) async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('F_ProcessOrderId', id); // <-- เพิ่มตรงนี้
      final results = await ApiService.getProcessOrderDetail(id);
      final casted = results.cast<Map<String, dynamic>>();

      setState(() {
        _barcodeController.clear();
        _filteredData = casted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลคำสั่งผลิต')));
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black,
      builder: (context) {
        return Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 5,
              child: SizedBox.expand(
                // ✅ กินทั้งจอ
                child:
                    imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain, // ✅ ปรับเป็น cover ได้ถ้าต้องการ
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/images/pp.png',
                                fit: BoxFit.contain,
                              ),
                        )
                        : Image.asset(
                          'assets/images/pp.png',
                          fit: BoxFit.contain,
                        ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }

  final Map<String, String> _docTypes = {
    'ใบทดแทน': 'Production_Replace',
    'ใบสั่งผลิต': 'Production_Document',
    'ใบขาด': 'Production_Missed',
    'ใบตัดแกน': 'Production_CutCore',
  };

  String _formatNumber(dynamic value) {
    try {
      final number = num.tryParse(value.toString().replaceAll(',', ''));
      if (number != null) {
        return NumberFormat.decimalPattern().format(number);
      }
    } catch (_) {}
    return value.toString(); // ถ้าไม่ใช่ตัวเลข ให้คืนค่าตามเดิม
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

  Color _statusColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'black':
        return Colors.black;

      case 'gray':
        return Colors.grey;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      default:
        return const Color(0xFF00008B);
    }
  }

  Color _parseRGB(dynamic rgbString) {
    try {
      final parts = rgbString.toString().split(',');
      if (parts.length == 3) {
        final r = int.parse(parts[0]);
        final g = int.parse(parts[1]);
        final b = int.parse(parts[2]);
        return Color.fromRGBO(r, g, b, 1);
      }
    } catch (_) {}
    return Colors.transparent;
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final formatter = DateFormat('dd/MM/yyyy');
    final imagePath = item['imagePath'] ?? '';
    final sendDate =
        item['F_SendDate'] != null
            ? formatter.format(DateTime.parse(item['F_SendDate']))
            : '-';
    final color = _mapColor(item['Color']?.toString().toLowerCase() ?? '');
    final stationColor = _statusColor(item['statusColor']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        border: Border(left: BorderSide(color: stationColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ใบกำกับการผลิต',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                sendDate,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          Text(
            item['F_ProcessOrderId'] ?? '-',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          AutoSizeText(
            item['F_ProductName'] ?? '-',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
            maxLines: 2,
            minFontSize: 10,
            overflow: TextOverflow.ellipsis,
          ),
          AutoSizeText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      'ประเภทพิมพ์ : ${item['F_Product_PrintTypeName'] ?? '-'}  ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: 'เครื่อง : ${item['F_McName'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            minFontSize: 10,
            stepGranularity: 0.5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _parseRGB(
                          item['F_STTypeColourCode'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'รหัสกระดาษ: ${item['F_STTypeIdFG'] ?? '-'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _parseRGB(item['F_STTypeColourCode']),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: stationColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item['F_StationName'] ?? '-',
                    style: TextStyle(color: stationColor, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          _buildInfoGrid(item), // ✅ วางตรงนี้
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imagePath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 150,
                  maxHeight: 250,
                ),
                color: Colors.grey[100],
                child:
                    imagePath.isNotEmpty && imagePath.startsWith('http')
                        ? CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => Image.asset(
                                'assets/images/pp.png',
                                fit: BoxFit.contain,
                              ),
                        )
                        : Image.asset(
                          'assets/images/pp.png',
                          fit: BoxFit.contain,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Map<String, dynamic> item) {
    Widget buildBox(String title, String value, Color color) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 18, // ✅ กำหนดความสูงให้กล่องข้อความแน่นอน
                child: AutoSizeText(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  minFontSize: 6,
                  stepGranularity: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 20, // ✅ ความสูงสำหรับเลขหรือข้อความ value
                child: AutoSizeText(
                  _formatNumber(value),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  minFontSize: 9,
                  stepGranularity: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            buildBox(
              'สั่งผลิต',
              '${item['F_TotalQtyFG'] ?? '-'}',
              Colors.deepPurple,
            ),
            buildBox('SO', '${item['F_QtySaleOrder'] ?? '-'}', Colors.indigo),
            buildBox('WP', '${item['F_WPQTY'] ?? '-'}', Colors.orange),
            buildBox(
              'ต้องผลิต',
              '${item['F_TotalQtyFGReal'] ?? '-'}',
              const Color(0xFF006400),
            ),
          ],
        ),

        Row(
          children: [
            buildBox(
              'PLATE',
              _checkLabel(item['F_CheckPlate']),
              _checkColor(item['F_CheckPlate']),
            ),
            buildBox(
              'BLOCK',
              _checkLabel(item['F_CheckBlock']),
              _checkColor(item['F_CheckBlock']),
            ),
            buildBox(
              'COLOUR',
              _checkLabel(item['F_CheckColour']),
              _checkColor(item['F_CheckColour']),
            ),
            buildBox(
              'PAPER',
              _checkLabel(item['F_CheckPaper']),
              _checkColor(item['F_CheckPaper']),
            ),
          ],
        ),
      ],
    );
  }

  String _checkLabel(dynamic v) {
    final s = v?.toString().toLowerCase();

    if (s == 'pass') {
      return 'Pass';
    } else if (v == true || s == 'true' || s == '1') {
      return 'True';
    } else if (v == false || s == 'false' || s == '0') {
      return 'False';
    } else {
      return '';
    }
  }

  Color _checkColor(dynamic v) {
    final s = v?.toString().toLowerCase();

    if (s == 'pass') {
      return const Color(0xFFDAA520); // ✅ เหลืองเข้ม (goldenrod)
    } else if (v == true || s == 'true' || s == '1') {
      return Colors.green; // ✅ เขียว
    } else if (v == false || s == 'false' || s == '0') {
      return Colors.red; // ✅ แดง
    }

    return Colors.grey;
  }

  void _showAlert(
    String title,
    String message,
    IconData icon,
    Color color, {
    bool autoClose = true,
  }) {
    bool isDialogOpen = true;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true, // ✅ แตะนอกจอเพื่อปิดได้
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 4),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            OutlinedButton(
              onPressed: () {
                if (isDialogOpen && mounted && Navigator.of(context).canPop()) {
                  isDialogOpen = false;
                  Navigator.of(context).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: const BorderSide(color: Colors.deepPurple),
              ),
              child: const Text(
                'ตกลง',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );

    if (autoClose) {
      Future.delayed(const Duration(seconds: 2), () {
        if (isDialogOpen && mounted && Navigator.of(context).canPop()) {
          isDialogOpen = false;
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1F2B),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('สถานะการผลิต'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              final currentId = _barcodeController.text.trim();

              if (currentId.isNotEmpty) {
                _loadByProcessOrderId(currentId);
              } else {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('F_ProcessOrderId'); //ล้างเฉพาะ
                setState(() {
                  _filteredData.clear();
                  _isLoading = false;
                });
              }
            },
          ),
        ],
      ),
      body: BarcodeKeyboardListener(
        bufferDuration: const Duration(milliseconds: 200),
        onBarcodeScanned: (barcode) {
          final trimmed = barcode.trim();
          if (trimmed.isNotEmpty) {
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            FocusScope.of(context).unfocus();
            _barcodeController.text = trimmed;
            _loadByProcessOrderId(trimmed);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // ✅ แสดงข้อมูล
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredData.isEmpty
                        ? const Center(
                          child: Text('ไม่พบข้อมูลโปรดสแกน ProcessOrderId'),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredData.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildCard(_filteredData[index]),
                        ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // 🔹 เครื่องพิมพ์ (ของจริง)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            return GestureDetector(
                              onTap: () {
                                final RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                final Offset offset = renderBox.localToGlobal(
                                  Offset.zero,
                                );

                                showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    offset.dx + renderBox.size.width - 200,
                                    offset.dy - (_printerOptions.length * 48),
                                    offset.dx + renderBox.size.width,
                                    offset.dy,
                                  ),
                                  items:
                                      _printerOptions.map((printer) {
                                        return PopupMenuItem<String>(
                                          value:
                                              printer['f_PrinterID']
                                                  ?.toString(),
                                          child: Text(
                                            printer['f_PrinterName']
                                                    ?.toString() ??
                                                'ไม่ทราบชื่อ',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ).then((selectedValue) {
                                  if (selectedValue != null) {
                                    setState(() {
                                      _selectedPrinterId = selectedValue;
                                    });
                                  }
                                });
                              },
                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black26),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _printerOptions
                                                .firstWhere(
                                                  (p) =>
                                                      p['f_PrinterID'] ==
                                                      _selectedPrinterId,
                                                  orElse: () => {},
                                                )['f_PrinterName']
                                                ?.toString() ??
                                            'กรุณาเลือกเครื่องพิมพ์',
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_up),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            return GestureDetector(
                              onTap: () async {
                                final renderBox =
                                    context.findRenderObject() as RenderBox;
                                final offset = renderBox.localToGlobal(
                                  Offset.zero,
                                );

                                final selected = await showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    offset.dx + 10,
                                    offset.dy -
                                        (4 *
                                            48), // เด้งขึ้น = จำนวนเมนู x ความสูงเมนู
                                    offset.dx + renderBox.size.width,
                                    offset.dy,
                                  ),

                                  items: const [
                                    PopupMenuItem(
                                      value: 'ใบทดแทน',
                                      child: Text('ใบทดแทน'),
                                    ),
                                    PopupMenuItem(
                                      value: 'ใบสั่งผลิต',
                                      child: Text('ใบสั่งผลิต'),
                                    ),
                                    PopupMenuItem(
                                      value: 'ใบขาด',
                                      child: Text('ใบขาด'),
                                    ),
                                    PopupMenuItem(
                                      value: 'ใบตัดแกน',
                                      child: Text('ใบตัดแกน'),
                                    ),
                                  ],
                                );

                                if (selected != null) {
                                  setState(() {
                                    _docTypeDisplay = selected;
                                  });
                                }
                              },

                              child: Container(
                                height: 44,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black26),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _docTypeDisplay, // ✅ เปลี่ยนตามที่เลือก
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('พิมพ์'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1F2B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final employeeName = prefs.getString('employeeName') ?? '';
                    final processOrderId =
                        prefs.getString('F_ProcessOrderId') ?? '';

                    if (processOrderId.isEmpty || employeeName.isEmpty) {
                      _showAlert(
                        'ไม่พบข้อมูล',
                        'ไม่พบข้อมูล ProcessOrderId หรือชื่อพนักงาน',
                        Icons.warning_amber_rounded,
                        Colors.orange,
                      );
                      return;
                    }

                    final printReport =
                        _docTypes[_docTypeDisplay] ?? 'Production_Document';
                    final apiService = ApiService();

                    try {
                      final result = await apiService.printAndLog(
                        processOrderId: processOrderId,
                        employeeName: employeeName,
                        printerId: _selectedPrinterId ?? '',
                        printReport: printReport,
                      );

                      if (result is Map<String, dynamic>) {
                        final alreadyPrinted = result['alreadyPrinted'] == true;

                        if (alreadyPrinted) {
                          _showAlert(
                            'เคยพิมพ์ไปแล้ว',
                            'ใบกำกับการผลิต "$processOrderId"\nเคยถูกสั่งพิมพ์ไปแล้ว',
                            Icons.info_outline,
                            Colors.orange,
                          );
                        } else {
                          _showAlert(
                            'พิมพ์สำเร็จ',
                            'พิมพ์สำเร็จสำหรับ\nProcessOrderId "$processOrderId"',
                            Icons.check_circle_outline,
                            Colors.green,
                          );
                        }
                      } else {
                        _showAlert(
                          'เกิดข้อผิดพลาด',
                          'ผลลัพธ์จากเซิร์ฟเวอร์ไม่ถูกต้อง',
                          Icons.error_outline,
                          Colors.red,
                        );
                      }
                    } catch (e) {
                      _showAlert(
                        'เกิดข้อผิดพลาด',
                        'ใบกำกับการผลิต "$processOrderId"\nเคยถูกสั่งพิมพ์ไปแล้ว',
                        Icons.info_outline,
                        Colors.orange,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
