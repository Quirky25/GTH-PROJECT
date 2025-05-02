import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';

class DataLogService {
  static final DataLogService _instance = DataLogService._internal();
  factory DataLogService() => _instance;

  final List<Map<String, dynamic>> _logs = [];
  final StreamController<List<Map<String, dynamic>>> _logStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  late DatabaseReference _sensorRef;
  Timer? _cleanupTimer;

  DataLogService._internal();

  Future<void> initialize() async {
    await _loadLogs();
    _initializeFirebaseListener();
    _startCleanupTimer();
  }

  Stream<List<Map<String, dynamic>>> get logStream => _logStreamController.stream;

  List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);

  Future<void> _loadLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data_logs.json');

      if (await file.exists()) {
        String contents = await file.readAsString();
        List<dynamic> jsonData = json.decode(contents);
        _logs.addAll(jsonData.map((log) => log as Map<String, dynamic>).toList());
        _logStreamController.add(_logs); // Notify listeners
      }
    } catch (e) {
      print("Error loading logs: $e");
    }
  }

  Future<void> _saveLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data_logs.json');
      String jsonData = json.encode(_logs);
      await file.writeAsString(jsonData);
    } catch (e) {
      print("Error saving logs: $e");
    }
  }

  void _initializeFirebaseListener() {
    _sensorRef = FirebaseDatabase.instance.ref("sensor");

    // Listen to real-time updates from Firebase
    _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        double temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
        double humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;
        int gasLevel = (data['gas'] as int?) ?? 0;

        _addLog(temperature, humidity, gasLevel);
      }
    });
  }

  void _addLog(double temperature, double humidity, int gasLevel) {
    final now = DateTime.now();
    final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final formattedTime = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    final newLog = {
      'calibrationName': 'Calibration ${_logs.length + 1}',
      'temperature': temperature.toStringAsFixed(1),
      'humidity': humidity.toStringAsFixed(1),
      'gasLevel': gasLevel.toString(),
      'time': formattedTime,
      'date': formattedDate,
      'timestamp': now.toIso8601String(),
    };

    _logs.insert(0, newLog);
    _logStreamController.add(_logs); // Notify listeners
    _saveLogs();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupOldLogs();
    });
  }

  void _cleanupOldLogs() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 48));

    _logs.removeWhere((log) {
      final logTimestamp = DateTime.parse(log['timestamp']);
      return logTimestamp.isBefore(cutoff);
    });

    _logStreamController.add(_logs); // Notify listeners
    _saveLogs();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _logStreamController.close();
  }
}