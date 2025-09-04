// lib/monthly_accomplishment_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cparapp/models/user_profile.dart';

class WeekEntry {
  final String majorActivity;
  final List<String> processedItems;
  final String? customActivity;
  bool isSaved;

  WeekEntry({
    required this.majorActivity,
    this.processedItems = const [],
    this.customActivity,
    this.isSaved = false,
  });
}

class MonthlyAccomplishmentScreen extends StatefulWidget {
  final UserProfile userProfile;

  const MonthlyAccomplishmentScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<MonthlyAccomplishmentScreen> createState() => _MonthlyAccomplishmentScreenState();
}

class _MonthlyAccomplishmentScreenState extends State<MonthlyAccomplishmentScreen> {
  // ✅ 1. Define your URLs
  final String marApiUrl = 'https://script.google.com/macros/s/AKfycbzGHwbf-cCTTNjy3YsDpAJH41M0eI78Lbf_Q4rnVOm6u58Nq36oHN9uoBY1H9dT2EvY/exec';
  final String proxyBaseUrl = 'https://cpar-web.netlify.app/.netlify/functions/proxy';

  List<String> majorActivities = [];
  List<String> processedItems = [];

  String? selectedMajor;
  Set<String> selectedProcessedItems = {};
  String customActivity = '';
  int selectedWeek = 1;
  late String selectedMonth;
  late int selectedYear;

  Map<int, List<WeekEntry>> weeklyEntries = {
    1: [],
    2: [],
    3: [],
    4: [],
  };

  Map<int, String> weekDates = {};

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  bool isLoading = true;

  @override
  void initState() {
    selectedMonth = DateFormat('MMMM').format(DateTime.now());
    selectedYear = DateTime.now().year;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadMasterData();
    });
  }

  Future<void> loadMasterData() async {
    setState(() { isLoading = true; });

    try {
      await Future.wait([
        fetchMajorActivities(),
        fetchProcessedItems(),
      ]);

      final monthNum = _getMonthNumber(selectedMonth);
      final allWeeks = _getGroupedWeekdaysByWeek(selectedYear, monthNum);
      final fourWeeks = _mergeToFourWeeks(allWeeks);

      weekDates = {};
      for (int i = 0; i < fourWeeks.length; i++) {
        final week = fourWeeks[i];
        if (week.isEmpty) continue;
        final start = week.first;
        final end = week.last;
        final monthStr = DateFormat('MMM').format(start);
        weekDates[i + 1] = '$monthStr ${start.day}–${end.day}';
      }

      await loadUserEntries();
    } catch (e) {
      print("Error in loadMasterData: $e");
    } finally {
      setState(() { isLoading = false; });
    }
  }

  int _getIsoWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = (8 - firstDayOfYear.weekday) % 7;
    final firstMonday = DateTime(date.year, 1, 1 + daysOffset);
    final daysSince = date.difference(firstMonday).inDays;
    return (daysSince / 7).floor() + 1;
  }

  List<List<DateTime>> _getGroupedWeekdaysByWeek(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final List<DateTime> allWeekdays = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday >= 1 && date.weekday <= 5) {
        allWeekdays.add(date);
      }
    }

    final Map<int, List<DateTime>> weeksMap = {};
    for (final date in allWeekdays) {
      final weekNum = _getIsoWeekNumber(date);
      weeksMap.putIfAbsent(weekNum, () => []);
      weeksMap[weekNum]!.add(date);
    }

    final sortedKeys = weeksMap.keys.toList()..sort();
    return sortedKeys.map((key) => weeksMap[key]!).toList();
  }

  List<List<DateTime>> _mergeToFourWeeks(List<List<DateTime>> weeks) {
    if (weeks.length <= 4) return weeks;

    int bestIndex = 0;
    int minTotal = weeks[0].length + weeks[1].length;

    for (int i = 1; i < weeks.length - 1; i++) {
      final total = weeks[i].length + weeks[i + 1].length;
      if (total < minTotal) {
        minTotal = total;
        bestIndex = i;
      }
    }

    final result = List<List<DateTime>>.from(weeks);
    final merged = (result[bestIndex] + result[bestIndex + 1])..sort((a, b) => a.compareTo(b));

    result
      ..removeAt(bestIndex + 1)
      ..removeAt(bestIndex)
      ..insert(bestIndex, merged);

    return result.length > 4 ? _mergeToFourWeeks(result) : result;
  }

  int _getMonthNumber(String monthName) {
    return months.indexOf(monthName) + 1;
  }

  Future<void> fetchMajorActivities() async {
    if (widget.userProfile.name == null || widget.userProfile.name.isEmpty) return;

    try {
      final String rawUrl = '$marApiUrl?action=getMajorActivities&userEmail=${Uri.encodeComponent(widget.userProfile.name)}';
      final String encodedUrl = Uri.encodeComponent(rawUrl);
      final String url = '$proxyBaseUrl?url=$encodedUrl';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            majorActivities = data.map((e) => e.toString()).toList();
          });
        }
      }
    } catch (e) {
      print("Failed to load major activities: $e");
    }
  }

  Future<void> fetchProcessedItems() async {
    try {
      final String rawUrl = '$marApiUrl?action=getSubActivities&activity=Processed';
      final String encodedUrl = Uri.encodeComponent(rawUrl);
      final String url = '$proxyBaseUrl?url=$encodedUrl';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            processedItems = data.map((e) => e.toString()).toList();
          });
        }
      }
    } catch (e) {
      print("Failed to load processed items: $e");
    }
  }

  Future<void> loadUserEntries() async {
    try {
      final String rawUrl = '$marApiUrl?action=getEntries'
          '&userEmail=${Uri.encodeComponent(widget.userProfile.name)}'
          '&month=${Uri.encodeComponent(selectedMonth)}'
          '&year=$selectedYear';

      final String encodedUrl = Uri.encodeComponent(rawUrl);
      final String url = '$proxyBaseUrl?url=$encodedUrl';

      final response = await http.get(Uri.parse(url));
      final List<dynamic> data = json.decode(response.body);

      final entries = <int, List<WeekEntry>>{
        1: [],
        2: [],
        3: [],
        4: [],
      };

      for (var item in data) {
        final week = int.tryParse(item['week'].toString()) ?? 1;
        entries[week]?.add(WeekEntry(
          majorActivity: item['majorActivity'] ?? '',
          processedItems: List<String>.from(item['processedItems'] ?? []),
          customActivity: item['customActivity'],
          isSaved: true,
        ));
      }

      setState(() {
        weeklyEntries = entries;
      });
    } catch (e) {
      print("Failed to load entries: $e");
    }
  }

  void addEntry() {
    if ((selectedMajor == null && customActivity.isEmpty)) return;

    final entry = WeekEntry(
      majorActivity: customActivity.isNotEmpty ? customActivity : selectedMajor!,
      processedItems: selectedMajor == 'Processed' ? selectedProcessedItems.toList() : [],
      customActivity: null,
      isSaved: false,
    );

    setState(() {
      weeklyEntries[selectedWeek]!.add(entry);
      if (customActivity.isNotEmpty) {
        saveCustomActivityToSheet(customActivity);
        customActivity = '';
      }
      selectedMajor = null;
      selectedProcessedItems.clear();
    });
  }

  Future<void> saveCustomActivityToSheet(String activity) async {
    try {
      final String rawUrl = '$marApiUrl?action=addMajorActivity&userEmail=${Uri.encodeComponent(widget.userProfile.name)}&activity=${Uri.encodeComponent(activity)}';
      final String encodedUrl = Uri.encodeComponent(rawUrl);
      final String url = '$proxyBaseUrl?url=$encodedUrl';

      await http.get(Uri.parse(url));
      fetchMajorActivities();
    } catch (e) {
      print("Failed to save custom activity: $e");
    }
  }

  void removeEntry(int week, int index) {
    setState(() {
      weeklyEntries[week]!.removeAt(index);
    });
  }

  Future<void> saveAllEntries() async {
    final List<Map<String, dynamic>> allEntries = [];
    final Set<int> weeksToSave = {};

    for (int week = 1; week <= 4; week++) {
      if (weeklyEntries[week]!.isNotEmpty) {
        weeksToSave.add(week);
        for (var entry in weeklyEntries[week]!) {
          allEntries.add({
            'week': week,
            'majorActivity': entry.majorActivity,
            'processedItems': json.encode(entry.processedItems),
            'customActivity': entry.customActivity ?? '',
          });
        }
      }
    }

    if (allEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No entries to save")),
      );
      return;
    }

    try {
      // ✅ Delete old entries
      final String deleteRawUrl = '$marApiUrl?action=deleteUserEntriesForWeeks'
          '&userEmail=${Uri.encodeComponent(widget.userProfile.name)}'
          '&month=${Uri.encodeComponent(selectedMonth)}'
          '&year=$selectedYear'
          '&weeks=${json.encode(weeksToSave.toList())}';
      final String deleteEncodedUrl = Uri.encodeComponent(deleteRawUrl);
      final String deleteUrl = '$proxyBaseUrl?url=$deleteEncodedUrl';
      final deleteResponse = await http.get(Uri.parse(deleteUrl));
      if (deleteResponse.statusCode != 200) throw Exception("Delete failed");

      // ✅ Save new entries
      final String saveRawUrl = '$marApiUrl?action=saveAllEntries'
          '&userEmail=${Uri.encodeComponent(widget.userProfile.name)}'
          '&month=${Uri.encodeComponent(selectedMonth)}'
          '&year=$selectedYear'
          '&entries=${Uri.encodeComponent(json.encode(allEntries))}';
      final String saveEncodedUrl = Uri.encodeComponent(saveRawUrl);
      final String saveUrl = '$proxyBaseUrl?url=$saveEncodedUrl';
      final saveResponse = await http.get(Uri.parse(saveUrl));
      if (saveResponse.statusCode != 200) throw Exception("Save failed");

      await loadUserEntries();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ All entries saved!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    }
  }

  Future<void> generatePdf() async {
    final pdf = pw.Document();

    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final font = pw.Font.ttf(fontData);
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final bold = pw.Font.ttf(boldData);

      double fontSize = 10.0;
      double titleSize = 14.0;
      double headerSize = 11.0;

      final totalItems = weeklyEntries.values.expand((list) => list).length;
      if (totalItems > 15) {
        fontSize = 8.5;
        titleSize = 12.0;
        headerSize = 10.0;
      } else if (totalItems > 10) {
        fontSize = 9.0;
        titleSize = 13.0;
        headerSize = 10.5;
      }

      final theme = pw.ThemeData.withFont(
        base: font,
        bold: bold,
      );

      final logoLeftBytes = await http.readBytes(Uri.parse('https://raw.githubusercontent.com/cparrhem21/logos/main/denr_logo.png'));
      final logoRightBytes = await http.readBytes(Uri.parse('https://raw.githubusercontent.com/cparrhem21/logos/main/bp_logo.png'));

      final logoLeft = pw.MemoryImage(logoLeftBytes);
      final logoRight = pw.MemoryImage(logoRightBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          theme: theme,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    pw.Container(width: 60, height: 60, child: pw.Image(logoLeft)),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text("Republic of the Philippines", style: pw.TextStyle(fontSize: 9)),
                          pw.Text("Department of Environment and Natural Resources", style: pw.TextStyle(fontSize: 9)),
                          pw.Text("Cordillera Administrative Region", style: pw.TextStyle(fontSize: 9)),
                          pw.Text("Community Environment and Natural Resources Office - Paracelis", style: pw.TextStyle(fontSize: 9)),
                          pw.Text("Poblacion, Paracelis, Mountain Province", style: pw.TextStyle(fontSize: 9)),
                          pw.Text("Mobile No: 0960-223-9908", style: pw.TextStyle(fontSize: 9)),
                          pw.Text("E-mail: cenroparacelis@denr.gov.ph", style: pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Container(width: 100, height: 100, child: pw.Image(logoRight)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text("MONTHLY ACCOMPLISHMENT REPORT",
                    style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text("Employee Name: ${widget.userProfile.name}", style: pw.TextStyle(fontSize: fontSize)),
                ),
                pw.SizedBox(height: 10),
                _buildCompactQuadrantTable(headerSize, fontSize),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Prepared by:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 12),
                        pw.Text(widget.userProfile.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(widget.userProfile.role, style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Concurred by:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 12),
                        pw.Text(widget.userProfile.concurredBy, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Immediate Supervisor", style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("PDF Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate PDF: $e")),
      );
    }
  }

  pw.Widget _buildCompactQuadrantTable(double headerSize, double fontSize) {
    final cellWidth = (PdfPageFormat.a4.width - 40) / 2;
    final cellHeight = 220.0;

    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
      border: pw.TableBorder.all(width: 0.5),
      children: [
        pw.TableRow(
          children: [
            _buildFixedCell(1, weeklyEntries[1] ?? [], cellWidth, cellHeight, headerSize, fontSize),
            _buildFixedCell(3, weeklyEntries[3] ?? [], cellWidth, cellHeight, headerSize, fontSize),
          ],
        ),
        pw.TableRow(
          children: [
            _buildFixedCell(2, weeklyEntries[2] ?? [], cellWidth, cellHeight, headerSize, fontSize),
            _buildFixedCell(4, weeklyEntries[4] ?? [], cellWidth, cellHeight, headerSize, fontSize),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFixedCell(int week, List<WeekEntry> entries, double width, double height, double headerSize, double fontSize) {
    final contentHeight = height - 30;

    return pw.Container(
      width: width,
      height: height,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: pw.EdgeInsets.all(6),
            color: PdfColors.grey300,
            child: pw.Text(
              'Week $week: ${weekDates[week] ?? "N/A"}',
              style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Container(
            height: contentHeight,
            padding: pw.EdgeInsets.all(6),
            child: entries.isEmpty
                ? pw.Text(
                    "No entries",
                    style: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey),
                  )
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: entries
                        .expand((e) {
                          final List<pw.Widget> items = [];

                          if (e.majorActivity.isNotEmpty) {
                            items.add(
                              pw.Wrap(
                                children: [
                                  pw.Text("- ", style: pw.TextStyle(fontSize: fontSize)),
                                  pw.Container(
                                    constraints: pw.BoxConstraints(maxWidth: width - 60),
                                    child: pw.Text(
                                      e.majorActivity,
                                      style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (e.processedItems.isNotEmpty) {
                            items.addAll(e.processedItems.map((item) {
                              return pw.Wrap(
                                children: [
                                  pw.Text("  • ", style: pw.TextStyle(fontSize: fontSize - 1)),
                                  pw.Container(
                                    constraints: pw.BoxConstraints(maxWidth: width - 60),
                                    child: pw.Text(
                                      item,
                                      style: pw.TextStyle(fontSize: fontSize - 1),
                                    ),
                                  ),
                                ],
                              );
                            }));
                          }

                          if (e.customActivity != null && e.customActivity!.isNotEmpty) {
                            items.add(
                              pw.Wrap(
                                children: [
                                  pw.Text("  • ", style: pw.TextStyle(fontSize: fontSize - 1)),
                                  pw.Container(
                                    constraints: pw.BoxConstraints(maxWidth: width - 60),
                                    child: pw.Text(
                                      e.customActivity!,
                                      style: pw.TextStyle(fontSize: fontSize - 1),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return items;
                        })
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Accomplishment Report")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedMonth,
                      items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (value) => setState(() {
                        selectedMonth = value!;
                        loadMasterData();
                      }),
                      decoration: const InputDecoration(labelText: "Month"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedYear,
                      items: [2024, 2025, 2026].map((y) => DropdownMenuItem(value: y, child: Text("$y"))).toList(),
                      onChanged: (value) => setState(() {
                        selectedYear = value!;
                        loadMasterData();
                      }),
                      decoration: const InputDecoration(labelText: "Year"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  return isMobile
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildEntryForm(context),
                            const SizedBox(height: 16),
                            SizedBox(height: 300, child: _buildEntriesList()),
                            const SizedBox(height: 16),
                            _buildActionButtons(context),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: _buildEntryForm(context)),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 400, child: _buildEntriesList()),
                                  const SizedBox(height: 16),
                                  _buildActionButtons(context),
                                ],
                              ),
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return EdgeInsets.all(width > 600 ? 32 : 16);
  }

  Widget _buildEntryForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Activity", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: selectedWeek,
              items: [1, 2, 3, 4].map((w) => DropdownMenuItem(value: w, child: Text("Week $w"))).toList(),
              onChanged: (value) => setState(() => selectedWeek = value!),
              decoration: const InputDecoration(labelText: "Week"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMajor,
              hint: const Text("Select Major Activity"),
              items: majorActivities.map((act) => DropdownMenuItem(value: act, child: Text(act))).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMajor = value;
                  selectedProcessedItems.clear();
                });
              },
              decoration: const InputDecoration(labelText: "Major Activity"),
            ),
            if (selectedMajor == 'Processed' && processedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text("Select items:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...processedItems.map((item) {
                return Row(
                  children: [
                    Checkbox(
                      value: selectedProcessedItems.contains(item),
                      onChanged: (checked) {
                        setState(() {
                          if (checked!) {
                            selectedProcessedItems.add(item);
                          } else {
                            selectedProcessedItems.remove(item);
                          }
                        });
                      },
                    ),
                    Expanded(child: Text(item)),
                  ],
                );
              }).toList(),
            ],
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: "Or enter custom activity", border: OutlineInputBorder()),
              onChanged: (value) => customActivity = value,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: addEntry,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add to Report"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (int week = 1; week <= 4; week++)
              if (weeklyEntries[week]!.isNotEmpty)
                _buildWeekCard(week),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCard(int week) {
    return ExpansionTile(
      title: Text("Week $week: ${weekDates[week] ?? "N/A"}"),
      children: weeklyEntries[week]!.map((entry) {
        return ListTile(
          leading: const Icon(Icons.circle, size: 8),
          title: Text(entry.majorActivity),
          subtitle: entry.processedItems.isNotEmpty
              ? Text(entry.processedItems.join(", "))
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => removeEntry(week, weeklyEntries[week]!.indexOf(entry)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: generatePdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("Generate PDF"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: saveAllEntries,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("💾 Save All"),
          ),
        ),
      ],
    );
  }
}