// lib/main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:cparapp/models/user_profile.dart';

// ✅ Import your main screens
import 'applications/applications_screen.dart';
import 'monitoring/monitoring_screen.dart';
import 'monthly_accomplishment_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPAR App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ Use the proxy URL to bypass CORS
  final String proxyBaseUrl = 'https://cpar-web.netlify.app/.netlify/functions/proxy?url=https%3A%2F%2Fscript.google.com%2Fmacros%2Fs%2FAKfycbzGHwbf-cCTTNjy3YsDpAJH41M0eI78Lbf_Q4rnVOm6u58Nq36oHN9uoBY1H9dT2EvY%2Fexec';
  List<UserProfile> users = [];
  String? selectedUserName;
  String password = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
  setState(() {
    isLoading = true;
  });

  try {
    final String actionUrl = '$proxyBaseUrl%3Faction%3DgetUsers';
    final response = await http.get(Uri.parse(actionUrl));

    if (response.statusCode == 200) {
      final responseBody = response.body.trim();

      if (responseBody.isEmpty) {
        throw Exception('Empty response from server');
      }

      final List<dynamic> data = json.decode(responseBody);

      setState(() {
        // ✅ Map and sort users by name
        users = data
            .map((u) => UserProfile(
                  name: u['name'],
                  concurredBy: u['concurredBy'],
                  role: u['role'],
                  password: u['password'],
                ))
            .toList()
          ..sort((a, b) => a.name!.compareTo(b.name!)); // ✅ Sort A-Z

        // ✅ Default to first user after sort
        if (users.isNotEmpty) {
          selectedUserName = users[0].name;
        }
      });
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to load user list: $e")),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  // ✅ Show login dialog
  Future<void> _showLoginDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Access Monthly Accomplishment Report"),
            content: isLoading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Loading users..."),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedUserName,
                        hint: const Text("Select your name"),
                        items: users.map<DropdownMenuItem<String>>((u) {
                          return DropdownMenuItem(
                            value: u.name,
                            child: Text(u.name!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedUserName = value);
                        },
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Name"),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => password = value,
                        autofocus: true,
                      ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedUserName == null || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  // ✅ Send both selected user AND password
                  final String validateUrl =
                      '$proxyBaseUrl%3Faction%3DvalidatePasswordForUser%26user%3D${Uri.encodeComponent(selectedUserName!)}%26password%3D${Uri.encodeComponent(password)}';

                  try {
                    final response = await http.get(Uri.parse(validateUrl));
                    final responseBody = response.body.trim();

                    if (response.statusCode == 200 && responseBody.isNotEmpty) {
                      final result = json.decode(responseBody);

                      if (result['valid'] == true) {
                        final UserProfile? user = users.firstWhereOrNull((u) => u.name == selectedUserName);

                        if (user != null) {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MonthlyAccomplishmentScreen(userProfile: user),
                            ),
                          );
                          return;
                        }
                      }
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid password for this user")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Login failed: $e")),
                    );
                  }
                },
                child: const Text("Login"),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CPAR App")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ApplicationsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Applications",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MonitoringScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Monitoring",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (users.isEmpty && !isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User list not loaded yet. Try again.")),
                  );
                  fetchUsers();
                } else {
                  _showLoginDialog(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Monthly Accomplishment Report",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}