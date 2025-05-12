import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

/// 데이터베이스 관련 기능을 제공하는 클래스
class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'ocr_images.db';

  /// 데이터베이스 인스턴스를 가져옵니다.
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 데이터베이스를 초기화합니다.
  static Future<Database> _initDatabase() async {
    // 현재 디렉토리에 데이터베이스 파일 생성
    final path = join(Directory.current.path, _dbName);
    print('Initializing database at: $path');
    
    // 데이터베이스 파일이 이미 존재하는지 확인
    final dbFile = File(path);
    final exists = await dbFile.exists();
    print('Database file exists: $exists');

    // 데이터베이스 연결
    final db = sqlite3.open(path);
    print('Database connection established');

    // 테이블 생성
    print('Creating tables...');
    
    // 이미지 테이블 생성
    db.execute('''
      CREATE TABLE IF NOT EXISTS images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        text_content TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    print('Images table created');

    // 문장 테이블 생성
    db.execute('''
      CREATE TABLE IF NOT EXISTS sentences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sentence_id TEXT NOT NULL,
        text TEXT NOT NULL,
        book_name TEXT NOT NULL,
        book_writer TEXT NOT NULL,
        date TEXT NOT NULL,
        image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(sentence_id)
      )
    ''');
    print('Sentences table created');

    // 테이블이 제대로 생성되었는지 확인
    final tables = db.select("SELECT name FROM sqlite_master WHERE type='table'");
    print('Created tables: ${tables.map((t) => t['name']).join(', ')}');
    
    // 데이터베이스 파일이 실제로 생성되었는지 확인
    if (await dbFile.exists()) {
      print('Database file created successfully at: ${dbFile.path}');
      print('File size: ${await dbFile.length()} bytes');
    } else {
      print('Warning: Database file was not created!');
    }
    
    return db;
  }

  /// 이미지 정보를 저장합니다.
  static Future<int> saveImage(String imagePath, String textContent) async {
    final db = await database;
    db.execute(
      'INSERT INTO images (image_path, text_content) VALUES (?, ?)',
      [imagePath, textContent]
    );
    // 마지막으로 삽입된 ID 가져오기
    final result = db.select('SELECT last_insert_rowid() as id');
    return result.first['id'] as int;
  }

  /// 문장을 저장합니다.
  static Future<String> saveSentence({
    required String sentenceId,
    required String text,
    required String bookName,
    required String bookWriter,
    required String date,
    String? imageUrl,
  }) async {
    final db = await database;
    try {
      // 테이블 존재 여부 확인
      final tables = db.select("SELECT name FROM sqlite_master WHERE type='table' AND name='sentences'");
      if (tables.isEmpty) {
        throw Exception('sentences table does not exist');
      }

      print('Saving sentence with ID: $sentenceId');
      db.execute(
        '''
        INSERT INTO sentences (
          sentence_id, text, book_name, book_writer, date, image_url
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [sentenceId, text, bookName, bookWriter, date, imageUrl]
      );
      print('Sentence saved successfully');
      return sentenceId;
    } catch (e) {
      print('Error saving sentence: $e');
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Sentence with ID $sentenceId already exists');
      }
      rethrow;
    }
  }

  /// 모든 이미지 정보를 가져옵니다.
  static Future<List<Map<String, dynamic>>> getAllImages() async {
    final db = await database;
    final result = db.select('SELECT * FROM images ORDER BY created_at DESC');
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// 특정 이미지 정보를 가져옵니다.
  static Future<Map<String, dynamic>?> getImage(int id) async {
    final db = await database;
    final result = db.select('SELECT * FROM images WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return Map<String, dynamic>.from(result.first);
  }

  /// 이미지 정보를 삭제합니다.
  static Future<void> deleteImage(int id) async {
    final db = await database;
    db.execute('DELETE FROM images WHERE id = ?', [id]);
  }

  /// 데이터베이스 연결을 닫습니다.
  static Future<void> close() async {
    if (_database != null) {
      _database!.dispose();
      _database = null;
    }
  }
} 