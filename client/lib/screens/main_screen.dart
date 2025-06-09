import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thatline_client/screens/camera_screen.dart';
import 'package:thatline_client/screens/curation_page.dart';
import 'package:thatline_client/screens/recommendation_page.dart';
import 'package:thatline_client/screens/bookmark_page.dart' as bookmark;

class MainScreen extends StatefulWidget {
  final int? initialTabIndex;
  
  const MainScreen({super.key, this.initialTabIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex ?? 0;
  }

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    Container(), // Camera placeholder
    const bookmark.BookmarkPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_filled),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '검색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: '저장목록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              },
              backgroundColor: Colors.black,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// 홈 화면
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFE),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(TimeOfDay.now().format(context),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  const Row(
                    children: [
                      Icon(Icons.signal_cellular_alt, size: 18),
                      SizedBox(width: 6),
                      Icon(Icons.wifi, size: 18),
                      SizedBox(width: 6),
                      Icon(Icons.battery_full, size: 18),
                    ],
                  )
                ],
              ),
            ),

            // 최근 문장
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '풀서프_훈님이\n최근 사랑한 문장이에요!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/sample_book.jpg'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '그만큼 내일을 믿고 기다리는 것은 매우 중요하다.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Text('좋아하기 때문에 · 나태주',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            // 추천 섹션
            _SectionTitle(
              title: '이럴 땐 이런 책 어떠세요?',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecommendationPage()),
                );
              },
            ),
            _HorizontalBookList(books: const [
              {'title': '노벨상 작가 한강 모음', 'subtitle': '한강'},
              {'title': '과학은 아름답다', 'subtitle': '과학 도서 모음'},
            ]),

            _SectionTitle(
              title: '큐레이터가 추천하는 책',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CurationPage(curationId: 1)),
                );
              },
            ),
            _HorizontalBookList(books: const [
              {'title': '경희대학교 사서 Pick!', 'subtitle': '이여령의 말'},
              {'title': '20대를 위한 금융서', 'subtitle': '티빙 포인트의 설계자들'},
            ]),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionTitle({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _HorizontalBookList extends StatelessWidget {
  final List<Map<String, String>> books;

  const _HorizontalBookList({required this.books});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CurationPage(curationId: 1),
                ),
              );
            },
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(book['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(book['subtitle']!,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 검색 페이지
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('검색 화면'));
  }
}

// 마이페이지
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('마이페이지 화면'));
  }
}
