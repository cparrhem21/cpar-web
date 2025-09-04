// lib/inventory_update_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventoryUpdateScreen extends StatefulWidget {
  final String currentUser;

  const InventoryUpdateScreen({super.key, required this.currentUser});

  @override
  State<InventoryUpdateScreen> createState() => _InventoryUpdateScreenState();
}

class _InventoryUpdateScreenState extends State<InventoryUpdateScreen> {
  // ✅ Correct URL – no trailing spaces
  final String apiUrl = 'https://script.google.com/macros/s/AKfycbwbrJzUVcEwEbAljnsaZo3cugtm9JEMKZweDjNC4rmVuC3q2b52IGhv8m4dUOgXHP93DQ/exec';

  String get currentUser => widget.currentUser;

  bool isLoading = false;

  // For Update Remarks
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  Map<String, dynamic> selectedForEdit = {};

  // For New Item
  final TextEditingController articleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController propertyController = TextEditingController();
  final TextEditingController uomController = TextEditingController();
  final TextEditingController unitValueController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController actualUserController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Update"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Welcome, $currentUser!",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                searchResults.clear();
                selectedForEdit.clear();
              });
              _showUpdateRemarks();
            },
            icon: const Icon(Icons.edit, size: 20),
            label: const Text("Update Remarks"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showEnterNewItem,
            icon: const Icon(Icons.add, size: 20),
            label: const Text("Enter New Item"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateRemarks() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) {
          return AlertDialog(
            title: const Text("Update Remarks"),
            content: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            labelText: "Search by Name (User or Actual User)",
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) => _searchInventory(value, dialogSetState),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _searchInventory(searchController.text, dialogSetState),
                        child: const Icon(Icons.search),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else if (searchResults.isEmpty)
                    const Text("No results found")
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (ctx, i) {
                          final item = searchResults[i];
                          final isSelected = selectedForEdit == item;
                          return Card(
                            color: isSelected ? Colors.blue.shade50 : null,
                            child: ListTile(
                              title: Text(item['description'] ?? ''),
                              subtitle: Text("Ref: ${item['ref'] ?? ''} | User: ${item['user'] ?? ''}"),
                              onTap: () {
                                dialogSetState(() {
                                  selectedForEdit = item;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              if (selectedForEdit.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditRemarkDialog(selectedForEdit);
                  },
                  child: const Text("Edit Remark"),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _searchInventory(String query, StateSetter dialogSetState) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      searchResults = [];
      selectedForEdit = {};
    });

    try {
      final url = Uri.parse('$apiUrl?action=searchInventory&query=$query&searchBy=user');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final data = result['data'];

        if (data is List) {
          final List<Map<String, dynamic>> results = [];
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              results.add(item);
            } else if (item is Map) {
              results.add(Map<String, dynamic>.from(item));
            }
          }

          setState(() {
            searchResults = results;
          });

          dialogSetState(() {});
        } else {
          dialogSetState(() {});
        }
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Search failed: $e")),
      );
      dialogSetState(() {});
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showEditRemarkDialog(Map<String, dynamic> item) {
    final remarkController = TextEditingController(text: item['remarks']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Remark"),
        content: TextField(
          controller: remarkController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Remarks",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _submitRemarkUpdate(item, remarkController.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRemarkUpdate(Map<String, dynamic> item, String newRemark) async {
    final oldRemark = item['remarks']?.toString() ?? '';
    final ref = item['ref']?.toString() ?? '';

    if (newRemark == oldRemark) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No changes made")),
      );
      return;
    }

    try {
      final body = {
        'action': 'updateRemark',
        'ref': ref,
        'oldRemark': oldRemark,
        'newRemark': newRemark,
        'user': currentUser,
      };

      final response = await http.post(Uri.parse(apiUrl), body: body);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Remark updated successfully")),
          );
          Navigator.pop(context);
        } else {
          throw Exception(result['error']);
        }
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Update failed: $e")),
      );
    }
  }

  void _showEnterNewItem() {
    articleController.clear();
    descriptionController.clear();
    propertyController.clear();
    uomController.clear();
    unitValueController.clear();
    qtyController.clear();
    userController.clear();
    remarksController.clear();
    actualUserController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enter New Item"),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: articleController, decoration: const InputDecoration(labelText: "Article")),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
                const SizedBox(height: 12),
                TextField(controller: propertyController, decoration: const InputDecoration(labelText: "Property Number")),
                const SizedBox(height: 12),
                TextField(controller: uomController, decoration: const InputDecoration(labelText: "Unit of Measure")),
                const SizedBox(height: 12),
                TextField(controller: unitValueController, decoration: const InputDecoration(labelText: "Unit Value")),
                const SizedBox(height: 12),
                TextField(controller: qtyController, decoration: const InputDecoration(labelText: "Quantity")),
                const SizedBox(height: 12),
                TextField(controller: userController, decoration: const InputDecoration(labelText: "User")),
                const SizedBox(height: 12),
                TextField(controller: remarksController, decoration: const InputDecoration(labelText: "Remarks")),
                const SizedBox(height: 12),
                TextField(controller: actualUserController, decoration: const InputDecoration(labelText: "Actual User")),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => _submitNewItem(ctx),
            child: const Text("Add Item"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNewItem(BuildContext ctx) async {
    final body = {
      'action': 'addNewItem',
      'article': articleController.text,
      'description': descriptionController.text,
      'propertyNumber': propertyController.text,
      'unitOfMeasure': uomController.text,
      'unitValue': unitValueController.text,
      'quantity': qtyController.text,
      'user': userController.text,
      'remarks': remarksController.text,
      'actualUser': actualUserController.text,
      'addedBy': currentUser,
    };

    try {
      final response = await http.post(Uri.parse(apiUrl), body: body);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ New item added successfully")),
          );
        } else {
          throw Exception(result['error']);
        }
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Add failed: $e")),
      );
    }
  }
}