import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async'; // For the Timer

class ChartPage extends StatefulWidget {
  final String viewMode;
  final List<Map<String, dynamic>> logs;

  ChartPage({required this.viewMode, required this.logs});

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  late List<Map<String, dynamic>> logs;
  late List<FlSpot> gasLevelData;
  late List<FlSpot> temperatureData;
  late List<FlSpot> humidityData;

  @override
  void initState() {
    super.initState();
    logs = widget.logs;
    gasLevelData = _generateData(logs, 'gasLevel');
    temperatureData = _generateData(logs, 'temperature');
    humidityData = _generateData(logs, 'humidity');

    // Simulate real-time updates by adding a new data point every 2 seconds
    Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        // Add a new log entry with random data (or get new data from your source)
        var newLog = {
          'gasLevel': (gasLevelData.last.y + 5) % 100, // Example increment
          'temperature': (temperatureData.last.y + 1) % 40, // Example increment
          'humidity': (humidityData.last.y + 2) % 100, // Example increment
        };

        logs.add(newLog); // Add new data to the logs
        gasLevelData = _generateData(logs, 'gasLevel'); // Re-generate data for chart
        temperatureData = _generateData(logs, 'temperature'); // Re-generate data for chart
        humidityData = _generateData(logs, 'humidity'); // Re-generate data for chart
      });
    });
  }

  List<FlSpot> _generateData(List<Map<String, dynamic>> logs, String type) {
    List<FlSpot> data = [];
    int maxPoints = 50; // Limit the number of points to 50 (or any other number)

    for (int i = 0; i < logs.length; i++) {
      if (data.length >= maxPoints) break; // Stop adding more points once max is reached

      double x = i.toDouble(); // Using index as x-axis
      double y = 0.0;

      if (type == 'gasLevel') {
        y = double.tryParse(logs[i]['gasLevel'].toString()) ?? 0.0;
      } else if (type == 'temperature') {
        y = double.tryParse(logs[i]['temperature'].toString()) ?? 0.0;
      } else if (type == 'humidity') {
        y = double.tryParse(logs[i]['humidity'].toString()) ?? 0.0;
      }

      data.add(FlSpot(x.toDouble(), y)); // Add the data point
    }

    // Re-scale the x-axis to fit within the last 'maxPoints' values
    for (int i = 0; i < data.length; i++) {
      data[i] = FlSpot(i.toDouble(), data[i].y);
    }

    return data;
  }

  Widget _buildChart(List<FlSpot> spots, String title, Color color) {
    double interval = spots.length > 10 ? spots.length / 10.0 : 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(fontSize: 10),
                  );
                },
                interval: interval,
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(0));
                },
                interval: 5,
                reservedSize: 32,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          gridData: FlGridData(show: true),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: spots,
              barWidth: 2,
              color: color,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Log Chart'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gas Level'),
              Tab(text: 'Temperature'),
              Tab(text: 'Humidity'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChart(
              gasLevelData,
              'Gas Level',
              Colors.black,
            ),
            _buildChart(
              temperatureData,
              'Temperature',
              Colors.black,
            ),
            _buildChart(
              humidityData,
              'Humidity',
              Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
