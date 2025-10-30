import 'package:flutter/material.dart';
import 'package:snow_trading_cool/services/challan_api.dart';

class ChallanScreen extends StatefulWidget {
  const ChallanScreen({super.key});

  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  final ChallanApi _api = ChallanApi();

  TextEditingController customerNameController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController transporterController = TextEditingController();
  TextEditingController vehicleDriverDetailsController =
      TextEditingController();
  TextEditingController mobileNumberController = TextEditingController();

  TextEditingController smallRegularQtyController = TextEditingController();
  TextEditingController smallRegularSrNoController = TextEditingController();
  TextEditingController smallFloronQtyController = TextEditingController();
  TextEditingController smallFloronSrNoController = TextEditingController();
  TextEditingController bigRegularQtyController = TextEditingController();
  TextEditingController bigRegularSrNoController = TextEditingController();
  TextEditingController bigFloronQtyController = TextEditingController();
  TextEditingController bigFloronSrNoController = TextEditingController();

  bool challanTypeSelected = true;

  String type = "Received";

  List<Map<String, String>> allCustomerNames = [
    {"name": "Abhishek", "mobileNumber": "9511789875"},
    {"name": "Saurav", "mobileNumber": "9511789876"},
    {"name": "Subodh", "mobileNumber": "9511789877"},
    {"name": "Himanshu", "mobileNumber": "9511789878"},
    {"name": "Abhijeet", "mobileNumber": "9511789879"},
  ];

  List<Map<String, String>> filteredCustomerNames = [];
  bool showDropdown = false;

  bool _loading = false;

  void searchCustomer(String query) {
    setState(() {
      if (query.isEmpty) {
        showDropdown = false;
        filteredCustomerNames = [];
      } else {
        filteredCustomerNames = allCustomerNames
            .where(
              (c) => c['name']!.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        showDropdown = filteredCustomerNames.isNotEmpty;
      }
    });
  }

  void selectCustomer(String name, String mobileNumber) {
    setState(() {
      customerNameController.text = name;
      mobileNumberController.text = mobileNumber;
      showDropdown = false;
    });
  }

  Future<void> _saveChallanData() async {
    final customerName = customerNameController.text;
    final challanType = type;
    final location = locationController.text;
    final transporter = transporterController.text;
    final vehicleDriverDetails = vehicleDriverDetailsController.text;
    final mobileNumber = mobileNumberController.text;
    final smallRegularQty = smallRegularQtyController.text;
    final smallRegularSrNo = smallRegularSrNoController.text;
    final smallFloronQty = smallFloronQtyController.text;
    final smallFloronSrNo = smallFloronSrNoController.text;
    final bigRegularQty = bigRegularQtyController.text;
    final bigRegularSrNo = bigRegularSrNoController.text;
    final bigFloronQty = bigFloronQtyController.text;
    final bigFloronSrNo = bigFloronSrNoController.text;

    if (customerName.isEmpty ||
        challanType.isEmpty ||
        location.isEmpty ||
        transporter.isEmpty ||
        vehicleDriverDetails.isEmpty ||
        mobileNumber.isEmpty ||
        smallRegularQty.isEmpty ||
        smallRegularSrNo.isEmpty ||
        smallFloronSrNo.isEmpty ||
        smallFloronQty.isEmpty ||
        bigRegularQty.isEmpty ||
        bigRegularSrNo.isEmpty ||
        bigFloronQty.isEmpty ||
        bigFloronSrNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: StadiumBorder(side: BorderSide(color: Colors.red)),
          behavior: SnackBarBehavior.floating,
          // margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          width: MediaQuery.of(context).size.width - 64,
          content: Text(
            'Please fill all fields',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    return _api
        .challanData(
          customerName,
          challanType,
          location,
          transporter,
          vehicleDriverDetails,
          mobileNumber,
          smallRegularQty,
          smallRegularSrNo,
          smallFloronQty,
          smallFloronSrNo,
          bigRegularQty,
          bigRegularSrNo,
          bigFloronQty,
          bigFloronSrNo,
        )
        .then((success) {
          setState(() => _loading = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                shape: StadiumBorder(side: BorderSide(color: Colors.green)),
                behavior: SnackBarBehavior.floating,
                width: MediaQuery.of(context).size.width - 64,
                content: Text(
                  'Challan data saved successfully',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                shape: StadiumBorder(side: BorderSide(color: Colors.red)),
                behavior: SnackBarBehavior.floating,
                width: MediaQuery.of(context).size.width - 64,
                content: Text(
                  'Failed to save challan data',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        })
        .catchError((error) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              shape: StadiumBorder(side: BorderSide(color: Colors.red)),
              behavior: SnackBarBehavior.floating,
              width: MediaQuery.of(context).size.width - 64,
              content: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  void dispose() {
    customerNameController.dispose();
    locationController.dispose();
    transporterController.dispose();
    vehicleDriverDetailsController.dispose();
    mobileNumberController.dispose();
    smallRegularQtyController.dispose();
    smallRegularSrNoController.dispose();
    smallFloronQtyController.dispose();
    smallFloronSrNoController.dispose();
    bigRegularQtyController.dispose();
    bigRegularSrNoController.dispose();
    bigFloronQtyController.dispose();
    bigFloronSrNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Received/Delivered Challan"),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color.fromRGBO(0, 140, 192, 1),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 10,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Customer Name",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(20, 20, 20, 1),
                      ),
                    ),
                    TextField(
                      controller: customerNameController,
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
                        hintText: "Enter Customer Name",
                      ),
                      onChanged: searchCustomer,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    if (showDropdown)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredCustomerNames.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                filteredCustomerNames[index]['name']!,
                              ),
                              onTap: () => selectCustomer(
                                filteredCustomerNames[index]['name']!,
                                filteredCustomerNames[index]['mobileNumber']!,
                              ),
                            );
                          },
                        ),
                      ),
                    Row(
                      spacing: 10,
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Challan Type",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              challanTypeSelected = true;
                              type = "Receive";
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 2,
                                    color: Color.fromRGBO(
                                      0,
                                      140,
                                      192,
                                      1,
                                    ), //Color.fromRGBO(156, 156, 156, 1),
                                  ),
                                  shape: BoxShape.circle,
                                  color: challanTypeSelected
                                      ? Color.fromRGBO(0, 140, 192, 1)
                                      : Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Receive",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              challanTypeSelected = false;
                              type = "Delivery";
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 2,
                                    color: Color.fromRGBO(0, 140, 192, 1),
                                  ),
                                  shape: BoxShape.circle,
                                  color: challanTypeSelected
                                      ? Colors.white
                                      : Color.fromRGBO(0, 140, 192, 1),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Delivery",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _buildTitleAndField(
                      title: "Location",
                      controller: locationController,
                      hintText: "Enter Location",
                    ),
                    _buildTitleAndField(
                      title: "Transporter",
                      controller: transporterController,
                      hintText: "Enter Transporter Details",
                    ),
                    _buildTitleAndField(
                      title: "Vehicle/Driver Details",
                      controller: vehicleDriverDetailsController,
                      hintText: "Enter Transporter Details",
                    ),

                    Text(
                      "Mobile Number",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(20, 20, 20, 1),
                      ),
                    ),
                    TextField(
                      controller: mobileNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        hintText: "Your Mobile Number",
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
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromRGBO(238, 238, 238, 1),
                        ),
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // outer curved border radius
                      ),
                      child: Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        border: TableBorder(
                          top: BorderSide.none,
                          bottom: BorderSide.none,
                          left: BorderSide.none,
                          right: BorderSide.none,
                          horizontalInside: BorderSide.none,
                          verticalInside: BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        columnWidths: {
                          0: FlexColumnWidth(0.7),
                          1: FlexColumnWidth(0.5),
                          // 2: FixedColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(238, 238, 238, 1),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                topLeft: Radius.circular(12),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  "Product",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(0, 140, 192, 1),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  "QTY",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(0, 140, 192, 1),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  "Sr. No",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(0, 140, 192, 1),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  "Small Regular",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  controller: smallRegularQtyController,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  controller: smallRegularSrNoController,
                                ),
                              ),
                            ],
                          ),

                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  "Small Floron",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  controller: smallFloronQtyController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  controller: smallFloronSrNoController,
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  "Big Regular",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  controller: bigRegularQtyController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  controller: bigRegularSrNoController,
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  "Big Floron",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  controller: bigFloronQtyController,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromRGBO(238, 238, 238, 1),
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  controller: bigFloronSrNoController,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    customerNameController.clear();
                    locationController.clear();
                    transporterController.clear();
                    vehicleDriverDetailsController.clear();
                    mobileNumberController.clear();
                    smallRegularQtyController.clear();
                    smallRegularSrNoController.clear();
                    smallFloronQtyController.clear();
                    smallFloronSrNoController.clear();
                    bigRegularQtyController.clear();
                    bigRegularSrNoController.clear();
                    bigFloronQtyController.clear();
                    bigFloronSrNoController.clear();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2.2,
                    height: 46,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromRGBO(0, 140, 192, 1),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Reset",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(0, 140, 192, 1),
                        ),
                      ),
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    _saveChallanData();
                    customerNameController.clear();
                    locationController.clear();
                    transporterController.clear();
                    vehicleDriverDetailsController.clear();
                    mobileNumberController.clear();
                    smallRegularQtyController.clear();
                    smallRegularSrNoController.clear();
                    smallFloronQtyController.clear();
                    smallFloronSrNoController.clear();
                    bigRegularQtyController.clear();
                    bigRegularSrNoController.clear();
                    bigFloronQtyController.clear();
                    bigFloronSrNoController.clear();

                    // log(customerNameController.text);
                  },
                  child: Container(
                    height: 46,
                    width: MediaQuery.of(context).size.width / 2.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromRGBO(0, 140, 192, 1),
                    ),
                    child: Center(
                      child: Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndField({
    required String title,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(20, 20, 20, 1),
          ),
        ),
        TextField(
          controller: controller,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(20, 20, 20, 1),
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            hintText: hintText,
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
          ),
        ),
      ],
    );
  }
}
