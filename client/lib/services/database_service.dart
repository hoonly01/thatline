import 'dart:async';
import '../screens/bookmark_page.dart';

class DatabaseService {
  static Future<BookInfo?> getRecentBookInfo() async {
    // Simulate fetching data from a database
    await Future.delayed(const Duration(seconds: 2));
    return BookInfo(title: 'Sample Book Title', author: 'Sample Author');
  }

  // Example static data, replace with real DB logic
  static Future<List<BookmarkRecord>> getBookmarkRecords() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      BookmarkRecord(
        date: '2025. 03. 12.',
        imagePath: 'test_ocr_pics/IMG_2103.jpeg',
        sentence:
            '나는 이사한 날 그 방의 도코나마에 장식된 꽃과 그 옆에 세워진 거문고를 봤네. 둘 다 마음에 들지 않는다.',
      ),
      BookmarkRecord(
        date: '2025. 03. 04.',
        imagePath: 'test_ocr_pics/IMG_1424.jpeg',
        sentence: '오늘은 새로운 가구를 배치해보았고, 방이 훨씬 넓어 보이더군. 이제는 편안하게 느껴져.',
      ),
      BookmarkRecord(
        date: '2025. 02. 15.',
        imagePath: 'test_ocr_pics/IMG_7262.jpeg',
        sentence: '정원에서의 길',
      ),
    ];
  }
}

class BookInfo {
  final String title;
  final String author;

  BookInfo({required this.title, required this.author});
}
