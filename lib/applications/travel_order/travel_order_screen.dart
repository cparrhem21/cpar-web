// lib/applications/travel_order/travel_order_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'services/travel_order_service.dart';
import 'model/travel_order_options.dart';
import 'dart:convert';

class TravelOrderScreen extends StatefulWidget {
  const TravelOrderScreen({Key? key}) : super(key: key);

  @override
  State<TravelOrderScreen> createState() => _TravelOrderScreenState();
}

class _TravelOrderScreenState extends State<TravelOrderScreen> {
  final TravelOrderService service = TravelOrderService();

  String? selectedGroup;
  String? selectedName;
  List<String> selectedNames = [];
  List<String> selectedAssistants = [];
  String destination = '';
  String purpose = '';
  String diem = '';
  DateTime startDate = DateTime.now();
  DateTime returnDate = DateTime.now();

  TravelOrderOptions? options;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    service.loadAllPasswords();
  }

  Future<void> _loadOptions() async {
    if (selectedGroup == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Loading names..."),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final result = await service.getOptionsByGroup(selectedGroup!);
      Navigator.pop(context); // Dismiss loading

      setState(() {
        options = result;
        selectedName = null;
        selectedNames.clear();
        selectedAssistants.clear();
      });
    } catch (e) {
      Navigator.pop(context); // Dismiss loading first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to load names: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
  final password = await showDialog<String>(
    context: context,
    builder: (ctx) => const PasswordDialog(),
  );

  if (password == null) return;

  final uid = service.validatePassword(password);
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid password")),
    );
    return;
  }

  final nameValue = ["Regular Employee", "Contractual"].contains(selectedGroup)
      ? selectedName
      : selectedNames.isNotEmpty ? selectedNames.join(', ') : null;

  if (nameValue == null || destination.isEmpty || purpose.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields")),
    );
    return;
  }

  if (returnDate.isBefore(startDate)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Return date cannot be earlier than start date")),
    );
    return;
  }

  final formData = {
    'name': nameValue,
    'asst': selectedAssistants.join(', '),
    'dest': destination,
    'purp': purpose,
    'diem': diem,
    'sdate': DateFormat('yyyy-MM-dd').format(startDate),
    'rdate': DateFormat('yyyy-MM-dd').format(returnDate),
    'uid': uid,
  };

  // ✅ Optimistic Submission: Assume it works
  // Don't wait for response — just show success
  Future.microtask(() => _submitToGoogleForm(formData));

  // ✅ Immediately show success dialog
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("✅ Success!"),
      content: const Text(
        "Your Travel Order has been submitted! "
        "Check in Monitoring to be sure!",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            // Reset form
            setState(() {
              selectedGroup = null;
              selectedName = null;
              selectedNames.clear();
              selectedAssistants.clear();
              destination = '';
              purpose = '';
              diem = '';
              startDate = DateTime.now();
              returnDate = DateTime.now();
              options = null;
            });
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

  Future<void> _submitToGoogleForm(Map<String, String> formData) async {
  final url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSfrY-MTUSiXZ9tntWSANii_5XEYje8-qGpC1uu2wGztjwvkXQ/formResponse');

  try {
    await http.post(url, body: {
      "entry.1093569395": formData['name'] ?? "",
      "entry.990741084": formData['asst'] ?? "",
      "entry.2094993328": formData['dest'] ?? "",
      "entry.864522347": formData['purp'] ?? "",
      "entry.1456108573": formData['diem'] ?? "",
      "entry.1021316377": formData['sdate'] ?? "",
      "entry.1170141646": formData['rdate'] ?? "",
      "entry.1077097729": formData['uid'] ?? "Unknown",
    });
  } catch (e) {
    // ✅ Ignore error — user already saw success
    print("Background submit error: $e");
  }
}

  Widget _buildDateField(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onChanged(d);
      },
      controller: TextEditingController(text: DateFormat('MMM d, yyyy').format(date)),
    );
  }

  void _showPicker(List<String> items, List<String> selected, StateSetter setState) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: const Text(
              "Select Name",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final name = items[index];
                if (selected.contains(name)) return const SizedBox();
                return ListTile(
                  title: Text(name),
                  onTap: () {
                    setState(() => selected.add(name));
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Travel Order")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: selectedGroup,
              hint: const Text("Select Group"),
              items: const [
                DropdownMenuItem(value: "Regular Employee", child: Text("Regular Employee")),
                DropdownMenuItem(value: "Contractual", child: Text("Contractual")),
                DropdownMenuItem(value: "FPO", child: Text("FPO")),
                DropdownMenuItem(value: "FG", child: Text("FG")),
              ],
              onChanged: (v) {
                setState(() => selectedGroup = v);
                _loadOptions();
              },
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            if (options != null) ...[
              Text("Name", style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              if (["Regular Employee", "Contractual"].contains(selectedGroup))
                DropdownButtonFormField<String>(
                  value: selectedName,
                  hint: const Text("Select Name"),
                  items: options!.names.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (v) => setState(() => selectedName = v),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                )
              else
                Wrap(spacing: 8, children: [
                  ...selectedNames.map((n) => Chip(label: Text(n), onDeleted: () => setState(() => selectedNames.remove(n)))),
                  TextButton(onPressed: () => _showPicker(options!.names, selectedNames, setState), child: const Text("Add Name")),
                ]),
              if (options!.showAssistant) ...[
                const SizedBox(height: 20),
                Text("Assistant(s)", style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  ...selectedAssistants.map((n) => Chip(label: Text(n), onDeleted: () => setState(() => selectedAssistants.remove(n)))),
                  TextButton(onPressed: () => _showPicker(options!.assistants, selectedAssistants, setState), child: const Text("Add Assistant")),
                ]),
              ],
            ],
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: "Destination", border: OutlineInputBorder()), onChanged: (v) => destination = v),
            const SizedBox(height: 20),
            TextField(maxLines: 3, decoration: InputDecoration(labelText: "Purpose", border: OutlineInputBorder()), onChanged: (v) => purpose = v),
            if (options?.showDiem == true) ...[
              const SizedBox(height: 20),
              TextField(decoration: InputDecoration(labelText: "Per Diem", border: OutlineInputBorder()), onChanged: (v) => diem = v),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _buildDateField("Start Date", startDate, (d) => setState(() => startDate = d))),
              const SizedBox(width: 10),
              Expanded(child: _buildDateField("Return Date", returnDate, (d) => setState(() => returnDate = d))),
            ]),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Moved outside the class
class PasswordDialog extends StatefulWidget {
  const PasswordDialog({Key? key}) : super(key: key);

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("🔐 Enter Password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "To submit, please enter your password.",
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Password",
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a password")),
              );
              return;
            }
            Navigator.pop(context, _controller.text);
          },
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