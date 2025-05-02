import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class BatteryStatusWidget extends StatelessWidget {
  const BatteryStatusWidget({super.key});

  Future<Map<String, dynamic>> _fetchBatteryData() async {
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.get();
    final data = snapshot.value as Map<dynamic, dynamic>?;

    double voltage = 0.0;
    int percentage = 0;

    if (data != null) {
      voltage = double.tryParse(data['battery_voltage']?.toString() ?? '') ?? 0.0;
      percentage = int.tryParse(data['battery_percentage']?.toString() ?? '') ?? 0;
    }

    return {
      'voltage': voltage,
      'percentage': percentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchBatteryData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBatteryIcon(percentage: null, voltage: null);
        } else if (snapshot.hasError) {
          return _buildBatteryIcon(percentage: null, voltage: null, error: true);
        } else {
          final data = snapshot.data!;
          return _buildBatteryIcon(
            percentage: data['percentage'],
            voltage: data['voltage'],
          );
        }
      },
    );
  }

  Widget _buildBatteryIcon({int? percentage, double? voltage, bool error = false}) {
    Color batteryColor;
    if (error || percentage == null) {
      batteryColor = Colors.grey;
    } else if (percentage < 20) {
      batteryColor = Colors.red;
    } else if (percentage < 50) {
      batteryColor = Colors.orange;
    } else {
      batteryColor = Colors.green;
    }

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.battery_full,
              color: batteryColor,
              size: 36,
            ),
            if (percentage != null)
              Positioned(
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              percentage != null ? '$percentage%' : '--%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: batteryColor,
              ),
            ),
            Text(
              voltage != null && voltage > 0 ? '${voltage.toStringAsFixed(2)} V' : '-- V',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ],
    );
  }
}