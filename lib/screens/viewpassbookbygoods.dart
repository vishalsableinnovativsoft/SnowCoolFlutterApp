import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:snow_trading_cool/screens/home_screen.dart';
import 'package:snow_trading_cool/services/passbook_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';

class GoodsPassbook extends StatefulWidget {
  const GoodsPassbook({
    super.key,
    required this.customerName,
    required this.customerId,
    required this.itemName,
    this.fromDate,
    this.toDate,
  });

  final String customerName;
  final int customerId;
  final String itemName;
  final DateTime? fromDate;
  final DateTime? toDate;

  @override
  State<GoodsPassbook> createState() => _GoodsPassbookState();
}

class _GoodsPassbookState extends State<GoodsPassbook> {
  // String _userRole = 'Employee';
  // late bool isAdmin = _userRole == 'ADMIN';

  String _searchQuery = '';
  String _poSearchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;

  bool _hasDialogAppeared = false;

  int customerId = 1;

  List<Map<String, dynamic>> _paginatedEntries = [];
  // bool _isLoading = true;
  int _currentPage = 0;
  int _totalPages = 1;
  late final int _rowsPerPage = 6;

  final PassbookApi _passbookApi = PassbookApi();
  void _applyFilters() {
    _loadPassbookByGoods(page: 0);
  }

  void _showFiltersBottomSheet() {
    String localSearchQuery = _searchQuery;
    String localPoSearchQuery = _poSearchQuery;
    DateTime? localFromDate = _fromDate;
    DateTime? localToDate = _toDate;
    // GoodsDTO? localSelectedGoods = selectedGoods;

    final TextEditingController nameController = TextEditingController(
      text: localSearchQuery,
    );
    final TextEditingController poController = TextEditingController(
      text: localPoSearchQuery,
    );

    nameController.addListener(() {
      localSearchQuery = nameController.text;
    });
    poController.addListener(() {
      localPoSearchQuery = poController.text;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBottomSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 12, 20, 8),
                    child: Row(
                      children: [
                        const Spacer(),
                        const Text(
                          "Advanced Filters",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),

                        TextButton(
                          onPressed: _hasActiveFilters()
                              ? () {
                                  setStateBottomSheet(() {
                                    localSearchQuery = '';
                                    localPoSearchQuery = '';
                                    localFromDate = null;
                                    localToDate = null;
                                  });

                                  nameController.clear();
                                  poController.clear();

                                  setState(() {
                                    _searchQuery = '';
                                    _poSearchQuery = '';
                                    _fromDate = null;
                                    _toDate = null;
                                  });

                                  Navigator.pop(context);
                                  _applyFilters();
                                }
                              : null,
                          child: Text(
                            "Reset",
                            style: TextStyle(
                              color: _hasActiveFilters()
                                  ? Colors.red.shade600
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSearchField(
                          label: "Search by SR No.",
                          hint: "SR No.",
                          icon: Icons.search,
                          value: localSearchQuery,
                          onChanged: (value) => setStateBottomSheet(
                            () => localSearchQuery = value,
                          ),
                          controller: nameController,
                        ),
                        const SizedBox(height: 20),
                        _buildSearchField(
                          label: "Search by PO Number / Site Location",
                          hint: "PO Number / Site Location",
                          icon: Icons.receipt_long,
                          value: localPoSearchQuery,
                          onChanged: (value) => setStateBottomSheet(
                            () => localPoSearchQuery = value,
                          ),
                          controller: poController,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateButton(
                                "From Date",
                                localFromDate,
                                () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        localFromDate ?? DateTime.now(),
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
                                    setStateBottomSheet(
                                      () => localFromDate = picked,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateButton(
                                "To Date",
                                localToDate,
                                () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: localToDate ?? DateTime.now(),
                                    firstDate:
                                        localFromDate?.add(
                                          const Duration(days: 1),
                                        ) ??
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
                                    setStateBottomSheet(
                                      () => localToDate = picked,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // APPLY BUTTON
                  Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      top: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [/* ... */],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Commit local values to global state
                          setState(() {
                            _searchQuery = localSearchQuery;
                            _poSearchQuery = localPoSearchQuery;
                            _fromDate = localFromDate;
                            _toDate = localToDate;
                            // selectedGoods = localSelectedGoods;
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Apply Filters",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

  Widget _buildSearchField({
    required String label,
    required String hint,
    required IconData icon,
    required String value,
    required ValueChanged<String> onChanged,
    TextEditingController? controller,
  }) {
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
        TextField(
          controller: controller,
          onChanged: onChanged,
          cursorColor: AppColors.accentBlue,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
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
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }

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

  bool _hasActiveFilters() =>
      _searchQuery.isNotEmpty ||
      _poSearchQuery.isNotEmpty ||
      _fromDate != null ||
      _toDate != null;
  // selectedGoods != null;

  Widget _buildTotalRecordsBadge() {
    final int recordCount = _paginatedEntries.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.format_list_numbered, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            "$recordCount Records",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportDropdown() {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'current_or_all') {
          _showExportOptionsDialog();
        } else if (value == 'customize') {
          _showCustomizeExportDialog();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 55),
      elevation: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade800],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.download_rounded, color: Colors.white, size: 24),
            SizedBox(width: 6),
            Text(
              "Export",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'current_or_all',
          child: Row(
            children: [
              Icon(Icons.speed, color: Colors.green.shade700),
              const SizedBox(width: 12),
              const Text("Quick Export (Current / All)"),
            ],
          ),
        ),

        const PopupMenuDivider(),

        PopupMenuItem(
          value: 'customize',
          child: Row(
            children: [
              Icon(Icons.tune, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Text("Customize Export (Date Range)"),
            ],
          ),
        ),
      ],
    );
  }

  void _showExportOptionsDialog() {
    String selectedScope = 'current'; // current or all
    String selectedFormat = 'pdf'; // pdf or excel

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.file_download_outlined,
                        color: Colors.green,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Export Passbook",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Export Scope",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          label: const Text("Current Page"),
                          selected: selectedScope == 'current',
                          onSelected: (_) =>
                              setStateDialog(() => selectedScope = 'current'),
                          selectedColor: Colors.blue.shade100,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: FilterChip(
                          label: const Text("Complete Passbook"),
                          selected: selectedScope == 'all',
                          onSelected: (_) =>
                              setStateDialog(() => selectedScope = 'all'),
                          selectedColor: Colors.green.shade100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Export Format",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // PDF Chip
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setStateDialog(() => selectedFormat = 'pdf'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedFormat == 'pdf'
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/sheet.png",
                                  height: 22,
                                  width: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "PDF",
                                  style: TextStyle(
                                    color: selectedFormat == 'pdf'
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Excel Chip
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setStateDialog(() => selectedFormat = 'excel'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedFormat == 'excel'
                                  ? Colors.green.shade600
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/excel.png",
                                  height: 22,
                                  width: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Excel",
                                  style: TextStyle(
                                    color: selectedFormat == 'excel'
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleQuickExport(selectedScope, selectedFormat);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Export",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleQuickExport(String scope, String format) {
    final passbookApi = PassbookApi();

    if (format == 'pdf') {
      if (scope == 'current') {
        passbookApi.showCurrentPDF(context: context);
      } else if (scope == 'all') {
        passbookApi.showAllPDF(context: context);
      }
    } else if (format == 'excel') {
      showErrorToast(context, "Excel export not implemented yet");
    }
  }

  void _showCustomizeExportDialog() {
    DateTime? localFromDate;
    DateTime? localToDate;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.date_range_rounded,
                        color: Colors.blue,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Customize Export",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Select Date Range",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDateButton(
                          "From Date",
                          localFromDate,
                          () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: localFromDate ?? DateTime.now(),
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
                              setStateDialog(() => localFromDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateButton(
                          "To Date",
                          localToDate,
                          () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: localToDate ?? DateTime.now(),
                              firstDate:
                                  localFromDate?.add(const Duration(days: 1)) ??
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
                            if (picked != null) {
                              setStateDialog(() => localToDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          final passbookApi = PassbookApi();
                          passbookApi.showAllPDF(
                            context: context,
                            fromDate: localFromDate.toString(),
                            toDate: localToDate.toString(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Export",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSrNoCell({
    required String srNoText,
    required BuildContext context,
    List<Map<String, dynamic>>? productSrDetails,
    required double srNoWidth,
  }) {
    final List<Map<String, dynamic>> details = productSrDetails ?? [];

    final parts = srNoText
        .split('/')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return _dataCell('-', srNoWidth);
    }

    if (parts.length <= 2) {
      return _dataCell(parts.join('\n'), srNoWidth, bold: true);
    }

    return SizedBox(
      width: srNoWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            parts.take(2).join('\n'),
            style: const TextStyle(fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (details.isNotEmpty) {
                _showAllSrNumbersDialog(context, details);
              }
            },
            child: Text(
              "+${parts.length - 2} more",
              style: TextStyle(
                color: details.isNotEmpty ? AppColors.accentBlue : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                // decoration: details.isEmpty ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllSrNumbersDialog(
    BuildContext context,
    List<Map<String, dynamic>> productSrDetails,
  ) {
    log("show details: $productSrDetails");
    if (productSrDetails.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                children: const [
                  Icon(Icons.inventory_2, color: Colors.cyan, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "SR Numbers",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 30),

              // Scrollable List
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: productSrDetails.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final product = entry.value;
                      final String productName =
                          product['productName'] ?? 'Unknown';
                      final String srJoined = product['srNoJoined'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Circle Number
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.cyan.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "$index",
                                  style: const TextStyle(
                                    color: Colors.cyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Product Name + SR Nos
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    srJoined.isEmpty ? "-" : srJoined,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: srJoined.isEmpty
                                          ? Colors.grey
                                          : Colors.black54,
                                      fontStyle: srJoined.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Close Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadPassbookByGoods({int page = 0}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine poNumber and siteLocation based on _poSearchQuery content
      String? poNum;
      String? siteLoc;
      final query = _poSearchQuery.trim();
      if (query.isNotEmpty) {
        bool hasLetters = RegExp(r'[a-zA-Z]').hasMatch(query);
        bool hasNumbers = RegExp(r'\d').hasMatch(query);
        if (hasLetters && !hasNumbers) {
          siteLoc = query;
        } else {
          poNum = query;
        }
      }

      final result = await _passbookApi.searchUnified(
        context: context,
        itemName: widget.itemName.trim().isNotEmpty == true
            ? widget.itemName.trim()
            : null,
        name: widget.customerName.trim().isNotEmpty == true
            ? widget.customerName.trim()
            : null,

        srNo: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
        poNumber: poNum,
        siteLocation: siteLoc,

        fromDate: _fromDate,
        toDate: _toDate,

        page: page,
        size: _rowsPerPage,
      );

      final List<Map<String, dynamic>> rawContent =
          List<Map<String, dynamic>>.from(result['content']);

      final List<Map<String, dynamic>> processed = rawContent.map((entry) {
        final rawItem = entry['raw'] as Map<String, dynamic>;
        final itemsList = (rawItem['items'] as List?) ?? [];
        final item = itemsList.isNotEmpty
            ? itemsList[0] as Map<String, dynamic>
            : null;

        return {
          ...entry,
          'openingBalance': item?['openingBalance'] ?? 0,
          'closingBalance': item?['closingBalance'] ?? 0,
        };
      }).toList();

      processed.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
        return dateA.compareTo(dateB);
      });

      if (mounted) {
        setState(() {
          _paginatedEntries = processed;
          _totalPages = result['totalPages'] ?? 1;
          _currentPage = result['number'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Goods Passbook load error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorToast(context, "Failed to load data");
      }
    }
  }

  void _showShareOptions(
    BuildContext context,
    String customerName,
    String productName,
    int customerId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Share Passbook of $customerName - $productName as",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      context: context,
                      icon: Image.asset("assets/images/sheet.png", width: 26),
                      label: "PDF",
                      color: Colors.red,
                      onTap: () async {
                        Navigator.pop(context);
                        // setState(() {
                        //   _isLoading = true;
                        // });
                        await _passbookApi.sharePassBookByGoods(
                          context: context,
                          customerId: customerId,
                          customerName: customerName,
                          itemName: productName,
                        );
                        //  setState(() {
                        //   _isLoading = false;
                        // });
                      },
                    ),
                    _buildShareOption(
                      context: context,
                      icon: Image.asset("assets/images/excel.png", width: 26),
                      label: "Excel",
                      color: Colors.green,
                      onTap: () async {
                        Navigator.pop(context);
                        await _passbookApi.shareExcelByGoods(
                          context: context,
                          customerId: customerId,
                          customerName: customerName,
                          itemName: productName,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required Widget icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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
                  _loadPassbookByGoods(page: _currentPage);
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
  void initState() {
    super.initState();
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
    // _loadUserRole();
    _loadPassbookByGoods();
  }

  // void _loadUserRole() {
  //   final savedRole = TokenManager().getRole();
  //   _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
  //   setState(() {});
  // }

  late final width = MediaQuery.of(context).size.width;

  // 🔹 Breakpoints
  late final bool isMobile = width < 600;
  late final bool isTablet = width >= 600 && width < 1024;
  late final bool isDesktop = width >= 1024;

  @override
  Widget build(BuildContext context) {
    // final bool isAdmin = _userRole == 'ADMIN';

    late final double challanNoWidth;
    late final double dateWidth;
    late final double srNoWidth;
    late final double poNoWidth;
    late final double siteLocationWidth;
    late final double openingBalanceWidth;
    late final double deliveredQtyWidth;
    late final double receivedQtyWidth;
    late final double balanceWidth;
    late final double actionsColWidth;

    if (isMobile) {
      challanNoWidth = (width * 0.40).clamp(140.0, 260.0);
      dateWidth = 130;
      srNoWidth = 110;
      poNoWidth = 110;
      siteLocationWidth = 150;
      openingBalanceWidth = 90;
      deliveredQtyWidth = 90;
      receivedQtyWidth = 90;
      balanceWidth = 90;
      actionsColWidth = 90;
    } else if (isTablet) {
      challanNoWidth = (width * 0.30).clamp(180.0, 300.0);
      dateWidth = 130;
      srNoWidth = 150;
      poNoWidth = 150;
      siteLocationWidth = 200;
      openingBalanceWidth = 120;
      deliveredQtyWidth = 120;
      receivedQtyWidth = 120;
      balanceWidth = 120;
      actionsColWidth = 160;
    } else {
      // Desktop / large screens
      challanNoWidth = (width * 0.30).clamp(220.0, 340.0);
      dateWidth = 130;
      srNoWidth = 190;
      poNoWidth = 190;
      siteLocationWidth = 260;
      openingBalanceWidth = 150;
      deliveredQtyWidth = 150;
      receivedQtyWidth = 150;
      balanceWidth = 150;
      actionsColWidth = 220;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Passbook',
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
      ),
      drawer: ShowSideMenu(),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isTablet = constraints.maxWidth > 600;
                      return Column(
                        children: [
                          Row(
                            children: [
                              _buildTotalRecordsBadge(),

                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildExportDropdown(),

                                  const SizedBox(width: 5),

                                  Stack(
                                    children: [
                                      SizedBox(
                                        height: 56,
                                        width: 54,
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
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.customerName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentBlue.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.itemName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.accentBlue.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showShareOptions(
                          context,
                          widget.customerName,
                          widget.itemName,
                          widget.customerId,
                        ),
                        icon: const Icon(Icons.share),
                        color: AppColors.accentBlue,
                        tooltip: 'Share',
                      ),
                    ],
                  ),
                ),

                // Main Table
                Expanded(
                  child: _paginatedEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                customerId != null
                                    ? "No passbook entries found for this customer"
                                    : "No passbook entries found",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Challan Numbers
                            SizedBox(
                              width: challanNoWidth,
                              child: Column(
                                children: [
                                  Container(
                                    height: 56,
                                    color: AppColors.accentBlue,
                                    child: const Center(
                                      child: Text(
                                        'Challan No.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: _paginatedEntries.length,
                                      itemBuilder: (_, i) {
                                        final challanNo =
                                            _paginatedEntries[i]['challanNumber'] ??
                                            'N/A';

                                        return Container(
                                          height: 70,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            challanNo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right: Data Columns
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const AlwaysScrollableScrollPhysics(),

                                child: SizedBox(
                                  width:
                                      dateWidth +
                                      srNoWidth +
                                      poNoWidth +
                                      siteLocationWidth +
                                      openingBalanceWidth +
                                      deliveredQtyWidth +
                                      receivedQtyWidth +
                                      balanceWidth +
                                      actionsColWidth,
                                  child: Column(
                                    children: [
                                      // Header
                                      Container(
                                        height: 56,
                                        color: AppColors.accentBlue,
                                        child: Row(
                                          children: [
                                            _headerCell('Date', dateWidth),
                                            _headerCell('SR No.', srNoWidth),
                                            _headerCell('PO No.', poNoWidth),
                                            _headerCell(
                                              'Site Location',
                                              siteLocationWidth,
                                            ),
                                            _headerCell(
                                              'Opening Bal',
                                              openingBalanceWidth,
                                            ),
                                            _headerCell(
                                              'Deliv Qty',
                                              deliveredQtyWidth,
                                            ),
                                            _headerCell(
                                              'Rece Qty',
                                              receivedQtyWidth,
                                            ),
                                            _headerCell(
                                              'Balance',
                                              balanceWidth,
                                            ),
                                            _headerCell(
                                              'Action',
                                              actionsColWidth,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Rows
                                      Expanded(
                                        child: ListView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: _paginatedEntries.length,
                                          itemBuilder: (_, i) {
                                            final e = _paginatedEntries[i];

                                            return Container(
                                              height: 70,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  _safeDateCell(
                                                    e['date'] as String?,
                                                    dateWidth,
                                                  ),
                                                  buildSrNoCell(
                                                    srNoText:
                                                        e['srNo']?.toString() ??
                                                        '',
                                                    productSrDetails:
                                                        e['product_sr_details']
                                                            as List<
                                                              Map<
                                                                String,
                                                                dynamic
                                                              >
                                                            >?,
                                                    context: context,
                                                    srNoWidth: srNoWidth,
                                                  ),
                                                  _dataCell(
                                                    e['purchaseOrderNo'] ?? '-',
                                                    poNoWidth,
                                                  ),
                                                  _dataCell(
                                                    e['siteLocation'] ?? '-',
                                                    siteLocationWidth,
                                                  ),
                                                  _dataCell(
                                                    e['openingBalance']
                                                        .toString(),
                                                    openingBalanceWidth,
                                                  ),
                                                  _dataCell(
                                                    e['delivered'].toString(),
                                                    deliveredQtyWidth,
                                                    color: Colors.red,
                                                  ),
                                                  _dataCell(
                                                    e['received'].toString(),
                                                    receivedQtyWidth,
                                                    color: Colors.green,
                                                  ),
                                                  _dataCell(
                                                    e['closingBalance']
                                                        .toString(),
                                                    balanceWidth,
                                                    color:
                                                        e['closingBalance'] >= 0
                                                        ? Colors.green
                                                        : Colors.red,
                                                    bold: true,
                                                  ),
                                                  SizedBox(
                                                    width: actionsColWidth,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        IconButton(
                                                          onPressed: () {
                                                            PassbookApi()
                                                                .showSingleChallanPassbookPdf(
                                                                  context:
                                                                      context,
                                                                  challanNumber:
                                                                      e['challanNumber'],
                                                                );
                                                          },
                                                          icon: Image.asset(
                                                            "assets/images/passbook.png",
                                                            width: 26,
                                                          ),
                                                          tooltip:
                                                              'View Challan',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                Container(
                  color: const Color(0xFFB3E0F2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: _currentPage > 0
                            ? () {
                                _loadPassbookByGoods(page: _currentPage - 1);
                              }
                            : null,
                      ),
                      ..._buildPageNumbers(isMobile: isMobile),
                      // Text(
                      //   'Page ${_currentPage + 1} of $_totalPages',
                      //   style: const TextStyle(fontWeight: FontWeight.w600),
                      // ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        onPressed: _currentPage < _totalPages - 1
                            ? () {
                                _loadPassbookByGoods(page: _currentPage + 1);
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
    );
  }
}

Widget _headerCell(String text, double width) {
  return SizedBox(
    width: width,
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _dataCell(String text, double width, {Color? color, bool bold = false}) {
  return SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Center(
        child: Text(
          text,
          // maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.black87,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ),
  );
}

Widget _safeDateCell(String? dateStr, double width) {
  final formatted = dateStr != null
      ? DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr))
      : '-';

  return _dataCell(formatted, width);
}
