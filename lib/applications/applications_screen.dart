// lib/applications/applications_screen.dart
import 'package:flutter/material.dart';
import 'travel_order/travel_order_screen.dart';
import 'leave_application/leave_application_screen.dart';
import 'certificate_of_appearance/certificate_of_appearance_screen.dart';
import 'inventory_update_screen.dart'; // ✅ Adjust path if needed
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({Key? key}) : super(key: key);

Future<void> _showPasswordDialog(BuildContext context) async {
  final passwordController = TextEditingController();

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Inventory Update"),
      content: TextField(
        controller: passwordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: "Enter Password",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _validateAndProceed(context, passwordController.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => _validateAndProceed(context, passwordController.text),
          child: const Text("Submit"),
        ),
      ],
    ),
  );
}

Future<void> _validateAndProceed(BuildContext parentContext, String password) async {
  if (password.isEmpty) {
    ScaffoldMessenger.of(parentContext).showSnackBar(
      const SnackBar(content: Text("Please enter a password")),
    );
    return;
  }

  // Show loading
  showDialog(
    context: parentContext,
    builder: (ctx) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Validating password..."),
        ],
      ),
    ),
  );

  try {
    final url = 'https://script.google.com/macros/s/AKfycbwbrJzUVcEwEbAljnsaZo3cugtm9JEMKZweDjNC4rmVuC3q2b52IGhv8m4dUOgXHP93DQ/exec?action=validatePassword&password=$password';
    final response = await http.get(Uri.parse(url));

    // Close loading
    Navigator.pop(parentContext);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['valid'] == true) {
        // ✅ Correct navigation: no 'const', pass currentUser
        Navigator.push(
          parentContext,
          MaterialPageRoute(
            builder: (_) => InventoryUpdateScreen(currentUser: data['user']),
          ),
        );

        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text("✅ Welcome, ${data['user']}!")),
        );
      } else {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text("❌ Invalid password")),
        );
      }
    } else {
      throw Exception("Failed to connect");
    }
  } catch (e) {
    // Close loading if still open
    if (ModalRoute.of(parentContext)?.isCurrent != true) {
      // Safe to pop?
    }
    Navigator.pop(parentContext, false);

    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text("❌ Failed to fetch: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Applications"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Travel Order
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TravelOrderScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Travel Order Application",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            // Leave Application
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaveApplicationScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Leave Application",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CertificateOfAppearanceScreen()),
    );
  },
  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
  child: const Text("Certificate of Appearance", style: TextStyle(color: Colors.white)),
),

const SizedBox(height: 20),

ElevatedButton.icon(
  onPressed: () => _showPasswordDialog(context),
  icon: const Icon(Icons.inventory),
  label: const Text("Inventory Update"),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
),
          ],
        ),
      ),
    );
  }
}