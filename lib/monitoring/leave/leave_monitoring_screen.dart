// lib/monitoring/leave/leave_monitoring_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaveMonitoringScreen extends StatefulWidget {
  const LeaveMonitoringScreen({Key? key}) : super(key: key);

  @override
  State<LeaveMonitoringScreen> createState() => _LeaveMonitoringScreenState();
}

class _LeaveMonitoringScreenState extends State<LeaveMonitoringScreen> {
  final TextEditingController _nameController = TextEditingController();
  final String _apiUrl = 'https://script.google.com/macros/s/AKfycbwFYB_dixev7MSuYkfzFVoLEGWEVcyec2DusaNoFpc4IaNAOF2PhN3kthlF1pXpJHZNNw/exec';

  List<LeaveRecord> filteredRecords = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave Monitoring")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search by Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Enter Name",
                border: OutlineInputBorder(),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _nameController.clear();
                        },
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            // Search Button
            ElevatedButton.icon(
              onPressed: () {
                final query = _nameController.text.trim();
                if (query.isNotEmpty) {
                  _searchByName(query);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a name")),
                  );
                }
              },
              icon: const Icon(Icons.search, size: 18),
              label: const Text("Search by Name"),
            ),

            const SizedBox(height: 16),

            // Search by Date
            ElevatedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  _searchByDate(date);
                }
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text("Search by Date"),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredRecords.isEmpty
                      ? const Center(child: Text("No results found"))
                      : ListView.builder(
                          itemCount: filteredRecords.length,
                          itemBuilder: (ctx, i) {
                            final r = filteredRecords[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Name: ${r.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("Leave Type: ${r.leaveType}"),
                                    if (r.startDate.isNotEmpty)
                                      Text("Date Range: ${r.startDate} to ${r.endDate}"),
                                    if (r.specificDates.isNotEmpty)
                                      Text("Specific Dates: ${r.specificDates.join(', ')}"),
                                      Text(
  "Status: ${r.status}",
  style: TextStyle(
    color: r.status.toLowerCase().contains('approved')
        ? Colors.green
        : r.status.toLowerCase().contains('pending')
            ? Colors.orange
            : r.status.toLowerCase().contains('cancelled')
                ? Colors.red
                : Colors.black,
  ),
),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchByName(String query) async {
    setState(() {
      isLoading = true;
      filteredRecords = [];
    });

    try {
      final url = Uri.parse('$_apiUrl?action=searchLeaveByName&query=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          filteredRecords = data.map((json) => LeaveRecord.fromJson(json)).toList();
        });
      } else {
        setState(() {
          filteredRecords = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search failed: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _searchByDate(DateTime date) async {
    setState(() {
      isLoading = true;
      filteredRecords = [];
    });

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final url = Uri.parse('$_apiUrl?action=getLeaveForDate&date=$dateStr');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          filteredRecords = data.map((json) => LeaveRecord.fromJson(json)).toList();
        });
      } else {
        setState(() {
          filteredRecords = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Date search failed: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class LeaveRecord {
  final String name, leaveType, startDate, endDate, status;
  final List<String> specificDates;

  LeaveRecord({
    required this.name,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.specificDates,
    required this.status, // ✅ Add status
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value) {
      if (value == null) return "";
      if (value is String) return value;
      return value.toString();
    }

    List<String> extractDates(dynamic value) {
      if (value is List) {
        return value.map(safeString).where((d) => d.isNotEmpty && d != "Invalid Date").toList();
      }
      return [];
    }

    return LeaveRecord(
      name: safeString(json['name']),
      leaveType: safeString(json['leaveType']),
      startDate: safeString(json['startDate']),
      endDate: safeString(json['endDate']),
      specificDates: extractDates(json['specificDates']),
      status: safeString(json['status']), // ✅ Add status
    );
  }
}