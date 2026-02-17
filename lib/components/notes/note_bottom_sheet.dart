import 'package:flutter/material.dart';
import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/models/note_item.dart';

class NoteBottomSheet {
  /// Usage:
  /// NoteBottomSheet.open(
  ///   context: context,
  ///   basePath: "/v1/ebooks/.../contents/$contentId",
  /// );
  static void open({
    required BuildContext context,
    required String basePath, // .../contents/{contentId}
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _NoteSheetWidget(basePath: basePath),
    );
  }
}

class _NoteSheetWidget extends StatefulWidget {
  final String basePath;

  const _NoteSheetWidget({required this.basePath});

  @override
  State<_NoteSheetWidget> createState() => _NoteSheetWidgetState();
}

class _NoteSheetWidgetState extends State<_NoteSheetWidget> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = true;
  List<NoteItem> _notes = [];
  int? _editingId; // null => create, else edit

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final mon = months[d.month - 1];
    return "$day $mon ${d.year}";
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final endpoint = "${widget.basePath}/notes";
      final data = await api.fetchEbookData(endpoint);

      _notes = (data['notes'] as List? ?? [])
          .map((e) => NoteItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);

    try {
      final api = ApiService();

      if (_editingId == null) {
        // create
        final endpoint = "${widget.basePath}/save";
        await api.postData(endpoint, {'text': text});
      } else {
        // edit
        final endpoint = "${widget.basePath}/notes/$_editingId/edit";
        await api.postData(endpoint, {'text': text});
      }

      _editingId = null;
      _controller.clear();

      await _fetch();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('আপনি কি নিশ্চিত এই নোটটি ডিলিট করতে চান?'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return result == true;
  }



  Future<void> _delete(int noteId) async {
    final ok = await _confirmDelete();
    if (!ok) return;
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final endpoint = "${widget.basePath}/notes/$noteId/delete";
      await api.deleteData(endpoint);
      await _fetch();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _startEdit(NoteItem n) {
    setState(() {
      _editingId = n.id;
      _controller.text = n.noteDetail;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_loading && _controller.text.trim().isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 10),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Text(
                      'Note',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  children: [
                    if (_editingId != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Editing note…',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: _cancelEdit,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),

                    // Input
                    TextField(
                      controller: _controller,
                      minLines: 3,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Write Your Note Here ...',
                        filled: true,
                        fillColor: const Color(0xFFF6F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Save button
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: canSave ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B7A2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _editingId == null ? 'Save' : 'Update',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // List header
                    Row(
                      children: [
                        Text(
                          'Note List: ${_notes.length}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        if (!_loading && _notes.isNotEmpty)
                          Text(
                            'Scroll ↓',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // List content
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_notes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: Text(
                            'No notes yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._notes.map((n) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFEDEFF5)),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(n.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                n.noteDetail,
                                style: const TextStyle(fontSize: 15, height: 1.35),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () => _startEdit(n),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: () => _delete(n.id),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 70),
                  ],
                ),
              ),

              // Sticky close
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, -2))
                  ],
                ),
                child: SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
