import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/models/passbook_product_model.dart';
import 'package:snow_trading_cool/screens/viewpassbookbygoods.dart';
import 'package:snow_trading_cool/screens/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:snow_trading_cool/services/customer_api.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/services/passbook_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';

class PassBookScreen extends StatefulWidget {
  const PassBookScreen({
    super.key,
    this.customerId,
    this.customerName,
    this.customerDeposit,
  });

  final dynamic customerId;
  final dynamic customerName;
  final dynamic customerDeposit;

  @override
  State<PassBookScreen> createState() => _PassBookScreenState();
}

class _PassBookScreenState extends State<PassBookScreen> {
  List<PassbookProduct> products = [];
  bool isLoadingProducts = false;

  GoodsDTO? selectedGoods;

  // String _userRole = 'Employee';
  // late bool isAdmin = _userRole == 'ADMIN';

  DateTime? _fromDate;
  DateTime? _toDate;

  List<GoodsDTO> goods = [];

  TextEditingController? customerNameController;

  OverlayEntry? _overlayEntry;

  bool _isSearching = false;

  final GlobalKey _customerFieldKey = GlobalKey();

  int? selectedCustomerId;
  double? balance;

  final CustomerApi _customerApi = CustomerApi();

  bool get isCustomerSelected => selectedCustomerId != null;

  String get displayedCustomerName => isCustomerSelected
      ? customerNameController?.text ?? "Customer"
      : "Select Customer Name";

  void _showError(String msg) => showErrorToast(context, msg);

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 55,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(
              date == null ? label : DateFormat('dd MMM yyyy').format(date),
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: date != null
                  ? AppColors.accentBlue
                  : Colors.grey.shade200,
              foregroundColor: date != null ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsTable() {
    return products.isEmpty
        ? Center(
            child: Text(
              "No transactions found",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB3E0F2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final bool isVerySmall = width < 400;
                  final bool isSmall = width < 600;

                  Map<int, TableColumnWidth> columnWidths = isVerySmall
                      ? const {
                          0: FlexColumnWidth(2.1),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(1.7),
                        }
                      : isSmall
                      ? const {
                          0: FlexColumnWidth(2.2),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(1.8),
                          3: FlexColumnWidth(1.8),
                        }
                      : const {
                          0: FlexColumnWidth(3.0),
                          1: FlexColumnWidth(1.6),
                          2: FlexColumnWidth(1.6),
                          3: FlexColumnWidth(1.2),
                        };

                  final double horizontalPadding = isVerySmall
                      ? 0
                      : (isSmall ? 8 : 12);
                  final double verticalPadding = isVerySmall ? 8 : 14;
                  final double fontSize = isVerySmall ? 16 : 17.5;
                  return Table(
                    defaultColumnWidth: const FlexColumnWidth(),
                    columnWidths: columnWidths,
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFFB3E0F2),
                        ),
                        children: [
                          _headerCell("Products"),
                          _headerCell("Opening"),
                          _headerCell("Closing"),
                          _headerCell("View"),
                        ],
                      ),
                      ...products
                          .map(
                            (p) => TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: verticalPadding,
                                    horizontal: horizontalPadding,
                                  ),
                                  child: Text(
                                    p.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSize,
                                    ),
                                    // maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: verticalPadding,
                                    // horizontal: horizontalPadding,
                                  ),
                                  child: Text(
                                    p.openingBalance.toString(),
                                    textAlign: TextAlign.center,
                                     overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: p.openingBalance < 0
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: verticalPadding,
                                    // horizontal: horizontalPadding,
                                  ),
                                  child: Text(
                                    p.closingBalance.toString(),
                                    textAlign: TextAlign.center,
                                     overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: p.closingBalance < 0
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    // vertical: verticalPadding,
                                    // horizontal: horizontalPadding,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => GoodsPassbook(
                                            customerName: displayedCustomerName,
                                            customerId: selectedCustomerId!,
                                            fromDate: _fromDate,
                                            toDate: _toDate,
                                            itemName: p.name,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.visibility_rounded,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                      // if (products.isEmpty)
                      //   TableRow(
                      //     children: [
                      //       const SizedBox(),
                      //       Padding(
                      //         padding: const EdgeInsets.all(20),
                      //         child: Center(
                      //           child: Text(
                      //             "No data available",
                      //             style: TextStyle(color: Colors.grey[600]),
                      //           ),
                      //         ),
                      //       ),
                      //       const SizedBox(),
                      //       const SizedBox(),
                      //     ],
                      //   ),
                    ],
                  );
                },
              ),
            ),
          );
  }

  Widget _headerCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
    ),
  );

  void clearCustomerSelection() {
    setState(() {
      customerNameController?.clear();
      selectedCustomerId = null;
    });
  }

  @override
  void dispose() {
    customerNameController?.dispose();
    _removeOverlay();
    super.dispose();
  }

  Widget _buildCustomerSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Customer Name",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(20, 20, 20, 1),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              "*",
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          // enabled: !isEditMode,
          cursorColor: AppColors.accentBlue,
          key: _customerFieldKey, // Use the GlobalKey directly
          controller: customerNameController,
          onChanged: _onCustomerSearchChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s]')),
          ],
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            hintText: "Search by name or mobile...",
            hintStyle: const TextStyle(
              fontSize: 15,
              color: Color.fromRGBO(156, 156, 156, 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color.fromRGBO(156, 156, 156, 1),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(111, 0, 141, 192),
                width: 2,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            suffixIcon: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child :_isSearching
                ? CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentBlue,
                )
                : const Icon(Icons.search, color: Colors.grey),
            ),
          ),
        ),

      ],
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onCustomerSearchChanged(String query) async {
    final trimmed = query.trim();
    _removeOverlay();
    if (trimmed.isEmpty) {
      setState(() {
        _isSearching = false;
        selectedCustomerId = null;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<CustomerDTO> results = [];

      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        results = await _customerApi.getCustomers(searchQuery: trimmed);
      } else if (trimmed.contains('@')) {
        results = await _customerApi.getCustomers(searchQuery: trimmed);
      } else {
        results = await _customerApi.getCustomers(searchQuery: trimmed);
      }

      if (!mounted) return;

      _showOverlay(results);
    } catch (e) {
      _showError('Search failed: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showOverlay(List<CustomerDTO> results) {
    _removeOverlay();

    final RenderBox? renderBox =
        _customerFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final double width =
        renderBox?.size.width ?? MediaQuery.of(context).size.width * 0.9;
    final Offset offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final double top = offset.dy + (renderBox?.size.height ?? 55);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx,
            top: top,
            width: width,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black26,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: results.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No customers found",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (context, i) {
                          final c = results[i];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              c.contactNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              selectCustomer(c);
                              _removeOverlay();
                            },
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void selectCustomer(CustomerDTO customer) {
    setState(() {
      customerNameController!.text = customer.name;
      selectedCustomerId = customer.id;
      balance = customer.runningBalance;
    });
    _fetchPassbookProducts();
    //  Navigator.pop(context);
  }

  final PassbookApi _passbookApi = PassbookApi();

  Future<void> _fetchPassbookProducts() async {
    if (selectedCustomerId == null) return;

    setState(() => isLoadingProducts = true);

    try {
      final result = await _passbookApi.getPassbookSummary(
        customerId: selectedCustomerId!,
        fromDate: _fromDate != null
            ? DateFormat('yyyy-MM-dd').format(_fromDate!)
            : null,
        toDate: _toDate != null
            ? DateFormat('yyyy-MM-dd').format(_toDate!)
            : null,
      );

      setState(() {
        products = result;
      });
    } catch (e) {
      showErrorToast(context, "Failed to load passbook data");
    } finally {
      setState(() => isLoadingProducts = false);
    }
  }

  // void _loadUserRole() {
  //   final savedRole = TokenManager().getRole();
  //   _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
  //   setState(() {});
  // }

  void _resetFilters() {
    setState(() {
      customerNameController?.clear();
      selectedCustomerId = null;
      balance = null;
      _fromDate = null;
      _toDate = null;
      products = [];
    });
  }

  Widget _buildResetButton() {
    final bool hasActiveFilters =
        isCustomerSelected || _fromDate != null || _toDate != null;

    return Column(
      children: [
        SizedBox(height: 25),
        SizedBox(
          height: 55,
          width: 79,
          child: ElevatedButton.icon(
            onPressed: hasActiveFilters ? _resetFilters : null,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              "Reset",
              style: TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasActiveFilters
                  ? Colors.red
                  : Colors.grey.shade200,
              foregroundColor: hasActiveFilters ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4, //hasActiveFilters ? 4 : 0,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // _loadUserRole();
    customerNameController = TextEditingController();
    if (widget.customerId != null) {
      customerNameController?.text = widget.customerName;
      selectedCustomerId = widget.customerId;
      balance = widget.customerDeposit;
      _fetchPassbookProducts();
    }
  }
  // @override
  // void initState() {
  //   super.initState();
  //   _loadUserRole();
  //   customerNameController = TextEditingController();

  // }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PassBook'),
        leadingWidth: 96,
        leading: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            // if (isAdmin)
            IconButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
              icon: const Icon(Icons.home),
            ),
          ],
        ),
      ),
      drawer: const ShowSideMenu(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isSmallScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomerSearchField(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateButton(
                                "From Date",
                                _fromDate,
                                () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _fromDate ?? DateTime.now(),
                                    firstDate: DateTime(2005),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppColors.accentBlue,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black87,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.accentBlue,
                                              textStyle: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => _fromDate = picked);
                                    if (selectedCustomerId != null) {
                                      _fetchPassbookProducts();
                                    } else {
                                      showErrorToast(
                                        context,
                                        "Select customer first",
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateButton(
                                "To Date",
                                _toDate,
                                () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _toDate ?? DateTime.now(),
                                    firstDate:
                                        _fromDate?.add(const Duration(days: 1)) ??
                                        DateTime(2005),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppColors.accentBlue,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black87,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.accentBlue,
                                              textStyle: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => _toDate = picked);
                                    if (selectedCustomerId != null) {
                                      _fetchPassbookProducts();
                                    } else {
                                      showErrorToast(
                                        context,
                                        "Select customer first",
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildResetButton(),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 2, child: _buildCustomerSearchField()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateButton(
                            "From Date",
                            _fromDate,
                            () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _fromDate ?? DateTime.now(),
                                firstDate: DateTime(2005),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppColors.accentBlue,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.accentBlue,
                                          textStyle: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _fromDate = picked);
                              }
                              if (selectedCustomerId != null) {
                                _fetchPassbookProducts();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateButton("To Date", _toDate, () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _toDate ?? DateTime.now(),
                              firstDate:
                                  _fromDate?.add(const Duration(days: 1)) ??
                                  DateTime(2005),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppColors.accentBlue,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.accentBlue,
                                        textStyle: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setState(() => _toDate = picked);
                            if (selectedCustomerId != null) {
                              _fetchPassbookProducts();
                            }
                          }),
                        ),
                        const SizedBox(width: 10),
                        _buildResetButton(),
                      ],
                    ),
        
              const SizedBox(height: 32),
        
              Expanded(
                child: isCustomerSelected
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  displayedCustomerName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
        
                              // Small gap
                              const SizedBox(width: 12),
        
                              IntrinsicWidth(
                                child: Text(
                                  "Balance: ₹${(balance ?? 0).toStringAsFixed(2)}",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildProductsTable(),
                        ],
                      )
                    : Center(
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Select Customer Name",
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Search and select a customer to view their passbook",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade500,
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
    );
  }
}
