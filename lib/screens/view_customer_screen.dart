import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/create_customer_screen.dart';
import 'package:snow_trading_cool/screens/home_screen.dart';
import 'package:snow_trading_cool/screens/passbook_screen.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:snow_trading_cool/services/customer_api.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';

class ViewCustomerScreenFixed extends StatefulWidget {
  const ViewCustomerScreenFixed({super.key});

  @override
  State<ViewCustomerScreenFixed> createState() =>
      _ViewCustomerScreenFixedState();
}

class _ViewCustomerScreenFixedState extends State<ViewCustomerScreenFixed> {
   late final width = MediaQuery.of(context).size.width;

    // 🔹 Breakpoints
    late final bool isMobile = width < 600;
    late final bool isTablet = width >= 600 && width < 1024;
    late final bool isDesktop = width >= 1024;

  bool canCreateCustomer = TokenManager().canCreateCustomer;

  final CustomerApi _api = CustomerApi();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _selectionMode = false;

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredData = [];

  String _searchQuery = '';
  List<String> _selectedIds = [];
  String _currentSearchQuery = '';

  int _currentPage = 0;
  late final int _rowsPerPage = 9;
  int _totalPages = 1;

  String _userRole = 'Employee';

  Timer? _searchDebounce; // ← Add this at the top of your State class

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchCustomers();

    // ────── DEBOUNCED LIVE SEARCH (400ms) ──────
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _searchDebounce?.cancel(); // Cancel previous timer

      _searchDebounce = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return; // Safety check

        // Reset to first page on new search
        _currentPage = 0;

        // This triggers the unified API with smart detection
        _fetchCustomers();
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel(); // ← Always cancel timer
    _searchController.dispose(); // ← Dispose controller
    super.dispose();
  }

  void _loadUserRole() {
    final role = TokenManager().getRole();
    _userRole = (role?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
    setState(() {});
  }

  Future<void> _fetchCustomers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await CustomerApi().searchCustomersUnified(
        page: _currentPage,
        size: _rowsPerPage,
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      final mapped = response.content.map((c) {
        return {
          'id': c.id,
          'name': c.name.isNotEmpty ? c.name : 'Unknown Customer',
          'contactNumber': c.contactNumber,
          'email': c.email ?? '',
          'address': c.address ?? '',
          'runningBalance': c.runningBalance,
          'reminder': c.reminder,
          'items': c.items,
        };
      }).toList();

      setState(() {
        _customers = mapped;
        _filteredData = mapped;
        _totalPages = response.totalPages <= 0 ? 1 : response.totalPages;
      });
    } catch (e, s) {
      debugPrint("Error loading customers: $e\n$s");
      if (mounted) showErrorToast(context, "Failed to load customers");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showUserGoodsDetails(
    int customerId,
    double runningBalance,
  ) async {
    double remainingBalance = runningBalance;
    if (customerId <= 0) {
      showErrorToast(context, "Invalid challan ID");
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: SizedBox(width: 60, height: 60, child: customLoader())),
    );

    final inventoryItems = await ChallanApi().getCustomerPendingInventoryItems(
      customerId,
      context,
    );

    if (mounted) Navigator.of(context).pop();

    if (inventoryItems == null) {
      showErrorToast(context, "Failed to load goods details");
      return;
    }

    if (!mounted) return;

    if (inventoryItems.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            // width: double.maxFinite,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: const Text(
                      "No items found.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Deposit: ₹ ${remainingBalance.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: remainingBalance >= 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
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
      return;
    }

    //   if (customerId != null && customerId > 0) {
    //   try {
    //     remainingBalance = await CustomerApi().getCustomerPreviousBalance(
    //           customerId,
    //           context,
    //         ) ??
    //         0.0;
    //   } catch (e) {
    //     debugPrint("Failed to load remaining balance: $e");
    //     remainingBalance = 0.0;
    //   }
    // }

    final List<Map<String, dynamic>> displayItems = inventoryItems.map((item) {
      return {
        'name': item['name'] ?? 'Unknown',
        'receivedQty': item['receivedQty'] ?? 0,
        'deliveredQty': item['deliveredQty'] ?? 0,
        // 'type': (item['type']?.toString() ?? '').trim(),
        // 'srNo': srNoStr,
        // 'id': item['id'],
      };
    }).toList();

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
                // Header
                Row(
                  spacing: 5,
                  children: [
                    const Expanded(
                      child: Text(
                        "Item Name",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
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
                const Divider(height: 16),

                // Item List
                ...displayItems.map(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "${item['receivedQty']}",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "${item['deliveredQty']}",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Deposit: ₹ ${remainingBalance.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: remainingBalance > 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
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

  Widget _header(String text, double width) => SizedBox(
    width: width,
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13.5,
        ),
      ),
    ),
  );

  Widget _cell(String text, double width) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 13.5),
      ),
    ),
  );

  Future<void> _editCustomer(customerId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCustomerScreen(customerId: customerId),
      ),
    );

    if (result == true) {
      _fetchCustomers();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? "No customers found for '$_searchQuery'"
                : "No customers yet",
            style: GoogleFonts.inter(fontSize: 18, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text("Clear search"),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(int customerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final resp = await _api.deleteCustomer(customerId);
      if (resp.success) {
        await _fetchCustomers();
        if (mounted)
          showSuccessToast(context, "Customer deleted successfully!");
      } else {
        if (mounted) showErrorToast(context, 'Delete failed: ${resp.message}');
      }
    } catch (e) {
      if (mounted) showErrorToast(context, 'Error: $e');
    }
  }

  List<Widget> _buildPageNumbers({required bool isMobile}) {
    List<Widget> pages = [];

    int delta = isMobile
        ? 0
        : 1; // ← This controls how many pages on each side of current
    // delta = 2 → total 5 pages in middle (2 left + current + 2 right)

    if (_totalPages <= delta * 2 + 3) {
      // If total pages are small enough, show all pages (no ellipsis needed)
      for (int i = 1; i <= _totalPages; i++) {
        pages.add(_pageButton(i, i == _currentPage + 1));
      }
    } else {
      // Always show page 1
      pages.add(_pageButton(1, _currentPage == 0));

      // Calculate the range around current page
      int left = _currentPage - delta + 1; // +1 because pages are 1-based
      int right = _currentPage + delta + 1;

      // Adjust when near the beginning
      if (left < 2) {
        right += (2 - left);
        left = 2;
      }

      // Adjust when near the end
      if (right > _totalPages - 1) {
        left -= (right - (_totalPages - 1));
        right = _totalPages - 1;
      }
      if (left < 2) left = 2;

      // Ellipsis after page 1
      if (left > 2) {
        pages.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '...',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        );
      }

      // Middle 5 pages
      for (int i = left; i <= right; i++) {
        pages.add(_pageButton(i, i == _currentPage + 1));
      }

      // Ellipsis before last page
      if (right < _totalPages - 1) {
        pages.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '...',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        );
      }

      // Always show last page
      if (_totalPages > 1) {
        pages.add(_pageButton(_totalPages, _currentPage == _totalPages - 1));
      }
    }

    return pages;
  }

  Widget _pageButton(int pageNum, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isCurrent
            ? null
            : () {
                setState(() {
                  _currentPage = pageNum - 1;
                  _fetchCustomers();
                });
              },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrent ? Colors.blue[800] : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isCurrent ? null : Border.all(color: Colors.blue[800]!),
          ),
          alignment: Alignment.center,
          child: Text(
            '$pageNum',
            style: TextStyle(
              color: isCurrent ? Colors.white : Colors.blue[800],
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
   

    final bool isAdmin = _userRole == 'ADMIN';

    // 🔹 Responsive column widths
    late final double nameColWidth;
    late final double mobileColWidth;
    late final double emailColWidth;
    late final double addressColWidth;
    late final double passbookColWidth;
    late final double actionsColWidth;

    if (isMobile) {
      nameColWidth = (width * 0.45).clamp(140.0, 260.0);
      mobileColWidth = 100;
      emailColWidth = 210;
      addressColWidth = 180;
      passbookColWidth = 80;
      actionsColWidth = 150;
    } else if (isTablet) {
      nameColWidth = (width * 0.35).clamp(160.0, 280.0);
      mobileColWidth = 100;
      emailColWidth = 220;
      addressColWidth = 220;
      passbookColWidth = 80;
      actionsColWidth = 180;
    } else {
      // Desktop / large screens
      nameColWidth = (width * 0.30).clamp(200.0, 320.0);
      mobileColWidth = 220;
      emailColWidth = 280;
      addressColWidth = 300;
      passbookColWidth = 150;
      actionsColWidth = 250;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Customers',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        leadingWidth: 96,
        leading: Row(
          children: [
            Builder(
              builder: (c) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(c).openDrawer(),
              ),
            ),
            // if (isAdmin)
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
            ),
          ],
        ),
        actions: [
          if (canCreateCustomer || isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCustomerScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Create Customer",
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: const ShowSideMenu(),
      body: RefreshIndicator(
        onRefresh: _fetchCustomers,
        color: AppColors.accentBlue,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Search & Filters
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            cursorColor: AppColors.accentBlue,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search by name, mobile or email...',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: const Color.fromRGBO(156, 156, 156, 1),
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.accentBlue,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                _currentSearchQuery = '';
                                _currentPage = 0;
                                _fetchCustomers();
                              },
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Clear",
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Responsive Table
                  Expanded(
                    child: _filteredData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? "No customers found matching '$_searchQuery'"
                                      : "No customer created",
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fixed Name Column
                              SizedBox(
                                width: nameColWidth,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 56,
                                      color: AppColors.accentBlue,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Customer Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    ..._filteredData.map((row) {
                                      final isSelected = _selectedIds.contains(
                                        row['id'].toString(),
                                      );
                                      return InkWell(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PassBookScreen(
                                              customerId: row['id'],
                                              customerName: row['name'],
                                              customerDeposit:
                                                  row['runningBalance'],
                                            ),
                                          ),
                                        ),
                                        child: Container(
                                          height: 56,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.blue.shade50
                                                : null,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            row['name'],
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: AppColors.accentBlue,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),

                              // Scrollable Right Table
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    children: [
                                      // Header Row
                                      Container(
                                        height: 56,
                                        color: AppColors.accentBlue,
                                        child: Row(
                                          children: [
                                            _header('Mobile', mobileColWidth),
                                            _header('Email', emailColWidth),
                                            _header('Address', addressColWidth),
                                            _header(
                                              'Passbook',
                                              passbookColWidth,
                                            ),
                                            _header('Actions', actionsColWidth),
                                          ],
                                        ),
                                      ),
                                      // Data Rows
                                      ..._filteredData.map((row) {
                                        final isSelected = _selectedIds
                                            .contains(row['id'].toString());
                                        return Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.blue.shade50
                                                : null,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _cell(
                                                row['contactNumber'] ?? '—',
                                                mobileColWidth,
                                              ),
                                              _cell(
                                                row['email']?.isEmpty ?? true
                                                    ? '—'
                                                    : row['email'],
                                                emailColWidth,
                                              ),
                                              _cell(
                                                row['address']?.isEmpty ?? true
                                                    ? '—'
                                                    : row['address'],
                                                addressColWidth,
                                              ),
                                              SizedBox(
                                                width: passbookColWidth,
                                                child: IconButton(
                                                  onPressed: () async {
                                                    setState(
                                                      () => _isLoading = true,
                                                    );
                                                    try {
                                                      final id =
                                                          int.tryParse(
                                                            row['id']
                                                                .toString(),
                                                          ) ??
                                                          0;
                                                      if (id <= 0) {
                                                        showErrorToast(
                                                          context,
                                                          "Invalid Challan ID",
                                                        );
                                                        return;
                                                      }
                                                      await CustomerApi()
                                                          .downloadAndShowPdf(
                                                            row,
                                                            context: context,
                                                            customerId:
                                                                row['id'],
                                                            customerName:
                                                                row['name'],
                                                          );
                                                    } catch (e) {
                                                      showErrorToast(
                                                        context,
                                                        "Failed to load PDF",
                                                      );
                                                    } finally {
                                                      setState(
                                                        () =>
                                                            _isLoading = false,
                                                      );
                                                    }
                                                  },
                                                  icon: Image.asset(
                                                    "assets/images/passbook.png",
                                                    width: 26,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: actionsColWidth,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      onPressed: () =>
                                                          _showUserGoodsDetails(
                                                            int.tryParse(
                                                                  row['id']
                                                                      .toString(),
                                                                ) ??
                                                                0,
                                                            row['runningBalance'] ??
                                                                0,
                                                          ),
                                                      icon: Icon(
                                                        CupertinoIcons
                                                            .doc_text_search,
                                                        color: Color.fromRGBO(
                                                          0,
                                                          140,
                                                          192,
                                                          1,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isAdmin)
                                                      IconButton(
                                                        icon: Image.asset(
                                                          "assets/images/edit.png",
                                                          width: 26,
                                                        ),
                                                        onPressed: () =>
                                                            _editCustomer(
                                                              row['id'],
                                                            ),
                                                      ),
                                                    if (isAdmin)
                                                      IconButton(
                                                        icon: const Icon(
                                                          CupertinoIcons
                                                              .bin_xmark_fill,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          final id =
                                                              int.tryParse(
                                                                row['id']
                                                                    .toString(),
                                                              ) ??
                                                              0;
                                                          _deleteCustomer(id);
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
                            ],
                          ),
                  ),
                  // Pagination
                  Container(
                    color: const Color(0xFFB3E0F2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0
                              ? () {
                                  setState(() => _currentPage--);
                                  _fetchCustomers();
                                }
                              : null,
                        ),

                        // Text(
                        //   'Page ${_currentPage + 1} of $_totalPages',
                        //   style: GoogleFonts.poppins(
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        ..._buildPageNumbers(isMobile: isMobile),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages - 1
                              ? () {
                                  setState(() => _currentPage++);
                                  _fetchCustomers();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) customLoader(),
          ],
        ),
      ),
    );
  }
}
