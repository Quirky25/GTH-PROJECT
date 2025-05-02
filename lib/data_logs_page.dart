import 'package:flutter/material.dart';
import 'data_log_service.dart'; // Import the DataLogService
import 'chart_page.dart';

class DataLogsPage extends StatefulWidget {
  const DataLogsPage({super.key});

  @override
  State<DataLogsPage> createState() => _DataLogsPageState();
}

class _DataLogsPageState extends State<DataLogsPage> {
  int _currentPage = 0; // Current page index
  int _logsPerPage = 10; // Default number of logs per page
  String _formatTime(String time24hr) {
  try {
    final time = TimeOfDay(
      hour: int.parse(time24hr.split(":")[0]),
      minute: int.parse(time24hr.split(":")[1]),
    );
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  } catch (_) {
    return time24hr; // fallback to original if parsing fails
  }
}

  List<Map<String, dynamic>> _getLogsForCurrentPage(List<Map<String, dynamic>> logs) {
    final startIndex = _currentPage * _logsPerPage;
    final endIndex = startIndex + _logsPerPage;
    return logs.sublist(
      startIndex,
      endIndex > logs.length ? logs.length : endIndex,
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    List<Widget> pageWidgets = [];

    // Add the first page
    pageWidgets.add(_buildPageButton(0));

    // Add ellipsis if necessary
    if (_currentPage > 4) {
      pageWidgets.add(_buildEllipsis());
    }

    // Add middle pages
    int start = (_currentPage > 4) ? _currentPage - 2 : 1;
    int end = (_currentPage < totalPages - 5) ? _currentPage + 2 : totalPages - 2;

    for (int i = start; i <= end; i++) {
      pageWidgets.add(_buildPageButton(i));
    }

    // Add ellipsis if necessary
    if (_currentPage < totalPages - 5) {
      pageWidgets.add(_buildEllipsis());
    }

    // Add the last page
    if (totalPages > 1) {
      pageWidgets.add(_buildPageButton(totalPages - 1));
    }

    return pageWidgets;
  }

  Widget _buildPageButton(int pageIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentPage = pageIndex;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _currentPage == pageIndex ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          '${pageIndex + 1}',
          style: TextStyle(
            color: _currentPage == pageIndex ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return GestureDetector(
      onTap: () {
        _showPageInputDialog();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(8.0),
        child: const Text(
          '...',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showPageInputDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController pageController = TextEditingController();
        return AlertDialog(
          title: const Text('Go to Page'),
          content: TextField(
            controller: pageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter page number'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                int? page = int.tryParse(pageController.text);
                if (page != null && page > 0 && page <= (DataLogService().logs.length / _logsPerPage).ceil()) {
                  setState(() {
                    _currentPage = page - 1;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: DataLogService().logStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No logs available.', style: TextStyle(color: Colors.white)),
          );
        }

        final logs = snapshot.data!;
        final totalPages = (logs.length / _logsPerPage).ceil();
        final logsForCurrentPage = _getLogsForCurrentPage(logs);
        final startIndex = _currentPage * _logsPerPage + 1;
        final endIndex = (_currentPage + 1) * _logsPerPage > logs.length
            ? logs.length
            : (_currentPage + 1) * _logsPerPage;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dataTableTheme: const DataTableThemeData(
                            dataTextStyle: TextStyle(color: Colors.white),
                            headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            dividerThickness: 1,
                          ),
                          dividerColor: Colors.black,
                        ),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Calibration Name')),
                            DataColumn(label: Text('Gas Level')),
                            DataColumn(label: Text('Temperature (°C)')),
                            DataColumn(label: Text('Humidity (%)')),
                            DataColumn(label: Text('Time (AM/PM)')),
                            DataColumn(label: Text('Date')),
                          ],
                          rows: logsForCurrentPage.map((log) {
                            return DataRow(cells: [
                              DataCell(Text(log['calibrationName'])),
                              DataCell(Text(log['gasLevel'])),
                              DataCell(Text(log['temperature'])),
                              DataCell(Text(log['humidity'])),
                              DataCell(Text(_formatTime(log['time']))),
                              DataCell(Text(log['date'])),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Results: $startIndex - $endIndex of ${logs.length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            DropdownButton<int>(
                              dropdownColor: Colors.grey[900],
                              value: _logsPerPage,
                              items: [10, 20, 50, 100].map((value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value', style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _logsPerPage = value!;
                                  _currentPage = 0;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: _currentPage > 0
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                    }
                                  : null,
                            ),
                            ..._buildPageNumbers(totalPages),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Colors.white),
                              onPressed: _currentPage < totalPages - 1
                                  ? () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChartPage(
        viewMode: 'default',
        logs: logs, // or logsForCurrentPage
      ),
    ),
  );
},
                backgroundColor: Colors.blue,
                child: const Icon(Icons.insights), // Or Icons.analytics
                tooltip: 'View Graph',
              ),
            ),
          ],
        );
      },
    ),
  );
}
}
