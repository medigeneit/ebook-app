class NoteItem {
  final int id;
  final int questionId;
  final String noteDetail;
  final DateTime? createdAt;

  NoteItem({
    required this.id,
    required this.questionId,
    required this.noteDetail,
    required this.createdAt,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    final raw = json['created_at']?.toString();
    if (raw != null && raw.isNotEmpty) {
      dt = DateTime.tryParse(raw);
    }

    return NoteItem(
      id: (json['id'] ?? 0) is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      questionId: (json['question_id'] ?? 0) is int
          ? json['question_id']
          : int.tryParse('${json['question_id']}') ?? 0,
      noteDetail: (json['note_detail'] ?? '').toString(),
      createdAt: dt,
    );
  }
}
