import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/travel_order_options.dart';

class TravelOrderService {
  // Public Google Sheets JSON feed (gid=0)
  static const String sheetUrl =
    'https://script.google.com/macros/s/AKfycbyKrA6KrKQ9a5ZujIFTZX9tC2hROrhM5fAnLFhqVhthYaT2R1wLqX1sL0-XysO1vQAV/exec?action=getEmployeeData';

  // ✅ Declare the cells map
  final Map<String, String> cells = {};

  // 🗄 Cache for passwords
  Set<String> _passwords = {};
  bool _loaded = false;

  Future<TravelOrderOptions> getOptionsByGroup(String group) async {
  try {
    final response = await http.get(Uri.parse(sheetUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load sheet');
    }

    // ✅ Parse the JSON (it's a list of lists)
    final List<List<dynamic>> values = List<List<dynamic>>.from(json.decode(response.body));

    List<String> names = [];
    List<String> assistants = [];
    bool showAssistant = true;
    bool showDiem = group == 'Regular Employee';

    // Helper: extract non-empty strings and sort
    List<String> extractColumn(List<List<dynamic>> data, int colIndex, int startRow, [int? endRow]) {
      final result = <String>{};
      for (int i = startRow - 2; i < data.length; i++) {
        if (endRow != null && (i + 2) > endRow) break;
        if (i < 0 || i >= data.length) continue;
        final cell = data[i][colIndex];
        if (cell is String && cell.trim().isNotEmpty) {
          result.add(cell.trim());
        }
      }
      return result.toList()..sort();
    }

    switch (group) {
      case "Regular Employee":
        names = extractColumn(values, 0, 2, 49);  // G2:G49
        assistants = extractColumn(values, 0, 51); // G51+
        break;
      case "Contractual":
        names = extractColumn(values, 0, 52, 65); // G52:G65
        assistants = extractColumn(values, 0, 66); // G66+
        break;
      case "FPO":
        names = extractColumn(values, 0, 66, 90); // G66:G90
        assistants = extractColumn(values, 0, 93); // G93+
        break;
      case "FG":
        names = extractColumn(values, 0, 93); // G93+
        showAssistant = false;
        break;
      default:
        return TravelOrderOptions(names: [], assistants: [], showAssistant: false, showDiem: false);
    }

    return TravelOrderOptions(
      names: names,
      assistants: assistants,
      showAssistant: showAssistant,
      showDiem: showDiem,
    );
  } catch (e) {
    throw Exception('Error: $e');
  }
}

  Future<void> loadAllPasswords() async {
  if (_loaded) return;

  try {
    final response = await http.get(Uri.parse(sheetUrl));
    if (response.statusCode == 200) {
      final List<List<dynamic>> values = List<List<dynamic>>.from(json.decode(response.body));

      for (var row in values) {
        if (row.length > 5 && row[5] is String && row[5].trim().isNotEmpty) {
          _passwords.add(row[5].trim()); // Column L is index 5 in G:M
        }
      }
      _loaded = true;
    }
  } catch (e) {
    print("Failed to load passwords: $e");
  }
}

  String? validatePassword(String password) {
    return _passwords.contains(password) ? password : null;
  }

  // ✅ Add this method to TravelOrderService
Future<List<String>> getLeaveTypes() async {
  try {
    final response = await http.get(Uri.parse(sheetUrl));
    if (response.statusCode != 200) throw Exception('Failed to load sheet');

    final data = json.decode(response.body);
    final entries = List<Map<String, dynamic>>.from(data['feed']['entry'] ?? []);
    final Map<String, String> cells = {};

    for (var entry in entries) {
      final cell = entry['gs\$cell'] as Map<String, dynamic>;
      final row = cell['row'] as String;
      final col = cell['col'] as String;
      final value = cell['\$t'] as String;
      cells['$row,$col'] = value;
    }

    // ✅ Column P = 16
    return List.generate(6, (i) {
      final val = cells['${i + 2},16']?.trim();
      return val?.isNotEmpty == true ? val : null;
    }).where((v) => v != null).map((v) => v!).toList();
  } catch (e) {
    print("Error loading leave types: $e");
    return [];
  }
}

}
