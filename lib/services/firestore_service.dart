import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';
  static const String _itemsCollection = 'items';

  // ==========================================
  // 👤 사용자(User) 관련 메서드
  // ==========================================

  // 1. 사용자 정보 저장
  static Future<void> saveUserToFirestore(UserModel user) async {
    print('🔥 Firestore 사용자 저장 시작: ${user.id}');
    try {
      final docRef = _firestore.collection(_usersCollection).doc(user.id);

      final data = {
        ...user.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));
      print('✅ 사용자 정보 저장 성공');
    } catch (e) {
      print('❌ 사용자 저장 실패: $e');
      rethrow;
    }
  }

  // 2. 사용자 정보 가져오기
  static Future<UserModel?> getUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ 사용자 조회 실패: $e');
      return null;
    }
  }

  // 💡 [추가됨] 3. 사용자 정보 업데이트 (위치 저장 등에 필수!)
  // 이 함수가 없어서 오류가 났던 것입니다.
  static Future<void> updateUserInFirestore(String userId, Map<String, dynamic> updates) async {
    try {
      // 업데이트 시간 자동 갱신
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_usersCollection).doc(userId).update(updates);
      print('✅ 사용자 정보 업데이트 성공: $updates');
    } catch (e) {
      print('❌ 사용자 정보 업데이트 실패: $e');
      rethrow;
    }
  }

  // 4. 이메일로 사용자 찾기
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
      return null;
    }
  }

  // 5. 닉네임 중복 확인
  static Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 📦 게시글(Item) 관련 메서드
  // ==========================================

  // 1. 게시글 저장
  static Future<void> saveItemToFirestore(ItemModel item) async {
    print('🔥 게시글 저장 시작: ${item.id}');
    try {
      final docRef = _firestore.collection(_itemsCollection).doc(item.id);
      await docRef.set(item.toJson(), SetOptions(merge: true));
      print('✅ 게시글 저장 성공');
    } catch (e) {
      print('❌ 게시글 저장 실패: $e');
      rethrow;
    }
  }

  // 2. 위치 기반 게시글 조회
  static Stream<List<ItemModel>> getItemsByLocation(String locationName) {
    print('🔥 위치 기반 조회 요청: $locationName');

    return _firestore
        .collection(_itemsCollection)
        .where('location', isEqualTo: locationName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ItemModel.fromJson(data);
      }).toList();
    });
  }

  // 3. 사용자별 게시글 조회
  static Future<List<ItemModel>> getItemsByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_itemsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ItemModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('❌ 사용자 판매 내역 조회 실패: $e');
      return [];
    }
  }

  // 4. 게시글 삭제
  static Future<void> deleteItemFromFirestore(String itemId) async {
    try {
      await _firestore.collection(_itemsCollection).doc(itemId).delete();
      print('✅ 게시글 삭제 성공');
    } catch (e) {
      print('❌ 게시글 삭제 실패: $e');
      rethrow;
    }
  }
}