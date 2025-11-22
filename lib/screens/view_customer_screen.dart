import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:snow_trading_cool/services/customer_store_api.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
// import 'package:snow_trading_cool/screens/view_customer_screennew.dart';
import '../services/customer_api.dart';

class ViewCustomerScreenFixed extends StatefulWidget {
  const ViewCustomerScreenFixed({super.key});

  @override
  State<ViewCustomerScreenFixed> createState() =>
      _ViewCustomerScreenFixedState();
}

class _ViewCustomerScreenFixedState extends State<ViewCustomerScreenFixed> {
  final CustomerApi _api = CustomerApi();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  late CustomerStore _store;

  int _rowsPerPage = 8;
  int _currentPage = 1;
  final List<int> _availableRowsPerPage = [5, 8, 10, 20];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      if (!_isLoading) {
        _store.applyFilter(_searchController.text);
        setState(() {
          _currentPage = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _api.getAllCustomers();
      _store = CustomerStore(customers);
    } catch (e) {
      _store = CustomerStore(_demoCustomers());
      if (mounted) {
        showWarningToast(context, "Failed to load customers, using demo data");
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _editCustomer(CustomerDTO c) async {
    final name = TextEditingController(text: c.name);
    final mobile = TextEditingController(text: c.contactNumber);
    final email = TextEditingController(text: c.email ?? '');
    final address = TextEditingController(text: c.address ?? '');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: mobile,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res != true) return;

    try {
      final resp = await _api.updateCustomer(
        c.id,
        name.text,
        mobile.text,
        email.text,
        address.text,
      );
      if (resp.success) {
        await _load();
        if (mounted)
        showSuccessToast(context, "Customer updated successfully!");
      } else {
        if (mounted)
        showErrorToast(context, 'Update failed: ${resp.message}');
      }
    } catch (e) {
      if (mounted)
      showErrorToast(context, 'Error: $e');
    }
  }

  Future<void> _deleteCustomer(CustomerDTO c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${c.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final resp = await _api.deleteCustomer(c.id);
      if (resp.success) {
        await _load();
        if (mounted)
        showSuccessToast(context, "Customer deleted successfully!");
      } else {
        if (mounted)
        showErrorToast(context, 'Delete failed: ${resp.message}');
      }
    } catch (e) {
      if (mounted)
      showErrorToast(context, 'Error: $e');
    }
  }

  List<CustomerDTO> _pageItems() {
    final total = _store.filteredCount;
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= total) return [];
    final end = (start + _rowsPerPage) > total ? total : (start + _rowsPerPage);
    return _store.getRange(start, end);
  }

  int _totalPages() {
    final total = _store.filteredCount;
    return total == 0 ? 1 : ((total / _rowsPerPage).ceil());
  }

  String _pageRangeText() {
    final total = _store.filteredCount;
    if (total == 0) return '0-0 of 0';
    final start = (_currentPage - 1) * _rowsPerPage + 1;
    final end = (_currentPage * _rowsPerPage) < total
        ? (_currentPage * _rowsPerPage)
        : total;
    return '$start-$end of $total';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        title: const Text('View Customers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color.fromRGBO(0, 140, 192, 1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search...',
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Table area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // leave room for footer
                  const footerHeight = 72.0; // approx
                  final tableHeight = constraints.maxHeight - footerHeight;
                  final double nameColWidth = isMobile
                      ? 140
                      : (isTablet ? 180 : 220);
                  final double rightAreaWidth = isMobile
                      ? 640
                      : (isTablet ? 760 : 900);

                  final items = _pageItems();

                  Widget nameTable(double height) => SizedBox(
                    width: nameColWidth,
                    height: height,
                    child: DataTable2(
                      columns: [
                        DataColumn2(
                          label: Text(
                            'Customer Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade50,
                      ),
                      minWidth: nameColWidth,
                      rows: items
                          .map((c) => DataRow(cells: [DataCell(Text(c.name))]))
                          .toList(),
                    ),
                  );

                  Widget otherTable(double height) => SizedBox(
                    width: rightAreaWidth,
                    height: height,
                    child: DataTable2(
                      columns: [
                        DataColumn2(
                          size: ColumnSize.M,
                          label: Text(
                            'Mobile Number',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        DataColumn2(
                          size: ColumnSize.M,
                          label: Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        DataColumn2(
                          size: ColumnSize.L,
                          label: Text(
                            'Address',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        DataColumn2(
                          size: ColumnSize.S,
                          label: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade50,
                      ),
                      minWidth: rightAreaWidth,
                      columnSpacing: 12,
                      rows: items
                          .map(
                            (c) => DataRow(
                              cells: [
                                DataCell(Text(c.contactNumber)),
                                DataCell(Text(c.email ?? '')),
                                DataCell(Text(c.address ?? '')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        color: Colors.blue,
                                        onPressed: () => _editCustomer(c),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                        ),
                                        color: Colors.red,
                                        onPressed: () => _deleteCustomer(c),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  );

                  // Tablet / Desktop and Mobile: side-by-side (keep Customer Name fixed on the left,
                  // other columns horizontally scrollable on the right). User requested the mobile
                  // view behave like tablet view (no stacked name column), so we render the same layout
                  // for all screen sizes.
                  return Container(
                    height: tableHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromRGBO(238, 238, 238, 1),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        nameTable(tableHeight),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: otherTable(tableHeight),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer (fixed)
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  // Left: takes remaining space and can shrink if necessary
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Rows per page: '),
                        DropdownButton<int>(
                          value: _rowsPerPage,
                          items: _availableRowsPerPage
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _rowsPerPage = v;
                              _currentPage = 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Right: size to its content so it won't force overflow
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Flexible(
                        child: Text(
                          _pageRangeText(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages()
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // demo data
  List<CustomerDTO> _demoCustomers() {
    return List.generate(
      120,
      (i) => CustomerDTO(
        id: i + 1,
        name: 'John Doe ${i + 1}',
        contactNumber: '98${(10000000 + i).toString().padLeft(7, '0')}',
        email: 'john${i + 1}@example.com',
        address: 'Address ${i + 1}',
      ),
    );
  }
}