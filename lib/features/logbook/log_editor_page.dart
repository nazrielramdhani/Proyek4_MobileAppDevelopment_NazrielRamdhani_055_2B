// log_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

bool _isSaving = false;
class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.log?.title ?? "");

    _descController = TextEditingController(
      text: widget.log?.description ?? "",
    );

    /// Listener agar preview otomatis update
    _descController.addListener(() {
      setState(() {});
    });
  }

  /// =========================
  /// SAVE LOG
  /// =========================
  Future<void> _save() async {
    if (_isSaving) return; 

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan isi tidak boleh kosong")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.log == null) {
        /// =========================
        /// CREATE
        /// =========================
        await widget.controller.addLog(
          title,
          desc,
          widget.currentUser['uid'],
          widget.currentUser['teamId'],
        );
      } else {
        /// =========================
        /// UPDATE
        /// =========================
        await widget.controller.updateLog(
          widget.index!,
          title,
          desc,
          widget.currentUser['uid'],
          widget.currentUser['teamId'],
        );
      }

      /// TAMPILKAN FEEDBACK
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Catatan berhasil disimpan")),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      /// ERROR HANDLING
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan catatan")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            /// =========================
            /// TAB EDITOR
            /// =========================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      expands: true,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan menggunakan Markdown...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// =========================
            /// TAB PREVIEW MARKDOWN
            /// =========================
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(data: _descController.text),
            ),
          ],
        ),
      ),
    );
  }
}
