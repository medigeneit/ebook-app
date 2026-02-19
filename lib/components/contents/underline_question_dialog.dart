import 'dart:ui' show TextRange;

import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/utils/token_store.dart';
import 'package:flutter/material.dart';

/// Underline Question Title
///
/// - Text select করে U চাপলে ওই অংশ underline হবে
/// - যদি আগেই underline থাকে, আবার U চাপলে underline remove হবে (toggle)
/// - Save চাপলে HTML (<u>...</u>) আকারে /underline API তে যাবে
///
/// NOTE: TextField read-only রাখা হয়েছে যাতে text edit না হয় (range stable থাকে)

class UnderlineQuestionDialog {
  static Future<String?> open({
    required BuildContext context,
    required String basePath,
    required String titleHtmlOrText,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _UnderlineQuestionDialogBody(
        basePath: basePath,
        titleHtmlOrText: titleHtmlOrText,
      ),
    );
  }
}

class _UnderlineQuestionDialogBody extends StatefulWidget {
  final String basePath;
  final String titleHtmlOrText;

  const _UnderlineQuestionDialogBody({
    required this.basePath,
    required this.titleHtmlOrText,
  });

  @override
  State<_UnderlineQuestionDialogBody> createState() =>
      _UnderlineQuestionDialogBodyState();
}

class _UnderlineQuestionDialogBodyState
    extends State<_UnderlineQuestionDialogBody> {
  late final UnderlineTextController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final parsed = _parseUnderlinedHtml(widget.titleHtmlOrText);
    _controller = UnderlineTextController(
      text: parsed.text,
      underlines: parsed.underlines,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ UNDERLINE TOGGLE
  void _toggleUnderline() {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    if (sel.start == sel.end) return; // কিছু select না করলে কিছু করবে না

    _controller.toggleUnderline(TextRange(start: sel.start, end: sel.end));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final html = _buildHtmlWithUnderlines(
        _controller.text,
        _controller.underlines,
      );

      final api = ApiService();
      var endpoint = '${widget.basePath}/underline';
      endpoint = await TokenStore.attachPracticeToken(endpoint);

      final res = await api.postData(endpoint, {
        'underlinedText': html, // ✅ আপনার backend key
      });

      if (res == null || res['status'] != 'success') {
        throw Exception((res?['message'] ?? 'Underline save failed').toString());
      }

      if (!mounted) return;

      // ✅ modal বন্ধ করে updated html parent এ পাঠিয়ে দিচ্ছি
      Navigator.pop(context, html);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Underline Question',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              readOnly: true,
              enableInteractiveSelection: true,
              minLines: 4,
              maxLines: 7,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF6A39D7),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            height: 44,
            child: OutlinedButton(
              onPressed: _saving ? null : _toggleUnderline, // ✅ toggle এখানে
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'U',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40, // ✅ এখানে button height
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32), // ✅ default min height override
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅ extra space remove
                    visualDensity: VisualDensity.compact, // ✅ আরও compact
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 14,
                    height: 14, // ✅ spinner realistic size
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    'Save',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Controller (partial underline render) ----------------

class UnderlineTextController extends TextEditingController {
  UnderlineTextController({
    super.text,
    List<TextRange>? underlines,
  }) : _underlines = _mergeRanges(underlines ?? const <TextRange>[]);

  List<TextRange> _underlines;

  List<TextRange> get underlines => List.unmodifiable(_underlines);

  /// ✅ toggle underline
  void toggleUnderline(TextRange sel) {
    if (sel.start < 0 || sel.end > text.length) return;
    if (sel.start >= sel.end) return;

    final fully = _isFullyUnderlined(_underlines, sel);

    if (fully) {
      _underlines = _removeFromRanges(_underlines, sel);
    } else {
      _underlines = _mergeRanges([..._underlines, sel]);
    }

    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final t = text;

    if (_underlines.isEmpty || t.isEmpty) {
      return TextSpan(style: base, text: t);
    }

    final children = <TextSpan>[];
    int pos = 0;

    for (final r in _underlines) {
      final start = r.start.clamp(0, t.length);
      final end = r.end.clamp(0, t.length);
      if (start >= end) continue;

      if (start > pos) {
        children.add(TextSpan(text: t.substring(pos, start)));
      }

      children.add(
        TextSpan(
          text: t.substring(start, end),
          style: base.copyWith(decoration: TextDecoration.underline),
        ),
      );

      pos = end;
    }

    if (pos < t.length) {
      children.add(TextSpan(text: t.substring(pos)));
    }

    return TextSpan(style: base, children: children);
  }
}

/// selection কি পুরোটা underline আছে?
bool _isFullyUnderlined(List<TextRange> ranges, TextRange sel) {
  if (ranges.isEmpty) return false;

  final overlaps = <TextRange>[];
  for (final r in ranges) {
    final s = (r.start > sel.start) ? r.start : sel.start;
    final e = (r.end < sel.end) ? r.end : sel.end;
    if (s < e) overlaps.add(TextRange(start: s, end: e));
  }

  if (overlaps.isEmpty) return false;

  final merged = _mergeRanges(overlaps);
  int covered = 0;
  for (final m in merged) {
    covered += (m.end - m.start);
  }

  return covered >= (sel.end - sel.start);
}

/// underline list থেকে selection অংশ কেটে ফেলো
List<TextRange> _removeFromRanges(List<TextRange> ranges, TextRange sel) {
  if (ranges.isEmpty) return const [];

  final out = <TextRange>[];

  for (final r in ranges) {
    // no overlap
    if (r.end <= sel.start || r.start >= sel.end) {
      out.add(r);
      continue;
    }

    // overlap আছে → left part রাখো
    final leftStart = r.start;
    final leftEnd = sel.start.clamp(r.start, r.end);
    if (leftStart < leftEnd) {
      out.add(TextRange(start: leftStart, end: leftEnd));
    }

    // right part রাখো
    final rightStart = sel.end.clamp(r.start, r.end);
    final rightEnd = r.end;
    if (rightStart < rightEnd) {
      out.add(TextRange(start: rightStart, end: rightEnd));
    }
  }

  return _mergeRanges(out);
}

// ---------------- HTML parse/build helpers ----------------

class _ParsedUnderline {
  final String text;
  final List<TextRange> underlines;

  const _ParsedUnderline({required this.text, required this.underlines});
}

_ParsedUnderline _parseUnderlinedHtml(String html) {
  if (!html.contains('<')) {
    return _ParsedUnderline(text: _decodeEntities(html), underlines: const []);
  }

  final sb = StringBuffer();
  final ranges = <TextRange>[];

  int i = 0;
  int plainIndex = 0;
  int? openStart;

  while (i < html.length) {
    if (html.startsWith('<u', i)) {
      final close = html.indexOf('>', i);
      if (close == -1) break;
      openStart = plainIndex;
      i = close + 1;
      continue;
    }

    if (html.startsWith('</u>', i)) {
      if (openStart != null && openStart < plainIndex) {
        ranges.add(TextRange(start: openStart, end: plainIndex));
      }
      openStart = null;
      i += 4;
      continue;
    }

    if (html[i] == '<') {
      final close = html.indexOf('>', i);
      if (close == -1) {
        i++;
      } else {
        i = close + 1;
      }
      continue;
    }

    if (html[i] == '&') {
      final semi = html.indexOf(';', i);
      if (semi != -1) {
        final ent = html.substring(i, semi + 1);
        final ch = _decodeEntities(ent);
        sb.write(ch);
        plainIndex += ch.length;
        i = semi + 1;
        continue;
      }
    }

    sb.write(html[i]);
    plainIndex++;
    i++;
  }

  final text = sb.toString().trim();
  final merged = _mergeRanges(ranges);
  return _ParsedUnderline(text: text, underlines: merged);
}

String _buildHtmlWithUnderlines(String text, List<TextRange> underlines) {
  final t = text;
  if (t.isEmpty) return '';

  final merged = _mergeRanges(underlines);
  if (merged.isEmpty) return _escapeHtml(t);

  final sb = StringBuffer();
  int pos = 0;

  for (final r in merged) {
    final start = r.start.clamp(0, t.length);
    final end = r.end.clamp(0, t.length);
    if (start >= end) continue;

    if (start > pos) sb.write(_escapeHtml(t.substring(pos, start)));
    sb.write('<u>${_escapeHtml(t.substring(start, end))}</u>');
    pos = end;
  }

  if (pos < t.length) sb.write(_escapeHtml(t.substring(pos)));
  return sb.toString();
}

List<TextRange> _mergeRanges(List<TextRange> input) {
  if (input.isEmpty) return const [];
  final ranges = [...input]..sort((a, b) => a.start.compareTo(b.start));

  final merged = <TextRange>[];
  TextRange cur = ranges.first;

  for (int i = 1; i < ranges.length; i++) {
    final r = ranges[i];
    if (r.start <= cur.end) {
      cur = TextRange(
        start: cur.start,
        end: (r.end > cur.end) ? r.end : cur.end,
      );
    } else {
      merged.add(cur);
      cur = r;
    }
  }
  merged.add(cur);
  return merged;
}

String _escapeHtml(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _decodeEntities(String s) {
  return s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}
