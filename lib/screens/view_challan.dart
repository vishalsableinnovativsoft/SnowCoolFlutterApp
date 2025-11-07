import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snow_trading_cool/screens/challan_screen.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:intl/intl.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';

class ViewChallanScreen extends StatefulWidget {
  const ViewChallanScreen({super.key});

  @override
  State<ViewChallanScreen> createState() => _ViewChallanScreenState();
}

class _ViewChallanScreenState extends State<ViewChallanScreen> {
  final List<Map<String, dynamic>> _customers = [
    {
      'id': '1',
      'name': 'Abhishek Sharma',
      'type': 'Receive',
      'location': 'Mumbai, Maharashtra',
      'qty': "2",
      'date': '2025-10-01',
    },
    {
      'id': '2',
      'name': 'Priya Singh',
      'type': 'Delivery',
      'location': 'Delhi',
      'qty': "3",
      'date': '2025-10-08',
    },
    {
      'id': '3',
      'name': 'Rakesh Kumar',
      'type': 'Delivery',
      'location': 'Bangalore',
      'qty': "1",
      'date': '2025-11-01',
    },
    {
      'id': '4',
      'name': 'Anjali Mehta',
      'type': 'Receive',
      'location': 'Pune',
      'qty': "6",
      'date': '2025-10-15',
    },
    {
      'id': '5',
      'name': 'Vikram Patel',
      'type': 'Delivery',
      'location': 'Ahmedabad',
      'qty': "4",
      'date': '2025-08-01',
    },
    {
      'id': '6',
      'name': 'Neha Sharma',
      'type': 'Receive',
      'location': 'Chandigarh',
      'qty': "2",
      'date': '2025-09-18',
    },
    {
      'id': '7',
      'name': 'Abhishek Verma',
      'type': 'Delivery',
      'location': 'Nashik',
      'qty': "5",
      'date': '2025-07-01',
    },
    {
      'id': '8',
      'name': 'Priya Nair',
      'type': 'Receive',
      'location': 'Indore',
      'qty': "3",
      'date': '2025-02-01',
    },
    {
      'id': '9',
      'name': 'Rakesh Yadav',
      'type': 'Receive',
      'location': 'Jaipur',
      'qty': "1",
      'date': '2025-05-01',
    },
    {
      'id': '10',
      'name': 'Siddharth Deshmukh',
      'type': 'Delivery',
      'location': 'Goa',
      'qty': "2",
      'date': '2025-10-01',
    },
    {
      'id': '11',
      'name': 'Pooja Iyer',
      'type': 'Receive',
      'location': 'Nagpur',
      'qty': "7",
      'date': '2025-10-30',
    },
    {
      'id': '12',
      'name': 'Vikram Chauhan',
      'type': 'Receive',
      'location': 'Surat',
      'qty': "3",
      'date': '2025-04-01',
    },
    {
      'id': '13',
      'name': 'Neha Pandey',
      'type': 'Delivery',
      'location': 'Lucknow',
      'qty': "2",
      'date': '2025-10-13',
    },
    {
      'id': '14',
      'name': 'Amit Joshi',
      'type': 'Delivery',
      'location': 'Hyderabad',
      'qty': "4",
      'date': '2025-10-06',
    },
    {
      'id': '15',
      'name': 'Anjali Bhatia',
      'type': 'Delivery',
      'location': 'Bhopal',
      'qty': "5",
      'date': '2025-12-01',
    },
  ];

  final ChallanApi challanApi = ChallanApi();
  List<Map<String, dynamic>> _challans = [];
  List<Map<String, dynamic>> _filteredData = [];

  String _searchQuery = '';
  String _selectedType = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  List<String> _selectedIds = [];
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  List<Map<String, dynamic>> get _filteredCustomers {
    return _customers.where((customer) {
      final nameMatch = customer['name'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final typeMatch =
          _selectedType == 'All' || customer['type'] == _selectedType;

      final date = DateTime.parse(customer['date']);
      final fromOk =
          _fromDate == null ||
          date.isAfter(_fromDate!.subtract(const Duration(days: 1)));
      final toOk =
          _toDate == null ||
          date.isBefore(_toDate!.add(const Duration(days: 1)));

      return nameMatch && typeMatch && fromOk && toOk;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedCustomers {
    final start = _currentPage * _rowsPerPage;
    final end = start + _rowsPerPage;
    final filtered = _filteredCustomers;
    // if (start >= _filteredData.length) return [];
    // return _filteredData.sublist(start, end.clamp(0, _filteredData.length));
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end.clamp(0, filtered.length));
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // 🔹 Delete Challan
  Future<void> _deleteChallan(String challanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Challan'),
        content: const Text('Are you sure you want to delete this challan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await challanApi.deleteChallanData(challanId);

    if (success) {
      showSuccessToast(context, "Challan deleted successfully");
      _fetchChallans();
    } else {
      showErrorToast(context, "Failed to delete challan");
    }
  }

  // 🔹 Edit Challan
  Future<void> _editChallan(Map challanId) async {

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ChallanScreen(challanId: challanId)));

    // final controller = TextEditingController();

    // final newCustomerName = await showDialog<String>(
    //   context: context,
    //   builder: (_) => AlertDialog(
    //     title: const Text('Edit Challan'),
    //     content: TextField(
    //       controller: controller,
    //       decoration: const InputDecoration(
    //         labelText: 'Enter new customer name',
    //       ),
    //     ),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context),
    //         child: const Text('Cancel'),
    //       ),
    //       ElevatedButton(
    //         onPressed: () => Navigator.pop(context, controller.text),
    //         child: const Text('Save'),
    //       ),
    //     ],
    //   ),
    // );

    // if (newCustomerName == null || newCustomerName.isEmpty) return;

    // final success = await challanApi.editChallanData(
    //   challanId,
    //   customerName: newCustomerName,
    // );

    // if (success) {
    //   showSuccessToast(context, "Challan updated successfully");
    //   _fetchChallans();
    // } else {
    //   showErrorToast(context, "Failed to update challan");
    // }
  }

  Future<void> _generateAndPrintPdf(Map<String, dynamic> challan) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "Challan Details",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Customer Name: ${challan['name']}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Type: ${challan['type']}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Location: ${challan['location']}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Quantity: ${challan['qty']}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Date: ${challan['date']}",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  "Generated by Snowcool Trading Co.",
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Save PDF locally
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/challan_${challan['id']}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Open print/share
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    showSuccessToast(context, "PDF generated successfully");
  }

  @override
  void initState() {
    super.initState();
    _fetchChallans();
  }

  // 🔹 Fetch all challans from API
  Future<void> _fetchChallans() async {
    try {
      final fetchedData = await challanApi.fetchChallanData();
      setState(() {
        _challans = fetchedData;
        _filteredData = _challans;
      });
    } catch (e) {
      showErrorToast(context, "Failed to load challans: $e");
    }
  }

  // 🔹 Apply filters and search
  void applyFilters(String query, dynamic type) {
    setState(() {
      _filteredData = _challans.where((customer) {
        final matchesName = (customer['name'] as String).toLowerCase().contains(
          query.toLowerCase(),
        );
        final matchesType = type == 'All' || customer['type'] == type;
        return matchesName && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // final filtered = _filteredCustomers;
    final totalPages = (_filteredData.length / _rowsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challan Details'),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChallanScreen()),
              );
            },
            child: Container(
              height: 30,
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromRGBO(0, 140, 192, 1),
              ),
              child: const Center(
                child: Text(
                  "Add Challan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),

      body: Column(
        children: [
          // 🔍 Filter Section
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search by Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedType,
                  items: ['All', 'Receive', 'Delivery']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(0, 140, 192, 1),
                  ),
                  onPressed: _pickFromDate,
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  label: Text(
                    _fromDate == null
                        ? "From Date"
                        : DateFormat('yyyy-MM-dd').format(_fromDate!),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(0, 140, 192, 1),
                  ),
                  onPressed: _pickToDate,
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  label: Text(
                    _toDate == null
                        ? "To Date"
                        : DateFormat('yyyy-MM-dd').format(_toDate!),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(0, 140, 192, 1),
                    ),
                    onPressed: () {
                      showSuccessToast(
                        context,
                        "Printing ${_selectedIds.length} selected records...",
                      );
                    },
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text(
                      "Print Multiple",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (_selectedIds.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
                    ),
                    onPressed: () async {
                      // Step 1: Confirm delete
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Multiple Challans'),
                          content: Text(
                            'Are you sure you want to delete ${_selectedIds.length} selected challans?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      // Step 2: Call API for each challan ID
                      bool allDeleted = true;
                      for (final id in _selectedIds) {
                        final success = await challanApi.deleteChallanData(id);
                        if (!success) allDeleted = false;
                      }

                      // Step 3: Clear selection & refresh data
                      setState(() {
                        _selectedIds.clear();
                      });
                      await _fetchChallans();

                      // Step 4: Show result message
                      if (allDeleted) {
                        showSuccessToast(context, 'All selected challans deleted successfully');
                      } else {
                        showErrorToast(context, "Some challans could not be deleted");
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text(
                      "Delete Multiple",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                // if (_selectedIds.isNotEmpty)
                //   ElevatedButton.icon(
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Color.fromRGBO(0, 140, 192, 1),
                //     ),
                //     onPressed: () {
                //       showSuccessToast(
                //         context,
                //         "Deleting ${_selectedIds.length} selected records...",
                //       );
                //     },
                //     icon: const Icon(Icons.print, color: Colors.white),
                //     label: const Text(
                //       "Delete Multiple",
                //       style: TextStyle(color: Colors.white),
                //     ),
                //   ),
              ],
            ),
          ),

          // 🧾 Fixed First Column + Scrollable Columns
          Row(
            children: [
              // Fixed Column (Checkbox + Name)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 200,
                  // padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide(color: Colors.grey.shade300),
                      top: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        // color: Colors.teal.shade100,
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 50,
                              child: Center(child: Text('✓')),
                            ),
                            Expanded(
                              child: Text(
                                'Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color.fromRGBO(0, 140, 192, 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _paginatedCustomers.isEmpty
                          ? Container(
                              height: 100,
                              alignment: Alignment.center,
                              child: Lottie.asset(
                                'assets/lottieFile/GAS Cylinder.json',
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              children: [
                                ..._paginatedCustomers.map((row) {
                                  final isSelected = _selectedIds.contains(
                                    row['id'],
                                  );
                                  return Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (_) =>
                                                _toggleSelect(row['id']),
                                          ),
                                        ),
                                        Expanded(child: Text(row['name'])),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                    ],
                  ),
                ),
              ),

              // Scrollable Other Columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 650,
                    child: Column(
                      children: [
                        // Header Row
                        Container(
                          height: 50,
                          // color: Colors.teal.shade100,
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 100,
                                child: Center(
                                  child: Text(
                                    'Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromRGBO(0, 140, 192, 1),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: Center(
                                  child: Text(
                                    'Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromRGBO(0, 140, 192, 1),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text(
                                    'Qty',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromRGBO(0, 140, 192, 1),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Center(
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromRGBO(0, 140, 192, 1),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Actions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromRGBO(0, 140, 192, 1),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Data Rows
                        ..._paginatedCustomers.map((row) {
                          return Container(
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 100, child: Text(row['type'])),
                                SizedBox(
                                  width: 200,
                                  child: Text(row['location']),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Center(child: Text(row['qty'])),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Center(child: Text(row['date'])),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          _editChallan(row);
                                          showSuccessToast(context, "Editing Challan...");
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          _deleteChallan(row['id']);
                                          setState(() {
                                            _customers.removeWhere(
                                              (c) => c['id'] == row['id'],
                                            );
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.share,
                                          color: Colors.green,
                                        ),
                                        onPressed: () {
                                          // ScaffoldMessenger.of(
                                          //   context,
                                          // ).showSnackBar(
                                          //   SnackBar(
                                          //     content: Text(
                                          //       "Share ${row['name']}",
                                          //     ),
                                          //   ),
                                          // );
                                          Share.share(
                                            'Check this challan detail',
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.save_outlined,
                                          color: Colors.deepPurple,
                                        ),
                                        onPressed: () {
                                          _generateAndPrintPdf(row);
                                          showSuccessToast(context, 'Printing PDF...');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Pagination Footer
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text('Page ${_currentPage + 1} of $totalPages'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
