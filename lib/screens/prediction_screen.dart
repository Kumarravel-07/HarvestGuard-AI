import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/weather_service.dart';
import '../services/tomato_ai_service.dart';
import '../services/prediction_history_service.dart';
import '../models/prediction_history_record.dart';
import '../services/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  static const _green = Color(0xFF1B5E20);
  final ImagePicker _picker = ImagePicker();
  XFile? _overallImage;
  final List<XFile> _closeUpImages = [];
  String? _storage;
  String? _packaging;
  String? _transport;
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  double? _temperature;
  int? _humidity;
  String? _weatherCondition;
  String? _weatherError;
  bool _isLoadingWeather = false;

  final WeatherService _weatherService = WeatherService();
  final TomatoAiService _tomatoAiService = TomatoAiService();
  final PredictionHistoryService _historyService = PredictionHistoryService();

  bool get _hasRequiredPredictionDetails =>
      _storage != null && _packaging != null && _transport != null;

  bool get _canPredict => _overallImage != null && _closeUpImages.length >= 2;

  void _validateAndOpenResult() {
    if (!_hasRequiredPredictionDetails) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select Storage Type, Packaging Type and Transport Mode before predicting.',
          ),
        ),
      );
      return;
    }

    _openResult();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is unavailable.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = _cityFromPlacemarks(placemarks);
      if (city.isEmpty)
        throw Exception('Unable to identify your current location.');

      _locationController.text = city;
      await _fetchWeatherForCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      _showWeatherUnavailable();
    }
  }

  String _cityFromPlacemarks(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return '';
    final place = placemarks.first;
    for (final value in [
      place.subAdministrativeArea,
      place.locality,
      place.administrativeArea,
    ]) {
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  Future<void> _fetchWeatherForEnteredLocation() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) return;

    try {
      final locations = await locationFromAddress(location);
      if (locations.isEmpty) throw Exception('Location not found.');
      final resolved = locations.first;
      await _fetchWeatherForCoordinates(
        latitude: resolved.latitude,
        longitude: resolved.longitude,
      );
    } catch (_) {
      _showWeatherUnavailable();
    }
  }

  Future<void> _fetchWeatherForCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    if (!mounted) return;
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
      _temperature = null;
      _humidity = null;
      _weatherCondition = null;
    });

    try {
      final weather = await _weatherService.getWeather(latitude, longitude);
      final main = weather?['main'];
      final conditions = weather?['weather'];
      final condition = conditions is List && conditions.isNotEmpty
          ? (conditions.first as Map<String, dynamic>)['main'] as String?
          : null;
      final temperature = main is Map ? main['temp'] : null;
      final humidity = main is Map ? main['humidity'] : null;
      if (temperature is! num || humidity is! num || condition == null) {
        throw Exception('Weather data is unavailable.');
      }

      if (!mounted) return;
      setState(() {
        _temperature = temperature.toDouble();
        _humidity = humidity.toInt();
        _weatherCondition = condition;
        _isLoadingWeather = false;
      });
    } catch (_) {
      _showWeatherUnavailable();
    }
  }

  void _showWeatherUnavailable() {
    if (!mounted) return;
    setState(() {
      _temperature = null;
      _humidity = null;
      _weatherCondition = null;
      _isLoadingWeather = false;
      _weatherError = 'Weather unavailable for this location';
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAiModel();
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus) _fetchWeatherForEnteredLocation();
    });
  }

  Future<void> _loadAiModel() async {
    try {
      await _tomatoAiService.loadModel();
    } catch (e) {
      print('❌ AI model loading failed: $e');
    }
  }

  Future<void> _pickOverall(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null && mounted) setState(() => _overallImage = image);
  }

  Future<void> _addCloseUp(ImageSource source) async {
    if (_closeUpImages.length == 3) return;
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null && mounted) setState(() => _closeUpImages.add(image));
  }

  Future<void> _retakeCloseUp(int index) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null && mounted) setState(() => _closeUpImages[index] = image);
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
          tr(context, 'prediction'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(
                    title: tr(context, 'captureBatch'),
                    description: tr(context, 'captureBatchDescription'),
                  ),
                  const SizedBox(height: 20),
                  _ImageCaptureSection(
                    title: tr(context, 'overallBatchPhoto'),
                    description: tr(context, 'batchPhotoDescription'),
                    image: _overallImage,
                    onCamera: () => _pickOverall(ImageSource.camera),
                    onGallery: () => _pickOverall(ImageSource.gallery),
                    onRemove: () => setState(() => _overallImage = null),
                    onRetake: () => _pickOverall(ImageSource.camera),
                  ),
                  const SizedBox(height: 18),
                  _CloseUpCaptureSection(
                    images: _closeUpImages,
                    onCamera: () => _addCloseUp(ImageSource.camera),
                    onGallery: () => _addCloseUp(ImageSource.gallery),
                    onRemove: (index) =>
                        setState(() => _closeUpImages.removeAt(index)),
                    onRetake: _retakeCloseUp,
                  ),
                  const SizedBox(height: 32),
                  _SectionTitle(title: tr(context, 'storageDetails')),
                  const SizedBox(height: 12),
                  _LargeDropdown(
                    label: tr(context, 'storageType'),
                    isRequired: true,
                    value: _storage,
                    options: const [
                      'Open Storage',
                      'Room Storage',
                      'Cold Storage',
                    ],
                    onChanged: (value) => setState(() => _storage = value),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: tr(context, 'packaging')),
                  const SizedBox(height: 12),
                  _LargeDropdown(
                    label: tr(context, 'packagingType'),
                    isRequired: true,
                    value: _packaging,
                    options: const [
                      'Plastic Crate',
                      'Bamboo Basket',
                      'Gunny Bag',
                      'Carton Box',
                      'Other',
                    ],
                    onChanged: (value) => setState(() => _packaging = value),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: tr(context, 'transport')),
                  const SizedBox(height: 12),
                  _LargeDropdown(
                    label: tr(context, 'transportMode'),
                    isRequired: true,
                    value: _transport,
                    options: const [
                      'Bike',
                      'Auto',
                      'Mini Van',
                      'Truck',
                      'Tractor',
                    ],
                    onChanged: (value) => setState(() => _transport = value),
                  ),
                  const SizedBox(height: 32),
                  _SectionTitle(title: tr(context, 'weather')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _fetchWeatherForEnteredLocation(),
                    decoration: InputDecoration(
                      labelText: tr(context, 'location'),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: _isLoadingWeather
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Use current location',
                              icon: const Icon(Icons.my_location),
                              onPressed: _getCurrentLocation,
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _WeatherCard(
                    icon: Icons.thermostat,
                    label: tr(context, 'temperature'),
                    value: _temperature == null
                        ? '-- °C'
                        : '${_temperature!.toStringAsFixed(1)} °C',
                  ),

                  const SizedBox(height: 12),

                  _WeatherCard(
                    icon: Icons.water_drop,
                    label: tr(context, 'humidity'),
                    value: _humidity == null ? '-- %' : '$_humidity%',
                  ),
                  const SizedBox(height: 12),
                  _WeatherCard(
                    icon: Icons.cloud_outlined,
                    label: tr(context, 'weather'),
                    value: _weatherCondition ?? '--',
                  ),
                  if (_weatherError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _weatherError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 15),
                    ),
                  ],
                  SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _canPredict ? _validateAndOpenResult : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.black54,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 28),
                      label: Text(tr(context, 'predictShelfLife')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    !_canPredict
                        ? 'Add 1 batch photo and at least 2 close-up photos to continue.'
                        : !_hasRequiredPredictionDetails
                        ? 'Select Storage Type, Packaging Type and Transport Mode to continue.'
                        : 'Ready to predict.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openResult() async {
    if (!_hasRequiredPredictionDetails) {
      _validateAndOpenResult();
      return;
    }

    try {
      // Predict the overall batch image
      final overallResult = await _tomatoAiService.predict(_overallImage!.path);

      // Predict each close-up image
      final List<Map<String, dynamic>> closeUpResults = [];

      for (final image in _closeUpImages) {
        final result = await _tomatoAiService.predict(image.path);
        closeUpResults.add(result);
      }

      // Collect all predictions
      final allResults = [overallResult, ...closeUpResults];

      final counts = <String, int>{
        'Damaged': 0,
        'Old': 0,
        'Ripe': 0,
        'Unripe': 0,
      };

      for (final result in allResults) {
        final predictedClass = result['class'] as String;
        counts[predictedClass] = (counts[predictedClass] ?? 0) + 1;
      }

      // Determine the batch condition from actual predictions.
      // Damaged > Old > Unripe > Ripe
      const conditionPriority = ['Damaged', 'Old', 'Unripe', 'Ripe'];
      final finalClass = conditionPriority.firstWhere(
        (condition) => counts[condition]! > 0,
        orElse: () => 'Ripe',
      );

      // Use the strongest confidence among images that produced the
      // batch's overall condition.
      final finalConfidence = allResults
          .where((result) => result['class'] == finalClass)
          .map((result) => result['confidence'] as double)
          .reduce(
            (highest, confidence) =>
                confidence > highest ? confidence : highest,
          );

      // Calculate shelf-life and recommendation
      String shelfLife;
      String risk;
      String recommendation;

      switch (finalClass) {
        case 'Damaged':
          shelfLife = '1–2 Days';
          risk = 'High';
          recommendation =
              'Remove damaged tomatoes immediately. Keep them separate from healthy tomatoes and transport the good tomatoes as soon as possible.';
          break;

        case 'Old':
          shelfLife = '1–2 Days';
          risk = 'High';
          recommendation =
              'Some tomatoes appear old. Remove old tomatoes from the batch and prioritize the remaining good tomatoes for sale or transport.';
          break;

        case 'Unripe':
          shelfLife = '5–7 Days';
          risk = 'Low';
          recommendation =
              'Tomatoes are mostly unripe. Store in a cool, dry and well-ventilated place and avoid direct sunlight.';
          break;

        default:
          shelfLife = '3–5 Days';
          risk = 'Low';
          recommendation =
              'Tomatoes are in good condition. Store at 10–15°C and transport within 2–3 days.';
      }

      final location = _locationController.text.trim();
      final historyRecord = PredictionHistoryRecord(
        createdAt: DateTime.now(),
        cropName: 'Tomato',
        totalImages: allResults.length,
        damagedCount: counts['Damaged']!,
        oldCount: counts['Old']!,
        ripeCount: counts['Ripe']!,
        unripeCount: counts['Unripe']!,
        overallCondition: finalClass,
        confidence: finalConfidence,
        spoilageRisk: risk,
        shelfLife: shelfLife,
        recommendation: recommendation,
        location: location.isEmpty ? null : location,
        temperature: _temperature,
        humidity: _humidity,
      );

      String? historyRecordId;
      try {
        historyRecordId = await _historyService.save(historyRecord);
      } catch (error) {
        // The completed batch result remains available if history storage fails.
        debugPrint('Unable to save prediction history: $error');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            totalImages: allResults.length,
            damagedCount: counts['Damaged']!,
            oldCount: counts['Old']!,
            ripeCount: counts['Ripe']!,
            unripeCount: counts['Unripe']!,
            overallClass: finalClass,
            overallConfidence: finalConfidence,
            shelfLife: shelfLife,
            spoilageRisk: risk,
            recommendation: recommendation,
            recordedAt: historyRecord.createdAt,
            location: historyRecord.location,
            temperature: historyRecord.temperature,
            humidity: historyRecord.humidity,
            reminderKey:
                historyRecordId ??
                'batch_${historyRecord.createdAt.millisecondsSinceEpoch}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI prediction failed: $e')));
    }
  }

  @override
  void dispose() {
    _tomatoAiService.close();
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            style: const TextStyle(fontSize: 18, height: 1.35),
          ),
        ],
      ],
    );
  }
}

class _ImageCaptureSection extends StatelessWidget {
  const _ImageCaptureSection({
    required this.title,
    required this.description,
    required this.image,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    required this.onRetake,
  });

  final String title;
  final String description;
  final XFile? image;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 14),
            if (image == null)
              _ImageActions(onCamera: onCamera, onGallery: onGallery)
            else ...[
              _ImagePreview(image: image!),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRetake,
                      child: Text(tr(context, 'retake')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRemove,
                      child: Text(tr(context, 'remove')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloseUpCaptureSection extends StatelessWidget {
  const _CloseUpCaptureSection({
    required this.images,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    required this.onRetake,
  });

  final List<XFile> images;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onRetake;

  @override
  Widget build(BuildContext context) {
    final canAdd = images.length < 3;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(context, 'closeUpPhotos'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, 'closeUpDescription'),
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 14),
            if (images.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(images.length, (index) {
                  return _CloseUpPreview(
                    image: images[index],
                    onRetake: () => onRetake(index),
                    onRemove: () => onRemove(index),
                  );
                }),
              ),
            if (images.isNotEmpty) const SizedBox(height: 14),
            if (canAdd) _ImageActions(onCamera: onCamera, onGallery: onGallery),
            if (!canAdd)
              Text(
                tr(context, 'closeUpPhotoCountMessage'),
                style: TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImageActions extends StatelessWidget {
  const _ImageActions({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt_outlined, size: 26),
            label: Text(tr(context, 'cameraPhoto')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 26),
            label: Text(tr(context, 'galleryPhoto')),
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image});

  final XFile image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(image.path),
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _CloseUpPreview extends StatelessWidget {
  const _CloseUpPreview({
    required this.image,
    required this.onRetake,
    required this.onRemove,
  });

  final XFile image;
  final VoidCallback onRetake;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(image.path),
              height: 115,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onRetake,
                  child: const Text('Retake'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: onRemove,
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LargeDropdown extends StatelessWidget {
  const _LargeDropdown({
    required this.label,
    this.isRequired = false,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final bool isRequired;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 19, color: Colors.black),
      decoration: InputDecoration(
        label: Text.rich(
          TextSpan(
            text: label,
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : const [],
          ),
        ),
        labelStyle: const TextStyle(fontSize: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: const OutlineInputBorder(),
      ),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _WeatherPlaceholders extends StatelessWidget {
  const _WeatherPlaceholders();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _WeatherCard(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: '-- deg C',
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _WeatherCard(
            icon: Icons.water_drop_outlined,
            label: 'Humidity',
            value: '-- %',
          ),
        ),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1B5E20), size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
