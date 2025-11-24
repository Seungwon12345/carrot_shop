import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'location_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isTermsAgreed = false;
  bool _isMarketingAgreed = false;
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (_phoneController.text.isEmpty) {
      _showError('휴대폰 번호를 입력해주세요');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showError('아이디를 입력해주세요');
      return;
    }
    if (_nicknameController.text.isEmpty) {
      _showError('닉네임을 입력해주세요');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('비밀번호를 입력해주세요');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError('비밀번호는 8자 이상이어야 합니다');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('비밀번호가 일치하지 않습니다');
      return;
    }
    if (!_isTermsAgreed) {
      _showError('이용약관에 동의해주세요');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _nicknameController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.isSuccess && result.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LocationScreen()),
        );
      } else {
        _showError(result.message ?? '회원가입 실패');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16),

            const Text(
              '천안마켓에',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: Colors.black),
            ),
            const Text(
              '오신 것을 환영합니다!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              '계정을 만들고 중고거래를 시작해보세요',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            _buildTextFieldGroup(
              controller: _phoneController,
              title: '휴대폰 번호',
              hint: '01012345678',
              keyboardType: TextInputType.phone,
            ),

            _buildTextFieldGroup(
              controller: _emailController,
              title: '아이디',
              hint: '사용할 아이디를 입력하세요',
            ),

            _buildTextFieldGroup(
              controller: _nicknameController,
              title: '닉네임',
              hint: '사용할 닉네임을 입력하세요',
            ),

            const SizedBox(height: 20),

            _buildTextFieldGroup(
              controller: _passwordController,
              title: '비밀번호',
              hint: '비밀번호 입력 (8자 이상)',
              obscureText: true,
            ),

            _buildTextFieldGroup(
              controller: _confirmPasswordController,
              title: '비밀번호 확인',
              hint: '비밀번호 재입력',
              obscureText: true,
            ),

            const SizedBox(height: 40),

            _buildCheckboxRow(
              title: '[필수] 이용약관 및 개인정보처리방침에 동의합니다',
              value: _isTermsAgreed,
              onChanged: (newValue) {
                setState(() {
                  _isTermsAgreed = newValue!;
                });
              },
            ),

            _buildCheckboxRow(
              title: '[선택] 마케팅 정보 수신에 동의합니다',
              value: _isMarketingAgreed,
              onChanged: (newValue) {
                setState(() {
                  _isMarketingAgreed = newValue!;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isTermsAgreed && !_isLoading) ? _handleSignUp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldGroup({
    required TextEditingController controller,
    required String title,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            ),
            keyboardType: keyboardType,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: _isLoading ? null : onChanged,
              activeColor: Colors.blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}