import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snow_trading_cool/screens/challan_screen.dart';
import 'package:snow_trading_cool/services/challan_api.dart';

class ViewChallanScreen extends StatefulWidget {
  const ViewChallanScreen({super.key});

  @override
  State<ViewChallanScreen> createState() => _ViewChallanScreenState();
}

class _ViewChallanScreenState extends State<ViewChallanScreen> {
  final TextEditingController searchController = TextEditingController();

  late ChallanDataSource _dataSource;

  int _rowsPerPage = 5;
  List<int> _availableRowsPerPage = [5, 10, 20];
  double headingHeight = 56;
  double dataRowHeight = 60;

  String selectedType = 'All';

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
      'date': '2025-8-1',
    },
    {
      'id': '6',
      'name': 'Neha Sharma',
      'type': 'Receive',
      'location': 'Chandigarh',
      'qty': "2",
      'date': '2025-9-18',
    },
    {
      'id': '7',
      'name': 'Abhishek Verma',
      'type': 'Delivery',
      'location': 'Nashik',
      'qty': "5",
      'date': '2025-7-01',
    },
    {
      'id': '8',
      'name': 'Priya Nair',
      'type': 'Receive',
      'location': 'Indore',
      'qty': "3",
      'date': '2025-2-01',
    },
    {
      'id': '9',
      'name': 'Rakesh Yadav',
      'type': 'Receive',
      'location': 'Jaipur',
      'qty': "1",
      'date': '2025-5-01',
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
      'date': '2025-4-01',
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

  DateTime? fromDate;
  DateTime? toDate;
  final ChallanApi challanApi = ChallanApi();
    List<Map<String, dynamic>> _challanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChallans();
    _dataSource = ChallanDataSource(_customers);

    // If you call API, do it async and then call _dataSource = ChallanDataSource(fetchedList) and _updatePagination();
    // Example (uncomment to use):
    // _loadFromApi();
    _updatePagination();
  }

  
  Future<void> _fetchChallans() async {
    setState(() => _isLoading = true);
    final data = await challanApi.fetchChallanData();
    setState(() {
      _challanList = data;
      _isLoading = false;
    });
  }

 
  int _tableRebuildKey = 0;

  // Example of how to fetch from API (if needed)
  // Future<void> _loadFromApi() async {
  //   final challApi = ChallanApi();
  //   final fetched = await challApi.fetchChallanData();
  //   setState(() {
  //     _dataSource = ChallanDataSource(fetched);
  //     _updatePagination();
  //   });
  // }
  // void _applyFilters() {
  //   final query = searchController.text.toLowerCase();
  //   final type = selectedType;
  //   _dataSource.applyFilters(query, type);
  //   _updatePagination();
  //   // force rebuild of PaginatedDataTable2 to reset internal page offset
  //   setState(() {
  //     _tableRebuildKey++;
  //   });
  // }
  void _applyFilters() {
    String query = searchController.text.toLowerCase();
    String type = selectedType;

    setState(() {
      _dataSource.applyFilters(query, type);

      // 🔁 update pagination after filtering
      _updatePagination();
    });
  }

  void _resetFilters() {
    searchController.clear();
    selectedType = 'All';
    _dataSource.applyFilters('', 'All');
    _updatePagination();
    setState(() {
      _tableRebuildKey++;
    });
  }

  void _updatePagination() {
    final totalRows = _dataSource.rowCount;

    if (totalRows == 0) {
      _rowsPerPage = 1;
      _availableRowsPerPage = [1];
    } else if (totalRows <= 8) {
      _rowsPerPage = totalRows;
      _availableRowsPerPage = [totalRows];
    }
    // else if (totalRows <= 8) {
    //   _rowsPerPage = 5;
    //   _availableRowsPerPage = [5, 8];
    // }
    else if (totalRows <= 10) {
      _rowsPerPage = 8;
      _availableRowsPerPage = [8, 10];
    } else if (totalRows <= 15) {
      _rowsPerPage = 8;
      _availableRowsPerPage = [8, 10, 15];
    } else if (totalRows <= 20) {
      _rowsPerPage = 8;
      _availableRowsPerPage = [8, 10, 20];
    } else {
      _rowsPerPage = 8;
      _availableRowsPerPage = [8, 10, 20, 50];
    }

    _tableRebuildKey++;
    setState(() {});
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final pickedFrom = await showDatePicker(
      context: context,
      initialDate: fromDate ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      helpText: 'Select Start Date',
    );

    if (pickedFrom == null) return;

    final pickedTo = await showDatePicker(
      context: context,
      initialDate: toDate ?? pickedFrom,
      firstDate: pickedFrom,
      lastDate: DateTime(2026),
      helpText: 'Select End Date',
    );

    if (pickedTo == null) return;

    setState(() {
      fromDate = pickedFrom;
      toDate = pickedTo;

      _filterByDate();
    });
  }

  void _filterByDate() {
    if (fromDate == null || toDate == null) return;

    final filtered = _customers.where((customer) {
      final date = DateTime.parse(customer['date']);
      return date.isAfter(fromDate!.subtract(const Duration(days: 1))) &&
          date.isBefore(toDate!.add(const Duration(days: 1)));
    }).toList();

    setState(() {
      _dataSource = ChallanDataSource(filtered);
      _updatePagination();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // table size constants
    const double headingHeight = 56;
    const double dataRowHeight = 64;

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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          // using Column's default spacing via SizedBox
          children: [
            Row(
              spacing: 5,
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(156, 156, 156, 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(156, 156, 156, 1),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(156, 156, 156, 1),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      hintText: 'Search by Customer Name',
                    ),
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
                // const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color.fromRGBO(0, 140, 192, 1),
                    ),
                  ),
                  child: DropdownButton<String>(
                    icon: const Icon(Icons.filter_list_outlined),
                    dropdownColor: Colors.white,
                    hint: const Text("Challan Type"),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text(
                          'All',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Receive',
                        child: Text(
                          'Receive',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Delivery',
                        child: Text(
                          'Delivery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedType = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                // const SizedBox(width: 8),
                 GestureDetector(
                  onTap: _selectDateRange,
                   child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color.fromRGBO(0, 140, 192, 1),
                      ),
                    ),
                    child: Row(
                      spacing: 10,
                      children: [
                        Text("Date"),
                        Icon(Icons.filter_list_outlined),
                      ],
                    ),
                   ),
                 ),
              ],
            ),

            const SizedBox(height: 12),

            // Animated container with dynamic height (replaces Expanded)
            LayoutBuilder(
              builder: (context, constraints) {
                final int totalRows = _dataSource.rowCount;
                final int visibleRows = totalRows < _rowsPerPage
                    ? totalRows
                    : _rowsPerPage;

                final double tableHeight =
                    headingHeight + (visibleRows * dataRowHeight) + 70;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: tableHeight,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromRGBO(238, 238, 238, 1),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PaginatedDataTable2(
                    key: ValueKey(_tableRebuildKey),
                    source: _dataSource,
                    // dynamic rows per page / options
                    rowsPerPage: _rowsPerPage,
                    availableRowsPerPage: _availableRowsPerPage,
                    onRowsPerPageChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _rowsPerPage = value;
                      });
                    },

                    // visual config
                    header: null,
                    wrapInCard: false,
                    headingRowColor: WidgetStateProperty.all(
                      const Color.fromRGBO(238, 238, 238, 1),
                    ),
                    showFirstLastButtons: true,
                    headingRowHeight: headingHeight,
                    dataRowHeight: dataRowHeight,
                    fixedLeftColumns: 1,
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(
                        label: Text(
                          'Customer Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 140, 192, 1),
                          ),
                        ),
                      ),
                      DataColumn2(
                        fixedWidth: 80,
                        label: Text(
                          'Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 140, 192, 1),
                          ),
                        ),
                      ),
                      DataColumn2(
                        label: Text(
                          'Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 140, 192, 1),
                          ),
                        ),
                      ),
                      DataColumn2(
                        fixedWidth: 60,
                        label: Text(
                          'Qty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 140, 192, 1),
                          ),
                        ),
                      ),
                      DataColumn2(
                        fixedWidth: 200,
                        label: Text(
                          'Actions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 140, 192, 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChallanDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _originalData;
  List<Map<String, dynamic>> _filteredData = [];

  ChallanDataSource(this._originalData) {
    _filteredData = List.from(_originalData);
  }
   final ChallanApi challanApi = ChallanApi();
    List<Map<String, dynamic>> _challanList = [];
  bool _isLoading = true;

   Future<void> _deleteChallan(String challanId) async {
        await challanApi.deleteChallanData(challanId);

    // final confirmed = await showDialog<bool>(
    //   context: context,
    //   builder: (_) => AlertDialog(
    //     title: const Text('Delete Challan'),
    //     content: const Text('Are you sure you want to delete this challan?'),
    //     actions: [
    //       TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
    //       ElevatedButton(
    //         onPressed: () => Navigator.pop(context, true),
    //         style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    //         child: const Text('Delete'),
    //       ),
    //     ],
    //   ),
    // );

    // if (confirmed != true) return;

    // final success = await challanApi.deleteChallanData(challanId);

    // if (success) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Challan deleted successfully')),
    //   );
    //   _fetchChallans();
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Failed to delete challan')),
    //   );
    // }
  }

  Future<void> _editChallan(String challanId) async {
    final controller = TextEditingController();

    // final newCustomerName = await showDialog<String>(
    //   context: context,
    //   builder: (_) => AlertDialog(
    //     title: const Text('Edit Challan'),
    //     content: TextField(
    //       controller: controller,
    //       decoration: const InputDecoration(labelText: 'Enter new customer name'),
    //     ),
    //     actions: [
    //       TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Challan updated successfully')),
    //   );
    //   _fetchChallans();
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Failed to update challan')),
    //   );
    // }
  }



  void applyFilters(String query, dynamic type) {
    _filteredData = _originalData.where((customer) {
      final matchesName = (customer['name'] as String).toLowerCase().contains(
        query,
      );
      final matchesType = type == 'All' || customer['type'] == type;
      return matchesName && matchesType;
    }).toList();
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _filteredData.length) return null;
    final customer = _filteredData[index];
    return DataRow(
      cells: [
        DataCell(Text(customer['name'] ?? '')),
        DataCell(Text(customer['type'] ?? '')),
        DataCell(Text(customer['location'] ?? '')),
        DataCell(Text(customer['qty'] ?? '')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                color: Colors.blue,
                onPressed:() => _editChallan(customer['id']),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share, size: 18),
                color: Colors.green,
                onPressed: () {
                  // share_plus example (simple)
                  Share.share('Check this challan detail');
                  // If you prefer SharePlus.instance.share with ShareParams, adapt accordingly.
                },
              ),
              IconButton(
                icon: const Icon(Icons.print, size: 18),
                color: Colors.orange,
                onPressed: ()=> _deleteChallan(customer['id']),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  int get rowCount => _filteredData.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
