// lib/ui/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/history_entry.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepositoryImpl _repo = HistoryRepositoryImpl();
  List<HistoryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await _repo.getAllEntries();
    setState(() {
      _entries = list;
      _isLoading = false;
    });
  }

  Future<void> _exportCsv() async {
    final csvData = await _repo.exportToCsv();
    await Share.share(csvData, subject: 'lemon_leaf_scan_history.csv');
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All History?'),
        content: const Text('This will permanently delete all local analysis records. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteAllEntries();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if (_entries.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Export CSV',
              onPressed: _exportCsv,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All',
              onPressed: _deleteAll,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      const Text(
                        'No Scans Yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Analyzed leaves will appear here offline in local SQLite.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final item = _entries[index];
                    return _buildHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(HistoryEntry entry) {
    final isAccepted = entry.status == 'accepted';
    final isAbstained = entry.status == 'abstained';

    Color statusColor;
    IconData statusIcon;
    String statusTitle;

    if (isAccepted) {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle_outline;
      statusTitle = kClassDisplayNames[entry.predictedClass] ?? (entry.predictedClass ?? 'Accepted');
    } else if (isAbstained) {
      statusColor = Colors.amber.shade800;
      statusIcon = Icons.help_outline;
      statusTitle = 'Uncertain (Abstained)';
    } else {
      statusColor = Colors.red.shade700;
      statusIcon = Icons.highlight_off;
      statusTitle = 'Quality Rejected';
    }

    return Dismissible(
      key: Key('hist_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        if (entry.id != null) {
          await _repo.deleteEntry(entry.id!);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Icon(statusIcon, color: statusColor),
          ),
          title: Text(
            statusTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                entry.timestamp.toLocal().toString().substring(0, 16),
                style: const TextStyle(fontSize: 12),
              ),
              if (entry.probability != null)
                Text(
                  'Confidence: ${(entry.probability! * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () async {
              if (entry.id != null) {
                await _repo.deleteEntry(entry.id!);
                await _loadHistory();
              }
            },
          ),
        ),
      ),
    );
  }
}

