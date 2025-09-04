// lib/leave_application/leave_application_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({Key? key}) : super(key: key);

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  // Form data
  String? selectedName;
  String? selectedType;
  DateTime dateFrom = DateTime.now();
  DateTime dateTo = DateTime.now();
  List<DateTime?> individualDates = [];

  // UI state
  bool showConsecutive = false;
  bool showIndividual = false;

  // Data from sheet
  List<String> names = [];
  List<String> leaveTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    const String apiUrl = 'https://script.google.com/macros/s/AKfycbw-Nx-NnL7w5Mklhg0_NMxTUaPMm1Um9M4D_cNGNMmw25rr4D_co-OqN9-_WBkOVjPl6Q/exec';

    try {
      final namesRes = await http.get(Uri.parse('$apiUrl?action=getEmployeeNames'));
      if (namesRes.statusCode == 200) {
        final data = json.decode(namesRes.body);
        if (data is List) {
          setState(() {
            names = List<String>.from(data);
          });
        }
      }

      final typesRes = await http.get(Uri.parse('$apiUrl?action=getLeaveTypes'));
      if (typesRes.statusCode == 200) {
        final data = json.decode(typesRes.body);
        if (data is List) {
          setState(() {
            leaveTypes = List<String>.from(data);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to load: $e")),
      );
    }
  }

  Future<void> _submitForm() async {
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => const PasswordDialog(),
    );

    if (password == null) return;

    final uid = password;

    // ✅ Validation: Name and Type
    if (selectedName == null || selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Name and Leave Type")),
      );
      return;
    }

    // ✅ Validation: At least one date type must be filled
    bool hasValidDates = false;

    if (showConsecutive && dateFrom != null && dateTo != null) {
      hasValidDates = true;
    }

    if (showIndividual) {
      hasValidDates = individualDates.any((d) => d != null);
    }

    if (!hasValidDates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least one date")),
      );
      return;
    }

    final formData = <String, String>{};

    // Add basic fields
    formData['name'] = selectedName!;
    formData['type'] = selectedType!;

    // Add consecutive dates
    if (showConsecutive) {
      formData['dateFrom'] = DateFormat('yyyy-MM-dd').format(dateFrom);
      formData['dateTo'] = DateFormat('yyyy-MM-dd').format(dateTo);
    }

    // Add individual dates
    for (int i = 0; i < individualDates.length; i++) {
      if (individualDates[i] != null) {
        formData['date${i + 1}'] = DateFormat('yyyy-MM-dd').format(individualDates[i]!);
      }
    }

    // ✅ Optimistic Submission: Assume success
    Future.microtask(() => _submitToGoogleForm(formData));

    // ✅ Immediately show success
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("✅ Success!"),
        content: const Text("Your leave application has been submitted. Check in Monitoring"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetForm();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitToGoogleForm(Map<String, String> formData) async {
    final url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSfdyDOk1d2qWbRkRbXyyPSC7ttMcsoqtpDDNqzN-sC-VAAznQ/formResponse');

    try {
      await http.post(url, body: {
        "entry.1374311245": formData['name'] ?? "",
        "entry.258507669": formData['type'] ?? "",
        "entry.1008871780": formData['dateFrom'] ?? "",
        "entry.14406673": formData['dateTo'] ?? "",
        "entry.1235632097": formData['date1'] ?? "",
        "entry.1228742625": formData['date2'] ?? "",
        "entry.635337329": formData['date3'] ?? "",
        "entry.1013665385": formData['date4'] ?? "",
        "entry.38373863": formData['date5'] ?? "",
        "entry.634662813": formData['date6'] ?? "",
      });
    } catch (e) {
      print("Background submit error: $e");
    }
  }

  void _resetForm() {
    setState(() {
      selectedName = null;
      selectedType = null;
      dateFrom = DateTime.now();
      dateTo = DateTime.now();
      individualDates.clear();
      showConsecutive = false;
      showIndividual = false;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Leave Application")),
    body: Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          // Name
          DropdownButtonFormField<String>(
            value: selectedName,
            hint: const Text("Select Name"),
            items: names.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
            onChanged: (v) => setState(() => selectedName = v),
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),

          const SizedBox(height: 20),

          // Leave Type
          DropdownButtonFormField<String>(
            value: selectedType,
            hint: const Text("Select Leave Type"),
            items: leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => selectedType = v),
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),

          const SizedBox(height: 30),

          // Date Type Selection
          Text("Select Date Type", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          // Consecutive Days Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                showConsecutive = !showConsecutive;
                if (!showConsecutive) {
                  dateFrom = DateTime.now();
                  dateTo = DateTime.now();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: showConsecutive ? Colors.blue : null,
            ),
            icon: const Icon(Icons.compare_arrows, size: 18),
            label: Text(showConsecutive ? "Hide Consecutive Days" : "Consecutive Days"),
          ),

          const SizedBox(height: 12),

          // Individual Dates Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                showIndividual = !showIndividual;
                if (showIndividual && individualDates.isEmpty) {
                  // ✅ Auto-add first date when opening
                  individualDates.add(null);
                } else if (!showIndividual) {
                  // ✅ Clear when closing
                  individualDates.clear();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: showIndividual ? Colors.green : null,
            ),
            icon: const Icon(Icons.event, size: 18),
            label: Text(showIndividual ? "Hide Individual Dates" : "Individual Dates"),
          ),

          // Consecutive Days Fields
          if (showConsecutive)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text("Consecutive Period", style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField("Date From", dateFrom, (d) => setState(() => dateFrom = d)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDateField("Date To", dateTo, (d) => setState(() => dateTo = d)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Individual Dates Fields
          if (showIndividual)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text("Individual Dates", style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...individualDates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: _buildDateField("Date ${index + 1}", date, (d) => setState(() => individualDates[index] = d)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            individualDates.removeAt(index);
                          });
                        },
                      ),
                    ],
                  );
                }).expand((w) => [w, const SizedBox(height: 12)]),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      individualDates.add(null);
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add Another Date"),
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Submit Button
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              "Submit Leave Application",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDateField(String label, DateTime? date, ValueChanged<DateTime> onChanged) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onChanged(d);
      },
      controller: TextEditingController(
        text: date != null ? DateFormat('MMM d, yyyy').format(date) : '',
      ),
    );
  }
}

// Reuse PasswordDialog
class PasswordDialog extends StatefulWidget {
  const PasswordDialog({Key? key}) : super(key: key);

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter Password"),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text("Submit"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}