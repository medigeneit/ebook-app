class SavedContentItem {
  final int ebookId;
  final String ebookTitle;

  final int? subjectId;
  final int? chapterId;
  final int? topicId;
  final int? contentId;

  final String subjectTitle;
  final String chapterTitle;
  final String topicTitle;
  final String contentTitle;

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

  static DateTime? _asDateTime(dynamic v) {
    final s = _asString(v).trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  /// ✅ Flexible parser: backend keys change হলেও কাজ করবে
  factory SavedContentItem.fromJsonFlexible(Map<String, dynamic> json) {
    final contentObj =
    (json['content'] is Map) ? Map<String, dynamic>.from(json['content']) : null;

    final ebookObj =
    (json['ebook'] is Map) ? Map<String, dynamic>.from(json['ebook']) : null;

    // ebook/product id
    final ebookId = _asInt(
      json['ebook_id'] ??
          json['softcopy_id'] ??
          json['softcopyId'] ??
          json['product_id'] ??
          json['productId'] ??
          (ebookObj?['id']),
    );

    final ebookTitle = _asString(
      json['ebook_title'] ??
          json['ebook_name'] ??
          json['ebookName'] ??
          json['product_name'] ??
          json['product'] ??
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
          json['question_id'] ??
          (contentObj?['id']),
    );

    // titles
    final subjectTitle = _asString(
      json['subject_title'] ??
          json['subject'] ??
          (contentObj?['subject_title']) ??
          '',
    );
    final chapterTitle = _asString(
      json['chapter_title'] ??
          json['chapter'] ??
          (contentObj?['chapter_title']) ??
          '',
    );
    final topicTitle = _asString(
      json['topic_title'] ??
          json['topic'] ??
          (contentObj?['topic_title']) ??
          '',
    );
    final contentTitle = _asString(
      json['content_title'] ??
          json['question_title'] ??
          json['title'] ??
          (contentObj?['title']) ??
          '',
    );

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
      contentTitle: contentTitle,
      createdAt: createdAt,
    );
  }
}
