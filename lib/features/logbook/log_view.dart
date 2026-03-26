// log_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/access_control_service.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class LogView extends StatefulWidget {
  final dynamic currentUser;

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;

  bool _isLoading = true;
  bool _isOffline = false;

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();

    _controller = LogController();
    _initDatabase();
    _controller.startAutoSync(widget.currentUser['teamId']);
  }

  /// ===============================
  /// INIT DATABASE
  /// ===============================
  Future<void> _initDatabase() async {
    await _controller.loadLogs(widget.currentUser['teamId']);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ===============================
  /// NAVIGATE TO EDITOR
  /// ===============================
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  /// ===============================
  /// LOGOUT CONFIRM
  /// ===============================
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const OnboardingView()),
                (route) => false,
              );

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Berhasil logout")));
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// DELETE CONFIRM
  /// ===============================
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan"),
        content: const Text("Apakah Anda yakin ingin menghapus catatan ini?"),
        actions: [
          TextButton(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus"),
            onPressed: () {
              Navigator.pop(context);

              _controller.removeLog(index);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Catatan berhasil dihapus")),
              );
            },
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// CATEGORY COLOR
  /// ===============================
  Color _getCategoryColor(String category) {
    switch (category) {
      default:
        return Colors.green.shade100;
    }
  }

  /// ===============================
  /// HUMAN FRIENDLY DATE
  /// ===============================
  String _formatDate(String dateString) {

    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return "Baru saja";
    }

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} menit lalu";
    }

    if (diff.inHours < 24) {
      return "${diff.inHours} jam lalu";
    }

    if (diff.inDays == 1) {
      return "Kemarin";
    }

    if (diff.inDays < 7) {
      return "${diff.inDays} hari lalu";
    }

    return DateFormat("dd MMM yyyy", "id_ID").format(date);

  }

  /// ===============================
  /// EMPTY STATE
  /// ===============================
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            "Belum ada catatan.\nYuk buat catatan pertama!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// BUILD BODY
  /// ===============================
  Widget _buildBody() {
    return ValueListenableBuilder<List<LogModel>>(
      valueListenable: _controller.logsNotifier,
      builder: (context, logs, child) {
        final filteredLogs = logs.where((log) {
          return log.title.toLowerCase().contains(_searchQuery) ||
              log.description.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredLogs.isEmpty) {
          return _buildEmptyState();
        }

        return ValueListenableBuilder<bool>(
          valueListenable: _controller.isOfflineNotifier,
          builder: (context, isOffline, _) {
            return Column(
              children: [
                /// OFFLINE BANNER
                if (isOffline)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade100,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      "Offline Mode Aktif - Data mungkin tidak sinkron.",
                      textAlign: TextAlign.center,
                    ),
                  ),

                /// SEARCH
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Cari Catatan...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                /// LIST
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _controller.syncPendingLogs();
                      await _controller.loadLogs(widget.currentUser['teamId']);
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];

                        final bool isOwner =
                            log.authorId == widget.currentUser['uid'];

                        return Card(
                          color: _getCategoryColor("Pribadi"),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            /// SYNC STATUS ICON
                            leading: Icon(
                              log.isSynced
                                  ? Icons.cloud_done
                                  : Icons.cloud_upload_outlined,
                              color: log.isSynced
                                  ? Colors.green
                                  : Colors.orange,
                            ),

                            ///  TITLE
                            title: Text(log.title),

                            /// DESCRIPTION + DATE (FIX OVERFLOW)
                            subtitle: Text(
                              "${log.description}\n${_formatDate(log.date)}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            /// ACTIONS (RBAC)
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// EDIT
                                if (AccessControlService.canPerform(
                                  widget.currentUser['role'],
                                  AccessControlService.actionUpdate,
                                  isOwner: isOwner,
                                ))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _goToEditor(log: log, index: index),
                                  ),

                                /// DELETE
                                if (AccessControlService.canPerform(
                                  widget.currentUser['role'],
                                  AccessControlService.actionDelete,
                                  isOwner: isOwner,
                                ))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      final realIndex = _controller
                                          .logsNotifier
                                          .value
                                          .indexOf(log);

                                      _confirmDelete(realIndex);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ===============================
  /// BUILD
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.currentUser['username']}"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke MongoDB Atlas..."),
                ],
              ),
            )
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }
}
