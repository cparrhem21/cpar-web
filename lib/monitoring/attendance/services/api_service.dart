// lib/attendance/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/attendance.dart'; // ✅ Correct

class ApiService {
  // ✅ Your Web App URL with ?data=1
  static const String apiUrl =
      'https://script.google.com/macros/s/AKfycbxTEjZnuLU8uz05edrhW5HP3wVwY3f82A2Tipz2aPWYsELgXZI54c77gmfWtKK4dm1Q7Q/exec?data=1';

  Future<List<AttendanceData>> getAttendanceData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
      final body = response.body;
      if (body.startsWith('<')) {
        throw Exception('Received HTML instead of JSON');
      }
      final data = json.decode(body);
      if (data is List) {
        return data.map((item) => AttendanceData.fromJson(item)).toList();
      } else {
        throw Exception('Expected list, got: ${data.runtimeType}');
      }
    } catch (e) {
      throw Exception('Failed to load  $e');
    }
  }
}