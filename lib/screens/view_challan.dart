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
  @override
  void initState() {
    final challApi = ChallanApi();
    final challans = challApi.fetchChallanData(
      // customerName: "Abhishek Sharma",
      // challanType: "Recieive",
    );
    // fetchChallanData();
    _dataSource = ChallanDataSource(_customers);
    super.initState();
  }

  TextEditingController searchController = TextEditingController();
  late ChallanDataSource _dataSource;

  String selectedType = 'All';

  // API

  //   final challanApi = ChallanApi();
  // final challans = await challanApi.fetchChallanData(
  //   customerName: "John Doe",
  //   challanType: "Received",
  // );

  // if (challans.isNotEmpty) {
  //   print("Fetched ${challans.length} challans");
  //   print(challans);
  // } else {
  //   print("No challan data found.");
  // }

  final List<Map<String, dynamic>> _customers = [
  {'name': 'Abhishek Sharma', 'type': 'Receive', 'location': 'Mumbai, Maharashtra', 'qty': "2"},
  {'name': 'Priya Singh', 'type': 'Delivery', 'location': 'Delhi', 'qty': "3"},
  {'name': 'Rakesh Kumar', 'type': 'Delivery', 'location': 'Bangalore', 'qty': "1"},
  {'name': 'Anjali Mehta', 'type': 'Receive', 'location': 'Pune', 'qty': "6"},
  {'name': 'Vikram Patel', 'type': 'Delivery', 'location': 'Ahmedabad', 'qty': "4"},
  {'name': 'Neha Sharma', 'type': 'Receive', 'location': 'Chandigarh', 'qty': "2"},
  {'name': 'Abhishek Verma', 'type': 'Delivery', 'location': 'Nashik', 'qty': "5"},
  {'name': 'Priya Nair', 'type': 'Receive', 'location': 'Indore', 'qty': "3"},
  {'name': 'Rakesh Yadav', 'type': 'Receive', 'location': 'Jaipur', 'qty': "1"},
  {'name': 'Siddharth Deshmukh', 'type': 'Delivery', 'location': 'Goa', 'qty': "2"},
  {'name': 'Pooja Iyer', 'type': 'Receive', 'location': 'Nagpur', 'qty': "7"},
  {'name': 'Vikram Chauhan', 'type': 'Receive', 'location': 'Surat', 'qty': "3"},
  {'name': 'Neha Pandey', 'type': 'Delivery', 'location': 'Lucknow', 'qty': "2"},
  {'name': 'Amit Joshi', 'type': 'Delivery', 'location': 'Hyderabad', 'qty': "4"},
  {'name': 'Anjali Bhatia', 'type': 'Delivery', 'location': 'Bhopal', 'qty': "5"},
];



  void _applyFilters() {
    String query = searchController.text.toLowerCase();
    String type = selectedType;
    setState(() {
      _dataSource.applyFilters(query, type);
    });
  }

  void _resetFilters() {
    searchController.clear();
    setState(() {
      selectedType = 'All';
      _dataSource.applyFilters('', 'All');
    });
  }

  @override
  Widget build(BuildContext context) {
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
              width: 110, //width: MediaQuery.of(context).size.width / 2.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromRGBO(0, 140, 192, 1),
              ),
              child: Center(
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
        actionsPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 10,
          children: [
            Row(
              spacing: 10,
              children: [
                // Spacer(),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    
                    decoration: InputDecoration(
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
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(156, 156, 156, 1),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(156, 156, 156, 1),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Search by Customer Name',
                      ),
                    onChanged: (value) => _applyFilters(),
                  ),
                ),
                Container(
                  // height: 30,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color.fromRGBO(0, 140, 192, 1)),
                  ),
                  child: DropdownButton<String>(
                    icon: Icon(Icons.filter_list_outlined),
                    dropdownColor: Colors.white,
                    // dropdownColor: Color.fromRGBO(0, 140, 192, 1),
                    hint: Text(
                      "Challan Type",
                      style: TextStyle(
                        // color: Colors.grey
                      ),
                    ),
                    style: TextStyle(
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
                            // color: Colors.white,
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
                            // color: Colors.white,
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
                            // color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color.fromRGBO(238, 238, 238, 1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PaginatedDataTable2(
                  source: _dataSource,
                  headingRowColor: WidgetStateProperty.all(
                    Color.fromRGBO(238, 238, 238, 1),
                  ),
                  // rowsPerPage: 5, // 👈 number of rows per page
                  // availableRowsPerPage: const [5, 10, 20],
                  showFirstLastButtons: true,

                  // dataRowColor: WidgetStateProperty.all(Colors.white),
                  border: TableBorder(
                    top: BorderSide.none,
                    bottom: BorderSide.none,
                    left: BorderSide.none,
                    right: BorderSide.none,
                    horizontalInside: BorderSide.none,
                    verticalInside: BorderSide.none,
                    // borderRadius: BorderRadius.circular(12),
                  ),
                  // border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                  headingRowHeight: 56,
                  dataRowHeight: 64,
                  fixedLeftColumns: 1,
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 600,
                  columns: [
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
              ),
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

  void applyFilters(String query, dynamic type) {
    _filteredData = _originalData.where((customer) {
      final matchesName = customer['name']!.toLowerCase().contains(query);
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
        DataCell(Text(customer['name']!)),
        DataCell(Text(customer['type']!)),
        DataCell(Text(customer['location']!)),
        DataCell(Text(customer['qty']!)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                color: Colors.blue,
                onPressed: () {},
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
                  SharePlus.instance.share(
                    ShareParams(text: 'check out my website https://example.com')
                  );
                },
              ),
              IconButton(onPressed: (){}, icon: Icon(Icons.print, size: 18), color: Colors.orange,),
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
