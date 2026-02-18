class SavedContentItem {
  final int ebookId;
  final String ebookTitle;

  final int? subjectId;
  final int? chapterId;
  final int? topicId;
  final int? contentId; // question_id/content_id

  final String subjectTitle;
  final String chapterTitle;
  final String topicTitle;
  final String contentTitle;

  // ✅ Notes এর জন্য
  final String noteDetail;

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

  /// ✅ saved_contents_list_page.dart এ এটা লাগে
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

  static String _excerpt(String s, {int max = 60}) {
    final t = s.trim();
    if (t.isEmpty) return '';
    if (t.length <= max) return t;
    return '${t.substring(0, max)}...';
  }

  static DateTime? _asDateTime(dynamic v) {
    final s = _asString(v).trim();
    if (s.isEmpty) return null;

    // 1) ISO (2026-02-16T11:49:38.000000Z) টাইপ
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // 2) "16 Feb 2026" টাইপ (তোমার notes response)
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]) ?? 0;
      final monStr = parts[1].toLowerCase();
      final year = int.tryParse(parts[2]) ?? 0;

      final monthMap = <String, int>{
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'sept': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      final month = monthMap[monStr] ?? 0;
      if (day > 0 && month > 0 && year > 0) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  /// ✅ Flexible parser: backend keys change হলেও কাজ করবে
  factory SavedContentItem.fromJsonFlexible(Map<String, dynamic> json) {
    final contentObj =
    (json['content'] is Map) ? Map<String, dynamic>.from(json['content']) : null;

    final ebookObj =
    (json['ebook'] is Map) ? Map<String, dynamic>.from(json['ebook']) : null;

    // notes nested objects
    final subjectObj =
    (json['subject'] is Map) ? Map<String, dynamic>.from(json['subject']) : null;
    final chapterObj =
    (json['chapter'] is Map) ? Map<String, dynamic>.from(json['chapter']) : null;
    final topicObj =
    (json['topic'] is Map) ? Map<String, dynamic>.from(json['topic']) : null;

    // ebook/product id
    final ebookId = _asInt(
      json['ebook_id'] ??
          json['book_id'] ?? // ✅ notes row
          json['softcopy_id'] ??
          json['softcopyId'] ??
          json['product_id'] ??
          json['productId'] ??
          (ebookObj?['id']),
    );

    final productObj =
    (json['product'] is Map) ? Map<String, dynamic>.from(json['product']) : null;

    final ebookTitle = _asString(
      json['ebook_title'] ??
          json['ebook_name'] ??
          json['ebookName'] ??
          json['product_name'] ??
          (productObj?['book_name'] ?? productObj?['name']) ??
          (ebookObj?['name']) ??
          (ebookObj?['title']) ??
          '',
    );

    // ids
    final subjectId = _asInt(
      json['subject_id'] ??
          json['ebook_subject_id'] ??
          (contentObj?['subject_id']),
    );
    final chapterId = _asInt(
      json['chapter_id'] ??
          json['ebook_chapter_id'] ??
          (contentObj?['chapter_id']),
    );
    final topicId = _asInt(
      json['topic_id'] ??
          json['ebook_topic_id'] ??
          (contentObj?['topic_id']),
    );

    // content/question id
    final contentId = _asInt(
      json['content_id'] ??
          json['ebook_content_id'] ??
          json['question_id'] ?? // ✅ notes/bookmarks/flags
          (contentObj?['id']),
    );

    // titles (✅ notes nested keys included)
    final subjectTitle = _asString(
      json['subject_title'] ??
          (subjectObj?['subject_name']) ?? // ✅ notes response
          json['subject'] ??
          (contentObj?['subject_title']) ??
          '',
    );

    final chapterTitle = _asString(
      json['chapter_title'] ??
          (chapterObj?['chapter_name']) ?? // ✅ notes response
          json['chapter'] ??
          (contentObj?['chapter_title']) ??
          '',
    );

    final topicTitle = _asString(
      json['topic_title'] ??
          (topicObj?['topic_name']) ?? // ✅ notes response
          json['topic'] ??
          (contentObj?['topic_title']) ??
          '',
    );

    // ✅ Notes text
    final noteText = _asString(
      json['note_detail'] ??
          json['note'] ??
          json['note_text'] ??
          json['note_body'] ??
          json['details'] ??
          json['body'] ??
          json['description'] ??
          '',
    );

    // contentTitle (bookmark/flag এ question_title থাকবে)
    final rawContentTitle = _asString(
      json['content_title'] ??
          json['question_title'] ??
          json['title'] ??
          (contentObj?['title']) ??
          '',
    );

    final finalContentTitle = rawContentTitle.trim().isNotEmpty
        ? rawContentTitle
        : (noteText.trim().isNotEmpty
        ? _excerpt(noteText)
        : (contentId > 0 ? 'Question #$contentId' : ''));

    final createdAt = _asDateTime(json['created_at'] ?? json['createdAt']);

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
      contentTitle: finalContentTitle,
      noteDetail: noteText,
      createdAt: createdAt,
    );
  }
}
