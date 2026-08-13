import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/prediction_history_record.dart';
import '../services/prediction_history_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _green = Color(0xFF1B5E20);
  final PredictionHistoryService _historyService = PredictionHistoryService();

  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> _confirmClearHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently remove all saved prediction history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    try {
      await _historyService.clearHistory();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to clear prediction history.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _green,
        elevation: 0,
        title: const Text(
          'Prediction History',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_isSignedIn)
            IconButton(
              tooltip: 'Clear History',
              onPressed: _confirmClearHistory,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: _isSignedIn ? _historyBody() : _signedOutBody(),
      ),
    );
  }

  Widget _signedOutBody() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Please sign in to see your prediction history.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _historyBody() {
    return StreamBuilder<List<PredictionHistoryRecord>>(
      stream: _historyService.watchHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load history. Please try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!;
        if (records.isEmpty) return _emptyHistory();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          itemCount: records.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _PredictionHistoryCard(
            record: records[index],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ResultScreen(
                  totalImages: records[index].totalImages,
                  damagedCount: records[index].damagedCount,
                  oldCount: records[index].oldCount,
                  ripeCount: records[index].ripeCount,
                  unripeCount: records[index].unripeCount,
                  overallClass: records[index].overallCondition,
                  overallConfidence: records[index].confidence,
                  shelfLife: records[index].shelfLife,
                  spoilageRisk: records[index].spoilageRisk,
                  recommendation: records[index].recommendation,
                  recordedAt: records[index].createdAt,
                  location: records[index].location,
                  temperature: records[index].temperature,
                  humidity: records[index].humidity,
                  reminderKey: records[index].documentId ??
                      'batch_${records[index].createdAt.millisecondsSinceEpoch}',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyHistory() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 84, color: _green),
            SizedBox(height: 20),
            Text(
              'No predictions yet. Your completed predictions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionHistoryCard extends StatelessWidget {
  const _PredictionHistoryCard({required this.record, required this.onTap});

  final PredictionHistoryRecord record;
  final VoidCallback onTap;

  Color get _riskColor {
    switch (record.spoilageRisk.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return const Color(0xFF1B5E20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDateTime(record.createdAt),
                      style: const TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ),
                  _RiskBadge(risk: record.spoilageRisk, color: _riskColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                record.overallCondition,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${record.totalImages} tomato image${record.totalImages == 1 ? '' : 's'} analyzed',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 14),
              Text(
                'Damaged ${record.damagedCount}  •  Old ${record.oldCount}  •  Ripe ${record.ripeCount}  •  Unripe ${record.unripeCount}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year} • $hour:$minute';
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk, required this.color});

  final String risk;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        risk.toUpperCase(),
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}
