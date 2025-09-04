// lib/monitoring/travel_order/travel_order_search_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TravelOrderSearchScreen extends StatefulWidget {
  const TravelOrderSearchScreen({Key? key}) : super(key: key);

  @override
  State<TravelOrderSearchScreen> createState() => _TravelOrderSearchScreenState();
}

class _TravelOrderSearchScreenState extends State<TravelOrderSearchScreen> {
  final TextEditingController _nameController = TextEditingController();
  final String _apiUrl = 'https://script.google.com/macros/s/AKfycbwdiqE6XjEyV2u54nqwuWpS592y16BBH9JyYlT3AN5XVdc6ezVS3aj2LlHp32z7iZP8/exec';

  List<TravelOrder> filteredOrders = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Travel Order Search")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search by Name or Assistant
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Enter Name or Assistant",
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
                    const SnackBar(content: Text("Please enter a search term")),
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
                  : filteredOrders.isEmpty
                      ? const Center(child: Text("No results found"))
                      : ListView.builder(
                          itemCount: filteredOrders.length,
                          itemBuilder: (ctx, i) {
                            final o = filteredOrders[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Name: ${o.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("TO #: ${o.toNumber}"),
                                    Text("Destination: ${o.destination}"),
                                    Text("Purpose: ${o.purpose}"),
                                    Text("Dates: ${o.startDateStr} to ${o.endDateStr}"),
                                    Text("Assistant: ${o.assistant}"),
                                    // ✅ Colored Status Chip
                                    _buildStatusChip(o.status),
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

  // ✅ Status Chip: Released (Green), For Signing (Orange), For Processing (Red)
  Widget _buildStatusChip(String? status) {
    final String displayText = (status ?? '').trim().toLowerCase();
    String text;
    Color color;

    if (displayText == 'released') {
      text = 'Released';
      color = Colors.green;
    } else if (displayText == 'for signing') {
      text = 'For Signing';
      color = Colors.orange;
    } else if (displayText.isEmpty || displayText == 'null') {
      text = 'For Processing';
      color = Colors.red;
    } else {
      text = status!.trim();
      color = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _searchByName(String query) async {
    setState(() {
      isLoading = true;
      filteredOrders = [];
    });

    try {
      final url = Uri.parse('$_apiUrl?action=searchByName&query=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          filteredOrders = data.map((json) => TravelOrder.fromJson(json)).toList();
        });
      } else {
        setState(() {
          filteredOrders = [];
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
      filteredOrders = [];
    });

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final url = Uri.parse('$_apiUrl?action=getTravelOrdersForDate&date=$dateStr');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          filteredOrders = data.map((json) => TravelOrder.fromJson(json)).toList();
        });
      } else {
        setState(() {
          filteredOrders = [];
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

class TravelOrder {
  final String name, assistant, destination, purpose, toNumber, status;
  final String startDateStr, endDateStr;

  TravelOrder({
    required this.name,
    required this.assistant,
    required this.destination,
    required this.purpose,
    required this.startDateStr,
    required this.endDateStr,
    required this.toNumber,
    required this.status,
  });

  factory TravelOrder.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value) {
      if (value == null) return "";
      if (value is String) return value;
      return value.toString();
    }

    return TravelOrder(
      name: safeString(json['name']),
      assistant: safeString(json['assistant']),
      destination: safeString(json['destination']),
      purpose: safeString(json['purpose']),
      startDateStr: safeString(json['startDate']),
      endDateStr: safeString(json['endDate']),
      toNumber: safeString(json['toNumber']),
      status: safeString(json['status']),
    );
  }
}