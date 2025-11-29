import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_write_screen.dart'; // ✅ 게시글 작성 화면 임포트
import '../models/item_model.dart'; // ✅ ItemModel 임포트
import '../services/firestore_service.dart'; // ✅ Firestore 서비스 임포트

//==================================================
// 1. PostListWidget (Firebase 연동된 게시글 목록 UI)
//    - 더미 로직은 모두 제거되었습니다.
//==================================================

class PostListWidget extends StatelessWidget {
  final String selectedLocation;

  const PostListWidget({super.key, required this.selectedLocation});

  @override
  Widget build(BuildContext context) {
    // 현재 위치 문자열에서 '동' 이름만 추출 (예: '충남 천안시 서북구 성정동' -> '성정동')
    final String locationName = selectedLocation.split(' ').last;

    // StreamBuilder를 사용하여 FirestoreService에서 실시간 데이터 스트림 연결
    return StreamBuilder<List<ItemModel>>(
      // FirestoreService.getItemsByLocation 함수를 통해 현재 위치의 게시글을 가져옵니다.
      stream: FirestoreService.getItemsByLocation(locationName),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (snapshot.hasError) {
          return Center(child: Text('게시글을 불러오는 중 오류가 발생했습니다: ${snapshot.error}'));
        }

        final posts = snapshot.data;

        if (posts == null || posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers_clear, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('게시글이 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('첫 게시글을 작성해보세요!', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostItem(context, post);
          },
        );
      },
    );
  }

  // 게시글 리스트 아이템 위젯 (ItemModel 사용)
  Widget _buildPostItem(BuildContext context, ItemModel post) {
    // Timestamp를 DateTime으로 변환하고 시간 포맷을 지정합니다.
    // 주의: ItemModel의 createdAt 필드는 Timestamp 타입이어야 toDate()가 작동합니다.
    final DateTime dateTime = post.createdAt.toDate();
    String formatTimeAgo(DateTime time) {
      final duration = DateTime.now().difference(time);
      if (duration.inMinutes < 60) return '${duration.inMinutes}분 전';
      if (duration.inHours < 24) return '${duration.inHours}시간 전';
      if (duration.inDays < 7) return '${duration.inDays}일 전';
      return '${time.month}/${time.day}';
    }
    final String timeAgo = formatTimeAgo(dateTime);

    // 가격 포맷 (세 자리마다 콤마 추가)
    final String priceText = post.price == 0
        ? post.status == '나눔' ? '나눔' : '가격 미정'
        : '${post.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';


    return InkWell(
      onTap: () {
        // TODO: 게시글 상세 화면으로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${post.title} 상세 보기')),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 영역
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: post.imageUrls.isEmpty
                      ? const Icon(Icons.photo_outlined, size: 40, color: Colors.grey)
                      : Image.network(
                    post.imageUrls.first, // 첫 번째 이미지 사용
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),

                // 텍스트 정보 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            post.location,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const Text(' · ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            timeAgo,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceText,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      // 좋아요/채팅 아이콘 (생략)
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
        ],
      ),
    );
  }
}

//==================================================
// 2. 더미 화면 위젯 유지 (SearchScreen, ChatScreen 등)
//==================================================

/// Navigation으로 이동하는 화면들을 대체하는 임시 위젯
class PlaceholderScreen extends StatelessWidget {
  final String screenName;
  final String? detail;

  const PlaceholderScreen({super.key, required this.screenName, this.detail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenName),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$screenName 화면', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (detail != null) Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(detail!, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            const Text('💡 이 화면은 아직 구현되지 않았습니다.', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(screenName: '검색');
  }
}

class ChatScreen extends StatelessWidget {
  final String currentUserId;
  const ChatScreen({super.key, required this.currentUserId});
  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(screenName: '채팅', detail: '사용자 ID: $currentUserId');
  }
}

//==================================================
// 3. HomeScreen (메인 화면)
//==================================================

class HomeScreen extends StatefulWidget {
  final String selectedLocation;
  final dynamic user;

  const HomeScreen({
    super.key,
    this.selectedLocation = '내 동네',
    required this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  String _getCurrentUserId() {
    // UserModel 객체에서 ID를 추출하는 헬퍼 함수
    if (widget.user != null && widget.user is Map) {
      return widget.user['uid'] ?? 'mock_user_id_from_home';
    }
    return 'fallback_user_id';
  }

  @override
  void initState() {
    super.initState();

    final currentUserId = _getCurrentUserId();

    _widgetOptions = <Widget>[
      PostListWidget(selectedLocation: widget.selectedLocation),
      const Center(child: Text('동네 지도 화면')),
      ChatScreen(currentUserId: currentUserId),
      const Center(child: Text('나의 마켓/프로필 화면')),
    ];
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCategoryButton(String text) {
    bool isSelected = text == '동네소식';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(text),
        selected: isSelected,
        selectedColor: Colors.grey.shade200,
        backgroundColor: Colors.transparent,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isSelected ? Colors.grey.shade400 : Colors.grey.shade300),
        ),
        onSelected: (selected) {
          // TODO: 카테고리 필터링 로직 구현
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex != 0) {
      final List<String> appBarTitles = ['중고거래', '동네 지도', '채팅', '나의 마켓'];

      return Scaffold(
        appBar: AppBar(
          title: Text(
            appBarTitles[_selectedIndex],
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(child: _widgetOptions[_selectedIndex]),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.selectedLocation,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () { /* 메뉴 */ },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.black),
                  onPressed: () { /* 알림 */ },
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildCategoryButton('동네소식'),
                _buildCategoryButton('가구/홈 물품'),
                _buildCategoryButton('부동산'),
                _buildCategoryButton('생활/공산품'),
                _buildCategoryButton('디지털기기'),
                _buildCategoryButton('기타'),
              ],
            ),
          ),
        ),
      ),

      body: _widgetOptions[0],

      bottomNavigationBar: _buildBottomNavigationBar(),

      // 플로팅 액션 버튼: PostWriteScreen으로 연결
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // PostWriteScreen 클래스는 import 'post_write_screen.dart'; 로 찾습니다.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostWriteScreen(
                userLocation: widget.selectedLocation,
                userId: _getCurrentUserId(),
              ),
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: '동네 지도',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: '채팅',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '나의 마켓',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: _onItemTapped,
      backgroundColor: Colors.white,
      elevation: 5,
    );
  }
}