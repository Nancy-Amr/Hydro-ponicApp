import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydroponics Alerts Demo',
      theme: ThemeData(
        // Keeping the Material 3 design and the green seed color
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        // Customizing AppBar for a cleaner look
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const AlertsScreen(),
    );
  }
}

class AlertItem {
  final String id;
  final String title;
  final String message;
  final String severity; // Critical, Warning, Info
  final String time; // e.g., "14:32"
  final String date; // e.g., "Today", "Yesterday"
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
      title: "High pH Detected",
      message: "pH level 7.8 exceeded safe range. Action required.",
      severity: "Critical",
      time: "14:32",
      date: "Today",
      isRead: false,
    ),
    AlertItem(
      id: 'a2',
      title: "Low Water Level",
      message: "Reservoir water below 30%. Replenish soon.",
      severity: "Warning",
      time: "12:50",
      date: "Today",
      isRead: false,
    ),
    AlertItem(
      id: 'a3',
      title: "Light Sensor Offline",
      message: "LDR sensor not responding. Check connection.",
      severity: "Info",
      time: "10:00",
      date: "Yesterday",
      isRead: true,
    ),
    AlertItem(
      id: 'a4',
      title: "Nutrient Auto-Dose Failed",
      message: "Pump P1 did not activate.",
      severity: "Critical",
      time: "08:15",
      date: "Yesterday",
      isRead: false,
    ),
    AlertItem(
      id: 'a5',
      title: "Temperature Stable",
      message: "System running at 22.5°C.",
      severity: "Info",
      time: "15:00",
      date: "Today",
      isRead: true,
    ),
  ];

  // --- Utility Functions ---

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

  // Gets the color for the severity indicator
  Color getSeverityColor(String severity) {
    switch (severity) {
      case "Critical":
        return Colors.red.shade700;
      case "Warning":
        return Colors.orange.shade700;
      case "Info":
        return Colors.green.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  // Gets the icon for the severity indicator
  IconData getSeverityIcon(String severity) {
    switch (severity) {
      case "Critical":
        return Icons.warning_rounded;
      case "Warning":
        return Icons.info_outline_rounded;
      case "Info":
        return Icons.notifications_active_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // --- Widgets ---

  // Custom filter chip widget
  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.green.shade700,
      backgroundColor: Colors.green.shade50,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.green.shade800,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.green.shade700 : Colors.green.shade300,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedFilter = label;
          });
        }
      },
    );
  }

  // Individual Alert List Item (Replaced ListTile with custom Card)
  Widget _buildAlertCard(AlertItem alert) {
    final severityColor = getSeverityColor(alert.severity);
    final severityIcon = getSeverityIcon(alert.severity);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Add a subtle border for unread critical alerts
        side: alert.severity == "Critical" && !alert.isRead
            ? BorderSide(color: severityColor, width: 2)
            : BorderSide.none,
      ),
      color: alert.isRead ? Colors.white : Colors.green.shade50,
      child: InkWell(
        onTap: () {
          setState(() {
            alert.isRead = true; // Mark as read on tap
          });
          _showAlertDialog(alert); // Show detailed dialog
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Severity/Status Indicator
              Container(
                width: 6,
                height: 50, // Match a good height for the text
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              // 2. Icon + Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(severityIcon, size: 20, color: severityColor),
                        const SizedBox(width: 6),
                        // Title
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontWeight: alert.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                              color: alert.isRead
                                  ? Colors.grey.shade700
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Message
                    Text(
                      alert.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: alert.isRead
                            ? Colors.grey.shade500
                            : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 3. Time/Date Indicator
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      alert.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: alert.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    Text(
                      alert.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog to show detailed alert information
  void _showAlertDialog(AlertItem alert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              getSeverityIcon(alert.severity),
              color: getSeverityColor(alert.severity),
            ),
            const SizedBox(width: 10),
            Text(
              alert.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 10),
            Text(
              'Severity: ${alert.severity}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Time: ${alert.time} on ${alert.date}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: TextStyle(color: Colors.green.shade700)),
          ),
        ],
      ),
    );
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // This navigates back to the previous screen (the Dashboard)
            Navigator.pop(context);
          },
        ),
        title: const Text("System Alerts"),
        actions: [
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
                  backgroundColor: Colors.green.shade700,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search title, message, or time...',
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Critical"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Warning"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Info"),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          // Alerts List
          Expanded(
            child: filteredAlerts.isEmpty
                ? Center(
                    child: Text(
                      alerts.isEmpty
                          ? "No historical alerts available."
                          : "No alerts match your current filter/search.",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      // Use a different color for the dismiss background
                      return Dismissible(
                        key: ValueKey(alert.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.done_all,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        onDismissed: (direction) {
                          // Note: In a real app, you'd likely update the DB/API here
                          setState(() {
                            alerts.removeWhere((a) => a.id == alert.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Alert "${alert.title}" resolved and removed.',
                              ),
                              backgroundColor: Colors.green.shade600,
                            ),
                          );
                        },
                        child: _buildAlertCard(alert),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
