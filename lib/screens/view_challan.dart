import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/challan_screen.dart';
import 'package:snow_trading_cool/screens/home_screen.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:intl/intl.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import 'package:universal_platform/universal_platform.dart';

class ViewChallanScreen extends StatefulWidget {
  final String? type;
  const ViewChallanScreen({super.key, this.type});

  @override
  State<ViewChallanScreen> createState() => _ViewChallanScreenState();
}

// SAFE TYPE HELPER — NOW USED EVERYWHERE
String safeChallanType(Map<String, dynamic> row) {
  final type = row['challanType'] ?? row['type'];
  if (type == null) return 'UNKNOWN';
  return type.toString().trim().toUpperCase();
}

class _ViewChallanScreenState extends State<ViewChallanScreen> {
  bool _selectionMode = false;
  bool _isLoading = false;

  int _totalPages = 1;
  final isDesktop = UniversalPlatform.isDesktop;

  final ChallanApi challanApi = ChallanApi();
  List<Map<String, dynamic>> _challans = [];
  List<Map<String, dynamic>> _filteredData = [];

  String _searchQuery = '';
  String _selectedType = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  List<String> _selectedIds = [];
  int _currentPage = 0;
  final int _rowsPerPage = 8;

  String? challanCreateType;
  bool challanCreateSelected = true;

  // SAFE DATE PARSING FUNCTION — PREVENTS CRASH
  DateTime? _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'null') return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _paginatedCustomers => _filteredData;

  //  late String typeStr = safeChallanType(_paginatedCustomers[]['type']);
  // late bool isReceived = typeStr == 'RECEIVED';

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.accentBlue, // Header background & selected day
              onPrimary: Colors.white, //  Text on header & selected day
              surface: Colors.white, //Calendar background
              onSurface: Colors.black87, //Normal text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentBlue, // OK / Cancel buttons
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
      _applyAllFilters();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime.now(),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.accentBlue, // Header background & selected day
              onPrimary: Colors.white, //  Text on header & selected day
              surface: Colors.white, //Calendar background
              onSurface: Colors.black87, //Normal text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentBlue, // OK / Cancel buttons
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _applyAllFilters();
    }
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

  // === ALL FILTER LOGIC IN ONE PLACE ===
  void _applyAllFilters() {
    setState(() {
      _currentPage = 0;
    });
    _fetchChallans();
  }

  Future<void> _showUserGoodsDetails(int challanId) async {
    if (challanId <= 0) {
      showErrorToast(context, "Invalid challan ID");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: SizedBox(width: 60, height: 60, child: customLoader())),
    );

    final challan = await challanApi.getChallan(challanId, context);
    if (mounted) Navigator.of(context).pop();

    if (challan == null) {
      showErrorToast(context, "Failed to load challan details");
      return;
    }

    if (!mounted) return;

    final items =
        (challan['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final String typeStr = safeChallanType(challan);
    final bool isReceived = typeStr == 'RECEIVED';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.receipt_long,
              color: Color.fromRGBO(0, 140, 192, 1),
            ),
            const SizedBox(width: 8),
            Text(
              "Goods Details",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Items",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isReceived)
                      Expanded(
                        child: Center(
                          child: Text(
                            "Received Qty",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    if (!isReceived)
                      Expanded(
                        child: Center(
                          child: Text(
                            "Delivered Qty",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Text(
                    "No items found",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ...items.map(
                  (item) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (isReceived)
                          Expanded(
                            child: Center(
                              child: Text(
                                "${item['receivedQty'] ?? 0}",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (!isReceived)
                          Expanded(
                            child: Center(
                              child: Text(
                                "${item['deliveredQty'] ?? 0}",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChallan(int challanId, String challanType) async {
  // Show confirmation dialog directly
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete Challan'),
      content: Text(
        'Permanently delete this ${challanType.toUpperCase()} challan?\n'
        // '${challanType.toUpperCase() == 'RECEIVED' 
        //     ? '(Will update parent stock)' 
        //     : '(All return challans will also be deleted)'}\n\n'
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  // If user didn't confirm, exit
  if (confirmed != true) return;

  // Show loading state
  setState(() => _isLoading = true);

  // Perform deletion
  final success = await challanApi.deleteChallanSmart(challanId, challanType);

  // Hide loading
  setState(() => _isLoading = false);

  if (success) {
    showSuccessToast(context, "$challanType challan deleted successfully");
    await _fetchChallans();
  } else {
    showErrorToast(context, "Failed to delete challan. Try again.");
  }
}

  // Future<void> _deleteChallan(int challanId, String challanType) async {
  //   final action = await showDialog<String>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('Delete Challan'),
  //       content: Text(
  //         challanType.toUpperCase() == 'RECEIVED'
  //             ? 'Delete this RECEIVED challan?\n(Will update parent stock)'
  //             : 'Delete this DELIVERED challan?\n(All return challans will also be deleted)',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, 'multiple'),
  //           child: Text(
  //             'Delete Multiple',
  //             style: GoogleFonts.inter(
  //               color: Colors.red,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, 'single'),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: Text(
  //             'Delete This',
  //             style: GoogleFonts.inter(color: Colors.white),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (action == 'multiple') {
  //     setState(() {
  //       _selectionMode = true;
  //       final idStr = challanId.toString();
  //       if (!_selectedIds.contains(idStr)) _selectedIds.add(idStr);
  //     });
  //     return;
  //   }

  //   if (action != 'single') return;

  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('Confirm Delete'),
  //       content: Text(
  //         'Permanently delete this ${challanType.toUpperCase()} challan?\nThis action cannot be undone.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('Delete', style: TextStyle(color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirmed != true) return;

  //   setState(() => _isLoading = true);

  //   final success = await challanApi.deleteChallanSmart(challanId, challanType);

  //   setState(() => _isLoading = false);

  //   if (success) {
  //     showSuccessToast(context, "$challanType challan deleted successfully");
  //     await _fetchChallans();
  //   } else {
  //     showErrorToast(context, "Failed to delete challan. Try again.");
  //   }
  // }

  // Future<void> _deleteMultipleChallans() async {
  //   if (_selectedIds.isEmpty) return;

  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('Delete Multiple Challans'),
  //       content: Text(
  //         'Are you sure you want to delete ${_selectedIds.length} selected challans?',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: Text(
  //             'Delete',
  //             style: GoogleFonts.inter(color: Colors.white),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirmed != true) return;

  //   setState(() => _isLoading = true);

  //   final List<int> idsToDelete = _selectedIds
  //       .map((id) => int.tryParse(id))
  //       .where((id) => id != null)
  //       .cast<int>()
  //       .toList();
  //   final success = await challanApi.deleteMultipleChallans(
  //     idsToDelete,
  //     context,
  //   );

  //   setState(() {
  //     _isLoading = false;
  //     _selectedIds.clear();
  //     _selectionMode = false;
  //   });

  //   await _fetchChallans();
  //   if (success) {
  //     showSuccessToast(context, "All selected challans deleted successfully");
  //   } else {
  //     showErrorToast(context, "Failed to delete some or all challans");
  //   }
  // }

  Future<void> _editChallan(Map<String, dynamic> challanRow) async {
    if (challanRow['id'] == null) {
      showErrorToast(context, "Invalid challan data");
      return;
    }

    final String typeStr = safeChallanType(challanRow);
    final bool isReceived = typeStr == 'RECEIVED';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallanScreen(
          challanData: challanRow,
          mode: isReceived ? ChallanMode.received : ChallanMode.delivered,
        ),
      ),
    ).then((_) => _fetchChallans());
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _selectedType != 'All' ||
        _fromDate != null ||
        _toDate != null;
  }

  @override
  void initState() {
    super.initState();

    // Set initial type from navigation
    if (widget.type != null) {
      final normalized = widget.type!.toLowerCase();
      if (normalized == 'received') {
        _selectedType = 'Received';
      } else if (normalized == 'delivered') {
        _selectedType = 'Delivered';
      } else if (normalized == 'all') {
        _selectedType = 'All';
      }
    }

    _loadUserRole();
    _fetchChallans();
  }

  String _userRole = 'Employee';

  void _loadUserRole() {
    final savedRole = TokenManager().getRole();
    _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
    setState(() {});
  }

  Future<void> _fetchChallans() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> result;

      final bool hasSearch = _searchQuery.trim().isNotEmpty;
      final bool hasDates = _fromDate != null || _toDate != null;
      final String selectedTypeUpper = _selectedType.toUpperCase();
      final String? challanTypeParam = _selectedType == 'All'
          ? null
          : selectedTypeUpper;
      final String? fromDateStr = _fromDate != null
          ? DateFormat('yyyy-MM-dd').format(_fromDate!)
          : null;
      final String? toDateStr = _toDate != null
          ? DateFormat('yyyy-MM-dd').format(_toDate!)
          : null;

      Map<String, dynamic>? response;

      // CASE 1: User is searching (name/mobile/email)
      if (hasSearch) {
        // Use the new smart search API with all filters
        response = await challanApi.searchChallans(
          query: _searchQuery.trim(),
          challanType: challanTypeParam,
          fromDate: fromDateStr,
          toDate: toDateStr,
          page: _currentPage,
          size: _rowsPerPage,
        );
      }
      // CASE 2: No search, but has type filter only → use optimized endpoints
      else if (!hasDates && _selectedType != 'All') {
        if (_selectedType == 'Delivered') {
          response = await challanApi.fetchDeliveredChallansPage(
            page: _currentPage,
            size: _rowsPerPage,
          );
        } else if (_selectedType == 'Received') {
          response = await challanApi.fetchReceivedChallansPage(
            page: _currentPage,
            size: _rowsPerPage,
          );
        }
      }
      // CASE 3: Any other case (dates, mixed filters, or no filters) → use full search API
      else {
        response = await challanApi.searchChallans(
          query: null, // no text search
          challanType: challanTypeParam,
          fromDate: fromDateStr,
          toDate: toDateStr,
          page: _currentPage,
          size: _rowsPerPage,
        );
      }

      // Parse response (same for all cases)
      final List<dynamic> content = response != null
          ? (response['content'] as List?) ?? []
          : [];

      final int totalPages = response != null
          ? (response['totalPages'] as int?) ?? 1
          : 1;

          result = content.map((item) {
  final itemsList = (item['items'] as List?) ?? [];
  final String challanType = (item['challanType'] ?? '').toString().trim().toLowerCase();

  int totalQty = 0;

  if (challanType == 'received') {
    // Only add receivedQty for RECEIVED challans
    totalQty = itemsList.fold<int>(
      0,
      (sum, i) => sum + ((i['receivedQty'] as num?)?.toInt() ?? 0),
    );
  } else if (challanType == 'delivered') {
    // Only add deliveredQty for DELIVERED challans
    totalQty = itemsList.fold<int>(
      0,
      (sum, i) => sum + ((i['deliveredQty'] as num?)?.toInt() ?? 0),
    );
  } else {
    // Fallback for unknown/other types: add both (original behavior)
    totalQty = itemsList.fold<int>(
      0,
      (sum, i) =>
          sum +
          ((i['deliveredQty'] as num?)?.toInt() ?? 0) +
          ((i['receivedQty'] as num?)?.toInt() ?? 0),
    );
  }

  return {
    'id': item['id'],
    'name': item['customerName'] ?? 'Unknown Customer',
    'challanType': (item['challanType'] ?? '').toString().toUpperCase(),
    'location': item['siteLocation'] ?? '',
    'qty': totalQty,
    'date': item['date'] ?? '',
    'challanNumber': item['challanNumber'] ?? 'CH-${item['id']}',
    'rawData': item,
  };
}).toList();

      // result = content.map((item) {
      //   final itemsList = (item['items'] as List?) ?? [];
      //   final totalQty = itemsList.fold<int>(
      //     0,
      //     (sum, i) =>
      //         sum +
      //         ((i['deliveredQty'] as num?)?.toInt() ?? 0) +
      //         ((i['receivedQty'] as num?)?.toInt() ?? 0),
      //   );

      //   return {
      //     'id': item['id'],
      //     'name': item['customerName'] ?? 'Unknown Customer',
      //     'challanType': (item['challanType'] ?? '').toString().toUpperCase(),
      //     'location': item['siteLocation'] ?? '',
      //     'qty': totalQty,
      //     'date': item['date'] ?? '',
      //     'challanNumber': item['challanNumber'] ?? 'CH-${item['id']}',
      //     'rawData': item,
      //   };
      // }).toList();

      setState(() {
        _challans = result;
        _filteredData = result;
        _totalPages = totalPages;
        _isLoading = false;
      });

      // Show toast only on first page + truly empty
      if (result.isEmpty && _currentPage == 0) {
        final filters = <String>[];
        if (hasSearch) filters.add("Search: '$_searchQuery'");
        if (_selectedType != 'All') filters.add("Type: $_selectedType");
        if (_fromDate != null)
          filters.add("From: ${DateFormat('dd-MM-yyyy').format(_fromDate!)}");
        if (_toDate != null)
          filters.add("To: ${DateFormat('dd-MM-yyyy').format(_toDate!)}");

        final msg = filters.isEmpty
            ? "No challans yet"
            : "No results for: ${filters.join(' | ')}";
        showErrorToast(context, msg);
      }
    } catch (e, s) {
      debugPrint("Error in _fetchChallans: $e\n$s");
      showErrorToast(context, "Failed to load challans");
      setState(() {
        _challans = [];
        _filteredData = [];
        _totalPages = 1;
        _isLoading = false;
      });
    }
  }

  Color _getTypeColor(Map<String, dynamic> row) {
    final String typeStr = safeChallanType(row);
    if (typeStr == 'RECEIVED') return Colors.green;
    if (typeStr == 'DELIVERED') return Colors.orange;
    return Colors.grey;
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_selectedIds.isEmpty && _selectionMode) {
      _selectionMode = false;
    }
  }

  Widget _headerCell({required String text, required double width}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showFiltersBottomSheet() {
  // Local copies initialized with current applied values
  String localSearchQuery = _searchQuery;
  String localSelectedType = _selectedType;
  DateTime? localFromDate = _fromDate;
  DateTime? localToDate = _toDate;

  // Create TextEditingController for search field to persist text
  final TextEditingController searchController = TextEditingController(text: localSearchQuery);

  // Sync controller with local variable
  searchController.addListener(() {
    localSearchQuery = searchController.text.trim();
  });

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateBottomSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      Text(
                        "Advanced Filters",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _hasActiveFilters()
                            ? () {
                                // Clear local
                                setStateBottomSheet(() {
                                  localSearchQuery = '';
                                  localSelectedType = 'All';
                                  localFromDate = null;
                                  localToDate = null;
                                });
                                searchController.clear();

                                // Apply globally
                                setState(() {
                                  _searchQuery = '';
                                  _selectedType = 'All';
                                  _fromDate = null;
                                  _toDate = null;
                                  _currentPage = 0;
                                });

                                Navigator.pop(modalContext);
                                _applyAllFilters();
                              }
                            : null,
                        child: Text(
                          "Reset",
                          style: TextStyle(
                            color: _hasActiveFilters() ? Colors.red.shade600 : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),
                const SizedBox(height: 10,),

                // FILTER FIELDS
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Field
                    Text(
                      "Search by Name, Mobile No. or Email",
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      cursorColor: AppColors.accentBlue,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: AppColors.accentBlue),
                        hintText: "Name / Mobile / Email",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Type Filter
                    Text(
                      "Challan Type",
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: localSelectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text("All Challans")),
                        DropdownMenuItem(value: 'Delivered', child: Text("Delivered")),
                        DropdownMenuItem(value: 'Received', child: Text("Received")),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateBottomSheet(() => localSelectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date Range
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Text(
                    //             "From Date",
                    //             style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    //           ),
                    //           const SizedBox(height: 8),
                    //           ElevatedButton.icon(
                    //             onPressed: () async {
                    //               final picked = await showDatePicker(
                    //                 context: context,
                    //                 initialDate: localFromDate ?? DateTime.now(),
                    //                 firstDate: DateTime(2005),
                    //                 lastDate: DateTime.now(),
                    //                 builder: (context, child) => Theme(
                    //                   data: Theme.of(context).copyWith(
                    //                     colorScheme: const ColorScheme.light(
                    //                       primary: AppColors.accentBlue,
                    //                       onPrimary: Colors.white,
                    //                     ),
                    //                   ),
                    //                   child: child!,
                    //                 ),
                    //               );
                    //               if (picked != null) {
                    //                 setStateBottomSheet(() => localFromDate = picked);
                    //               }
                    //             },
                    //             icon: const Icon(Icons.calendar_today, size: 18),
                    //             label: Text(
                    //               localFromDate == null
                    //                   ? "Select"
                    //                   : DateFormat('dd MMM yyyy').format(localFromDate!),
                    //               style: GoogleFonts.inter(fontSize: 14),
                    //             ),
                    //             style: ElevatedButton.styleFrom(
                    //               backgroundColor: AppColors.accentBlue,
                    //               foregroundColor: Colors.white,
                    //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //               padding: const EdgeInsets.symmetric(vertical: 16),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //     const SizedBox(width: 16),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Text(
                    //             "To Date",
                    //             style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    //           ),
                    //           const SizedBox(height: 8),
                    //           ElevatedButton.icon(
                    //             onPressed: () async {
                    //               final picked = await showDatePicker(
                    //                 context: context,
                    //                 initialDate: localToDate ?? DateTime.now(),
                    //                 firstDate: localFromDate ?? DateTime(2005),
                    //                 lastDate: DateTime.now(),
                    //                 builder: (context, child) => Theme(
                    //                   data: Theme.of(context).copyWith(
                    //                     colorScheme: const ColorScheme.light(
                    //                       primary: AppColors.accentBlue,
                    //                       onPrimary: Colors.white,
                    //                     ),
                    //                   ),
                    //                   child: child!,
                    //                 ),
                    //               );
                    //               if (picked != null) {
                    //                 setStateBottomSheet(() => localToDate = picked);
                    //               }
                    //             },
                    //             icon: const Icon(Icons.calendar_today, size: 18),
                    //             label: Text(
                    //               localToDate == null
                    //                   ? "Select"
                    //                   : DateFormat('dd MMM yyyy').format(localToDate!),
                    //               style: GoogleFonts.inter(fontSize: 14),
                    //             ),
                    //             style: ElevatedButton.styleFrom(
                    //               backgroundColor: AppColors.accentBlue,
                    //               foregroundColor: Colors.white,
                    //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //               padding: const EdgeInsets.symmetric(vertical: 16),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                 Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "From Date",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: localFromDate ?? DateTime.now(),
                firstDate: DateTime(2005),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.accentBlue,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setStateBottomSheet(() => localFromDate = picked);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: localFromDate != null ? Colors.white : AppColors.accentBlue,
              backgroundColor: localFromDate != null ? AppColors.accentBlue : Colors.transparent,
              side: BorderSide(
                color: localFromDate != null ? AppColors.accentBlue : Colors.grey.shade400,
                width: 1.8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: localFromDate != null ? 2 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Critical: prevents overflow
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: localFromDate != null ? Colors.white : AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                Flexible( // Wrap text in Flexible to allow shrinking
                  child: Text(
                    localFromDate == null
                        ? "Select From Date"
                        : DateFormat('dd MMM yyyy').format(localFromDate!),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: localFromDate != null ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis, // Truncate if too long
                    maxLines: 1,
                  ),
                ),
                // if (localFromDate != null) ...[
                //   const SizedBox(width: 8),
                //   GestureDetector(
                //     onTap: () => setStateBottomSheet(() => localFromDate = null),
                //     child: Icon(
                //       Icons.clear_rounded,
                //       size: 18,
                //       color: Colors.white.withOpacity(0.9),
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(width: 12), // Reduced from 16 to save space
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "To Date",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: localToDate ?? DateTime.now(),
                firstDate: localFromDate?.add(const Duration(days: 1)) ?? DateTime(2005),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.accentBlue,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setStateBottomSheet(() => localToDate = picked);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: localToDate != null ? Colors.white : AppColors.accentBlue,
              backgroundColor: localToDate != null ? AppColors.accentBlue : Colors.transparent,
              side: BorderSide(
                color: localToDate != null ? AppColors.accentBlue : Colors.grey.shade400,
                width: 1.8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: localToDate != null ? 2 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: localToDate != null ? Colors.white : AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    localToDate == null
                        ? "Select To Date"
                        : DateFormat('dd MMM yyyy').format(localToDate!),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: localToDate != null ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                // if (localToDate != null) ...[
                //   const SizedBox(width: 8),
                //   GestureDetector(
                //     onTap: () => setStateBottomSheet(() => localToDate = null),
                //     child: Icon(
                //       Icons.clear_rounded,
                //       size: 18,
                //       color: Colors.white.withOpacity(0.9),
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ],
      ),
    ),
  ],
),
                    const SizedBox(height: 30),
                  ],
                ),

                // APPLY BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Commit local values to global state
                      setState(() {
                        _searchQuery = localSearchQuery;
                        _selectedType = localSelectedType;
                        _fromDate = localFromDate;
                        _toDate = localToDate;
                        _currentPage = 0;
                      });
                      Navigator.pop(modalContext);
                      _applyAllFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      "Apply Filters",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  // void _showFiltersBottomSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     useSafeArea: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return Container(
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //             ),
  //             padding: EdgeInsets.only(
  //               bottom: MediaQuery.of(context).viewInsets.bottom,
  //             ),
  //             child: Column(
  //                               mainAxisSize: MainAxisSize.min,

  //               children: [
  //                 // HEADER
  //                 Padding(
  //                   padding: const EdgeInsets.fromLTRB(15, 12, 20, 8),
  //                   child: Row(
  //                     children: [
  //                       const Spacer(),
  //                       const Text(
  //                         "Advanced Filters",
  //                         style: TextStyle(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       const Spacer(),
  //                       TextButton(
  //                         onPressed: _hasActiveFilters()
  //                             ? () {
  //                                 setState(() {
  //                                   _searchQuery = '';
  //                                   _selectedType = 'All';
  //                                   _fromDate = null;
  //                                   _toDate = null;
  //                                   _currentPage = 0;
  //                                 });
  //                                 _applyAllFilters();
  //                                 // showSuccessToast(context, "Filters cleared");
  //                                 Navigator.pop(context);
  //                               }
  //                             : null,
  //                         child: Text(
  //                           "Reset",
  //                           style: TextStyle(
  //                             color: _hasActiveFilters()
  //                                 ? Colors.red.shade600
  //                                 : Colors.grey,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),

  //                 const Divider(height: 1),

  //                 Padding(
  //                   padding: const EdgeInsets.all(20),
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.start,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     spacing: 5,
  //                     children: [
  //                       Text(
  //                         "Search by Name, Mobile No. or Email",
  //                         style: GoogleFonts.inter(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       TextField(
  //                         onChanged: (val) {
  //                           _searchQuery = val.trim();
  //                           _currentPage = 0; // Reset to first page
  //                           _fetchChallans();
  //                         },
  //                         cursorColor: AppColors.accentBlue,
  //                         onSubmitted: (_) => _applyAllFilters(),
  //                         textInputAction: TextInputAction.search,
  //                         decoration: InputDecoration(
  //                           prefixIcon: Icon(
  //                             Icons.search,
  //                             color: AppColors.accentBlue,
  //                           ),
  //                           labelText: 'Search by Name/Mob No./Email',
  //                           border: OutlineInputBorder(
  //                             borderRadius: BorderRadius.circular(12),
  //                           ),
  //                         ),
  //                       ),
  //                       Row(
  //                         children: [
  //                           Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 "From Date",
  //                                 style: GoogleFonts.inter(
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                               const SizedBox(height: 4),
  //                               ElevatedButton.icon(
  //                                 onPressed: _pickFromDate,
  //                                 icon: Icon(
  //                                   Icons.calendar_today,
  //                                   size: 18,
  //                                   color: Colors.white,
  //                                 ),
  //                                 label: Text(
  //                                   _fromDate == null
  //                                       ? "From Date"
  //                                       : DateFormat(
  //                                           'dd MMM yy',
  //                                         ).format(_fromDate!),
  //                                   style: GoogleFonts.inter(fontSize: 16),
  //                                   overflow: TextOverflow.ellipsis,
  //                                 ),
  //                                 style: ElevatedButton.styleFrom(
  //                                   backgroundColor: const Color.fromRGBO(
  //                                     0,
  //                                     140,
  //                                     192,
  //                                     1,
  //                                   ),
  //                                   foregroundColor: Colors.white,
  //                                   padding: const EdgeInsets.symmetric(
  //                                     horizontal: 12,
  //                                     vertical: 14,
  //                                   ),
  //                                   shape: RoundedRectangleBorder(
  //                                     borderRadius: BorderRadius.circular(12),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                           Spacer(),
  //                           Column(
  //                             mainAxisAlignment: MainAxisAlignment.start,
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 "To Date",
  //                                 style: GoogleFonts.inter(
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                               const SizedBox(height: 4),
  //                               ElevatedButton.icon(
  //                                 onPressed: _pickToDate,
  //                                 icon: const Icon(
  //                                   Icons.calendar_today,
  //                                   size: 18,
  //                                 ),
  //                                 label: Text(
  //                                   _toDate == null
  //                                       ? "To Date"
  //                                       : DateFormat(
  //                                           'dd MMM yy',
  //                                         ).format(_toDate!),
  //                                   style: GoogleFonts.inter(fontSize: 16),
  //                                   overflow: TextOverflow.ellipsis,
  //                                 ),
  //                                 style: ElevatedButton.styleFrom(
  //                                   backgroundColor: const Color.fromRGBO(
  //                                     0,
  //                                     140,
  //                                     192,
  //                                     1,
  //                                   ),
  //                                   foregroundColor: Colors.white,
  //                                   padding: const EdgeInsets.symmetric(
  //                                     horizontal: 12,
  //                                     vertical: 14,
  //                                   ),
  //                                   shape: RoundedRectangleBorder(
  //                                     borderRadius: BorderRadius.circular(12),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),

  //                 // APPLY BUTTON
  //                 Container(
  //                   padding: const EdgeInsets.all(20),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Colors.black.withOpacity(0.1),
  //                         blurRadius: 10,
  //                       ),
  //                     ],
  //                   ),
  //                   child: SizedBox(
  //                     width: double.infinity,
  //                     height: 56,
  //                     child: ElevatedButton(
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                         _applyAllFilters();
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: AppColors.accentBlue,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(14),
  //                         ),
  //                       ),
  //                       child: const Text(
  //                         "Apply Filters",
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.white,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  // }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _userRole == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Challan Details',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        leadingWidth: 96,
        leading: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            // if (isAdmin)
              IconButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                ),
                icon: Icon(Icons.home),
              ),
          ],
        ),
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: null,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                hint: Text(
                  'Add Challan Entry',
                  style: GoogleFonts.inter(color: AppColors.accentBlue),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBlue,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Delivered',
                    child: Text('Delivered Entry'),
                  ),
                  DropdownMenuItem(
                    value: 'Received',
                    child: Text('Received Entry'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    challanCreateType = value;
                    challanCreateSelected = value == 'Received';
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChallanScreen(
                        mode: value == 'Received'
                            ? ChallanMode.received
                            : ChallanMode.delivered,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      drawer: ShowSideMenu(),
      body: RefreshIndicator(
        onRefresh: _fetchChallans,
        color: AppColors.accentBlue,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width - 100,
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedType,
                                      hint: const Text("All Types"),
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.filter_alt_outlined,
                                        color: Colors.grey,
                                      ),
                                      items: ['All', 'Received', 'Delivered']
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() => _selectedType = val!);
                                        _currentPage = 0;
                                        _fetchChallans();
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                  
                                Stack(
                                  children: [
                                    SizedBox(
                                      height: 56,
                                      width: 56,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showFiltersBottomSheet(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.accentBlue,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.tune_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    if (_hasActiveFilters())
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Text(
                                            "!",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                  
                            // const SizedBox(height: 16),
                            // Wrap(
                            //   spacing: 12,
                            //   runSpacing: 12,
                            //   children: [
                            //     SizedBox(
                            //       width: 150,
                            //       child: ElevatedButton.icon(
                            //         onPressed: _pickFromDate,
                            //         icon: const Icon(
                            //           Icons.calendar_today,
                            //           size: 18,
                            //         ),
                            //         label: Text(
                            //           _fromDate == null
                            //               ? "From Date"
                            //               : DateFormat(
                            //                   'dd MMM yy',
                            //                 ).format(_fromDate!),
                            //           style: GoogleFonts.inter(
                            //             fontSize: 13.5,
                            //           ),
                            //           overflow: TextOverflow.ellipsis,
                            //         ),
                            //         style: ElevatedButton.styleFrom(
                            //           backgroundColor: const Color.fromRGBO(
                            //             0,
                            //             140,
                            //             192,
                            //             1,
                            //           ),
                            //           foregroundColor: Colors.white,
                            //           padding: const EdgeInsets.symmetric(
                            //             horizontal: 12,
                            //             vertical: 14,
                            //           ),
                            //           shape: RoundedRectangleBorder(
                            //             borderRadius: BorderRadius.circular(
                            //               12,
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //     SizedBox(
                            //       width: 150,
                            //       child: ElevatedButton.icon(
                            //         onPressed: _pickToDate,
                            //         icon: const Icon(
                            //           Icons.calendar_today,
                            //           size: 18,
                            //         ),
                            //         label: Text(
                            //           _toDate == null
                            //               ? "To Date"
                            //               : DateFormat(
                            //                   'dd MMM yy',
                            //                 ).format(_toDate!),
                            //           style: GoogleFonts.inter(
                            //             fontSize: 13.5,
                            //           ),
                            //           overflow: TextOverflow.ellipsis,
                            //         ),
                            //         style: ElevatedButton.styleFrom(
                            //           backgroundColor: const Color.fromRGBO(
                            //             0,
                            //             140,
                            //             192,
                            //             1,
                            //           ),
                            //           foregroundColor: Colors.white,
                            //           padding: const EdgeInsets.symmetric(
                            //             horizontal: 12,
                            //             vertical: 14,
                            //           ),
                            //           shape: RoundedRectangleBorder(
                            //             borderRadius: BorderRadius.circular(
                            //               12,
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //     // if (_selectedIds.isNotEmpty)
                            //       // SizedBox(
                            //       //   width: 150,
                            //       //   child: ElevatedButton.icon(
                            //       //     onPressed: () => showSuccessToast(
                            //       //       context,
                            //       //       "Printing ${_selectedIds.length} challans...",
                            //       //     ),
                            //       //     icon: const Icon(
                            //       //       Icons.print,
                            //       //       size: 18,
                            //       //       color: Colors.white,
                            //       //     ),
                            //       //     label: Text(
                            //       //       "Print",
                            //       //       style: GoogleFonts.inter(
                            //       //         fontSize: 13.5,
                            //       //         color: Colors.white,
                            //       //       ),
                            //       //     ),
                            //       //     style: ElevatedButton.styleFrom(
                            //       //       backgroundColor: AppColors.accentBlue,
                            //       //       padding: const EdgeInsets.symmetric(
                            //       //         vertical: 14,
                            //       //       ),
                            //       //       shape: RoundedRectangleBorder(
                            //       //         borderRadius: BorderRadius.circular(
                            //       //           12,
                            //       //         ),
                            //       //       ),
                            //       //     ),
                            //       //   ),
                            //       // ),
                            //     // if (_selectedIds.isNotEmpty)
                            //     //   SizedBox(
                            //     //     width: 150,
                            //     //     child: ElevatedButton.icon(
                            //     //       onPressed: _deleteMultipleChallans,
                            //     //       icon: const Icon(
                            //     //         Icons.delete_forever,
                            //     //         size: 18,
                            //     //         color: Colors.white,
                            //     //       ),
                            //     //       label: Text(
                            //     //         "Delete",
                            //     //         style: GoogleFonts.inter(
                            //     //           fontSize: 13.5,
                            //     //           color: Colors.white,
                            //     //         ),
                            //     //       ),
                            //     //       style: ElevatedButton.styleFrom(
                            //     //         backgroundColor: Colors.red.shade600,
                            //     //         padding: const EdgeInsets.symmetric(
                            //     //           vertical: 14,
                            //     //         ),
                            //     //         shape: RoundedRectangleBorder(
                            //     //           borderRadius: BorderRadius.circular(
                            //     //             12,
                            //     //           ),
                            //     //         ),
                            //     //       ),
                            //     //     ),
                            //     //   ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                  
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = constraints.maxWidth;
                          final double fixedColumnWidth = (screenWidth * 0.3)
                              .clamp(150, 350);
                  
                          final double nameWidth =
                              screenWidth * 0.22; // 22% of screen
                          final double challanWidth = screenWidth * 0.14;
                          final double typeWidth = screenWidth * 0.10;
                          final double locationWidth = screenWidth * 0.18;
                          final double qtyWidth = 70;
                          final double dateWidth = screenWidth * 0.12;
                          final double actionsWidth = screenWidth * 0.24;
                          return _filteredData.isEmpty && !_isLoading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 80,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "No challans created yet",
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Create your first challan using the Add Challan button",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  children: [
                                    SizedBox(
                                      // width: nameWidth,
                                      width: fixedColumnWidth,
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 50,
                                            color: AppColors.accentBlue,
                                            // color: Colors.grey.shade50,
                                            child: Row(
                                              children: [
                                                if (_selectionMode)
                                                  SizedBox(
                                                    width: 50,
                                                    child: Center(
                                                      child: SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                      ),
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      SizedBox(width: 30),
                                                      Text(
                                                        'Name',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .white,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ..._paginatedCustomers.map((row) {
                                            final isSelected = _selectedIds
                                                .contains(
                                                  row['id'].toString(),
                                                );
                                            return Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.blue.shade50
                                                    : null,
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color:
                                                        Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  if (_selectionMode)
                                                    SizedBox(
                                                      width: 50,
                                                      child: Checkbox(
                                                        activeColor: AppColors
                                                            .accentBlue,
                                                        value: isSelected,
                                                        onChanged: (_) =>
                                                            _toggleSelect(
                                                              row['id']
                                                                  .toString(),
                                                            ),
                                                      ),
                                                    ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 25,
                                                          ),
                                                      child: Text(
                                                        row['name'] ?? 'N/A',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontWeight:
                                                                  isSelected
                                                                  ? FontWeight
                                                                        .bold
                                                                  : null,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                  
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            // minWidth: screenWidth,
                                            minWidth:
                                                screenWidth -
                                                fixedColumnWidth,
                                          ),
                                          child: SizedBox(
                                            width: 900,
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: 50,
                                                  color: AppColors.accentBlue,
                                                  // color: Colors.grey.shade50,
                                                  child: Row(
                                                    children: [
                                                      _headerCell(
                                                        text: "Challan No.",
                                                        // width: challanWidth,
                                                        width: 150,
                                                      ),
                                                      _headerCell(
                                                        text: 'Type',
                                                        // width: typeWidth,
                                                        width: 100,
                                                      ),
                                                      _headerCell(
                                                        text: 'Location',
                                                        // width: locationWidth
                                                        width: 200,
                                                      ),
                                                      _headerCell(
                                                        text: 'Qty',
                                                        // width: qtyWidth
                                                        width: 50,
                                                      ),
                                                      _headerCell(
                                                        text: 'Date',
                                                        // width: dateWidth
                                                        width: 150,
                                                      ),
                                                      Expanded(
                                                        // width: actionsWidth,
                                                        child: Center(
                                                          child: Text(
                                                            'Actions',
                                                            style: GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                  
                                                ..._paginatedCustomers.map((
                                                  row,
                                                ) {
                                                  final isSelected =
                                                      _selectedIds.contains(
                                                        row['id'].toString(),
                                                      );
                                                  final typeDisplay =
                                                      safeChallanType(row) ==
                                                          'DELIVERED'
                                                      ? 'Delivered'
                                                      : safeChallanType(
                                                              row,
                                                            ) ==
                                                            'RECEIVED'
                                                      ? 'Received'
                                                      : 'N/A';
                  
                                                  return Container(
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? Colors
                                                                .blue
                                                                .shade50
                                                          : null,
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          // width: challanWidth,
                                                          width: 150,
                                                          child: Text(
                                                            row['challanNumber'] ??
                                                                'N/A',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 100,
                                                          // width: typeWidth,
                                                          child: Center(
                                                            child: Text(
                                                              typeDisplay,
                                                              style: GoogleFonts.inter(
                                                                color:
                                                                    _getTypeColor(
                                                                      row,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          // width: locationWidth,
                                                          width: 200,
                                                          child: Center(
                                                            child: Text(
                                                              row['location'] ??
                                                                  'N/A',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          // width:qtyWidth,
                                                          width: 50,
                                                          child: Center(
                                                            child: Text(
                                                              row['qty']
                                                                      ?.toString() ??
                                                                  '0',
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          // width: dateWidth,
                                                          width: 150,
                                                          child: Center(
                                                            child: Text(
                                                              row['date']
                                                                      ?.toString() ??
                                                                  'N/A',
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          // width: actionsWidth,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              IconButton(
                                                                onPressed: () =>
                                                                    _showUserGoodsDetails(
                                                                      int.tryParse(
                                                                            row['id'].toString(),
                                                                          ) ??
                                                                          0,
                                                                    ),
                                                                icon: Icon(
                                                                  CupertinoIcons
                                                                      .doc_text_search,
                                                                  color:
                                                                      Color.fromRGBO(
                                                                        0,
                                                                        140,
                                                                        192,
                                                                        1,
                                                                      ),
                                                                ),
                                                              ),
                                                              if(isAdmin)
                                                              IconButton(
                                                                onPressed: () =>
                                                                    _editChallan(
                                                                      row,
                                                                    ),
                                                                icon: Image.asset(
                                                                  "assets/images/edit.png",
                                                                ),
                                                                tooltip:
                                                                    'Edit',
                                                              ),
                                                              if (isAdmin)
                                                                IconButton(
                                                                  onPressed: () =>
                                                                      _deleteChallan(
                                                                        row['id'],
                                                                        safeChallanType(
                                                                          row,
                                                                        ),
                                                                      ),
                                                                  icon: Icon(
                                                                    CupertinoIcons
                                                                        .bin_xmark_fill,
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                  tooltip:
                                                                      'Delete',
                                                                ),
                                                              IconButton(
                                                                onPressed: () =>
                                                                    challanApi.sharePdf(
                                                                      row['id'],
                                                                      context,
                                                                      row['challanNumber'],
                                                                    ),
                                                                icon: Icon(
                                                                  Icons
                                                                      .share_rounded,
                                                                  color:
                                                                      Color.fromRGBO(
                                                                        0,
                                                                        140,
                                                                        192,
                                                                        1,
                                                                      ),
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: Image.asset(
                                                                  "assets/images/sheet.png",
                                                                ),
                                                                tooltip:
                                                                    'Download & View PDF',
                                                                onPressed: () async {
                                                                  setState(
                                                                    () => _isLoading =
                                                                        true,
                                                                  );
                                                                  try {
                                                                    final id =
                                                                        int.tryParse(
                                                                          row['id'].toString(),
                                                                        ) ??
                                                                        0;
                                                                    if (id <=
                                                                        0) {
                                                                      showErrorToast(
                                                                        context,
                                                                        "Invalid Challan ID",
                                                                      );
                                                                      return;
                                                                    }
                                                                    await challanApi.downloadAndShowPdf(
                                                                      row['id'],
                                                                      challanNumber:
                                                                          row['challanNumber'],
                                                                      context:
                                                                          context,
                                                                    );
                                                                  } catch (
                                                                    e
                                                                  ) {
                                                                    showErrorToast(
                                                                      context,
                                                                      "Failed to load PDF",
                                                                    );
                                                                  } finally {
                                                                    setState(
                                                                      () => _isLoading =
                                                                          false,
                                                                    );
                                                                  }
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
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFFB3E0F2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() => _currentPage--);
                                _fetchChallans();
                              }
                            : null,
                        icon: Icon(Icons.arrow_back_ios),
                      ),
                      Text('Page ${_currentPage + 1} of $_totalPages'),

                      IconButton(
                        onPressed: _currentPage < _totalPages - 1
                            ? () {
                                setState(() => _currentPage++);
                                _fetchChallans();
                              }
                            : null,
                        icon: Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading) customLoader(),
          ],
        ),
      ),
    );
  }
}
