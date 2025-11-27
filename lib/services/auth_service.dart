import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import '../models/user_model.dart';
import 'storage_service.dart';
import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<void> initializeSdk() async {
    // 필요 시 초기화 코드
  }

  // ==========================================
  // 1. 이메일 회원가입
  // ==========================================
  static Future<AuthResult> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        nickname: name,
        profileImage: '',
      );

      // Firestore에 저장
      await FirestoreService.saveUserToFirestore(user);

      await _saveUserSession(user);
      return AuthResult.success(user: user);
    } on FirebaseAuthException catch (e) {
      String message = '회원가입 실패';
      if (e.code == 'email-already-in-use') message = '이미 사용 중인 이메일입니다.';
      if (e.code == 'weak-password') message = '비밀번호가 너무 약합니다.';
      return AuthResult.failure(message: message);
    } catch (e) {
      return AuthResult.failure(message: '오류가 발생했습니다: $e');
    }
  }

  // ==========================================
  // 2. 이메일 로그인
  // ==========================================
  static Future<AuthResult> loginWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에서 사용자 정보 가져오기
      UserModel? user = await FirestoreService.getUserFromFirestore(credential.user!.uid);

      // Firestore에 정보가 없으면 새로 생성
      if (user == null) {
        user = UserModel(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? '사용자',
          email: email,
          nickname: credential.user!.displayName ?? '사용자',
          profileImage: '',
        );
        await FirestoreService.saveUserToFirestore(user);
      }

      await _saveUserSession(user);
      return AuthResult.success(user: user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(message: '이메일 또는 비밀번호를 확인해주세요.');
    } catch (e) {
      return AuthResult.failure(message: '로그인 오류: $e');
    }
  }

  // ==========================================
  // 3. 구글 로그인
  // ==========================================
  static Future<AuthResult> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.cancelled();

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return AuthResult.failure(message: 'Firebase 인증 실패');

      final user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Google User',
        email: firebaseUser.email ?? '',
        nickname: firebaseUser.displayName ?? 'Google User',
        profileImage: firebaseUser.photoURL ?? '',
      );

      // Firestore에 저장
      await FirestoreService.saveUserToFirestore(user);

      await _saveUserSession(user);
      return AuthResult.success(user: user);
    } catch (e) {
      return AuthResult.failure(message: '구글 로그인 실패: $e');
    }
  }

  // ==========================================
  // 4. 카카오 로그인
  // ==========================================
  static Future<AuthResult> kakaoLogin() async {
    try {
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            return AuthResult.cancelled();
          }
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      kakao.User kakaoUser = await kakao.UserApi.instance.me();

      final user = UserModel(
        id: 'kakao_${kakaoUser.id}',
        name: kakaoUser.kakaoAccount?.profile?.nickname ?? 'Kakao User',
        email: kakaoUser.kakaoAccount?.email ?? '',
        nickname: kakaoUser.kakaoAccount?.profile?.nickname ?? 'Kakao User',
        profileImage: kakaoUser.kakaoAccount?.profile?.profileImageUrl ?? '',
      );

      // Firestore에 저장
      await FirestoreService.saveUserToFirestore(user);

      await _saveUserSession(user);
      return AuthResult.success(user: user);

    } catch (e) {
      if (e is PlatformException && e.code == 'CANCELED') {
        return AuthResult.cancelled();
      }
      return AuthResult.failure(message: '카카오 로그인 실패: $e');
    }
  }

  // ==========================================
  // 5. 네이버 로그인 (v2.1.1)
  // ==========================================
  static Future<AuthResult> naverLogin() async {
    try {
      print('🔵 네이버 로그인 시작');

      // 먼저 기존 토큰 삭제
      await FlutterNaverLogin.logOut();

      final result = await FlutterNaverLogin.logIn();

      print('🔵 로그인 결과 받음');
      print('🔵 result.account: ${result.account}');
      print('🔵 result.errorMessage: ${result.errorMessage}');

      // account가 null이 아니면 로그인 성공
      if (result.account != null) {
        final account = result.account!;

        print('✅ 네이버 로그인 성공');
        print('   - ID: ${account.id}');
        print('   - Name: ${account.name}');
        print('   - Email: ${account.email}');
        print('   - Nickname: ${account.nickname}');

        final user = UserModel(
          id: 'naver_${account.id}',
          name: account.name ?? 'Naver User',
          email: account.email ?? '',
          nickname: account.nickname ?? 'Naver User',
          profileImage: account.profileImage ?? '',
        );

        print('🔵 Firestore 저장 시작');
        // Firestore에 저장
        await FirestoreService.saveUserToFirestore(user);
        print('✅ Firestore 저장 완료');

        await _saveUserSession(user);
        return AuthResult.success(user: user);
      } else {
        print('❌ 네이버 로그인 실패: account is null');
        print('   errorMessage: ${result.errorMessage}');
        // account가 null이면 취소 또는 실패
        if (result.errorMessage != null &&
            (result.errorMessage!.contains('cancel') ||
                result.errorMessage!.contains('취소'))) {
          return AuthResult.cancelled();
        }
        return AuthResult.failure(message: result.errorMessage ?? '네이버 로그인 실패');
      }
    } on PlatformException catch (e) {
      print('❌ PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'CANCELED' || e.code == 'USER_CANCEL') {
        return AuthResult.cancelled();
      }
      return AuthResult.failure(message: '네이버 로그인 오류: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('❌ StackTrace: $stackTrace');
      return AuthResult.failure(message: '네이버 로그인 오류: $e');
    }
  }

  // ==========================================
  // 공통: 세션 저장 및 로그아웃
  // ==========================================
  static Future<void> _saveUserSession(UserModel user) async {
    await StorageService.saveUser(user);
    await StorageService.saveTokens(accessToken: 'dummy_token');
  }

  static Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      try { await _googleSignIn.signOut(); } catch (e) {}
      try { await kakao.UserApi.instance.logout(); } catch (e) {}
      try { await FlutterNaverLogin.logOutAndDeleteToken(); } catch (e) {}

      await StorageService.clearAll();
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  static Future<bool> isLoggedIn() => StorageService.isLoggedIn();
  static Future<UserModel?> getCurrentUser() => StorageService.getUser();
}

class AuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? message;
  final UserModel? user;

  AuthResult._({required this.isSuccess, required this.isCancelled, this.message, this.user});

  factory AuthResult.success({required UserModel user}) => AuthResult._(isSuccess: true, isCancelled: false, user: user);
  factory AuthResult.failure({required String message}) => AuthResult._(isSuccess: false, isCancelled: false, message: message);
  factory AuthResult.cancelled() => AuthResult._(isSuccess: false, isCancelled: true, message: '취소됨');
}