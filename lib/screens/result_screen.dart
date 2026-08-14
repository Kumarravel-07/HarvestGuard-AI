import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/app_localizations.dart';
import 'transportation_recommendation_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.totalImages,
    required this.damagedCount,
    required this.oldCount,
    required this.ripeCount,
    required this.unripeCount,
    required this.overallClass,
    required this.overallConfidence,
    required this.shelfLife,
    required this.spoilageRisk,
    required this.recommendation,
    this.recordedAt,
    this.location,
    this.temperature,
    this.humidity,
    required this.reminderKey,
  });

  final int totalImages;
  final int damagedCount;
  final int oldCount;
  final int ripeCount;
  final int unripeCount;
  final String overallClass;
  final double overallConfidence;
  final String shelfLife;
  final String spoilageRisk;
  final String recommendation;
  final DateTime? recordedAt;
  final String? location;
  final double? temperature;
  final int? humidity;
  final String reminderKey;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  ReminderDetails? _reminder;
  bool _isLoadingReminder = true;
  bool _isSavingReminder = false;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final reminder = await NotificationService.instance.loadReminder(
      widget.reminderKey,
    );
    if (mounted)
      setState(() {
        _reminder = reminder;
        _isLoadingReminder = false;
      });
  }

  List<int> get _reminderDays {
    final matches = RegExp(r'(\d+)\D+(\d+)').firstMatch(widget.shelfLife);
    if (matches == null) return const [1];
    final firstDay = int.parse(matches.group(1)!);
    final lastDay = int.parse(matches.group(2)!);
    final startDay = lastDay <= 2 ? firstDay : 2;
    return List<int>.generate(
      lastDay - startDay + 1,
      (index) => startDay + index,
    );
  }

  Future<void> _selectReminderDay() async {
    final selectedDays = await showDialog<int>(
      context: context,
      builder: (_) =>
          _ReminderDayDialog(days: _reminderDays, shelfLife: widget.shelfLife),
    );

    if (selectedDays != null) await _scheduleReminder(selectedDays);
  }

  Future<void> _scheduleReminder(int selectedDays) async {
    setState(() => _isSavingReminder = true);
    try {
      final permissionGranted = await NotificationService.instance
          .requestAndroidPermission();
      if (!permissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'notificationPermissionNotGranted')),
            ),
          );
        }
        return;
      }
      final reminder = await NotificationService.instance.scheduleReminder(
        batchKey: widget.reminderKey,
        selectedDays: selectedDays,
        shelfLife: widget.shelfLife,
      );
      if (!mounted) return;
      setState(() => _reminder = reminder);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'reminderSetForBatch'))),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'unableSetReminder'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingReminder = false);
    }
  }

  Future<void> _cancelReminder() async {
    setState(() => _isSavingReminder = true);
    try {
      await NotificationService.instance.cancelReminder(widget.reminderKey);
      if (!mounted) return;
      setState(() => _reminder = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'reminderCancelledForBatch'))),
      );
    } finally {
      if (mounted) setState(() => _isSavingReminder = false);
    }
  }

  Color get _riskColor {
    switch (widget.spoilageRisk.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return const Color(0xFF1B5E20);
      default:
        return const Color(0xFF1B5E20);
    }
  }

  int get _affectedCount => widget.damagedCount + widget.oldCount;

  bool get _needsAttention => _affectedCount > 0;

  String get _formattedDateTime {
    if (widget.recordedAt == null) return '';
    final date = widget.recordedAt!.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = widget.totalImages;
    final damagedCount = widget.damagedCount;
    final oldCount = widget.oldCount;
    final ripeCount = widget.ripeCount;
    final unripeCount = widget.unripeCount;
    final overallClass = widget.overallClass;
    final overallConfidence = widget.overallConfidence;
    final shelfLife = widget.shelfLife;
    final spoilageRisk = widget.spoilageRisk;
    final recommendation = widget.recommendation;
    final recordedAt = widget.recordedAt;
    final location = widget.location;
    final temperature = widget.temperature;
    final humidity = widget.humidity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        title: Text(
          tr(context, 'predictionResult'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFF1B5E20),
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr(context, 'batchAnalysis'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI $totalImages ${tr(context, 'tomato')} ${tr(context, 'batchAnalysis')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17),
                      ),
                      const SizedBox(height: 24),
                      _ResultValue(
                        label: tr(context, 'overallCondition'),
                        value: overallClass,
                      ),
                      _ResultValue(
                        label: tr(context, 'confidence'),
                        value: '${overallConfidence.toStringAsFixed(1)}%',
                      ),
                      _ConditionDistributionChart(
                        damagedCount: damagedCount,
                        oldCount: oldCount,
                        ripeCount: ripeCount,
                        unripeCount: unripeCount,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        tr(context, 'conditionSummary'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ConditionCount(
                        icon: '🔴',
                        label: tr(context, 'damaged'),
                        count: damagedCount,
                      ),
                      _ConditionCount(
                        icon: '🟠',
                        label: tr(context, 'old'),
                        count: oldCount,
                      ),
                      _ConditionCount(
                        icon: '🟢',
                        label: tr(context, 'ripe'),
                        count: ripeCount,
                      ),
                      _ConditionCount(
                        icon: '🟡',
                        label: tr(context, 'unripe'),
                        count: unripeCount,
                      ),
                      const SizedBox(height: 18),
                      _ResultValue(
                        label: tr(context, 'spoilageRisk'),
                        value: spoilageRisk.toUpperCase(),
                        valueColor: _riskColor,
                      ),
                      _ResultValue(
                        label: tr(context, 'estimatedShelfLife'),
                        value: shelfLife,
                      ),
                      _ShelfLifeReminder(
                        shelfLife: shelfLife,
                        reminder: _reminder,
                        isLoading: _isLoadingReminder,
                        isSaving: _isSavingReminder,
                        onSetReminder: _selectReminderDay,
                        onCancelReminder: _cancelReminder,
                      ),
                      _ResultValue(
                        label: tr(context, 'recommendedAction'),
                        value: recommendation,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TransportationRecommendationScreen(
                                    temperature: temperature,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: Text(tr(context, 'checkTransport')),
                      ),
                      if (recordedAt != null) ...[
                        _ResultValue(
                          label: tr(context, 'dateTime'),
                          value: _formattedDateTime,
                        ),
                        if (location != null)
                          _ResultValue(
                            label: tr(context, 'location'),
                            value: location!,
                          ),
                        if (temperature != null)
                          _ResultValue(
                            label: tr(context, 'temperature'),
                            value: '${temperature!.toStringAsFixed(1)} °C',
                          ),
                        if (humidity != null)
                          _ResultValue(
                            label: tr(context, 'humidity'),
                            value: '$humidity%',
                          ),
                      ],
                      _AttentionCard(
                        needsAttention: _needsAttention,
                        affectedCount: _affectedCount,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            tr(context, 'back'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderDayDialog extends StatefulWidget {
  const _ReminderDayDialog({required this.days, required this.shelfLife});

  final List<int> days;
  final String shelfLife;

  @override
  State<_ReminderDayDialog> createState() => _ReminderDayDialogState();
}

class _ReminderDayDialogState extends State<_ReminderDayDialog> {
  late int _selectedDay = widget.days.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr(context, 'checkTomatoBatchAfter')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${tr(context, 'estimatedShelfLife')}: ${widget.shelfLife}'),
          const SizedBox(height: 8),
          ...widget.days.map(
            (days) => RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              value: days,
              groupValue: _selectedDay,
              title: Text(
                '$days ${days == 1 ? tr(context, 'dayLabel') : tr(context, 'daysLabel')}',
              ),
              onChanged: (value) => setState(() => _selectedDay = value!),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr(context, 'cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedDay),
          child: Text(tr(context, 'setReminder')),
        ),
      ],
    );
  }
}

class _ShelfLifeReminder extends StatelessWidget {
  const _ShelfLifeReminder({
    required this.shelfLife,
    required this.reminder,
    required this.isLoading,
    required this.isSaving,
    required this.onSetReminder,
    required this.onCancelReminder,
  });

  final String shelfLife;
  final ReminderDetails? reminder;
  final bool isLoading;
  final bool isSaving;
  final VoidCallback onSetReminder;
  final VoidCallback onCancelReminder;

  String _reminderText(BuildContext context) {
    if (reminder == null) return '';
    if (reminder!.selectedDays == 1) return tr(context, 'reminderTomorrow');
    return tr(
      context,
      'reminderInDays',
    ).replaceFirst('{days}', '${reminder!.selectedDays}');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE8F5E9),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 8),
                Text(
                  tr(context, 'setReminder'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${tr(context, 'estimatedShelfLife')}: $shelfLife'),
            const SizedBox(height: 12),
            if (isLoading || isSaving)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1B5E20),
                ),
              )
            else if (reminder != null) ...[
              Text(
                tr(context, 'reminderSet'),
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(_reminderText(context)),
              TextButton.icon(
                onPressed: onCancelReminder,
                icon: const Icon(Icons.notifications_off_outlined),
                label: Text(tr(context, 'cancelReminder')),
              ),
            ] else
              OutlinedButton.icon(
                onPressed: onSetReminder,
                icon: const Icon(Icons.notifications_outlined),
                label: Text(tr(context, 'setReminder')),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConditionDistributionChart extends StatelessWidget {
  const _ConditionDistributionChart({
    required this.damagedCount,
    required this.oldCount,
    required this.ripeCount,
    required this.unripeCount,
  });

  final int damagedCount;
  final int oldCount;
  final int ripeCount;
  final int unripeCount;

  @override
  Widget build(BuildContext context) {
    final highestCount = [
      damagedCount,
      oldCount,
      ripeCount,
      unripeCount,
    ].reduce((highest, count) => count > highest ? count : highest);
    final chartMaximum = highestCount == 0 ? 1 : highestCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'conditionDistribution'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _DistributionBar(
          label: tr(context, 'damaged'),
          count: damagedCount,
          maximum: chartMaximum,
          color: Colors.red,
        ),
        _DistributionBar(
          label: tr(context, 'old'),
          count: oldCount,
          maximum: chartMaximum,
          color: Colors.orange,
        ),
        _DistributionBar(
          label: tr(context, 'ripe'),
          count: ripeCount,
          maximum: chartMaximum,
          color: const Color(0xFF1B5E20),
        ),
        _DistributionBar(
          label: tr(context, 'unripe'),
          count: unripeCount,
          maximum: chartMaximum,
          color: Colors.amber.shade800,
        ),
      ],
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.label,
    required this.count,
    required this.maximum,
    required this.color,
  });

  final String label;
  final int count;
  final int maximum;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: count / maximum,
                minHeight: 12,
                backgroundColor: color.withOpacity(0.16),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 22,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultValue extends StatelessWidget {
  const _ResultValue({
    required this.label,
    required this.value,
    this.valueColor = Colors.black,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionCount extends StatelessWidget {
  const _ConditionCount({
    required this.icon,
    required this.label,
    required this.count,
  });

  final String icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 17)),
          const Spacer(),
          Text(
            '$count',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.needsAttention,
    required this.affectedCount,
  });

  final bool needsAttention;
  final int affectedCount;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = needsAttention
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFE8F5E9);
    final iconColor = needsAttention
        ? Colors.deepOrange
        : const Color(0xFF1B5E20);

    return Card(
      color: backgroundColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              needsAttention
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color: iconColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    needsAttention
                        ? tr(context, 'attentionRequired')
                        : tr(context, 'batchAnalysis'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    needsAttention
                        ? tr(context, 'tomatoRiskWarning')
                              .replaceFirst('{count}', '$affectedCount')
                              .replaceFirst(
                                '{item}',
                                affectedCount == 1
                                    ? tr(context, 'tomatoAppears')
                                    : tr(context, 'tomatoesAppear'),
                              )
                        : tr(context, 'batchGoodCondition'),
                    style: const TextStyle(fontSize: 16, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
