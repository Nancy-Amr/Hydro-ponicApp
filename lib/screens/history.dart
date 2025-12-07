import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// Note: fl_chart is replaced with simplified native Flutter widgets for visualization.

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Available sensors
  final List<String> sensors = [
    'Temperature',
    'Humidity',
    'PH Level',
    'Water Level',
    'Light Intensity',
    'EC',
  ];

  String selectedSensor = 'Temperature';

  final Map<String, List<double>> sensorRanges = {
    'Temperature': [10.0, 35.0],
    'Humidity': [0.0, 100.0],
    'PH Level': [0.0, 14.0],
    'Water Level': [0.0, 2.0],
    'Light Intensity': [0.0, 100.0],
    'EC': [0.0, 3.0],
  };

  final Map<String, Color> sensorColors = {
    'Temperature': Colors.orange,
    'Humidity': Colors.blue,
    'PH Level': Colors.purple,
    'Water Level': Colors.teal,
    'Light Intensity': Colors.amber,
    'EC': Colors.green,
  };

  DateTimeRange selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(hours: 24)),
    end: DateTime.now(),
  );

  Duration _getSamplingInterval() {
    final days = selectedRange.end.difference(selectedRange.start).inDays;
    // If the range is > 2 days, switch to daily data points.
    return days > 2 ? const Duration(days: 1) : const Duration(hours: 1);
  }

  // Generate mock data (logic unchanged)
  List<Map<String, dynamic>> _mockData({
    required String sensor,
    required DateTimeRange range,
  }) {
    final hours = range.end.difference(range.start).inHours;
    final count = max(1, hours + 1);
    return List.generate(count, (i) {
      final dt = range.start.add(Duration(hours: i));
      double base = switch (sensor) {
        'PH Level' => 6.2,
        'Humidity' => 65.0,
        'Water Level' => 1.0,
        'Light Intensity' => 75.0,
        'EC' => 1.8,
        _ => 25.0, // Temperature
      };
      final noise = Random().nextDouble() * 2 - 1;
      final noiseFactor = _getSamplingInterval().inDays > 0
          ? 0.5
          : (sensor == 'PH Level' ? 0.2 : 1.0);

      final value = base + noise * noiseFactor;
      return {'time': dt, 'value': value};
    });
  }

  List<Map<String, dynamic>> _getAggregatedData(
    List<Map<String, dynamic>> hourlyData,
    Duration interval,
  ) {
    if (interval.inHours == 1) {
      return hourlyData;
    }

    final aggregatedData = <Map<String, dynamic>>[];
    DateTime? currentDay;
    List<double> dailyValues = [];

    for (var item in hourlyData) {
      final dt = item['time'] as DateTime;
      final value = item['value'] as double;
      final day = DateTime(dt.year, dt.month, dt.day);

      currentDay ??= day;

      if (day.isAtSameMomentAs(currentDay)) {
        dailyValues.add(value);
      } else {
        if (dailyValues.isNotEmpty) {
          final avgValue =
              dailyValues.reduce((a, b) => a + b) / dailyValues.length;
          aggregatedData.add({'time': currentDay, 'value': avgValue});
        }
        currentDay = day;
        dailyValues = [value];
      }
    }

    // Add the last calculated day's average
    if (dailyValues.isNotEmpty) {
      final avgValue = dailyValues.reduce((a, b) => a + b) / dailyValues.length;
      aggregatedData.add({'time': currentDay, 'value': avgValue});
    }

    return aggregatedData;
  }

  List<Map<String, dynamic>> get _currentData {
    final hourlyData = _mockData(sensor: selectedSensor, range: selectedRange);
    return _getAggregatedData(hourlyData, _getSamplingInterval());
  }

  // Summary (min/max/avg/last)
  Map<String, double> _summary(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return {'min': 0, 'max': 0, 'avg': 0, 'last': 0};
    final values = data.map((e) => e['value'] as double).toList();
    return {
      'min': values.reduce(min),
      'max': values.reduce(max),
      'avg': values.reduce((a, b) => a + b) / values.length,
      'last': values.last,
    };
  }
  
  // --- Simplified Line Visualization Widget ---
  Widget _buildSimpleLineChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available to plot'));
    }
    final color = sensorColors[selectedSensor] ?? Colors.green;
    final values = data.map((e) => e['value'] as double).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final rangeVal = maxVal - minVal;

    // This uses stacked containers to simulate a bar/line chart visualization
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Y-axis labels (min/max)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(maxVal.toStringAsFixed(1), style: TextStyle(fontSize: 10, color: color)),
                Text(minVal.toStringAsFixed(1), style: TextStyle(fontSize: 10, color: color)),
              ],
            ),
          ),
          // Placeholder line chart (colored container)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(data.length, (index) {
                  final value = data[index]['value'] as double;
                  // Normalize value between 0.0 and 1.0 for height calculation
                  double normalized = rangeVal == 0 ? 0.5 : (value - minVal) / rangeVal;
                  
                  return Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 2, // Width of each bar segment
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        height: 5 + (normalized * 95).clamp(0, 100), // Height based on value (clamped)
                        color: color.withOpacity(0.7 + normalized * 0.3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // X-axis label placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Text('End', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Light Exposure Distribution (Simplified Pie visualization)
  Widget _lightExposureChart() {
    const double activeHours = 16;
    const double inactiveHours = 8;
    final total = activeHours + inactiveHours;
    final activePercent = activeHours / total;
    final inactivePercent = inactiveHours / total;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '🌞 Light Cycle Analysis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            // Custom Pie Chart using LinearProgressIndicator for simplification
            SizedBox(
              height: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: activePercent,
                  backgroundColor: Colors.grey.shade400,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _exposureLegend(
                  label: 'Light ON',
                  hours: activeHours,
                  percent: activePercent,
                  color: Colors.amber,
                ),
                _exposureLegend(
                  label: 'Light OFF',
                  hours: inactiveHours,
                  percent: inactivePercent,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Target 16:8 Photoperiod',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget for Light Exposure Legend
  Widget _exposureLegend({required String label, required double hours, required double percent, required Color color}) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, color: color, margin: const EdgeInsets.only(right: 5)),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Text(
          '${hours.toStringAsFixed(0)} hrs (${(percent * 100).toStringAsFixed(0)}%)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }


  Future<void> _exportCsv() async {
    final data = _currentData;
    final buffer = StringBuffer();
    buffer.writeln('timestamp,${selectedSensor.toLowerCase()}');
    for (final r in data) {
      buffer.writeln('${r['time']},${r['value']}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
      content: const Text('CSV copied to clipboard'),
      backgroundColor: Colors.green.shade700,
    ));
  }

  // --- Updated Metric Card UI ---
  Widget _metricCard(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  // FIXED: Changed from ActionChip to ChoiceChip to correctly use the 'selected' parameter
  Widget _timeRangeChip(String label, bool isSelected, VoidCallback onPressed) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected, // This is now a valid parameter
      selectedColor: Colors.green.shade700,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? Colors.green.shade900 : Colors.green.shade400),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.green.shade900,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (bool selected) { // ChoiceChip uses onSelected(bool selected)
        if (selected) {
          onPressed();
        }
      },
    );
  }

  void _updateRange(Duration duration) {
    setState(() {
      selectedRange = DateTimeRange(
        start: DateTime.now().subtract(duration),
        end: DateTime.now(),
      );
    });
  }

  Widget _dateRangePickerChip() {
    return ActionChip(
      label: const Text('Custom Date'),
      avatar: const Icon(Icons.calendar_today, size: 18),
      onPressed: _selectDateRange,
      backgroundColor: Colors.green.shade100,
      side: BorderSide(color: Colors.green.shade400),
      labelStyle: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold),
    );
  }
  
  // Custom date picker function
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
    );
    if (picked != null && picked != selectedRange) {
      setState(() {
        selectedRange = picked;
      });
    }
  }


  Widget _buildSummaryCard(Map<String, double> stats, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metricCard('Min', stats['min']!, color),
            const VerticalDivider(width: 1),
            _metricCard('Max', stats['max']!, color),
            const VerticalDivider(width: 1),
            _metricCard('Avg', stats['avg']!, color),
            const VerticalDivider(width: 1),
            _metricCard('Last', stats['last']!, color),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReadingsList(List<Map<String, dynamic>> data, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Readings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: min(data.length, 7), // Show max 7 recent data points
          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
          itemBuilder: (_, i) {
            // Get the data point, showing most recent first
            final item = data[data.length - 1 - i]; 
            final isDaily = _getSamplingInterval().inDays > 0;
            final dt = item['time'] as DateTime;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.sensors, color: color),
              title: Text(
                '$selectedSensor: ${(item['value'] as double).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isDaily 
                ? '${dt.month}/${dt.day}/${dt.year} (Daily Avg)'
                : '${dt.month}/${dt.day} ${dt.hour}:00',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Text(
                selectedSensor == 'PH Level' ? 'pH' : (selectedSensor == 'EC' ? 'mS/cm' : (selectedSensor == 'Temperature' ? '°C' : '')),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final data = _currentData;
    final stats = _summary(data);
    final color = sensorColors[selectedSensor]!;

    // Check which range button is currently active for styling
    final is24h = selectedRange.duration.inDays < 2;
    final is7d = selectedRange.duration.inDays >= 6 && selectedRange.duration.inDays <= 8;
    final is30d = selectedRange.duration.inDays >= 29;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor History'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Time Range Selection Chips (FIXED) ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _timeRangeChip('24h', is24h, () => _updateRange(const Duration(hours: 24))),
                  _timeRangeChip('7d', is7d, () => _updateRange(const Duration(days: 7))),
                  _timeRangeChip('30d', is30d, () => _updateRange(const Duration(days: 30))),
                  _dateRangePickerChip(), // Custom date picker option (ActionChip)
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 2. Sensor Selector (Chips) ---
            const Text(
              'Select Metric',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: sensors.map((s) {
                return ActionChip(
                  label: Text(s),
                  avatar: s == selectedSensor ? Icon(Icons.check, color: color) : null,
                  backgroundColor: s == selectedSensor ? color.withOpacity(0.15) : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: s == selectedSensor ? color : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  onPressed: () => setState(() => selectedSensor = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // --- 3. Summary Statistics Card ---
            _buildSummaryCard(stats, color),
            const SizedBox(height: 20),

            // --- 4. Main Data Visualization (Simplified Chart) ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      selectedSensor,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                    Text(
                      '${_getSamplingInterval().inDays > 0 ? 'Daily Average' : 'Hourly Readings'} (${selectedRange.duration.inDays} days)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 1.8,
                      child: _buildSimpleLineChart(data), // Using the simplified visualization
                    ),
                  ],
                ),
              ),
            ),

            // --- 5. Light Exposure Pie Chart (Simplified) ---
            if (selectedSensor == 'Light Intensity') _lightExposureChart(),

            const SizedBox(height: 30),

            // --- 6. Recent Readings List ---
            _buildRecentReadingsList(data, color),
          ],
        ),
      ),
    );
  }
}

