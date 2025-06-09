import 'dart:async';

class DatabaseService {
  static Future<BookInfo?> getRecentBookInfo() async {
    // Simulate fetching data from a database
    await Future.delayed(const Duration(seconds: 2));
    return BookInfo(title: 'Sample Book Title', author: 'Sample Author');
  }
}

class BookInfo {
  final String title;
  final String author;

  BookInfo({required this.title, required this.author});
}
