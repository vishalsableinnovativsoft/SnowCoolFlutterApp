// import 'dart:async';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:snow_trading_cool/screens/home_screen.dart';
// import 'package:snow_trading_cool/services/goods_api.dart';
// import 'package:snow_trading_cool/services/passbook_api.dart';
// import 'package:snow_trading_cool/utils/constants.dart';
// import 'package:snow_trading_cool/utils/token_manager.dart';
// import 'package:snow_trading_cool/widgets/custom_toast.dart';
// import 'package:snow_trading_cool/widgets/drawer.dart';
// import 'package:snow_trading_cool/widgets/custom_loader.dart';

// class PassBookScreenn extends StatefulWidget {
//   final int? customerId;
//   final String? customerName;

//   const PassBookScreenn({super.key, this.customerId, this.customerName});

//   @override
//   State<PassBookScreenn> createState() => _PassBookScreennState();
// }

// class _PassBookScreennState extends State<PassBookScreenn> {
//   // final TextEditingController _nameSearchController = TextEditingController();
//   // final TextEditingController _poSearchController = TextEditingController();

//   Timer? _searchDebounce;

//   final GoodsApi _goodsApi = GoodsApi();

//   List<Map<String, dynamic>> _paginatedEntries = [];
//   Timer? _debounceTimer;

//   Timer? _searchTimer;

//   bool _isLoading = true;
//   bool _isFirstLoad = true;
//   bool _goodsLoading = true;
//   int _currentPage = 0;
//   final int _rowsPerPage = 7;

//   // Filters
//   String _searchQuery = '';
//   String _poSearchQuery = '';
//   DateTime? _fromDate;
//   DateTime? _toDate;

//   int _totalPages = 1;
//   int _totalElements = 0;

//   String _userRole = 'Employee';
//   late bool isAdmin = _userRole == 'ADMIN';

//   GoodsDTO? selectedGoods;
//   List<GoodsDTO> goods = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserRole();
//     _loadPassbook(page: 0);
//     _loadGoods();
//   }

//   Future<void> _loadGoods() async {
//     if (!_goodsLoading) return;

//     try {
//       final list = await _goodsApi.getAllGoods();
//       if (!mounted) return;

//       setState(() {
//         goods = list;
//         _goodsLoading = false;
//       });
//     } catch (e) {
//       debugPrint("Failed to load goods: $e");
//       if (mounted) {
//         showErrorToast(context, "Failed to load products");
//         setState(() {
//           _goodsLoading = false;
//           goods = [];
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _searchTimer?.cancel();
//     super.dispose();
//   }

//   void _loadUserRole() {
//     final savedRole = TokenManager().getRole();
//     _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
//     setState(() {});
//   }

//   Future<void> _loadPassbook({required int page}) async {
//     if (!mounted) return;

//     setState(() {
//       _isLoading = true;
//       _isFirstLoad = page == 0;
//     });

//     try {
//       Map<String, dynamic> result;

//       if (widget.customerId != null && widget.customerId! > 0) {
//         result = await PassbookApi().getPassbookByCustomerId(
//           context: context,
//           customerId: widget.customerId!,
//           page: page,
//           size: _rowsPerPage,
//         );
//       } else {
//         String? name, contactNumber, srNo, poNumber, siteLocation, itemName;

//         final mainSearch = _searchQuery.trim();
//         if (mainSearch.isNotEmpty) {
//           final onlyDigits = RegExp(r'^\d+$').hasMatch(mainSearch);
//           final onlyLetters = RegExp(r'^[a-zA-Z\s]+$').hasMatch(mainSearch);

//           if (onlyDigits && mainSearch.length >= 3) {
//             contactNumber = mainSearch;
//           } else if (onlyLetters) {
//             name = mainSearch;
//           } else {
//             srNo = mainSearch;
//           }
//         }

//         final poSearch = _poSearchQuery.trim();
//         if (poSearch.isNotEmpty) {
//           final hasDigits = RegExp(r'\d').hasMatch(poSearch);
//           if (hasDigits)
//             poNumber = poSearch;
//           else
//             siteLocation = poSearch;
//         }

//         if (selectedGoods != null) {
//           itemName = selectedGoods!.name;
//         }

//         result = await PassbookApi().searchUnified(
//           context: context,
//           name: name,
//           contactNumber: contactNumber,
//           srNo: srNo,
//           poNumber: poNumber,
//           siteLocation: siteLocation,
//           itemName: itemName,
//           fromDate: _fromDate,
//           toDate: _toDate,
//           page: page,
//           size: _rowsPerPage,
//         );
//       }

//       final List<Map<String, dynamic>> items = (result['content'] as List)
//           .cast<Map<String, dynamic>>();

//       items.sort((a, b) {
//         final da = a['date'] as String? ?? '';
//         final db = b['date'] as String? ?? '';
//         return db.compareTo(da);
//       });

//       int runningBalance = 0;
//       final balanceMap = <int, int>{};
//       for (var item in items) {
//         final delivered = item['delivered'] as int? ?? 0;
//         final received = item['received'] as int? ?? 0;
//         runningBalance += received - delivered;
//         balanceMap[item['id'] as int] = runningBalance;
//       }
//       for (var item in items) {
//         item['running_balance'] = balanceMap[item['id']] ?? 0;
//       }

//       setState(() {
//         _paginatedEntries = items;
//         _currentPage = result['number'] ?? page;
//         _totalPages = result['totalPages'] ?? 1;
//         _totalElements = result['totalElements'] ?? 0;
//         _isLoading = false;
//         _isFirstLoad = false;
//       });
//     } catch (e, s) {
//       debugPrint('Load passbook error: $e\n$s');
//       if (mounted) {
//         showErrorToast(context, 'Failed to load passbook');
//         setState(() {
//           _isLoading = false;
//           _paginatedEntries = [];
//         });
//       }
//     }
//   }

//   void _debouncedSearch() {
//     _searchDebounce?.cancel();
//     _searchDebounce = Timer(const Duration(milliseconds: 400), () {
//       _loadPassbook(page: 0);
//     });
//   }

//   Widget _safeDateCell(String? dateStr) {
//     if (dateStr == null || dateStr.isEmpty || dateStr.toLowerCase() == 'null') {
//       return _dataCell('-', 130);
//     }
//     try {
//       final date = DateTime.parse(dateStr);
//       return _dataCell(DateFormat('dd-MM-yyyy').format(date), 130);
//     } catch (e) {
//       return _dataCell('Invalid Date', 130);
//     }
//   }

//   void _applyFilters() {
//     _loadPassbook(page: 0);
//   }

//   void _clearFilters() {
//     setState(() {
//       _searchQuery = '';
//       _poSearchQuery = '';
//       _fromDate = null;
//       _toDate = null;
//       selectedGoods = null;
//       // _nameSearchController.clear();
//       // _poSearchController.clear();
//     });
//     _applyFilters();
//   }

//   bool _hasActiveFilters() =>
//       _searchQuery.isNotEmpty ||
//       _poSearchQuery.isNotEmpty ||
//       _fromDate != null ||
//       _toDate != null ||
//       selectedGoods != null;

//   Future<void> _pickFromDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2005),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: AppColors.accentBlue, // Header background & selected day
//               onPrimary: Colors.white, //  Text on header & selected day
//               surface: Colors.white, //Calendar background
//               onSurface: Colors.black87, //Normal text
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: AppColors.accentBlue, // OK / Cancel buttons
//                 textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//               ),
//             ),
//             dialogBackgroundColor: Colors.white,
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() => _fromDate = picked);
//       _applyFilters();
//     }
//   }

//   void _showFiltersBottomSheet() {
//     String localSearchQuery = _searchQuery;
//     String localPoSearchQuery = _poSearchQuery;
//     DateTime? localFromDate = _fromDate;
//     DateTime? localToDate = _toDate;
//     GoodsDTO? localSelectedGoods = selectedGoods;

//     final TextEditingController nameController = TextEditingController(
//       text: localSearchQuery,
//     );
//     final TextEditingController poController = TextEditingController(
//       text: localPoSearchQuery,
//     );

//     nameController.addListener(() {
//       localSearchQuery = nameController.text;
//     });
//     poController.addListener(() {
//       localPoSearchQuery = poController.text;
//     });

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setStateBottomSheet) {
//             return Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               padding: EdgeInsets.only(
//                 left: 0,
//                 right: 0,
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // HEADER
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(15, 12, 20, 8),
//                     child: Row(
//                       children: [
//                         const Spacer(),
//                         const Text(
//                           "Advanced Filters",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const Spacer(),

//                         TextButton(
//                           onPressed: _hasActiveFilters()
//                               ? () {
//                                   setStateBottomSheet(() {
//                                     localSearchQuery = '';
//                                     localPoSearchQuery = '';
//                                     localFromDate = null;
//                                     localToDate = null;
//                                     localSelectedGoods = null;
//                                   });
//                                   nameController.clear();
//                                   poController.clear();

//                                   setState(() {
//                                     _searchQuery = '';
//                                     _poSearchQuery = '';
//                                     _fromDate = null;
//                                     _toDate = null;
//                                     selectedGoods = null;
//                                   });

//                                   Navigator.pop(context);
//                                   _applyFilters();
//                                 }
//                               : null,
//                           child: Text(
//                             "Reset",
//                             style: TextStyle(
//                               color: _hasActiveFilters()
//                                   ? Colors.red.shade600
//                                   : Colors.grey,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const Divider(height: 1),

//                   Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       children: [
//                         _buildSearchField(
//                           label: "Search by Name / Mobile / SR No.",
//                           hint: "Name / Mobile / SR No.",
//                           icon: Icons.search,
//                           value: localSearchQuery,
//                           onChanged: (value) => setStateBottomSheet(
//                             () => localSearchQuery = value,
//                           ),
//                           controller: nameController,
//                         ),
//                         const SizedBox(height: 20),
//                         _buildSearchField(
//                           label: "Search by PO Number / Site Location",
//                           hint: "PO Number / Site Location",
//                           icon: Icons.receipt_long,
//                           value: localPoSearchQuery,
//                           onChanged: (value) => setStateBottomSheet(
//                             () => localPoSearchQuery = value,
//                           ),
//                           controller: poController,
//                         ),
//                         const SizedBox(height: 20),
//                         _buildProductDropdown(
//                           selectedGoods: localSelectedGoods,
//                           goods: goods,
//                           onChanged: (GoodsDTO? newValue) {
//                             setStateBottomSheet(
//                               () => localSelectedGoods = newValue,
//                             );
//                           },
//                         ),
//                         const SizedBox(height: 20),

//                         // Row(
//                         //   children: [
//                         //     Expanded(
//                         //       child: _buildDateButton(
//                         //         "From Date",
//                         //         localFromDate,
//                         //         () async {
//                         //           final picked = await showDatePicker(/* ... same as before ... */);
//                         //           if (picked != null) {
//                         //             setStateBottomSheet(() => localFromDate = picked);
//                         //           }
//                         //         },
//                         //       ),
//                         //     ),
//                         //     const SizedBox(width: 12),
//                         //     Expanded(
//                         //       child: _buildDateButton(
//                         //         "To Date",
//                         //         localToDate,
//                         //         () async {
//                         //           final picked = await showDatePicker(
//                         //             /* ... same, with firstDate: localFromDate ?? ... */
//                         //             initialDate: DateTime.now(),
//                         //             firstDate: localFromDate?.add(const Duration(days: 1)) ?? DateTime(2005),
//                         //             lastDate: DateTime.now(),
//                         //             // ...
//                         //           );
//                         //           if (picked != null) {
//                         //             setStateBottomSheet(() => localToDate = picked);
//                         //           }
//                         //         },
//                         //       ),
//                         //     ),
//                         //   ],
//                         // ),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildDateButton(
//                                 "From Date",
//                                 localFromDate,
//                                 () async {
//                                   final picked = await showDatePicker(
//                                     context:
//                                         context, // ← This 'context' is the StatefulBuilder's context → CORRECT
//                                     initialDate:
//                                         localFromDate ?? DateTime.now(),
//                                     firstDate: DateTime(2005),
//                                     lastDate: DateTime.now(),
//                                     builder: (context, child) {
//                                       return Theme(
//                                         data: Theme.of(context).copyWith(
//                                           colorScheme: ColorScheme.light(
//                                             primary: AppColors.accentBlue,
//                                             onPrimary: Colors.white,
//                                             surface: Colors.white,
//                                             onSurface: Colors.black87,
//                                           ),
//                                           textButtonTheme: TextButtonThemeData(
//                                             style: TextButton.styleFrom(
//                                               foregroundColor:
//                                                   AppColors.accentBlue,
//                                               textStyle: GoogleFonts.poppins(
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         child: child!,
//                                       );
//                                     },
//                                   );
//                                   if (picked != null) {
//                                     setStateBottomSheet(
//                                       () => localFromDate = picked,
//                                     );
//                                   }
//                                 },
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _buildDateButton(
//                                 "To Date",
//                                 localToDate,
//                                 () async {
//                                   final picked = await showDatePicker(
//                                     context: context, // ← Correct context
//                                     initialDate: localToDate ?? DateTime.now(),
//                                     firstDate:
//                                         localFromDate?.add(
//                                           const Duration(days: 1),
//                                         ) ??
//                                         DateTime(2005),
//                                     lastDate: DateTime.now(),
//                                     builder: (context, child) {
//                                       return Theme(
//                                         data: Theme.of(context).copyWith(
//                                           colorScheme: ColorScheme.light(
//                                             primary: AppColors.accentBlue,
//                                             onPrimary: Colors.white,
//                                             surface: Colors.white,
//                                             onSurface: Colors.black87,
//                                           ),
//                                           textButtonTheme: TextButtonThemeData(
//                                             style: TextButton.styleFrom(
//                                               foregroundColor:
//                                                   AppColors.accentBlue,
//                                               textStyle: GoogleFonts.poppins(
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         child: child!,
//                                       );
//                                     },
//                                   );
//                                   if (picked != null) {
//                                     setStateBottomSheet(
//                                       () => localToDate = picked,
//                                     );
//                                   }
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),

//                   // APPLY BUTTON
//                   Container(
//                     padding: EdgeInsets.only(
//                       left: 20,
//                       right: 20,
//                       bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//                       top: 12,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       boxShadow: [/* ... */],
//                     ),
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 56,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           // Commit local values to global state
//                           setState(() {
//                             _searchQuery = nameController.text;
//                             _poSearchQuery = poController.text;
//                             // _searchQuery = localSearchQuery;
//                             // _poSearchQuery = localPoSearchQuery;
//                             _fromDate = localFromDate;
//                             _toDate = localToDate;
//                             selectedGoods = localSelectedGoods;
//                           });
//                           Navigator.pop(context);
//                           _applyFilters(); // Reload data
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.accentBlue,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                         ),
//                         child: const Text(
//                           "Apply Filters",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> _pickToDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: _fromDate != null
//           ? _fromDate!.add(const Duration(days: 1))
//           : DateTime(2005),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: AppColors.accentBlue, // Header background & selected day
//               onPrimary: Colors.white, //  Text on header & selected day
//               surface: Colors.white, //Calendar background
//               onSurface: Colors.black87, //Normal text
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: AppColors.accentBlue, // OK / Cancel buttons
//                 textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//               ),
//             ),
//             dialogBackgroundColor: Colors.white,
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() => _toDate = picked);
//       _applyFilters();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const blueColor = AppColors.accentBlue;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.customerName != null
//               ? 'Passbook - ${widget.customerName}'
//               : 'Passbook - All Customers',
//           overflow: TextOverflow.ellipsis,
//           style: GoogleFonts.inter(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         leadingWidth: 96,
//         leading: Row(
//           children: [
//             Builder(
//               builder: (context) => IconButton(
//                 icon: Icon(Icons.menu),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               ),
//             ),
//             if (isAdmin)
//               IconButton(
//                 onPressed: () => Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(builder: (context) => HomeScreen()),
//                 ),
//                 icon: Icon(Icons.home),
//               ),
//           ],
//         ),
//         backgroundColor: blueColor,
       
//       ),
//       drawer: ShowSideMenu(),
//       body: RefreshIndicator(
//         onRefresh: () => _loadPassbook(page: 0),
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: LayoutBuilder(
//                     builder: (context, constraints) {
//                       final bool isTablet = constraints.maxWidth > 600;
//                       return Column(
//                         children: [
//                           Row(
//                             spacing: 5,
//                             children: [
//                               _buildTotalRecordsBadge(),

//                               const Spacer(),
//                               Row(
//                                 mainAxisSize: MainAxisSize
//                                     .min, // Prevents unnecessary stretching
//                                 children: [
//                                   _buildExportDropdown(),

//                                   const SizedBox(width: 5),

//                                   Stack(
//                                     children: [
//                                       SizedBox(
//                                         height: 56,
//                                         width: 54,
//                                         child: ElevatedButton(
//                                           onPressed: () =>
//                                               _showFiltersBottomSheet(),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor:
//                                                 AppColors.accentBlue,
//                                             padding: EdgeInsets.zero,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(16),
//                                             ),
//                                           ),
//                                           child: const Icon(
//                                             Icons.tune_rounded,
//                                             color: Colors.white,
//                                             size: 28,
//                                           ),
//                                         ),
//                                       ),
//                                       if (_hasActiveFilters())
//                                         Positioned(
//                                           right: 6,
//                                           top: 6,
//                                           child: Container(
//                                             padding: const EdgeInsets.all(4),
//                                             decoration: const BoxDecoration(
//                                               color: Colors.red,
//                                               shape: BoxShape.circle,
//                                             ),
//                                             child: const Text(
//                                               "!",
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 10,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
                         
                         
//                             ],
//                           ),
//                         ],
//                       );
//                     },
//                   ),
               
//                 ),

//                 // Main Table
//                 Expanded(
//                   child: _paginatedEntries.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const Icon(
//                                 Icons.inventory_2_outlined,
//                                 size: 60,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 widget.customerId != null
//                                     ? "No passbook entries found for this customer"
//                                     : "No passbook entries found",
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   color: Colors.grey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         )
//                       : Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Left: Challan Numbers
//                             SizedBox(
//                               width: 180,
//                               child: Column(
//                                 children: [
//                                   Container(
//                                     height: 56,
//                                     color: blueColor,
//                                     child: const Center(
//                                       child: Text(
//                                         'Challan No.',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Expanded(
//                                     child: ListView.builder(
//                                       physics:
//                                           const NeverScrollableScrollPhysics(),
//                                       shrinkWrap: true,
//                                       itemCount: _paginatedEntries.length,
//                                       itemBuilder: (_, i) {
//                                         final challanNo =
//                                             _paginatedEntries[i]['challanNumber'] ??
//                                             'N/A';
//                                         return Container(
//                                           height: 63,
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 12,
//                                           ),
//                                           alignment: Alignment.centerLeft,
//                                           decoration: BoxDecoration(
//                                             border: Border(
//                                               bottom: BorderSide(
//                                                 color: Colors.grey.shade200,
//                                               ),
//                                             ),
//                                           ),
//                                           child: Text(
//                                             challanNo,
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.w600,
//                                               fontSize: 14,
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),

//                             // Right: Data Columns
//                             Expanded(
//                               child: SingleChildScrollView(
//                                 scrollDirection: Axis.horizontal,
//                                 child: SizedBox(
//                                   width: 1550,
//                                   child: Column(
//                                     children: [
//                                       // Header
//                                       Container(
//                                         height: 56,
//                                         color: blueColor,
//                                         child: Row(
//                                           children: [
//                                             //    derCell(
//                                             //   'Received Challan Nos',
//                                             //   170,
//                                             // ),
//                                             _headerCell('Customer Name', 120),
//                                             _headerCell('Date', 130),
//                                             _headerCell('Type', 130),
//                                             _headerCell('SR No.', 130),
//                                             _headerCell('PO No.', 140),
//                                             _headerCell('Site', 160),
//                                             _headerCell('Deliv Qty', 110),
//                                             _headerCell('Rece Qty', 110),
//                                             _headerCell('Balance', 120),
//                                             _headerCell('Deposit', 140),
//                                             _headerCell('Deposit Balance', 120),
//                                             _headerCell('Action', 140),
//                                           ],
//                                         ),
//                                       ),

//                                       // Rows
//                                       Expanded(
//                                         child: ListView.builder(
//                                           physics:
//                                               const NeverScrollableScrollPhysics(),
//                                           shrinkWrap: true,
//                                           itemCount: _paginatedEntries.length,
//                                           itemBuilder: (_, i) {
//                                             final e = _paginatedEntries[i];
//                                             final balanceQty =
//                                                 e['delivered'] - e['received'];
//                                             final depositeBalance =
//                                                 e['deposite'] +
//                                                 e['returnedAmount'];

//                                             // log("e: $e");

//                                             return Container(
//                                               height: 63,
//                                               decoration: BoxDecoration(
//                                                 border: Border(
//                                                   bottom: BorderSide(
//                                                     color: Colors.grey.shade200,
//                                                   ),
//                                                 ),
//                                               ),
//                                               child: Row(
//                                                 children: [
//                                                   // buildReceivedChallansCell(
//                                                   //   context: context,
//                                                   //   receivedchallanList:
//                                                   //       _parseChallanList(
//                                                   //         e['receivedChallanNos'],
//                                                   //       ),
//                                                   // ),
//                                                   _dataCell(
//                                                     e['customerName'],
//                                                     120,
//                                                   ),

//                                                   _safeDateCell(
//                                                     e['date'] as String?,
//                                                   ),

//                                                   buildProductTypeCell(
//                                                     context: context,
//                                                     productTypes:
//                                                         e['productType']
//                                                             as List<String>?,
//                                                     // as List<
//                                                     //   String
//                                                     // >?, // Now safe because we fixed the API
//                                                     width: 130,
//                                                   ),
//                                                   buildSrNoCell(
//                                                     srNoText:
//                                                         e['srNo']?.toString() ??
//                                                         '',
//                                                     productSrDetails:
//                                                         e['product_sr_details']
//                                                             as List<
//                                                               Map<
//                                                                 String,
//                                                                 dynamic
//                                                               >
//                                                             >?,
//                                                     context: context,
//                                                   ),
//                                                   _dataCell(
//                                                     e['purchaseOrderNo'] ?? '-',
//                                                     140,
//                                                   ),
//                                                   _dataCell(
//                                                     e['siteLocation'] ?? '-',
//                                                     160,
//                                                   ),
//                                                   _dataCell(
//                                                     e['delivered'].toString(),
//                                                     110,
//                                                     color: Colors.red,
//                                                   ),
//                                                   _dataCell(
//                                                     e['received'].toString(),
//                                                     110,
//                                                     color: Colors.green,
//                                                   ),
//                                                   // _receivedDeliveredQty(
//                                                   //   e['delivered'].toString(),
//                                                   //   e['received'].toString(),
//                                                   //   110,
//                                                   // ),
//                                                   _dataCell(
//                                                     balanceQty.toString(),
//                                                     120,
//                                                     color: balanceQty >= 0
//                                                         ? Colors.green
//                                                         : Colors.red,
//                                                     bold: true,
//                                                   ),
//                                                   // _dataCell(
//                                                   //   e['deposite'].toString(),
//                                                   //   color: e['deposite'] <= 0
//                                                   //       ? Colors.red
//                                                   //       : Colors.green,
//                                                   //   140,
//                                                   // ),
//                                                   _depositCell(
//                                                     received:
//                                                         e['deposite']
//                                                             ?.toString() ??
//                                                         '0',
//                                                     returned:
//                                                         e['returnedAmount']
//                                                             ?.toString() ??
//                                                         '0',
//                                                     width: 140,
//                                                   ),
//                                                   _dataCell(
//                                                     depositeBalance.toString(),
//                                                     120,
//                                                     color: depositeBalance <= 0
//                                                         ? Colors.red
//                                                         : Colors.green,
//                                                     bold: true,
//                                                   ),
//                                                   SizedBox(
//                                                     width: 140,
//                                                     child: Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .center,
//                                                       children: [
//                                                         IconButton(
//                                                           onPressed: () {
//                                                             PassbookApi()
//                                                                 .showSingleChallanPassbookPdf(
//                                                                   context:
//                                                                       context,
//                                                                   challanNumber:
//                                                                       e['challanNumber'],
//                                                                 );
//                                                           },
//                                                           icon: Image.asset(
//                                                             "assets/images/passbook.png",
//                                                             width: 26,
//                                                           ),
//                                                           tooltip:
//                                                               'View Challan',
//                                                         ),
//                                                         // IconButton(
//                                                         //   onPressed: () {
//                                                         //     PassbookApi()
//                                                         //         .shareSingleChallanPassbookPdf(
//                                                         //           context:
//                                                         //               context,
//                                                         //           challanNumber:
//                                                         //               e['challanNumber'],
//                                                         //         );
//                                                         //   },
//                                                         //   icon: const Icon(
//                                                         //     Icons.share,
//                                                         //     color: Colors.blue,
//                                                         //   ),
//                                                         //   tooltip: 'Share',
//                                                         // ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),

//                 // Pagination
//                 Container(
//                   color: const Color(0xFFB3E0F2),
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back_ios, size: 18),
//                         onPressed: _currentPage > 0
//                             ? () {
//                                 _loadPassbook(page: _currentPage - 1);
//                               }
//                             : null,
//                       ),
//                       Text(
//                         'Page ${_currentPage + 1} of $_totalPages',
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.arrow_forward_ios, size: 18),
//                         onPressed: _currentPage < _totalPages - 1
//                             ? () {
//                                 _loadPassbook(page: _currentPage + 1);
//                               }
//                             : null,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             if (_isLoading) customLoader(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _depositCell({
//     required String received,
//     required String returned,
//     required double width,
//   }) {
//     final double rec =
//         double.tryParse(received.replaceAll('₹', '').trim()) ?? 0.0;
//     final double ret =
//         double.tryParse(returned.replaceAll('₹', '').trim()) ?? 0.0;

//     return SizedBox(
//       width: width,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // if (rec > 0)
//           Text(
//             "₹${rec.toStringAsFixed(0)}",
//             style: TextStyle(
//               color: rec >= 0 ? Colors.green : Colors.red,
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//           Divider(
//             color: Colors.grey.shade400,
//             height: 8,
//             thickness: 1,
//             indent: 20,
//             endIndent: 20,
//           ),
//           // if (ret > 0)
//           Text(
//             " ₹${ret.toStringAsFixed(0)}",
//             style: TextStyle(
//               color: ret >= 0 ? Colors.green : Colors.red,
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//           if (rec == 0 && ret == 0)
//             const Text("-", style: TextStyle(color: Colors.grey)),
//         ],
//       ),
//     );
//   }

//   List<String> _parseChallanList(dynamic data) {
//     if (data == null) return [];
//     if (data is List) {
//       return data
//           .where((e) => e != null)
//           .map((e) => e.toString().trim())
//           .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
//           .toList();
//     }
//     if (data is String) {
//       if (data.trim().isEmpty || data.toLowerCase() == 'null') return [];
//       return data
//           .split(RegExp(r'[,]')) // split by comma, newline, or semicolon
//           .map((e) => e.trim())
//           .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
//           .toList();
//     }
//     log("data: $data");
//     return [];
//   }

//   Widget _headerCell(String text, double width) => SizedBox(
//     width: width,
//     child: Center(
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 14,
//         ),
//       ),
//     ),
//   );

//   Widget _dataCell(
//     String text,
//     double width, {
//     Color? color,
//     bool bold = false,
//   }) => SizedBox(
//     width: width,
//     child: Center(
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color ?? Colors.black87,
//           fontWeight: bold ? FontWeight.bold : FontWeight.w500,
//           fontSize: 14,
//         ),
//       ),
//     ),
//   );

//   // Widget _receivedDeliveredQty(
//   //   String delivered,
//   //   String received,
//   //   double width, {
//   //   bool bold = false,
//   // }) => SizedBox(
//   //   width: width,
//   //   child: Column(
//   //     mainAxisAlignment: MainAxisAlignment.center,
//   //     children: [
//   //       Text(
//   //         "+ ${received.isEmpty ? '' : received}",
//   //         style: TextStyle(
//   //           color: Colors.green,
//   //           fontWeight: bold ? FontWeight.bold : FontWeight.w600,
//   //           fontSize: 14,
//   //         ),
//   //       ),
//   //       Divider(
//   //         color: Colors.grey.shade400,
//   //         height: 8,
//   //         thickness: 1,
//   //         indent: 20,
//   //         endIndent: 20,
//   //       ),

//   //       Text(
//   //         "- $delivered",
//   //         style: TextStyle(
//   //           color: Colors.red,
//   //           fontWeight: bold ? FontWeight.bold : FontWeight.w600,
//   //           fontSize: 14,
//   //         ),
//   //       ),
//   //     ],
//   //   ),
//   // );

//   Widget buildProductTypeCell({
//     required BuildContext context,
//     required List<String>? productTypes,
//     required double width,
//   }) {
//     if (productTypes == null || productTypes.isEmpty) {
//       return _dataCell('-', width);
//     }

//     if (productTypes.length <= 2) {
//       return _dataCell(productTypes.join('\n'), width, bold: true);
//     }
//     final List<String> items = productTypes.take(2).toList();
//     final bool hasMore = productTypes.length > items.length;

//     return SizedBox(
//       width: width,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             items.join('\n'),
//             // productTypes.take(2).join('\n'),
//             style: const TextStyle(fontWeight: FontWeight.bold, height: 1.4),
//           ),
//           if (hasMore)
//             GestureDetector(
//               onTap: () => _showProductTypesDialog(context, productTypes),
//               child: Text(
//                 "+${productTypes.length - 2} more",
//                 style: TextStyle(
//                   color: productTypes.isNotEmpty
//                       ? AppColors.accentBlue
//                       : Colors.grey,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 11,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _showProductTypesDialog(BuildContext context, List<String> types) {
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 children: const [
//                   Icon(Icons.inventory_2, color: Colors.cyan, size: 28),
//                   SizedBox(width: 10),
//                   Text(
//                     "Product Types",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//               const Divider(height: 30),

//               Flexible(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: types
//                         .map(
//                           (t) => Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 4),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 36,
//                                   height: 36,
//                                   decoration: BoxDecoration(
//                                     color: Colors.cyan.withOpacity(0.2),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: Center(
//                                     child: Text(
//                                       // "$index",
//                                       '',
//                                       style: const TextStyle(
//                                         color: Colors.cyan,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 14),
//                                 Text(
//                                   "$t",
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         )
//                         .toList(),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Close Button
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton.icon(
//                   onPressed: () => Navigator.pop(ctx),
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   label: const Text(
//                     "Close",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   style: TextButton.styleFrom(
//                     backgroundColor: Colors.red.shade600,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 10,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//   // Widget buildProductTypeCell({
//   //   required BuildContext context,
//   //   required List<Map>? productTypes, // nullable
//   //   double width = 130,
//   // }) {
//   //   final List<Map> details = productTypes ?? [];

//   //   // extract product type names (adjust key if needed)
//   //   final List<String> parts = details
//   //       .map((e) => (e['productType'] ?? '').toString().trim())
//   //       .where((e) => e.isNotEmpty)
//   //       .toList();

//   //   if (parts.isEmpty) {
//   //     return _dataCell('-', width);
//   //   }

//   //   if (parts.length <= 2) {
//   //     return _dataCell(parts.join('\n'), width, bold: true);
//   //   }

//   //   return SizedBox(
//   //     width: width,
//   //     child: Column(
//   //       mainAxisAlignment: MainAxisAlignment.center,
//   //       children: [
//   //         Text(
//   //           parts.take(2).join('\n'),
//   //           style: const TextStyle(fontWeight: FontWeight.bold, height: 1.4),
//   //           textAlign: TextAlign.center,
//   //         ),
//   //         const SizedBox(height: 4),
//   //         GestureDetector(
//   //           onTap: () {
//   //             _showAllProductTypesDialog(context, parts);
//   //           },
//   //           child: Text(
//   //             "+${parts.length - 2} more",
//   //             style: TextStyle(
//   //               color: AppColors.accentBlue,
//   //               fontWeight: FontWeight.bold,
//   //               fontSize: 11,
//   //             ),
//   //           ),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   void _showAllProductTypesDialog(
//     BuildContext context,
//     List<String> productTypes,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Product Types"),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: productTypes.length,
//             itemBuilder: (context, index) => Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Text(
//                 "${index + 1}. ${productTypes[index]}",
//                 style: const TextStyle(fontSize: 14),
//               ),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Close"),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildSrNoCell({
//     required String srNoText,
//     required BuildContext context,
//     double width = 130,
//     List<Map<String, dynamic>>? productSrDetails, // Now nullable
//   }) {
//     final List<Map<String, dynamic>> details = productSrDetails ?? [];

//     final parts = srNoText
//         .split('/')
//         .map((e) => e.trim())
//         .where((e) => e.isNotEmpty)
//         .toList();

//     if (parts.isEmpty) {
//       return _dataCell('-', width);
//     }

//     if (parts.length <= 2) {
//       return _dataCell(parts.join('\n'), width, bold: true);
//     }

//     return SizedBox(
//       width: width,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             parts.take(2).join('\n'),
//             style: const TextStyle(fontWeight: FontWeight.bold, height: 1.4),
//           ),
//           const SizedBox(height: 4),
//           GestureDetector(
//             onTap: () {
//               if (details.isNotEmpty) {
//                 _showAllSrNumbersDialog(context, details);
//               }
//             },
//             child: Text(
//               "+${parts.length - 2} more",
//               style: TextStyle(
//                 color: details.isNotEmpty ? AppColors.accentBlue : Colors.grey,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 11,
//                 // decoration: details.isEmpty ? TextDecoration.lineThrough : null,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildReceivedChallansCell({
//     required List<String> receivedchallanList,
//     required BuildContext context,
//     double width = 170,
//   }) {
//     if (receivedchallanList.isEmpty ||
//         receivedchallanList.every(
//           (e) => e.trim().isEmpty || e.toLowerCase() == 'null',
//         )) {
//       return _dataCell('-', width);
//     }

//     final visibleItems = receivedchallanList.take(2).toList();
//     final hasMore = receivedchallanList.length > 2;

//     return SizedBox(
//       width: width,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           ...visibleItems.map(
//             (challan) => Text(
//               challan.trim(),
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13.5,
//                 height: 1.3,
//                 color: Colors.black87,
//               ),
//               overflow: TextOverflow.ellipsis,
//               maxLines: 1,
//             ),
//           ),

//           if (hasMore)
//             GestureDetector(
//               onTap: () =>
//                   _showReceivedChallansDialog(context, receivedchallanList),
//               child: MouseRegion(
//                 cursor: SystemMouseCursors.click,
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 6),
//                   child: Text(
//                     "+${receivedchallanList.length - 2} more",
//                     style: TextStyle(
//                       color: AppColors.accentBlue,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 11.5,
//                       decoration: TextDecoration.underline,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _showReceivedChallansDialog(
//     BuildContext context,
//     List<String> challanNumbers,
//   ) {
//     final cleanList = challanNumbers
//         .map((e) => e.toString().trim())
//         .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
//         .toList();

//     if (cleanList.isEmpty) {
//       return;
//     }

//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (ctx) => Dialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.all(15),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Title - Specific for Received Challans
//               Row(
//                 children: [
//                   Icon(
//                     Icons.receipt_long,
//                     color: Colors.cyan.shade700,
//                     size: 28,
//                   ),
//                   const SizedBox(width: 5),
//                   Text(
//                     "All Received Challans",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.cyan.shade800,
//                     ),
//                   ),
//                 ],
//               ),
//               const Divider(height: 30),

//               // Scrollable List
//               ConstrainedBox(
//                 constraints: const BoxConstraints(maxHeight: 400),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: cleanList.asMap().entries.map((entry) {
//                       final index = entry.key + 1;
//                       final challan = entry.value;
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 7),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 34,
//                               height: 34,
//                               decoration: BoxDecoration(
//                                 color: Colors.cyan.withOpacity(0.15),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   "$index",
//                                   style: TextStyle(
//                                     color: Colors.cyan.shade700,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 14),
//                             Expanded(
//                               child: SelectableText(
//                                 challan,
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Close Button
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: ElevatedButton.icon(
//                   onPressed: () => Navigator.pop(ctx),
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   label: const Text(
//                     "Close",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red.shade600,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 12,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showAllSrNumbersDialog(
//     BuildContext context,
//     List<Map<String, dynamic>> productSrDetails,
//   ) {
//     log("show details: $productSrDetails");
//     if (productSrDetails.isEmpty) return;

//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (ctx) => Dialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Title
//               Row(
//                 children: const [
//                   Icon(Icons.inventory_2, color: Colors.cyan, size: 28),
//                   SizedBox(width: 10),
//                   Text(
//                     "SR Numbers",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//               const Divider(height: 30),

//               // Scrollable List
//               Flexible(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: productSrDetails.asMap().entries.map((entry) {
//                       final index = entry.key + 1;
//                       final product = entry.value;
//                       final String productName =
//                           product['productName'] ?? 'Unknown';
//                       final String srJoined = product['srNoJoined'] ?? '';

//                       return Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Circle Number
//                             Container(
//                               width: 36,
//                               height: 36,
//                               decoration: BoxDecoration(
//                                 color: Colors.cyan.withOpacity(0.2),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   "$index",
//                                   style: const TextStyle(
//                                     color: Colors.cyan,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 14),

//                             // Product Name + SR Nos
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     productName,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   SelectableText(
//                                     srJoined.isEmpty ? "-" : srJoined,
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: srJoined.isEmpty
//                                           ? Colors.grey
//                                           : Colors.black54,
//                                       fontStyle: srJoined.isEmpty
//                                           ? FontStyle.italic
//                                           : FontStyle.normal,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Close Button
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton.icon(
//                   onPressed: () => Navigator.pop(ctx),
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   label: const Text(
//                     "Close",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   style: TextButton.styleFrom(
//                     backgroundColor: Colors.red.shade600,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 10,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchField({
//     required String label,
//     required String hint,
//     required IconData icon,
//     required String value,
//     required ValueChanged<String> onChanged,
//     TextEditingController? controller,
//   }) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.inter(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 6),
//         TextField(
//           controller: controller,
//           onChanged: onChanged,
//           cursorColor: AppColors.accentBlue,
//           decoration: InputDecoration(
//             prefixIcon: Icon(icon, color: Colors.grey.shade600),
//             hintText: hint,
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(
//               vertical: 18,
//               horizontal: 16,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide(color: AppColors.accentBlue, width: 2.5),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.inter(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 6),
//         SizedBox(
//           height: 55,
//           child: ElevatedButton.icon(
//             onPressed: onTap,
//             icon: const Icon(Icons.calendar_today_rounded, size: 18),
//             label: Text(
//               date == null ? label : DateFormat('dd MMM yyyy').format(date),
//               style: const TextStyle(fontSize: 14),
//               overflow: TextOverflow.ellipsis,
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: date != null
//                   ? AppColors.accentBlue
//                   : Colors.grey.shade200,
//               foregroundColor: date != null ? Colors.white : Colors.black87,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               elevation: 4,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTotalRecordsBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.blue.shade700, Colors.blue.shade900],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.format_list_numbered, color: Colors.white, size: 22),
//           const SizedBox(width: 6),
//           Text(
//             "$_totalElements Records",
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductDropdown({
//     required GoodsDTO? selectedGoods,
//     required List<GoodsDTO> goods,
//     required ValueChanged<GoodsDTO?> onChanged,
//   }) {
//     return Column(
//       // mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Product Filter",
//           style: GoogleFonts.inter(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 6),
//         DropdownButtonFormField<GoodsDTO?>(
//           value: selectedGoods,
//           hint: const Text("All Products"),
//           isExpanded: true,
//           dropdownColor: Colors.white,
//           icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentBlue),
//           decoration: InputDecoration(
//             prefixIcon: const Icon(
//               Icons.inventory_2,
//               color: AppColors.accentBlue,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(
//                 color: AppColors.accentBlue,
//                 width: 2,
//               ),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 18,
//             ),
//           ),
//           items: [
//             const DropdownMenuItem<GoodsDTO?>(
//               value: null,
//               child: Text("All Products"),
//             ),
//             ...goods.map(
//               (g) => DropdownMenuItem<GoodsDTO?>(
//                 value: g,
//                 child: Text(g.name, overflow: TextOverflow.ellipsis),
//               ),
//             ),
//           ],
//           onChanged: onChanged,
//           // onChanged: (GoodsDTO? newValue) {
//           //   setState(() {
//           //     selectedGoods = newValue;
//           //   });
//           //   _loadPassbook(page: 0);
//           // },
//         ),
//       ],
//     );
//   }

//   Widget _buildExportDropdown() {
//     return PopupMenuButton<String>(
//       onSelected: (value) async {
//         if (value == 'current_or_all') {
//           _showExportOptionsDialog();
//         } else if (value == 'customize') {
//           _showCustomizeExportDialog();
//         }
//       },
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       offset: const Offset(0, 55),
//       elevation: 12,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.green.shade600, Colors.green.shade800],
//           ),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.green.withOpacity(0.5),
//               blurRadius: 12,
//               offset: const Offset(0, 6),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: const [
//             Icon(Icons.download_rounded, color: Colors.white, size: 24),
//             SizedBox(width: 6),
//             Text(
//               "Export",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//               ),
//             ),
//             SizedBox(width: 6),
//             Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
//           ],
//         ),
//       ),
//       itemBuilder: (context) => [
//         PopupMenuItem(
//           value: 'current_or_all',
//           child: Row(
//             children: [
//               Icon(Icons.speed, color: Colors.green.shade700),
//               const SizedBox(width: 12),
//               const Text("Quick Export (Current / All)"),
//             ],
//           ),
//         ),

//         const PopupMenuDivider(),

//         PopupMenuItem(
//           value: 'customize',
//           child: Row(
//             children: [
//               Icon(Icons.tune, color: Colors.blue.shade700),
//               const SizedBox(width: 12),
//               const Text("Customize Export (Date Range)"),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   void _showExportOptionsDialog() {
//     String selectedScope = 'current'; // current or all
//     String selectedFormat = 'pdf'; // pdf or excel

//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (_) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return Padding(
//               padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Title
//                   Row(
//                     children: const [
//                       Icon(
//                         Icons.file_download_outlined,
//                         color: Colors.green,
//                         size: 28,
//                       ),
//                       SizedBox(width: 12),
//                       Text(
//                         "Export Passbook",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),

//                   // Scope
//                   const Text(
//                     "Export Scope",
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: FilterChip(
//                           label: const Text("Current Page"),
//                           selected: selectedScope == 'current',
//                           onSelected: (_) =>
//                               setStateDialog(() => selectedScope = 'current'),
//                           selectedColor: Colors.blue.shade100,
//                         ),
//                       ),
//                       const SizedBox(width: 7),
//                       Expanded(
//                         child: FilterChip(
//                           label: const Text("Complete Passbook"),
//                           selected: selectedScope == 'all',
//                           onSelected: (_) =>
//                               setStateDialog(() => selectedScope = 'all'),
//                           selectedColor: Colors.green.shade100,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),

//                   const Text(
//                     "Export Format",
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       // PDF Chip
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () =>
//                               setStateDialog(() => selectedFormat = 'pdf'),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             decoration: BoxDecoration(
//                               color: selectedFormat == 'pdf'
//                                   ? Colors.blue.shade600
//                                   : Colors.grey.shade200,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Image.asset(
//                                   "assets/images/sheet.png",
//                                   height: 22,
//                                   width: 22,
//                                   fit: BoxFit.contain,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   "PDF",
//                                   style: TextStyle(
//                                     color: selectedFormat == 'pdf'
//                                         ? Colors.white
//                                         : Colors.black87,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(width: 12),

//                       // Excel Chip
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () =>
//                               setStateDialog(() => selectedFormat = 'excel'),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             decoration: BoxDecoration(
//                               color: selectedFormat == 'excel'
//                                   ? Colors.green.shade600
//                                   : Colors.grey.shade200,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Image.asset(
//                                   "assets/images/excel.png",
//                                   height: 22,
//                                   width: 22,
//                                   fit: BoxFit.contain,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   "Excel",
//                                   style: TextStyle(
//                                     color: selectedFormat == 'excel'
//                                         ? Colors.white
//                                         : Colors.black87,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 28),

//                   // Buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text(
//                           "Cancel",
//                           style: GoogleFonts.inter(color: Colors.red),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.pop(context);

//                           if (selectedFormat == 'pdf') {
//                             if (selectedScope == 'current') {
//                               PassbookApi().showCurrentPDF(context: context);

//                               log("$selectedScope");
//                             } else {
//                               PassbookApi().showAllPDF(context: context);
//                             }
//                           } else {
//                             // Excel
//                             if (selectedScope == 'current') {
//                               // exportCurrentPageToExcel(_paginatedEntries);
//                             } else {
//                               PassbookApi().exportToExcel(
//                                 isAll: true,
//                                 context: context,
//                               );
//                             }
//                           }
//                         },
//                         icon: const Icon(Icons.download_rounded, size: 18),
//                         label: Text(
//                           "Export Now",
//                           style: GoogleFonts.inter(color: Colors.white),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green.shade600,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   void _showCustomizeExportDialog() {
//     DateTime? fromDate = _fromDate;
//     DateTime? toDate = _toDate;
//     String selectedFormat = 'pdf'; // Default to PDF

//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setStateDialog) => Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Title
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.filter_list_alt,
//                       color: Colors.green.shade700,
//                       size: 28,
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       "Customize Export",
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green.shade800,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 // From Date
//                 Text(
//                   "From Date",
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     final picked = await showDatePicker(
//                       context: context,
//                       initialDate: fromDate ?? DateTime.now(),
//                       firstDate: DateTime(2005),
//                       lastDate: DateTime.now(),
//                       builder: (context, child) {
//                         return Theme(
//                           data: Theme.of(context).copyWith(
//                             colorScheme: ColorScheme.light(
//                               primary: AppColors
//                                   .accentBlue, // Header background & selected day
//                               onPrimary: Colors
//                                   .white, //  Text on header & selected day
//                               surface: Colors.white, //Calendar background
//                               onSurface: Colors.black87, //Normal text
//                             ),
//                             textButtonTheme: TextButtonThemeData(
//                               style: TextButton.styleFrom(
//                                 foregroundColor:
//                                     AppColors.accentBlue, // OK / Cancel buttons
//                                 textStyle: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             dialogBackgroundColor: Colors.white,
//                           ),
//                           child: child!,
//                         );
//                       },
//                     );
//                     if (picked != null) {
//                       setStateDialog(() => fromDate = picked);
//                     }
//                   },
//                   icon: const Icon(Icons.calendar_today),
//                   label: Text(
//                     fromDate == null
//                         ? "Select From Date"
//                         : DateFormat('dd MMM yyyy').format(fromDate!),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: fromDate != null
//                         ? AppColors.accentBlue
//                         : Colors.grey.shade300,
//                     foregroundColor: fromDate != null
//                         ? Colors.white
//                         : AppColors.accentBlue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     minimumSize: const Size(double.infinity, 50),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // To Date
//                 Text("To Date", style: TextStyle(fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 8),
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     final picked = await showDatePicker(
//                       context: context,
//                       initialDate: toDate ?? DateTime.now(),
//                       firstDate: fromDate ?? DateTime(2005),
//                       lastDate: DateTime.now(),
//                       builder: (context, child) {
//                         return Theme(
//                           data: Theme.of(context).copyWith(
//                             colorScheme: ColorScheme.light(
//                               primary: AppColors
//                                   .accentBlue, // Header background & selected day
//                               onPrimary: Colors
//                                   .white, //  Text on header & selected day
//                               surface: Colors.white, //Calendar background
//                               onSurface: Colors.black87, //Normal text
//                             ),
//                             textButtonTheme: TextButtonThemeData(
//                               style: TextButton.styleFrom(
//                                 foregroundColor:
//                                     AppColors.accentBlue, // OK / Cancel buttons
//                                 textStyle: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             dialogBackgroundColor: Colors.white,
//                           ),
//                           child: child!,
//                         );
//                       },
//                     );
//                     if (picked != null) {
//                       setStateDialog(() => toDate = picked);
//                     }
//                   },
//                   icon: const Icon(Icons.calendar_today),
//                   label: Text(
//                     toDate == null
//                         ? "Select To Date"
//                         : DateFormat('dd MMM yyyy').format(toDate!),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: toDate != null
//                         ? AppColors.accentBlue
//                         : Colors.grey.shade300,
//                     foregroundColor: toDate != null
//                         ? Colors.white
//                         : AppColors.accentBlue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     minimumSize: const Size(double.infinity, 50),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Format Selector
//                 Text(
//                   "Export Format",
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 DropdownButtonFormField<String>(
//                   value: selectedFormat,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 7,
//                       vertical: 16,
//                     ),
//                   ),
//                   items: [
//                     DropdownMenuItem(
//                       value: 'pdf',
//                       child: Row(
//                         children: [
//                           Image.asset("assets/images/sheet.png", height: 24),
//                           const SizedBox(width: 7),
//                           const Text("PDF Document"),
//                         ],
//                       ),
//                     ),
//                     DropdownMenuItem(
//                       value: 'excel',
//                       child: Row(
//                         children: [
//                           Image.asset("assets/images/excel.png", height: 24),
//                           const SizedBox(width: 7),
//                           const Text("Excel Spreadsheet"),
//                         ],
//                       ),
//                     ),
//                   ],
//                   onChanged: (val) =>
//                       setStateDialog(() => selectedFormat = val!),
//                 ),
//                 const SizedBox(height: 30),

//                 // Action Buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(ctx),
//                       child: const Text(
//                         "Cancel",
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     ElevatedButton.icon(
//                       onPressed: fromDate == null || toDate == null
//                           ? null
//                           : () {
//                               Navigator.pop(ctx);
//                               if (selectedFormat == 'pdf') {
//                                 PassbookApi().showAllPDF(
//                                   context: context,
//                                   fromDate: fromDate.toString(),
//                                   toDate: toDate.toString(),
//                                 );
//                                 log(" fromDate: $fromDate");
//                                 log("To Date: $toDate");
//                               } else {
//                                 PassbookApi().exportToExcel(
//                                   context: context,
//                                   fromDate: fromDate,
//                                   toDate: toDate,
//                                 );
//                               }
//                             },
//                       icon: const Icon(Icons.download_rounded),
//                       label: const Text("Export"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green.shade600,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 24,
//                           vertical: 16,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }


// }
