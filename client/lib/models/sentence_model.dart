class Sentence {
  final int id;
  final String sentenceId;
  final String text;
  final String bookName;
  final String bookWriter;
  final String date;
  final String? imageUrl;
  final String createdAt;

  Sentence({
    required this.id,
    required this.sentenceId,
    required this.text,
    required this.bookName,
    required this.bookWriter,
    required this.date,
    this.imageUrl,
    required this.createdAt,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    // Handle both string and integer IDs
    final dynamic idValue = json['id'];
    final int id = idValue is int ? idValue : int.tryParse(idValue.toString()) ?? 0;
    
    // Handle null or missing fields with default values
    return Sentence(
      id: id,
      sentenceId: (json['sentence_id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      bookName: (json['book_name'] ?? '알 수 없음').toString(),
      bookWriter: (json['book_writer'] ?? '알 수 없음').toString(),
      date: (json['date'] ?? DateTime.now().toIso8601String()).toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: (json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
    );
  }
}
