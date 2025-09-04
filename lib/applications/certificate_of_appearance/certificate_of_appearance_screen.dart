// lib/applications/certificate_of_appearance/certificate_of_appearance_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:meta/meta.dart' show unawaited;

class CertificateOfAppearanceScreen extends StatefulWidget {
  const CertificateOfAppearanceScreen({Key? key}) : super(key: key);

  @override
  State<CertificateOfAppearanceScreen> createState() => _CertificateOfAppearanceScreenState();
}

class _CertificateOfAppearanceScreenState extends State<CertificateOfAppearanceScreen> {
  // Form fields
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController employerController = TextEditingController();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  // Dynamic names list
  final List<TextEditingController> nameControllers = [TextEditingController()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Certificate of Appearance"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Purpose (taller)
            TextField(
              controller: purposeController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Purpose",
                hintText: "Enter the purpose of appearance",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Employer
            TextField(
              controller: employerController,
              decoration: const InputDecoration(
                labelText: "Employer",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Start Date
            _buildDateField("Start Date", startDate, (d) => setState(() => startDate = d)),

            const SizedBox(height: 20),

            // End Date
            _buildDateField("End Date", endDate, (d) => setState(() => endDate = d)),

            const SizedBox(height: 40),

            // Names Section
            Text("Names (at least one required)", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),

            // Dynamic name fields
            ...nameControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: "Name ${index + 1}",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (nameControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          nameControllers.removeAt(index);
                        });
                      },
                    ),
                ],
              );
            }).expand((w) => [w, const SizedBox(height: 12)]),

            const SizedBox(height: 12),

            // Add Name Button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  nameControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add Name"),
            ),

            const SizedBox(height: 40),

            // Submit Button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Submit Certificate",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onChanged(d);
      },
      controller: TextEditingController(
        text: DateFormat('MMM d, yyyy').format(date),
      ),
    );
  }

  Future<void> _submitForm() async {
  final String purpose = purposeController.text.trim();
  final String employer = employerController.text.trim();

  // Validate required fields
  if (purpose.isEmpty || employer.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill Purpose and Employer")),
    );
    return;
  }

  if (endDate.isBefore(startDate)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("End date cannot be before start date")),
    );
    return;
  }

  // Check at least one name is filled
  final List<String> filledNames = nameControllers.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
  if (filledNames.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter at least one name")),
    );
    return;
  }

  // Show password dialog
  final password = await showDialog<String>(
    context: context,
    builder: (ctx) => const PasswordDialog(),
  );

  if (password == null || password.isEmpty) return;

  // Validate OTP
  final isValid = await _validateOTP(password);
  if (!isValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid OTP")),
    );
    return;
  }

  // ✅ Prepare form data
  final formData = <String, String>{};

  formData['entry.944173511'] = purpose;
  formData['entry.716254752'] = employer;
  formData['entry.520649989'] = DateFormat('yyyy-MM-dd').format(startDate);
  formData['entry.321253392'] = DateFormat('yyyy-MM-dd').format(endDate);

  // Add up to 6 names
  final List<String> entryIds = [
    '726572294',
    '1335867164',
    '1626369174',
    '647902687',
    '1119361321',
    '2015416229'
  ];

  for (int i = 0; i < 6; i++) {
    final value = i < nameControllers.length ? nameControllers[i].text.trim() : '';
    formData['entry.${entryIds[i]}'] = value;
  }

  // ✅ Fire and forget using microtask (replaces unawaited)
  Future.microtask(() => _submitToGoogleForm(formData));

  // ✅ Immediately show success
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("✅ Submitted!"),
      content: const Text("Your Certificate of Appearance has been submitted."),
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

  Future<bool> _validateOTP(String otp) async {
    try {
      // ✅ Removed trailing spaces in URL
      final url = Uri.parse('https://script.google.com/macros/s/AKfycbw-Nx-NnL7w5Mklhg0_NMxTUaPMm1Um9M4D_cNGNMmw25rr4D_co-OqN9-_WBkOVjPl6Q/exec')
          .replace(queryParameters: {
        'action': 'validateOTP',
        'otp': otp,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map && data['valid'] == true;
      }

      print("validateOTP failed: ${response.statusCode} - ${response.body}");
      return false;
    } catch (e) {
      print("Error in validateOTP: $e");
      return false;
    }
  }

  Future<void> _submitToGoogleForm(Map<String, String> formData) async {
    // ✅ Removed trailing spaces in URL
    final url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSfL40Vs7-7JRZz5Cv6ZmRWlk9Ahz8WJ0VOl3vNpng2WYWe7bg/formResponse');

    try {
      await http.post(url, body: formData);
    } catch (e) {
      print("Background submit error: $e");
    }
  }

  void _resetForm() {
    purposeController.clear();
    employerController.clear();
    startDate = DateTime.now();
    endDate = DateTime.now();
    for (var c in nameControllers) c.dispose();
    nameControllers.clear();
    nameControllers.add(TextEditingController()); // Keep one field
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
      title: const Text("Enter OTP"),
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