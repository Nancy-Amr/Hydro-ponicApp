import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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

  final Map<String, List<double>> optimalRanges = {
    'Temperature': [20.0, 28.0],
    'PH Level': [5.5, 6.5],
    'EC': [1.5, 2.2],
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

  // Generate mock data at an hourly interval regardless of the selected range
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

  LineChartData _buildChartData(List<Map<String, dynamic>> data) {
    final samplingInterval = _getSamplingInterval();
    final isDaily = samplingInterval.inDays > 0;

    final spots = [
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i]['value'] as double),
    ];
    final color = sensorColors[selectedSensor] ?? Colors.green;
    final range = sensorRanges[selectedSensor]!;

    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            // Calculate a sensible interval, showing roughly 6-8 labels
            interval: (data.length / (isDaily ? 6 : 8))
                .clamp(1, data.length)
                .toDouble(),
            getTitlesWidget: (value, meta) {
              final idx = value.round().clamp(0, data.length - 1);
              final dt = data[idx]['time'] as DateTime;

              // Format labels based on sampling rate
              String labelText = isDaily
                  ? "${dt.month}/${dt.day}"
                  : "${dt.hour}:00";

              return SideTitleWidget(
                meta: meta,
                space: 4.0,
                child: Text(labelText, style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
      minX: 0,
      maxX: (data.length - 1)
          .toDouble(), // MaxX should be index of last element
      minY: range[0],
      maxY: range[1],
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,

          dotData: FlDotData(show: data.length <= 31),
        ),
      ],
    );
  }

  // Light Exposure Distribution (mock data)
  Widget _lightExposureChart() {
    const double activeHours = 16;
    const double inactiveHours = 8;

    final total = activeHours + inactiveHours;
    final activePercent = (activeHours / total) * 100;
    final inactivePercent = (inactiveHours / total) * 100;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              'Light Exposure Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.5,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 50,
                  sectionsSpace: 4,
                  sections: [
                    PieChartSectionData(
                      color: Colors.amber,
                      value: activePercent,
                      title: '${activePercent.toStringAsFixed(1)}% Active',
                      radius: 70,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.grey.shade400,
                      value: inactivePercent,
                      title: '${inactivePercent.toStringAsFixed(1)}% Inactive',
                      radius: 70,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Represents grow light ON/OFF ratio over last 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
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
    ).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
  }

  Widget _metricCard(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _currentData;
    final stats = _summary(data);
    final color = sensorColors[selectedSensor]!;

    // Check which range button is currently active for styling
    final is24h = selectedRange.duration.inDays < 2;
    final is7d =
        selectedRange.duration.inDays >= 6 &&
        selectedRange.duration.inDays <= 8;
    final is30d = selectedRange.duration.inDays >= 29;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Analytics'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Preset ranges (24h, 7d, 30d)
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() {
                      selectedRange = DateTimeRange(
                        start: DateTime.now().subtract(
                          const Duration(hours: 24),
                        ),
                        end: DateTime.now(),
                      );
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: is24h
                          ? Colors.green.shade900
                          : Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('24h'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      selectedRange = DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 7)),
                        end: DateTime.now(),
                      );
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: is7d
                          ? Colors.green.shade900
                          : Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('7d'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      selectedRange = DateTimeRange(
                        start: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        end: DateTime.now(),
                      );
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: is30d
                          ? Colors.green.shade900
                          : Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('30d'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sensor selector
              Wrap(
                spacing: 8,
                children: sensors.map((s) {
                  return ChoiceChip(
                    label: Text(s),
                    selected: s == selectedSensor,
                    selectedColor: color.withAlpha(51),
                    onSelected: (_) => setState(() => selectedSensor = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Summary cards
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricCard('Min', stats['min']!, color),
                      _metricCard('Max', stats['max']!, color),
                      _metricCard('Avg', stats['avg']!, color),
                      _metricCard('Last', stats['last']!, color),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Main line chart
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        // Updated title to show the time granularity
                        '$selectedSensor (${_getSamplingInterval().inDays > 0 ? 'Daily Average' : 'Hourly Readings'})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${selectedRange.start.month}/${selectedRange.start.day}–${selectedRange.end.month}/${selectedRange.end.day}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 1.7,
                        child: data.isNotEmpty
                            ? LineChart(_buildChartData(data))
                            : const Center(child: Text('No data available')),
                      ),
                    ],
                  ),
                ),
              ),

              // Light Exposure Pie Chart
              _lightExposureChart(),

              const SizedBox(height: 20),

              // Recent readings
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Readings (Aggregated)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // Only show a limited number of recent data points
                itemCount: min(data.length, 10),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item =
                      data[data.length - 1 - i]; // Show most recent first
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withAlpha(77),
                      child: Text(
                        (item['value'] as double).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(
                      '$selectedSensor: ${(item['value'] as double).toStringAsFixed(2)}',
                    ),
                    subtitle: Text(
                      '${item['time'].toString().substring(0, 10)} ${_getSamplingInterval().inDays > 0 ? '(Daily Avg)' : ''}',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}