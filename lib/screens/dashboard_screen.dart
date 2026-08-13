import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../services/weather_service.dart';
import 'history_screen.dart';
import 'prediction_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;
  int _homeRefreshToken = 0;
  String? _cachedLocation;
  double? _cachedTemperature;
  int? _cachedHumidity;
  String? _cachedWeatherCondition;
  DateTime? _cachedWeatherAt;

  static const _green = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screens = <Widget>[
      _HomeTab(
        user: user,
        refreshToken: _homeRefreshToken,
        cachedLocation: _cachedLocation,
        cachedTemperature: _cachedTemperature,
        cachedHumidity: _cachedHumidity,
        cachedWeatherCondition: _cachedWeatherCondition,
        cachedWeatherAt: _cachedWeatherAt,
        onWeatherUpdated: _storeWeatherCache,
      ),
      const PredictionScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: screens[_selectedTab]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() {
          if (index == 0 && _selectedTab != 0) _homeRefreshToken++;
          _selectedTab = index;
        }),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _green,
        unselectedItemColor: Colors.black87,
        selectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.eco_outlined, size: 28), label: 'Predict'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined, size: 28), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 28), label: 'Profile'),
        ],
      ),
    );
  }

  void _storeWeatherCache(
    String location,
    double temperature,
    int humidity,
    String condition,
    DateTime fetchedAt,
  ) {
    setState(() {
      _cachedLocation = location;
      _cachedTemperature = temperature;
      _cachedHumidity = humidity;
      _cachedWeatherCondition = condition;
      _cachedWeatherAt = fetchedAt;
    });
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({
    required this.user,
    required this.refreshToken,
    required this.cachedLocation,
    required this.cachedTemperature,
    required this.cachedHumidity,
    required this.cachedWeatherCondition,
    required this.cachedWeatherAt,
    required this.onWeatherUpdated,
  });

  final User? user;
  final int refreshToken;
  final String? cachedLocation;
  final double? cachedTemperature;
  final int? cachedHumidity;
  final String? cachedWeatherCondition;
  final DateTime? cachedWeatherAt;
  final void Function(
    String location,
    double temperature,
    int humidity,
    String condition,
    DateTime fetchedAt,
  )
  onWeatherUpdated;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const _green = Color(0xFF1B5E20);
  final WeatherService _weatherService = WeatherService();

  bool _isLoadingWeather = false;
  String? _weatherError;
  String? _location;
  double? _temperature;
  int? _humidity;
  String? _weatherCondition;
  DateTime? _lastWeatherFetch;
  bool _isRefreshingWeather = false;

  static const _weatherCacheDuration = Duration(minutes: 10);

  bool get _hasWeatherData =>
      _location != null &&
      _temperature != null &&
      _humidity != null &&
      _weatherCondition != null;

  bool get _hasValidWeatherCache =>
      _hasWeatherData &&
      _lastWeatherFetch != null &&
      DateTime.now().difference(_lastWeatherFetch!) < _weatherCacheDuration;

  @override
  void initState() {
    super.initState();
    _location = widget.cachedLocation;
    _temperature = widget.cachedTemperature;
    _humidity = widget.cachedHumidity;
    _weatherCondition = widget.cachedWeatherCondition;
    _lastWeatherFetch = widget.cachedWeatherAt;
    _loadWeather();
  }

  @override
  void didUpdateWidget(covariant _HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) _loadWeather();
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    if ((_isLoadingWeather || _isRefreshingWeather) ||
        (!forceRefresh && _hasValidWeatherCache)) {
      return;
    }

    final keepShowingWeather = _hasWeatherData;
    if (mounted) {
      setState(() {
        _isLoadingWeather = !keepShowingWeather;
        _isRefreshingWeather = keepShowingWeather;
        _weatherError = null;
      });
    }

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
      final weather = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );

      if (weather == null) throw Exception('Weather data is unavailable.');

      final weatherList = weather['weather'];
      final firstWeather = weatherList is List && weatherList.isNotEmpty
          ? weatherList.first as Map<String, dynamic>?
          : null;
      final main = weather['main'];
      final temperature = main is Map ? main['temp'] : null;
      final humidity = main is Map ? main['humidity'] : null;
      final condition = (firstWeather?['main'] as String?) ??
          (firstWeather?['description'] as String?);
      final resolvedLocation = city.isEmpty
          ? (weather['name'] as String? ?? '')
          : city;

      if (temperature is! num ||
          humidity is! num ||
          condition == null ||
          resolvedLocation.isEmpty) {
        throw Exception('Incomplete weather data.');
      }

      if (!mounted) return;
      final fetchedAt = DateTime.now();
      setState(() {
        _location = resolvedLocation;
        _temperature = temperature.toDouble();
        _humidity = humidity.toInt();
        _weatherCondition = condition;
        _isLoadingWeather = false;
        _isRefreshingWeather = false;
        _lastWeatherFetch = fetchedAt;
      });
      widget.onWeatherUpdated(
        resolvedLocation,
        temperature.toDouble(),
        humidity.toInt(),
        condition,
        fetchedAt,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
        _isRefreshingWeather = false;
        if (!keepShowingWeather) {
          _weatherError =
              'Weather is unavailable. Check location and internet access.';
        }
      });
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

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(
        child: Text('Please sign in to view your dashboard.', style: TextStyle(fontSize: 20)),
      );
    }

    final profile = FirebaseFirestore.instance.collection('users').doc(widget.user!.uid);
    final predictions = profile.collection('predictions');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: profile.snapshots(),
              builder: (context, snapshot) {
                final name = snapshot.data?.data()?['fullName'] as String? ?? 'Farmer';
                return Text(
                  'Welcome, $name \u{1F44B}',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _WeatherCard(
              isLoading: _isLoadingWeather,
              errorMessage: _weatherError,
              location: _location,
              temperature: _temperature,
              humidity: _humidity,
              condition: _weatherCondition,
              isRefreshing: _isRefreshingWeather,
              onRefresh: () => _loadWeather(forceRefresh: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PredictionScreen()),
                ),
                icon: const Icon(Icons.add_a_photo_outlined, size: 28),
                label: const Text('Start New Prediction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Summary',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: predictions.snapshots(),
              builder: (context, snapshot) {
                final records = snapshot.data?.docs ?? [];
                final safe = records
                    .where((item) => _savedPredictionRisk(item.data()) == 'low')
                    .length;
                final high = records
                    .where((item) => _savedPredictionRisk(item.data()) == 'high')
                    .length;
                return _SummarySection(
                  total: records.length,
                  safe: safe,
                  highRisk: high,
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Latest Predictions',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: predictions
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Could not load prediction history.', style: TextStyle(fontSize: 18)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final records = snapshot.data!.docs;
                if (records.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('No predictions yet. Start your first prediction!', style: TextStyle(fontSize: 18)),
                  );
                }
                return Column(
                  children: records
                      .map((record) => _PredictionCard(data: record.data()))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

String _savedPredictionRisk(Map<String, dynamic> data) {
  final savedRisk = data['spoilageRisk'] as String?;
  if (savedRisk != null && savedRisk.trim().isNotEmpty) {
    return savedRisk.trim().toLowerCase();
  }

  switch ((data['risk'] as String? ?? '').trim().toLowerCase()) {
    case 'red':
    case 'high':
      return 'high';
    case 'yellow':
    case 'medium':
      return 'medium';
    case 'green':
    case 'low':
      return 'low';
    default:
      return 'unknown';
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.isLoading,
    required this.errorMessage,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? location;
  final double? temperature;
  final int? humidity;
  final String? condition;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Today\'s Weather',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                if (isRefreshing)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1B5E20),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Refresh weather',
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, color: Color(0xFF1B5E20)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                ),
              )
            else if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(fontSize: 16, height: 1.35))
            else ...[
              if (location != null && location!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location!,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WeatherValue(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${temperature!.toStringAsFixed(1)} °C',
                  ),
                  _WeatherValue(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: '$humidity%',
                  ),
                  _WeatherValue(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Weather',
                    value: condition!,
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

class _WeatherValue extends StatelessWidget {
  const _WeatherValue({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1B5E20), size: 30),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.total, required this.safe, required this.highRisk});

  final int total;
  final int safe;
  final int highRisk;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Total', value: total, color: Colors.blue.shade700)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryCard(label: 'Safe', value: safe, color: Colors.green.shade700)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryCard(label: 'High Risk', value: highRisk, color: Colors.red.shade700)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text('$value', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 15), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final savedCropName = data['cropName'] as String?;
    final cropName = savedCropName?.trim().isNotEmpty == true
        ? savedCropName!.trim()
        : 'Tomato';
    final risk = _savedPredictionRisk(data);
    final createdAt = data['createdAt'];
    final date = createdAt is Timestamp
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : 'Date not available';
    final color = switch (risk) {
      'high' => Colors.red.shade700,
      'medium' => Colors.amber.shade800,
      'low' => Colors.green.shade700,
      _ => Colors.grey.shade700,
    };

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.eco_outlined, color: color, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cropName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
              child: Text(
                risk.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
