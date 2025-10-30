import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:snow_trading_cool/screens/challan_screen.dart';
import 'package:snow_trading_cool/services/challan_api.dart';

class ViewChallanScreen extends StatefulWidget {
  const ViewChallanScreen({super.key});

  @override
  State<ViewChallanScreen> createState() => _ViewChallanScreenState();
}

class _ViewChallanScreenState extends State<ViewChallanScreen> {

  @override
  void initState(){
    final challApi = ChallanApi();
    final challans = challApi.fetchChallanData(
      // customerName: "Abhishek Sharma",
      // challanType: "Recieive",
    );
    // fetchChallanData();
    super.initState();
  }

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
    {
      'name': 'Abhishek Sharma',
      'type': 'Recieive',
      'location': 'Mumbai, Maharashtra',
      'qty': 12,
    },
    {'name': 'Priya Singh', 'type': 'delivery', 'location': 'Delhi', 'qty': 8},
    {
      'name': 'Rakesh Kumar',
      'type': 'delivery',
      'location': 'Bangalore',
      'qty': 15,
    },
    {'name': 'Anjali Mehta', 'type': 'receive', 'location': 'Pune', 'qty': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challan Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 10,
          children: [
            Row(
              children: [
                Spacer(),
                GestureDetector(
                  onTap: (){
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ChallanScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 30,
                    width: 110,//width: MediaQuery.of(context).size.width / 2.2,
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
            ),
            // DataTable(
            //   headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
            //   // dataRowColor: WidgetStateProperty.all(Colors.white),
            //   border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            //   // border: TableBorder(
            //   //             top: BorderSide.none,
            //   //             bottom: BorderSide.none,
            //   //             left: BorderSide.none,
            //   //             right: BorderSide.none,
            //   //             horizontalInside: BorderSide.none,
            //   //             verticalInside: BorderSide.none,
            //   //             borderRadius: BorderRadius.circular(12),
            //   //           ),
            //   columnSpacing: 20,
            //   headingRowHeight: 56,
            //   dataRowHeight: 64,
            //   columns: const [
            //     // DataColumn(
            //     //   label: Text(
            //     //     '#',
            //     //     style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            //     //   ),
            //     // ),
            //     DataColumn(
            //       label: Text(
            //         'Customer Name',
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           color:  Color.fromRGBO(0, 140, 192, 1),
            //         ),
            //       ),
            //     ),
            //     DataColumn(
            //       label: Text(
            //         'Type',
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           color:  Color.fromRGBO(0, 140, 192, 1),
            //         ),
            //       ),
            //     ),
            //     DataColumn(
            //       label: Text(
            //         'Location',
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           color:  Color.fromRGBO(0, 140, 192, 1),
            //         ),
            //       ),
            //     ),
            //     DataColumn(
            //       label: Text(
            //         'Qty',
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           color:  Color.fromRGBO(0, 140, 192, 1),
            //         ),
            //       ),
            //     ),
            //     DataColumn(
            //       label: Text(
            //         'Actions',
            //         textAlign: TextAlign.center,
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           color:  Color.fromRGBO(0, 140, 192, 1),
            //         ),
            //       ),
            //     ),
            //   ],
            //   rows: _customers.asMap().entries.map((entry) {
            //     final index = entry.key + 1;
            //     final customer = entry.value;
            //     return DataRow(
            //       color: WidgetStateProperty.resolveWith<Color?>(
            //     (Set<WidgetState> states) {
            //       if (index.isOdd) {
            //         return Colors.grey[200]; // odd rows → light grey
            //       }
            //       return Colors.white; // even rows → white
            //     },
            //   ),
            //       cells: [
            //         // DataCell(Text('$index')),
            //         DataCell(
            //           Text(
            //             customer['name'],
            //             // challans[index]['customerName'] ?? '',
            //             style: const TextStyle(fontWeight: FontWeight.w500),
            //           ),
            //         ),
            //         DataCell(
            //           Text(
            //             customer['type'],
            //             style: const TextStyle(fontWeight: FontWeight.w500),
            //           ),
            //           // Container(
            //           //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            //           //   decoration: BoxDecoration(
            //           //     color: customer['type'] == 'Premium'
            //           //         ? Colors.green.shade100
            //           //         : Colors.orange.shade100,
            //           //     borderRadius: BorderRadius.circular(12),
            //           //   ),
            //           //   child: Text(
            //           //     customer['type'],
            //           //     style: TextStyle(
            //           //       color: customer['type'] == 'Premium'
            //           //           ? Colors.green.shade800
            //           //           : Colors.orange.shade800,
            //           //       fontWeight: FontWeight.w600,
            //           //     ),
            //           //   ),
            //           // ),
            //         ),
            //         // if (MediaQuery.of(context).size.width < 300)
            //         DataCell(Text(customer['location'])),
            //         DataCell(
            //           Text(
            //             '${customer['qty']}',
            //             style: const TextStyle(fontWeight: FontWeight.w600),
            //           ),
            //         ),
            //         DataCell(
            //           Row(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               // Edit Button
            //               IconButton(
            //                 icon: const Icon(Icons.edit, size: 18),
            //                 color: Colors.blue,
            //                 tooltip: 'Edit',
            //                 onPressed: () {
            //                   ScaffoldMessenger.of(context).showSnackBar(
            //                     SnackBar(
            //                       content: Text('Edit ${customer['name']}'),
            //                     ),
            //                   );
            //                 },
            //               ),
            //               // Delete Button
            //               IconButton(
            //                 icon: const Icon(Icons.delete, size: 18),
            //                 color: Colors.red,
            //                 tooltip: 'Delete',
            //                 onPressed: () {
            //                   setState(() {
            //                     _customers.removeAt(entry.key);
            //                   });
            //                   ScaffoldMessenger.of(context).showSnackBar(
            //                     SnackBar(
            //                       content: Text('${customer['name']} deleted'),
            //                     ),
            //                   );
            //                 },
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     );
            //   }
              
            //   ).toList(),
            // ),
            Expanded(
              child: DataTable2(
                 headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
              dataRowColor: WidgetStateProperty.all(Colors.white),
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              headingRowHeight: 56,
              dataRowHeight: 64,
                fixedLeftColumns: 1,
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 600,
                  columns: [
                    DataColumn(
                  label: Text(
                    'Customer Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:  Color.fromRGBO(0, 140, 192, 1),
                    ),
                  ),
                ),
                    DataColumn(
                  label: Text(
                    'Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:  Color.fromRGBO(0, 140, 192, 1),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:  Color.fromRGBO(0, 140, 192, 1),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Qty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:  Color.fromRGBO(0, 140, 192, 1),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:  Color.fromRGBO(0, 140, 192, 1),
                    ),
                  ),
                ),
                  ],
                  rows: _customers.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final customer = entry.value;
                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (index.isOdd) {
                    return Colors.grey[200]; // odd rows → light grey
                  }
                  return Colors.white; // even rows → white
                },
              ),
                  cells: [
                    // DataCell(Text('$index')),
                    DataCell(
                      Text(
                        customer['name'],
                        // challans[index]['customerName'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        customer['type'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      //   decoration: BoxDecoration(
                      //     color: customer['type'] == 'Premium'
                      //         ? Colors.green.shade100
                      //         : Colors.orange.shade100,
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Text(
                      //     customer['type'],
                      //     style: TextStyle(
                      //       color: customer['type'] == 'Premium'
                      //           ? Colors.green.shade800
                      //           : Colors.orange.shade800,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
                    ),
                    // if (MediaQuery.of(context).size.width < 300)
                    DataCell(Text(customer['location'])),
                    DataCell(
                      Text(
                        '${customer['qty']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.blue,
                            tooltip: 'Edit',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Edit ${customer['name']}'),
                                ),
                              );
                            },
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.red,
                            tooltip: 'Delete',
                            onPressed: () {
                              setState(() {
                                _customers.removeAt(entry.key);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${customer['name']} deleted'),
                                ),
                              );
                            },
                          ),
                          // IconButton(onPressed: (){}, icon: Icon(Icons.share))
                        ],
                      ),
                    ),
                  ],
                );
              } ).toList(),
                  // rows: List<DataRow>.generate(
                  //     100,
                  //     (index) => DataRow(cells: [
                  //           DataCell(Text('A' * (10 - index % 10))),
                  //           DataCell(Text('B' * (10 - (index + 5) % 10))),
                  //           DataCell(Text('C' * (15 - (index + 5) % 10))),
                  //           DataCell(Text('D' * (15 - (index + 10) % 10))),
                  //           DataCell(Text(((index + 0.1) * 25.4).toString()))
                  //         ]))
                          
                          ),
            ),
          ],
        ),
      ),
    );
  }
}
