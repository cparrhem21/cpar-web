import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/leave_options.dart';

class LeaveService {
  // 🔗 Your Apps Script Web App URL
  static const String scriptUrl =
      'https://script.google.com/macros/s/AKfycbyKrA6KrKQ9a5ZujIFTZX9tC2hROrhM5fAnLFhqVhthYaT2R1wLqX1sL0-XysO1vQAV/exec';

  // 🗄 Cache for passwords (same as Travel Order)
  Set<String> _passwords = {};
  bool _loaded = false;

  // 📋 Get names and leave types
  Future<LeaveOptions> getLeaveOptions() async {
    try {
      final response = await http.post(Uri.parse(scriptUrl), body: {
        'action': 'getDropdownData',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LeaveOptions(
          names: List<String>.from(data['names'] ?? []),
          leaveTypes: List<String>.from(data['leaveTypes'] ?? []),
        );
      } else {
        throw Exception('Failed to load options');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // 🔐 Load all passwords (same logic)
  Future<void> loadAllPasswords() async {
    if (_loaded) return;

    try {
      final response = await http.post(Uri.parse(scriptUrl), body: {
        'action': 'getAllPasswords', // We added this earlier
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          _passwords = data.map((p) => p.toString()).toSet();
          _loaded = true;
        }
      }
    } catch (e) {
      print("Failed to load passwords: $e");
    }
  }

  // ✅ Validate password locally
  String? validatePassword(String password) {
    return _passwords.contains(password) ? password : null;
  }
}