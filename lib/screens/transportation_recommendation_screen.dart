import 'package:flutter/material.dart';
import '../services/app_localizations.dart';

class TransportationRecommendationScreen extends StatefulWidget {
  const TransportationRecommendationScreen({super.key, this.temperature});

  final double? temperature;

  @override
  State<TransportationRecommendationScreen> createState() =>
      _TransportationRecommendationScreenState();
}

class _TransportationRecommendationScreenState
    extends State<TransportationRecommendationScreen> {
  static const _green = Color(0xFF1B5E20);
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _transportType;
  String? _packagingType;
  _TransportRecommendation? _recommendation;

  @override
  void dispose() {
    _distanceController.dispose();
    _durationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _getRecommendation() {
    final distance = double.tryParse(_distanceController.text.trim());
    final duration = double.tryParse(_durationController.text.trim());
    final quantity = double.tryParse(_quantityController.text.trim());

    if (distance == null ||
        distance < 0 ||
        duration == null ||
        duration <= 0 ||
        quantity == null ||
        quantity <= 0 ||
        _transportType == null ||
        _packagingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tr(context, 'transportDistance')}, ${tr(context, 'transportType')}, ${tr(context, 'travelDuration')}, ${tr(context, 'packagingType')} and ${tr(context, 'quantity')} are required.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _recommendation = _TransportRecommendation.create(
        distance: distance,
        duration: duration,
        quantity: quantity,
        temperature: widget.temperature,
        transportType: _transportType!,
        packagingType: _packagingType!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _green,
        title: Text(
          tr(context, 'transportRecommendation'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr(context, 'transportRecommendation'),
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'ruleBasedGuide'),
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _NumberField(
                    controller: _distanceController,
                    label: '${tr(context, 'transportDistance')} *',
                  ),
                  const SizedBox(height: 16),
                  _TransportDropdown(
                    label: '${tr(context, 'transportType')} *',
                    value: _transportType,
                    options: const ['Auto', 'Van', 'Truck', 'Other'],
                    onChanged: (value) =>
                        setState(() => _transportType = value),
                  ),
                  const SizedBox(height: 16),
                  _NumberField(
                    controller: _durationController,
                    label: '${tr(context, 'travelDuration')} *',
                  ),
                  const SizedBox(height: 16),
                  _TransportDropdown(
                    label: '${tr(context, 'packagingType')} *',
                    value: _packagingType,
                    options: const ['Basket', 'Plastic Crate', 'Box', 'Other'],
                    onChanged: (value) =>
                        setState(() => _packagingType = value),
                  ),
                  const SizedBox(height: 16),
                  _NumberField(
                    controller: _quantityController,
                    label: '${tr(context, 'quantity')} *',
                  ),
                  const SizedBox(height: 16),
                  _TemperatureInfo(temperature: widget.temperature),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _getRecommendation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        tr(context, 'getRecommendation'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (_recommendation != null) ...[
                    const SizedBox(height: 24),
                    _RecommendationCard(recommendation: _recommendation!),
                  ],
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(tr(context, 'backToResult')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _TransportDropdown extends StatelessWidget {
  const _TransportDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TemperatureInfo extends StatelessWidget {
  const _TemperatureInfo({required this.temperature});

  final double? temperature;

  @override
  Widget build(BuildContext context) {
    final available = temperature != null;
    return Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.thermostat, color: Color(0xFF1B5E20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                available
                    ? tr(
                        context,
                        'currentTemperatureValue',
                      ).replaceFirst('{temp}', temperature!.toStringAsFixed(1))
                    : tr(context, 'temperatureUnavailableGuide'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final _TransportRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final color = switch (recommendation.risk) {
      'HIGH' => Colors.red,
      'MEDIUM' => Colors.orange,
      _ => const Color(0xFF1B5E20),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                context,
                'transportRiskText',
              ).replaceFirst('{risk}', riskLabel(context, recommendation.risk)),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr(context, 'recommendedActions'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...recommendation.actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $action', style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, 'why'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              recommendation.reason,
              style: const TextStyle(fontSize: 16, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportRecommendation {
  const _TransportRecommendation({
    required this.risk,
    required this.actions,
    required this.reason,
  });

  final String risk;
  final List<String> actions;
  final String reason;

  factory _TransportRecommendation.create({
    required double distance,
    required double duration,
    required double quantity,
    required double? temperature,
    required String transportType,
    required String packagingType,
  }) {
    var score = 0;
    final factors = <String>[];
    final actions = <String>[];

    if (distance >= 250) {
      score += 2;
      factors.add(
        'the long transport distance (${distance.toStringAsFixed(0)} km)',
      );
    } else if (distance >= 100) {
      score++;
      factors.add('the transport distance (${distance.toStringAsFixed(0)} km)');
    }
    if (duration >= 8) {
      score += 2;
      factors.add(
        'the long travel duration (${duration.toStringAsFixed(1)} hours)',
      );
    } else if (duration >= 4) {
      score++;
      factors.add('the travel duration (${duration.toStringAsFixed(1)} hours)');
    }
    if (temperature != null && temperature >= 35) {
      score += 2;
      factors.add(
        'the high temperature (${temperature.toStringAsFixed(1)} °C)',
      );
    } else if (temperature != null && temperature >= 30) {
      score++;
      factors.add(
        'the warm temperature (${temperature.toStringAsFixed(1)} °C)',
      );
    }
    if (packagingType == 'Basket') {
      score += 2;
      factors.add(
        'basket packaging, which gives less protection from bruising',
      );
      actions.add(
        'Use ventilated plastic crates where possible to reduce bruising.',
      );
    } else if (packagingType == 'Other') {
      score++;
      factors.add('an unspecified packaging type');
      actions.add(
        'Use clean, ventilated packaging that protects tomatoes from pressure.',
      );
    } else if (packagingType == 'Box') {
      actions.add('Keep boxes ventilated and avoid over-filling them.');
    }
    if (transportType == 'Other') {
      score++;
      factors.add('an unspecified transport type');
    } else if (transportType == 'Auto' && (distance >= 100 || duration >= 4)) {
      score++;
      factors.add('using an auto for a longer trip');
    }
    if (distance >= 100 || duration >= 4) {
      actions.add(
        'Use a covered, appropriate vehicle and reduce unnecessary delays.',
      );
    }
    if (temperature != null && temperature >= 30) {
      actions.add(
        'Protect tomatoes from direct sunlight and keep the load ventilated.',
      );
    }
    if (quantity >= 100) {
      actions.add(
        'Avoid over-stacking heavy loads and leave space for airflow.',
      );
    }
    actions.add('Handle crates carefully during loading and unloading.');
    if (actions.length < 3) {
      actions.add(
        'Keep tomatoes dry and separate damaged fruits before transport.',
      );
    }

    final risk = score >= 5
        ? 'HIGH'
        : score >= 3
        ? 'MEDIUM'
        : 'LOW';
    final reason = factors.isEmpty
        ? 'The entered distance, duration, packaging and transport type indicate a lower transport risk.'
        : 'Risk is affected by ${factors.join(', ')}.';
    return _TransportRecommendation(
      risk: risk,
      actions: actions.take(5).toList(),
      reason: reason,
    );
  }
}
