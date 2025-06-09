import 'package:flutter/material.dart';
import 'package:thatline_client/screens/ocr_screen.dart';
import 'package:thatline_client/screens/curation_page.dart';
import 'package:thatline_client/screens/recommendation_page.dart';
import 'package:thatline_client/services/database_service.dart';
import 'package:thatline_client/screens/camera_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    Container(), // Placeholder for camera
    const BookmarkPage(),
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
                  MaterialPageRoute(builder: (context) => const OcrScreen()),
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
      body: Column(
        children: [
          // Dynamic Status Bar
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).padding.top + 56,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 17),
            color: const Color(0xFFFCFBFE),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TimeOfDay.now().format(context),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: Color(0xFF1E1B28),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.signal_cellular_4_bar, color: Colors.black),
                    const SizedBox(width: 8),
                    Icon(Icons.wifi, color: Colors.black),
                    const SizedBox(width: 8),
                    Icon(Icons.battery_full, color: Colors.black),
                  ],
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Recent Saved Photo and Book Info
                  FutureBuilder(
                    future: DatabaseService.getRecentBookInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasData) {
                        final bookInfo = snapshot.data;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 32),
                          color: const Color(0xFFFCFBFE),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookInfo?.title ?? 'Unknown Title',
                                style: const TextStyle(
                                  fontFamily: 'Domine',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                  height: 32 / 28,
                                  letterSpacing: -0.02,
                                  color: Color(0xFF1E1B28),
                                ),
                              ),
                              Text(
                                bookInfo?.author ?? 'Unknown Author',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                  color: Color(0xFF1E1B28),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const Text('No recent book info available.');
                      }
                    },
                  ),
                  // Navigation Section
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RecommendationPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        '이럴 땐 이런 책 어떠세요?',
                        style: TextStyle(
                          fontFamily: 'Domine',
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          color: Color(0xFF1E1B28),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CurationPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        '큐레이터가 추천하는 책',
                        style: TextStyle(
                          fontFamily: 'Domine',
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          color: Color(0xFF1E1B28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 검색 화면
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('검색 화면'),
    );
  }
}

// 저장목록 화면
class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('저장목록 화면'),
    );
  }
}

// 마이페이지 화면
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('마이페이지 화면'),
    );
  }
}
