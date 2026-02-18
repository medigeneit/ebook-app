class SavedContentItem {
  final int ebookId; // product id
  final String ebookTitle;

  final int? subjectId;
  final int? chapterId;
  final int? topicId;
  final int? contentId; // question_id / content_id

  final String subjectTitle;
  final String chapterTitle;
  final String topicTitle;
  final String contentTitle;

  final String noteDetail; // ✅ notes এর জন্য
  final DateTime? createdAt;

  const SavedContentItem({
    required this.ebookId,
    required this.ebookTitle,
    required this.subjectId,
    required this.chapterId,
    required this.topicId,
    required this.contentId,
    required this.subjectTitle,
    required this.chapterTitle,
    required this.topicTitle,
    required this.contentTitle,
    required this.noteDetail,
    required this.createdAt,
  });

  /// ✅ content open করা যাবে কিনা
  bool get canOpenContent {
    return ebookId > 0 &&
        subjectId != null &&
        chapterId != null &&
        topicId != null &&
        contentId != null;
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _asString(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  static DateTime? _asDateTime(dynamic v) {
    final s = _asString(v).trim();
    if (s.isEmpty) return null;

    // ISO parse (2026-02-16T11:49:38.000000Z)
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // "16 Feb 2026" / "16 Feb, 2026"
    final cleaned = s.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = cleaned.split(' ');
    if (parts.length == 3) {
      final dd = int.tryParse(parts[0]) ?? 0;
      final mon = parts[1].toLowerCase();
      final yy = int.tryParse(parts[2]) ?? 0;

      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      final mm = months[mon.substring(0, 3)];
      if (dd > 0 && (mm ?? 0) > 0 && yy > 0) {
        return DateTime(yy, mm!, dd);
      }
    }

    return null;
  }

  factory SavedContentItem.fromJsonFlexible(Map<String, dynamic> json) {
    final subjectObj = (json['subject'] is Map) ? Map<String, dynamic>.from(json['subject']) : null;
    final chapterObj = (json['chapter'] is Map) ? Map<String, dynamic>.from(json['chapter']) : null;
    final topicObj = (json['topic'] is Map) ? Map<String, dynamic>.from(json['topic']) : null;

    final ebookObj = (json['ebook'] is Map) ? Map<String, dynamic>.from(json['ebook']) : null;
    final productObj = (json['product'] is Map) ? Map<String, dynamic>.from(json['product']) : null;

    final ebookId = _asInt(
      json['ebook_id'] ??
          json['book_id'] ??
          json['product_id'] ??
          (productObj?['id']) ??
          (ebookObj?['id']),
    );

    final ebookTitle = _asString(
      json['ebook_title'] ??
          json['book_name'] ??
          json['product_name'] ??
          (productObj?['book_name']) ??
          (ebookObj?['title']) ??
          (ebookObj?['name']) ??
          '',
    );

    final subjectId = _asInt(json['subject_id'] ?? json['ebook_subject_id']);
    final chapterId = _asInt(json['chapter_id'] ?? json['ebook_chapter_id']);
    final topicId = _asInt(json['topic_id'] ?? json['ebook_topic_id']);

    final contentId = _asInt(
      json['content_id'] ??
          json['ebook_content_id'] ??
          json['question_id'] ??
          json['questionId'],
    );

    final subjectTitle = _asString(
      json['subject_title'] ??
          json['subject_name'] ??
          (subjectObj?['subject_name']) ??
          (subjectObj?['name']) ??
          '',
    );

    final chapterTitle = _asString(
      json['chapter_title'] ??
          json['chapter_name'] ??
          (chapterObj?['chapter_name']) ??
          (chapterObj?['name']) ??
          '',
    );

    final topicTitle = _asString(
      json['topic_title'] ??
          json['topic_name'] ??
          (topicObj?['topic_name']) ??
          (topicObj?['name']) ??
          '',
    );

    final noteDetail = _asString(
      json['note_detail'] ??
          json['note'] ??
          json['note_text'] ??
          json['details'] ??
          json['body'] ??
          '',
    );

    String contentTitle = _asString(
      json['content_title'] ?? json['question_title'] ?? json['title'] ?? '',
    ).trim();

    // যদি question_title না আসে—fallback
    if (contentTitle.isEmpty) {
      if (contentId > 0) {
        contentTitle = 'Question #$contentId';
      } else if (noteDetail.trim().isNotEmpty) {
        contentTitle = 'My Note';
      }
    }

    // created_at অনেক সময় non-ISO, তাই updated_at prefer
    final createdAt = _asDateTime(json['updated_at'] ?? json['created_at'] ?? json['createdAt']);

    return SavedContentItem(
      ebookId: ebookId,
      ebookTitle: ebookTitle,
      subjectId: subjectId > 0 ? subjectId : null,
      chapterId: chapterId > 0 ? chapterId : null,
      topicId: topicId > 0 ? topicId : null,
      contentId: contentId > 0 ? contentId : null,
      subjectTitle: subjectTitle,
      chapterTitle: chapterTitle,
      topicTitle: topicTitle,
      contentTitle: contentTitle,
      noteDetail: noteDetail,
      createdAt: createdAt,
    );
  }
}
