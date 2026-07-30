import 'package:diocese_frontend/models/user.dart';

class Note {
  final String? author;
  final String? content;
  final int? authorId;
  final String? timestamp;

  Note({
    this.author,
    this.content,
    this.authorId,
    this.timestamp,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      author: json['author'],
      content: json['content'],
      authorId: json['authorId'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (author != null) 'author': author,
      if (content != null) 'content': content,
      if (authorId != null) 'authorId': authorId,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }

  static Note? fromInput({
    required String text,
    required User? currentUser,
  }) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) return null;

    return Note(
      author: currentUser?.role == 'parishioner' ? 'parishioner' : 'admin',
      content: trimmed,
      authorId: currentUser?.id,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}
