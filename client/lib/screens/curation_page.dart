import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CurationPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String headerImageUrl;
  final String description;
  final Map<String, dynamic> recommender;
  final List<Map<String, dynamic>> books;

  const CurationPage({
    Key? key,
    this.title = '추천 도서',
    this.subtitle = '당신을 위한 특별한 책들',
    this.headerImageUrl = '',
    this.description = '',
    this.recommender = const {
      'name': '독립 서점',
      'title': '책방 이름',
      'latitude': 37.5665,
      'longitude': 126.9780,
    },
    this.books = const [],
  }) : super(key: key);

  @override
  State<CurationPage> createState() => _CurationPageState();
}

class _CurationPageState extends State<CurationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildMainContent(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 상단 이미지 헤더 및 타이틀 위젯
  Widget _buildHeader() {
    return Stack(
      children: [
        // 배경 이미지
        Container(
          width: double.infinity,
          height: 536,
          decoration: BoxDecoration(
            color: Colors.purple.shade900, // 이미지가 없을 경우 대체 배경색
            image: DecorationImage(
              image: widget.headerImageUrl.isNotEmpty
                  ? NetworkImage(widget.headerImageUrl) as ImageProvider
                  : const AssetImage('assets/images/book_cover_detail.png'),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {
                // 이미지 로드 실패 시 아무것도 하지 않고 배경색 표시
              },
            ),
          ),
        ),
        // 그라데이션 오버레이 (선택 사항)
        Container(
          width: double.infinity,
          height: 536,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        // 컨텐츠(제목, 부제목)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard, sans-serif',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard, sans-serif',
                    letterSpacing: -0.02,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 상태 표시줄
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '10:30',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStatusIcon(Icons.signal_cellular_4_bar, Colors.white),
                    const SizedBox(width: 8),
                    _buildStatusIcon(Icons.wifi, Colors.white),
                    const SizedBox(width: 8),
                    _buildBatteryIcon(Colors.white),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('큐레이션이 공유되었습니다.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 메인 콘텐츠 섹션
  Widget _buildMainContent() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 책 목록 섹션
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Column(
              children: [
                ...List.generate(
                  widget.books.isEmpty ? 5 : widget.books.length,
                  (index) => _buildBookItem(index),
                ),
              ],
            ),
          ),
          // 설명 섹션
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description.isNotEmpty
                      ? widget.description
                      : '''이 책은 마음의 평화를 찾는 사람들에게 추천하는 책입니다. 일상의 스트레스와 불안감에서 벗어나 자신만의 공간에서 휴식을 취할 수 있는 방법을 안내합니다. 다양한 명상 기법과 심리학적 접근법을 통해 독자들은 자신의 내면을 깊이 성찰하고 진정한 행복을 찾아가는 여정을 경험할 수 있습니다.''',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    height: 1.38,
                    letterSpacing: -0.02,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
          // 추천 서점 위치 섹션
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '추천 서점 위치',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Shantell Sans, cursive',
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.02,
                    color: Color(0xFF000000),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _showStoreLocation();
                  },
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 24,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 책 아이템 위젯
  Widget _buildBookItem(int index) {
    final Map<String, dynamic> book = widget.books.isNotEmpty
        ? widget.books[index]
        : {
            'name': '책 제목 ${index + 4}',
            'writer': '저자 ${index + 4}',
            'summary': '이 책은 ...',
            'image': 'assets/images/book_cover_1.png',
          };

    return InkWell(
      onTap: () {
        _showBookDetail(book);
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF444444),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 커버 이미지
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Container(
                width: 103,
                height: 152,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF444444), width: 2),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    )
                  ],
                  image: DecorationImage(
                    image: book['image'].toString().startsWith('http')
                        ? NetworkImage(book['image']) as ImageProvider
                        : const AssetImage('assets/images/book_cover_1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // 책 정보 (제목, 저자, 설명)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 순번
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Shantell Sans, cursive',
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 제목
                    Text(
                      book['name'] ?? '책 제목',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard, sans-serif',
                        color: Color(0xCC000000),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 저자
                    Text(
                      book['writer'] ?? '저자',
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Pretendard',
                        color: Color(0x80000000),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 설명
                    Text(
                      book['summary'] ?? '이 책은 독자들에게 새로운 시각을 제공합니다.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Pretendard',
                        color: Color(0x80000000),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // 서점 위치 정보 다이얼로그 표시
  void _showStoreLocation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${widget.recommender['title']} 위치'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이름: ${widget.recommender['name']}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                '위치: 위도 ${widget.recommender['latitude']}, 경도 ${widget.recommender['longitude']}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.recommender['latitude'],
                          widget.recommender['longitude']),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(widget.recommender['name']),
                        position: LatLng(widget.recommender['latitude'],
                            widget.recommender['longitude']),
                        infoWindow:
                            InfoWindow(title: widget.recommender['title']),
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      // You can use the controller to interact with the map if needed
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('지도 앱으로 이동합니다.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('지도 앱에서 보기'),
            ),
          ],
        );
      },
    );
  }

  // 책 상세 정보 다이얼로그 표시
  void _showBookDetail(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(book['name'] ?? '책 제목'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 책 커버 이미지
                  Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: book['image'].toString().startsWith('http')
                            ? NetworkImage(book['image']) as ImageProvider
                            : const AssetImage(
                                'assets/images/book_cover_1.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['name'] ?? '책 제목',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '저자: ${book['writer'] ?? '저자 정보 없음'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Icon(Icons.star_half,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            const Text('4.5', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '책 소개',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book['summary'] ?? '이 책에 대한 자세한 정보가 없습니다.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('책을 저장했습니다.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('저장하기'),
            ),
          ],
        );
      },
    );
  }

  // 하단 탭 바
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, true),
          _buildNavItem(Icons.search, false),
          _buildNavItem(Icons.add_a_photo, false),
          _buildNavItem(Icons.favorite_border, false),
          _buildNavItem(Icons.person_outline, false),
        ],
      ),
    );
  }

  // 하단 탭 아이템
  Widget _buildNavItem(IconData icon, bool isSelected) {
    return Icon(
      icon,
      size: 24,
      color:
          isSelected ? const Color(0xFF7A5DC7) : Colors.black.withOpacity(0.62),
    );
  }

  // 상태 아이콘 (와이파이, 신호 등)
  Widget _buildStatusIcon(IconData icon, Color color) {
    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  // 배터리 아이콘
  Widget _buildBatteryIcon(Color color) {
    return Container(
      width: 22,
      height: 11,
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 2,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 1),
        ],
      ),
    );
  }
}
