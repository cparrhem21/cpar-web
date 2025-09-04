// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  // ✅ Your API URL
  final String marApiUrl = 'https://script.google.com/macros/s/AKfycbzGHwbf-cCTTNjy3YsDpAJH41M0eI78Lbf_Q4rnVOm6u58Nq36oHN9uoBY1H9dT2EvY/exec';

  // ✅ Debug function to test API
  void debugTestApi() async {
    final url = '$marApiUrl?action=validatePassword&password=ember';

    try {
      final response = await http.get(Uri.parse(url));
      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    debugTestApi(); // ✅ Run test when screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login Debug")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Testing API..."),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: debugTestApi,
              child: Text("Test API Again"),
            ),
          ],
        ),
      ),
    );
  }
}