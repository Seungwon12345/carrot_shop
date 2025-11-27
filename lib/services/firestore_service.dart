import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // 사용자 정보를 Firestore에 저장
  static Future<void> saveUserToFirestore(UserModel user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set(
        {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'nickname': user.nickname,
          'profileImage': user.profileImage,
          'birthday': user.birthday,
          'age': user.age,
          'gender': user.gender,
          'mobile': user.mobile,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // 기존 데이터가 있으면 병합
      );
      print('✅ Firestore에 사용자 정보 저장 성공: ${user.id}');
    } catch (e) {
      print('❌ Firestore 저장 실패: $e');
      rethrow;
    }
  }

  // Firestore에서 사용자 정보 가져오기
  static Future<UserModel?> getUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Firestore 조회 실패: $e');
      return null;
    }
  }

  // 사용자 정보 업데이트
  static Future<void> updateUserInFirestore(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_usersCollection).doc(userId).update(updates);
      print('✅ Firestore 사용자 정보 업데이트 성공');
    } catch (e) {
      print('❌ Firestore 업데이트 실패: $e');
      rethrow;
    }
  }

  // 사용자 삭제
  static Future<void> deleteUserFromFirestore(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
      print('✅ Firestore 사용자 정보 삭제 성공');
    } catch (e) {
      print('❌ Firestore 삭제 실패: $e');
      rethrow;
    }
  }

  // 이메일로 사용자 찾기
  static Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ 이메일로 사용자 조회 실패: $e');
      return null;
    }
  }

  // 닉네임 중복 확인
  static Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('❌ 닉네임 중복 확인 실패: $e');
      return false;
    }
  }
}