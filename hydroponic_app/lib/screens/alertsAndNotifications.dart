import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alerts Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const AlertsScreen(),
    );
  }
}

class AlertItem {
  final String id;
  final String title;
  final String message;
  final String severity;
  final String time;
  final String date;
  bool isRead;

  AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.time,
    required this.date,
    this.isRead = false,
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String selectedFilter = "All";
  String searchQuery = '';

  // Sample alert data (typed)
  final List<AlertItem> alerts = [
    AlertItem(
      id: 'a1',
      title: "High pH detected",
      message: "pH level 7.8 exceeded safe range.",
      severity: "Critical",
      time: "14:32",
      date: "Today",
      isRead: false,
    ),
    AlertItem(
      id: 'a2',
      title: "Low water level",
      message: "Reservoir water below 30%.",
      severity: "Warning",
      time: "12:50",
      date: "Today",
      isRead: false,
    ),
    AlertItem(
      id: 'a3',
      title: "Light sensor offline",
      message: "LDR sensor not responding.",
      severity: "Info",
      time: "Yesterday",
      date: "Yesterday",
      isRead: true,
    ),
  ];

  // Filter + search logic
  List<AlertItem> get filteredAlerts {
    final query = searchQuery.trim().toLowerCase();

    // first apply severity filter
    final severityFiltered = selectedFilter == "All"
        ? alerts
        : alerts.where((a) => a.severity == selectedFilter).toList();

    // then apply search (if any)
    if (query.isEmpty) return severityFiltered;

    return severityFiltered.where((a) {
      return a.title.toLowerCase().contains(query) ||
          a.message.toLowerCase().contains(query) ||
          a.severity.toLowerCase().contains(query) ||
          a.date.toLowerCase().contains(query) ||
          a.time.toLowerCase().contains(query);
    }).toList();
  }

  Color getSeverityColor(String severity) {
    switch (severity) {
      case "Critical":
        return Colors.redAccent;
      case "Warning":
        return Colors.orangeAccent;
      case "Info":
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text("Alerts & Notifications"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            color: const Color.fromARGB(255, 227, 242, 228),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton("All"),
                _buildFilterButton("Critical"),
                _buildFilterButton("Warning"),
                _buildFilterButton("Info"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search alerts...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear Visible Alerts',
                  onPressed: () {
                    final visible = filteredAlerts;
                    if (visible.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No alerts to delete')),
                      );
                      return;
                    }
                    final idsToRemove = visible.map((a) => a.id).toSet();
                    setState(() {
                      alerts.removeWhere((a) => idsToRemove.contains(a.id));
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted ${idsToRemove.length} visible alert(s)',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Alerts List
          Expanded(
            child: filteredAlerts.isEmpty
                ? Center(
                    child: Text(
                      alerts.isEmpty
                          ? "No alerts available"
                          : "No matching alerts",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      return Dismissible(
                        key: ValueKey(alert.id),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          // remove from the master list by id
                          setState(() {
                            alerts.removeWhere((a) => a.id == alert.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${alert.title} dismissed')),
                          );
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: getSeverityColor(alert.severity),
                              child: Icon(
                                alert.severity == "Critical"
                                    ? Icons.error
                                    : alert.severity == "Warning"
                                    ? Icons.warning
                                    : Icons.info_outline,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              alert.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: alert.isRead
                                    ? Colors.grey.shade600
                                    : Colors.black,
                              ),
                            ),
                            subtitle: Text(alert.message),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  alert.time,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.date,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                alert.isRead = true;
                              });
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(alert.title),
                                  content: Text(alert.message),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Custom filter button widget
  Widget _buildFilterButton(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade700),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
