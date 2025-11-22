import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'signup_screen.dart'; // 회원가입 화면 import

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // 공통 로그인 핸들러
  Future<void> _handleLogin(Future<AuthResult> Function() loginMethod) async {
    setState(() => _isLoading = true);
    final result = await loginMethod();
    if (mounted) {
      setState(() => _isLoading = false);
      if (result.isSuccess && result.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen(user: result.user!)),
        );
      } else if (!result.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '로그인 실패')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // 로고 영역 (기존 코드와 동일)
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('당근마켓', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),

              const Spacer(flex: 2),

              // 1. 네이버 로그인
              CustomButton(
                onPressed: () => _handleLogin(AuthService.naverLogin),
                text: '네이버로 시작하기',
                backgroundColor: const Color(0xFF03C75A),
                isLoading: _isLoading,
                icon: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // 2. 카카오 로그인
              CustomButton(
                onPressed: () => _handleLogin(AuthService.kakaoLogin),
                text: '카카오로 시작하기',
                backgroundColor: const Color(0xFFFEE500),
                textColor: Colors.black87,
                isLoading: _isLoading,
                icon: const Icon(Icons.chat_bubble, color: Colors.black87, size: 20),
              ),
              const SizedBox(height: 12),

              // 3. 구글 로그인
              CustomButton(
                onPressed: () => _handleLogin(AuthService.googleLogin),
                text: 'Google로 시작하기',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                borderColor: Colors.grey[300],
                isLoading: _isLoading,
                icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
              ),

              const SizedBox(height: 24),

              // 4. 이메일 회원가입 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('계정이 없으신가요?'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                    },
                    child: const Text('이메일로 가입하기'),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}