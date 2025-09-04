// lib/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // ✅ Your working Apps Script Web App URL
  final String inventoryApiUrl =
  'https://script.google.com/macros/s/AKfycbwbrJzUVcEwEbAljnsaZo3cugtm9JEMKZweDjNC4rmVuC3q2b52IGhv8m4dUOgXHP93DQ/exec';

  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  List<String> headers = [];
  List<Map<String, dynamic>> data = [];

  Future<void> searchInventory() async {
  final queryText = searchController.text.trim();
  if (queryText.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a name")),
    );
    return;
  }

  final query = Uri.encodeComponent(queryText);
  final url = '$inventoryApiUrl?query=$query';

  setState(() {
    isLoading = true;
    data = [];
  });

  try {
    print("🔍 Fetching: $url");
    final response = await http.get(Uri.parse(url));

    print("📡 Status: ${response.statusCode}");
    print("📦 Body: ${response.body}");

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      // ✅ Safely parse headers
      final List<String> parsedHeaders = (result['headers'] as List?)
          ?.map((e) => e.toString())
          ?.toList() ?? [];

      // ✅ Safely parse data
      final List<Map<String, dynamic>> parsedData = (result['data'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          ?.toList() ?? [];

      setState(() {
        headers = parsedHeaders;
        data = parsedData;
      });

      print("✅ Headers: $headers");
      print("📊 Found ${data.length} items");

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        });
      }
    } else {
      throw Exception("HTTP ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Fetch Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to load: $e")),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Lookup"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: "Enter your name",
                      hintText: "e.g. Rembert Macaday",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => searchInventory(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: searchInventory,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text("Search"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (data.isEmpty)
              const Expanded(
                child: Center(child: Text("No items found. Try searching a name.")),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // 📱 Mobile: Card List
                      return _buildMobileList();
                    } else {
                      // 💻 Web/Desktop: DataTable
                      return _buildDesktopTable();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView(
      children: data.map((row) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: headers.map((header) {
                String value = _getValueFromRow(row, header);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: '$header: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: value),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTable() {
  return SizedBox(
    height: 500,
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1300, // Total width remains the same
          child: Column(
            children: [
              // Table Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                ),
                child: Row(
                  children: [
                    _tableCell('Ref', 60, isHeader: true),
                    _tableCell('Article', 120, isHeader: true),
                    _tableCell('Description', 350, isHeader: true), // ✅ Increased from 200 → 300
                    _tableCell('Prop #', 130, isHeader: true),
                    _tableCell('UoM', 50, isHeader: true),
                    _tableCell('Unit Value', 90, isHeader: true),
                    _tableCell('Qty', 60, isHeader: true),
                    _tableCell('User', 120, isHeader: true),
                    _tableCell('Remarks', 120, isHeader: true),
                    _tableCell('Actual User', 150, isHeader: true), // ✅ Reduced from 120 → 80
                  ],
                ),
              ),

              // Table Rows
              ...data.map((row) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(width: 1, color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tableCell(row['ref']?.toString() ?? '', 30),
                      _tableCell(row['article']?.toString() ?? '', 100),
                      _tableCell(row['description']?.toString() ?? '', 380, wrap: true), // ✅ Wider
                      _tableCell(row['propertyNumber']?.toString() ?? '', 150, wrap: true),
                      _tableCell(row['unitOfMeasure']?.toString() ?? '', 50),
                      _tableCell(_formatCurrency(row['unitValue']), 100),
                      _tableCell(row['quantity']?.toString() ?? '', 30),
                      _tableCell(row['user']?.toString() ?? '', 120),
                      _tableCell(row['remarks']?.toString() ?? '', 120, wrap: true),
                      _tableCell(row['actualUser']?.toString() ?? '', 150), // ✅ Narrower
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    ),
  );
}
// ✅ Table Header Row
Widget _buildTableHeaderRow() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
    ),
    child: Row(
      children: [
        _tableCell('Ref', 60, isHeader: true),
        _tableCell('Article', 120, isHeader: true),
        _tableCell('Description', 200, isHeader: true),
        _tableCell('Prop #', 140, isHeader: true),
        _tableCell('UoM', 80, isHeader: true),
        _tableCell('Unit Value', 100, isHeader: true),
        _tableCell('Qty', 60, isHeader: true),
        _tableCell('User', 120, isHeader: true),
        _tableCell('Remarks', 120, isHeader: true),
        _tableCell('Actual User', 120, isHeader: true),
      ],
    ),
  );
}

// ✅ Data Row
Widget _buildTableDataRow(Map<String, dynamic> row) {
  return Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(width: 1, color: Colors.grey.shade300)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, // ✅ Align to top
      children: [
        _tableCell(row['ref']?.toString() ?? '', 60),
        _tableCell(row['article']?.toString() ?? '', 120),
        _tableCell(row['description']?.toString() ?? '', 250, wrap: true),
        _tableCell(row['propertyNumber']?.toString() ?? '', 140),
        _tableCell(row['unitOfMeasure']?.toString() ?? '', 80),
        _tableCell(_formatCurrency(row['unitValue']), 100),
        _tableCell(row['quantity']?.toString() ?? '', 60),
        _tableCell(row['user']?.toString() ?? '', 120),
        _tableCell(row['remarks']?.toString() ?? '', 120, wrap: true),
        _tableCell(row['actualUser']?.toString() ?? '', 60),
      ],
    ),
  );
}

// ✅ Reusable cell with wrapping and header styling
Widget _tableCell(String text, double width, {bool wrap = false, bool isHeader = false}) {
  return SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        softWrap: wrap, // ✅ Wrap long text
        overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    ),
  );
}

// ✅ Helper: Build header with fixed width
Widget _buildHeader(String text, double width) {
  return SizedBox(
    width: width,
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      overflow: TextOverflow.visible,
      softWrap: true,
    ),
  );
}


// ✅ Format currency
String _formatCurrency(dynamic value) {
  if (value == null) return '';
  final String str = value.toString().trim();
  if (str.isEmpty) return '';
  final num = double.tryParse(str.replaceAll(',', ''));
  if (num == null) return str;
  return '₱${num.toStringAsFixed(2)}';
}

  // ✅ Map header to correct data field
  String _getValueFromRow(Map<String, dynamic> row, String header) {
    final lowerHeader = header.trim().toLowerCase();

    switch (lowerHeader) {
      case 'reference number':
        return row['ref']?.toString() ?? '';
      case 'article':
        return row['article']?.toString() ?? '';
      case 'description':
        return row['description']?.toString() ?? '';
      case 'property number':
        return row['propertyNumber']?.toString() ?? '';
      case 'unit of measure':
        return row['unitOfMeasure']?.toString() ?? '';
      case 'unit value':
        final num = double.tryParse(row['unitValue']?.toString() ?? '');
        return num != null ? '₱${num.toStringAsFixed(2)}' : '';
      case 'quantity per property card ':
      case 'quantity per property card':
        return row['quantity']?.toString() ?? '';
      case 'user':
        return row['user']?.toString() ?? '';
      case 'remarks':
        return row['remarks']?.toString() ?? '';
      case 'actual user':
        return row['actualUser']?.toString() ?? '';
      default:
        return row[header] != null ? row[header].toString() : '';
    }
  }
}