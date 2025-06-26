import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _login() async {
    final userID = _userController.text.trim();
    final password = _passController.text;

    if (userID.isEmpty || password.isEmpty) {
      _showDialog('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(userID: userID, password: password);

      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        final user = result['user'];

        print('✅ Login success user: $user');

        await prefs.setString('userID', userID);
        await prefs.setString('employeeId', user['F_EmployeeID'] ?? 'UNKNOWN');
        await prefs.setString(
          'employeeName',
          user['f_EmployeeName'] ?? 'ไม่ทราบชื่อ',
        );

        await prefs.setString(
          'employeeName',
          user['f_EmployeeName'] ?? 'ไม่ทราบชื่อ',
        );
        print('✅ Saved employeeId: ${user['F_EmployeeID']}');

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')));

          // ✅ ป้องกัน error "scheduleFrameCallback"
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          });
        }
      } else {
        final errorMsg = result['message']?.toLowerCase() ?? '';
        if (errorMsg.contains('user') || errorMsg.contains('ชื่อผู้ใช้')) {
          _showDialog('ชื่อผู้ใช้ไม่ถูกต้อง กรุณากรอกให้ถูกต้อง');
        } else if (errorMsg.contains('password') ||
            errorMsg.contains('รหัสผ่าน')) {
          _showDialog('รหัสผ่านไม่ถูกต้อง กรุณากรอกอีกครั้ง');
        } else {
          _showDialog('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
        }
      }
    } catch (e) {
      _showDialog('ชื่อผู้ใช้ หรือรหัสผ่านไม่ถูกต้องกรุณากรอกอีกครั้ง');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDialog(
    String message, {
    bool isSuccess = false,
    bool autoClose = true,
  }) {
    final dialog = showDialog(
      context: context,
      barrierDismissible: true, // 👈 กดที่ว่างก็ปิดได้
      builder:
          (_) => AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'แจ้งเตือน',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(fontSize: 14)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง'),
              ),
            ],
          ),
    );

    // 👇 ปิดอัตโนมัติใน 2 วินาที
    if (autoClose) {
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF5),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            color: const Color(0xFF1B1F2B),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                constraints: const BoxConstraints(maxWidth: 350),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/Logo_Genius_Group.png',
                        height: 90,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _userController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ใช้',
                          labelStyle: TextStyle(fontSize: 13),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          labelStyle: const TextStyle(fontSize: 13),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B1F2B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(fontSize: 14),
                          ),
                          // _isLoading
                          //     ? const CircularProgressIndicator(
                          //       valueColor: AlwaysStoppedAnimation<Color>(
                          //         Colors.white,
                          //       ),
                          //     )
                          //     : const Text(
                          //       'เข้าสู่ระบบ',
                          //       style: TextStyle(fontSize: 14),
                          //     ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
