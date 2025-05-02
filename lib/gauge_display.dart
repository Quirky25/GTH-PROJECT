import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:wave/wave.dart'; // Import the Wave package
import 'package:wave/config.dart';
import 'push_notification_service.dart';
import 'data_logs_page.dart';
import 'sdcard_page.dart';
import 'profile_page.dart';

class GaugeDisplayPage extends StatefulWidget {
  const GaugeDisplayPage({super.key});

  @override
  GaugeDisplayPageState createState() => GaugeDisplayPageState();
}

class GaugeDisplayPageState extends State<GaugeDisplayPage> {
  double humidity = 0.0;
  double temperature = 0.0;
  int? gasLevel;
  bool _hasSentNotification = false;
  bool _hasSentHumidityNotification = false; // ADD THIS
  bool _hasSentTemperatureNotification = false; 
  bool isLoading = false; // Track loading state for SDCardPage

  late PageController _pageController; // PageController for PageView

  // Colors for animated gradient background
  List<Color> _colors = [const Color(0xFF6A0572), const Color(0xFF00C9A7)];
  int _colorIndex = 0;

  int _currentIndex = 0; // Track the currently selected icon

  @override
  void initState() {
    super.initState();
    _fetchSensorData();

    _pageController = PageController(initialPage: 0); // Initialize PageController

    _startBackgroundAnimation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _fetchSensorData() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("sensor");

    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
  setState(() {
    humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;
    temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
    gasLevel = (data['gas'] as int?);
  });

  // GAS NOTIFICATION
  if (gasLevel != null && gasLevel! >= 400 && !_hasSentNotification) {
    PushNotificationService.showNotification(
      "🚨 Gas Alert!",
      "Dangerous gas level detected: $gasLevel. Take action immediately!",
    );
    _hasSentNotification = true;
  } else if (gasLevel != null && gasLevel! < 400) {
    _hasSentNotification = false;
  }

  // HUMIDITY NOTIFICATION
  if (humidity >= 75 && !_hasSentHumidityNotification) {
    PushNotificationService.showNotification(
      "💧 Humidity Alert!",
      "High humidity detected: ${humidity.toStringAsFixed(1)}%. Risk of mold or discomfort.",
    );
    _hasSentHumidityNotification = true;
  } else if (humidity < 75) {
    _hasSentHumidityNotification = false;
  }

  // TEMPERATURE NOTIFICATION
  if (temperature >= 40 && !_hasSentTemperatureNotification) {
    PushNotificationService.showNotification(
      "🌡️ Temperature Alert!",
      "High temperature detected: ${temperature.toStringAsFixed(1)}°C. Stay cool and hydrated.",
    );
    _hasSentTemperatureNotification = true;
  } else if (temperature < 40) {
    _hasSentTemperatureNotification = false;
  }
}

    });
  }

  void _startBackgroundAnimation() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _colorIndex = (_colorIndex + 1) % 2;
        _colors = _colorIndex == 0
            ? [const Color(0xFF6A0572), const Color(0xFF00C9A7)] // Purple to Teal
            : [const Color(0xFF00C9A7), const Color(0xFF6A0572)]; // Teal to Purple
      });
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: SafeArea(
      child: Stack(
        children: [
          // Animated Gradient Background
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Top Navigation Bar with Icons
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavIcon(
                  icon: Icons.home,
                  index: 0,
                  label: 'Home',
                  onTap: () {
                    if (!isLoading || _currentIndex != 2) {
                      setState(() {
                        _currentIndex = 0;
                      });
                      _pageController.jumpToPage(0);
                    }
                  },
                ),
                _buildNavIcon(
                  icon: Icons.history,
                  index: 1,
                  label: 'Data Logs',
                  onTap: () {
                    if (!isLoading || _currentIndex != 2) {
                      setState(() {
                        _currentIndex = 1;
                      });
                      _pageController.jumpToPage(1);
                    }
                  },
                ),
                _buildNavIcon(
                  icon: Icons.sd_card,
                  index: 2,
                  label: 'SD Card',
                  onTap: () {
                    if (isLoading) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please wait until the SD Card contents are loaded."),
                        ),
                      );
                    } else {
                      setState(() {
                        _currentIndex = 2;
                      });
                      _pageController.jumpToPage(2);
                    }
                  },
                ),
                _buildNavIcon(
                  icon: Icons.person,
                  index: 3,
                  label: 'Profile',
                  onTap: () {
                    if (!isLoading || _currentIndex != 2) {
                      setState(() {
                        _currentIndex = 3;
                      });
                      _pageController.jumpToPage(3);
                    }
                  },
                ),
              ],
            ),
          ),
          // PageView for swiping between pages
          Positioned.fill(
            top: 80,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (index == 2 && isLoading) {
                  // Prevent swiping to SDCardPage if it's still loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please wait until the SD Card contents are loaded."),
                    ),
                  );
                  _pageController.jumpToPage(_currentIndex); // Stay on the current page
                } else {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              physics: isLoading && _currentIndex == 2
                  ? const NeverScrollableScrollPhysics()
                  : null, // Disable swiping if on SDCardPage and loading
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildWaveSymbol(
                              label: 'Humidity',
                              value: humidity,
                              color: _getHumidityColor(humidity),
                              icon: Icons.water_drop,
                              unit: '%',
                            ),
                            _buildWaveSymbol(
                              label: 'Temperature',
                              value: temperature,
                              color: _getTemperatureColor(temperature),
                              icon: Icons.thermostat,
                              unit: '°C',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildWaveSymbol(
                          label: 'Gas Level',
                          value: gasLevel?.toDouble() ?? -1,
                          color: _getGasColor(gasLevel),
                          icon: Icons.gas_meter,
                          unit: '',
                        ),
                      ],
                    ),
                  ),
                ),
                const DataLogsPage(),
                SDCardPage(), // SDCardPage with the condition applied
                const ProfilePage(),
              ],
            ),
          ),
          // Block user interaction when loading
          if (_currentIndex == 2 && isLoading)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // Block taps
                child: Container(
                  color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
                  child: const Center(
                    child: CircularProgressIndicator(), // Show loading indicator
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildNavIcon({
    required IconData icon,
    required int index,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: _currentIndex == index ? Colors.blue : Colors.white,
          ),
          Text(
            label,
            style: TextStyle(
              color: _currentIndex == index ? Colors.blue : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveSymbol({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required String unit,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Stack(
          alignment: Alignment.center,
          children: [
            ClipOval(
              child: SizedBox(
                width: 120,
                height: 120,
                child: WaveWidget(
                  config: CustomConfig(
                    gradients: [
                      [color.withOpacity(0.5), color.withOpacity(0.3)],
                      [color.withOpacity(0.3), color.withOpacity(0.1)],
                    ],
                    durations: [2000, 2000],
                    heightPercentages: [
                      1.0 - _getGasFillLevel(value),
                      1.0 - _getGasFillLevel(value) + 0.05,
                    ],
                    blur: const MaskFilter.blur(BlurStyle.solid, 10),
                  ),
                  waveAmplitude: 10,
                  backgroundColor: Colors.transparent,
                  size: const Size(double.infinity, double.infinity),
                ),
              ),
            ),
            Icon(
              icon,
              size: 70,
              color: color,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value < 0 ? "No Data" : "${value.toStringAsFixed(1)} $unit",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  double _getGasFillLevel(double value) {
    if (value < 0) return 0.0;
    if (value >= 400) return 1.0;
    if (value >= 201) return 0.5;
    return 0.2;
  }

  Color _getHumidityColor(double value) {
    if (value >= 75) return Colors.red;
    if (value > 60) return Colors.orange;
    return Colors.green;
  }

  Color _getTemperatureColor(double value) {
    if (value >= 40) return Colors.red;
    if (value >= 36) return Colors.orange;
    return Colors.green;
  }

  Color _getGasColor(int? value) {
    if (value == null) return Colors.grey;
    if (value >= 400) return Colors.red;
    if (value >= 201) return Colors.orange;
    return Colors.green;
  }
}