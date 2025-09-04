// lib/attendance/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'model/attendance.dart';
import 'services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService apiService = ApiService();
  List<AttendanceData> regular = [];
  List<AttendanceData> jobOrder = [];
  List<AttendanceData> contract = [];

  String? selectedReg, selectedJO, selectedCos;

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await apiService.getAttendanceData();

      final reg = <AttendanceData>[];
      final jo = <AttendanceData>[];
      final cos = <AttendanceData>[];

      for (var item in data) {
        switch (item.type) {
          case 'reg':
            reg.add(item);
            break;
          case 'jo':
            jo.add(item);
            break;
          case 'cos':
            cos.add(item);
            break;
        }
      }

      reg.sort((a, b) => _compareDateStrings(b.date, a.date));
      jo.sort((a, b) => _compareDateStrings(b.date, a.date));
      cos.sort((a, b) => _compareDateStrings(b.date, a.date));

      setState(() {
        regular = reg;
        jobOrder = jo;
        contract = cos;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  int _compareDateStrings(String a, String b) {
    DateTime parse(String d) {
      try {
        return DateTime.parse('2023 ${d.trim()}');
      } catch (e) {
        return DateTime(2023, 1, 1);
      }
    }
    return parse(b).compareTo(parse(a));
  }

  Future<void> openPdf(String fileId) async {
  if (fileId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No file selected")),
    );
    return;
  }

  // ✅ Define the URL
  final String viewUrl = 'https://drive.google.com/file/d/$fileId/view';

  final Uri uri = Uri.parse(viewUrl);

  try {
    // ✅ Open in new tab
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    // Fallback: Show dialog with link
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Open PDF"),
        content: Text(
          "Tap the button below to open the PDF in your browser:\n\n$viewUrl",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Could not open PDF. Please try again.")),
                );
              }
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance PDF Viewer')),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Error: $error', style: TextStyle(color: Colors.red)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select a date to open the PDF', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 30),
                        _buildDropdown("Regular", regular, (value) {
                          if (value != null && value.isNotEmpty) {
                            final item = regular.firstWhere((e) => e.id == value);
                            openPdf(item.id);
                            Future.delayed(Duration.zero, () => setState(() => selectedReg = null));
                          }
                        }, selectedReg),
                        const SizedBox(height: 20),
                        _buildDropdown("Job Order", jobOrder, (value) {
                          if (value != null && value.isNotEmpty) {
                            final item = jobOrder.firstWhere((e) => e.id == value);
                            openPdf(item.id);
                            Future.delayed(Duration.zero, () => setState(() => selectedJO = null));
                          }
                        }, selectedJO),
                        const SizedBox(height: 20),
                        _buildDropdown("Contract of Service", contract, (value) {
                          if (value != null && value.isNotEmpty) {
                            final item = contract.firstWhere((e) => e.id == value);
                            openPdf(item.id);
                            Future.delayed(Duration.zero, () => setState(() => selectedCos = null));
                          }
                        }, selectedCos),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<AttendanceData> items, ValueChanged<String?> onChanged, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text('Select a date'),
          items: items.isEmpty
              ? null
              : [
                  const DropdownMenuItem(value: '', child: Text('Select a date')),
                  ...items.map((item) {
                    return DropdownMenuItem(value: item.id, child: Text(item.date));
                  }).toList(),
                ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          isExpanded: true,
        ),
      ],
    );
  }
}