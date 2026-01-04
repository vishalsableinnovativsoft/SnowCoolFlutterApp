import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/mobileinputformater.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../services/customer_api.dart';

class CreateCustomerScreen extends StatefulWidget {
  final int? customerId;
  const CreateCustomerScreen({super.key, this.customerId});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  bool get _isEditMode => widget.customerId != null;

  CustomerDTO? _fetchedCustomer;
  bool _customerLoading = false;

  // final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final depositOpeningBalanceController = TextEditingController();
  bool _isLoading = false;
  final CustomerApi _api = CustomerApi();
  String? setReminder = 'None';

  // Local controllers/state for each row
  final TextEditingController qtyController = TextEditingController();
  String? selectedSign = 'Del'; // default +

  // Add this map to store sign and qty for each goods
  final Map<String, String> _goodsSignMap = {}; // goods.id → "+" or "-"
  final Map<String, String> _goodsQtyMap = {}; // goods.id → "10"
  final Map<String, TextEditingController> _qtyControllers = {};

  List<GoodsDTO> allGoods = [];
  bool _goodsLoading = true;
  // final List<Map<String, dynamic>> _productEntries = [];
  // List<GoodsDTO> goods = [];

  bool challanTypeSelected = true;

  // Error messages state
  String? _nameError;
  String? _mobileError;
  String? _emailError;
  String? _addressError;

  @override
  void dispose() {
    depositOpeningBalanceController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _qtyControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      _fetchCustomerDetails();
    } else {
      _fetchGoods();
    }

   
  }

  Future<void> _fetchCustomerDetails() async {
    try {
      setState(() {
        _customerLoading = true;
        _isLoading = true;
      });

      final CustomerResponse apiResponse = await _api.getCustomerById(
        widget.customerId!.toString(),
      );

      CustomerDTO customer;

      if (apiResponse.data != null) {
        customer = apiResponse.data!;
      } else {
        throw Exception(
          "Direct parsing not supported yet in current API wrapper",
        );
      }

      setState(() {
        _fetchedCustomer = customer;

        _nameController.text = customer.name;
        _mobileController.text = customer.contactNumber;
        _emailController.text = customer.email ?? '';
        _addressController.text = customer.address ?? '';
        depositOpeningBalanceController.text = (customer.deposite ?? 0.0)
            .toStringAsFixed(2);
        setReminder = customer.reminder ?? 'None';

        if (customer.items != null && customer.items!.isNotEmpty) {
          for (var item in customer.items!) {
            final String? idStr = item['goodsItemId']?.toString();
            if (idStr == null || idStr.isEmpty) continue;

            final num delivered = item['deliveredQty'] as num? ?? 0;
            final num received = item['receivedQty'] as num? ?? 0;
            final int totalQty = (delivered + received).toInt();

            String sign = 'Del';
            if (delivered > 0 && received == 0) {
              sign = 'Del';
            } else if (received > 0 && delivered == 0) {
              sign = 'Rec';
            }

            _goodsSignMap[idStr] = sign;

            final controller = TextEditingController(
              text: totalQty > 0 ? totalQty.toString() : '',
            );
            _qtyControllers[idStr] = controller;
          }
        }

        _customerLoading = false;
        _isLoading = false;
      });

      _fetchGoods();
    } catch (e) {
      debugPrint("Customer load error: $e");
      if (mounted) {
        showErrorToast(context, "Failed to load customer details");
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _customerLoading = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchGoods() async {
    try {
      setState(() => _goodsLoading = true);
      final List<GoodsDTO> fetchedGoods = await GoodsApi().getAllGoods();
      if (!mounted) return;
      setState(() {
        allGoods = fetchedGoods;
        _goodsLoading = false;

        for (var goods in fetchedGoods) {
          final id = goods.id.toString();

          _goodsSignMap.putIfAbsent(id, () => 'Del');
          _goodsQtyMap.putIfAbsent(id, () => '');

          _qtyControllers.putIfAbsent(id, () => TextEditingController());
        }
      });
    } catch (e) {
      if (!mounted) return;
      // showErrorToast(context, 'Failed to fetch goods: $e');
      setState(() => _goodsLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _mobileController.clear();
      _emailController.clear();
      _addressController.clear();
      depositOpeningBalanceController.clear();

      setReminder = 'None';

      _nameError = _mobileError = _emailError = _addressError = null;

      for (var id in _qtyControllers.keys) {
        _qtyControllers[id]!.clear();
        _goodsQtyMap[id] = '';
        _goodsSignMap[id] = 'Del';
      }
    });

    showSuccessToast(context, "Form reset successfully");
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    final cleaned = value.trim();
    if (cleaned.length != 10) {
      return 'Mobile number must be 10 digits';
    }
    if (!RegExp(r'^[5-9]\d{9}$').hasMatch(cleaned)) {
      return 'Mobile must start with 5, 6, 7, 8, or 9';
    }
    return null;
  }

  // Email validator
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final email = value.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Auto-convert email to lowercase
  void _onEmailChanged(String value) {
    final lower = value.toLowerCase();
    if (value != lower) {
      _emailController.value = TextEditingValue(
        text: lower,
        selection: TextSelection.collapsed(offset: lower.length),
      );
    }
    _updateEmailError(lower);
  }

  void _updateNameError(String value) {
    final trimmed = value.trim();
    setState(() {
      if (trimmed.isEmpty) {
        _nameError = 'Please enter customer name';
      } else if (trimmed.length == 1) {
        _nameError = 'Customer name must be more than 1 character';
      } else {
        _nameError = null;
      }
    });
  }

  void _updateMobileError(String value) {
    setState(() {
      _mobileError = _validateMobile(value);
    });
  }

  void _updateEmailError(String value) {
    setState(() {
      _emailError = _validateEmail(value);
    });
  }

  void _updateAddressError(String value) {
    setState(() {
      _addressError = value.trim().isEmpty ? 'Please enter address' : null;
    });
  }

  bool _isFormValid() {
    return _nameError == null &&
        _mobileError == null &&
        _emailError == null &&
        _addressError == null &&
        _nameController.text.trim().isNotEmpty &&
        _mobileController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
  }

  Future<void> _submitCustomer() async {
    final nameTrimmed = _nameController.text.trim();
    // Reset errors first
    setState(() {
      if (nameTrimmed.isEmpty) {
        _nameError = 'Please enter customer name';
      } else if (nameTrimmed.length == 1) {
        _nameError = 'Customer name must be more than 1 character';
      } else {
        _nameError = null;
      }
      _mobileError = _validateMobile(_mobileController.text);
      _emailError = _validateEmail(_emailController.text);
      _addressError = _addressController.text.trim().isEmpty
          ? 'Please enter address'
          : null;
    });

    // If any required field has error → stop
    if (_nameError != null ||
        _mobileError != null ||
        _emailError != null ||
        _addressError != null) {
      showErrorToast(context, "Please fill all required fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Inside _submitCustomer() method, replace the goods preparation part with this:

      final List<Map<String, dynamic>> selectedGoods = [];
      for (var goods in allGoods) {
        final String id = goods.id.toString();
        final String qtyText = _qtyControllers[id]?.text.trim() ?? '';
        final int? qty = int.tryParse(qtyText);

        if (qty != null && qty > 0) {
          String sign = _goodsSignMap[id] ?? 'Del';

          // IMPORTANT: Set deliveredQty or receivedQty based on sign
          int deliveredQty = (sign == 'Del') ? qty : 0;
          int receivedQty = (sign == 'Rec') ? qty : 0;

          selectedGoods.add({
            'goodsItemId': goods.id,
            'name': goods.name,
            'sign': sign,
            'deliveredQty': deliveredQty,
            'receivedQty': receivedQty,
          });
        }
      }

      debugPrint("Sending goods with correct qty split: $selectedGoods");
      // Prepare deposit (optional)
      final double? deposit = double.tryParse(
        depositOpeningBalanceController.text.trim(),
      );
      final double? depositAmount = (deposit == null || deposit == 0)
          ? 00
          : deposit;

      final String reminderType = setReminder ?? 'None';

      if (_isEditMode) {
        final response = await _api.updateCustomer(
          id: widget.customerId!,
          name: _nameController.text.trim(),
          contactNumber: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          reminder: reminderType,
          deposite: depositAmount,
          items: selectedGoods.isEmpty ? null : selectedGoods,
        );

        if (response.success) {
          showSuccessToast(context, "Customer updated successfully!");
          Navigator.pop(context, true);
        } else {
          showErrorToast(context, response.message ?? "Update failed");
        }
      } else {
        // Call API

        await _api.createCustomer(
          context: context,
          name: _nameController.text.trim(),
          contactNumber: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          reminder: reminderType,
          deposite: depositAmount,
          items: selectedGoods.isEmpty ? null : selectedGoods,
        );
      }
    } catch (e) {
      // Only catch unexpected errors (should rarely happen now)
      showErrorToast(context, "Unexpected error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGoodsSelectionTable() {
    if (allGoods.isEmpty) {
      return const Center(child: Text("No goods available"));
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12), //withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine available width and adjust behavior
            final bool isSmallScreen = constraints.maxWidth < 500;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Table(
                  // Use Flex for natural responsiveness
                  defaultColumnWidth: const FlexColumnWidth(),
                  columnWidths: isSmallScreen
                      ? const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1.62),
                          2: FlexColumnWidth(1.3),
                        }
                      : const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1.5),
                        },
                  border: TableBorder.all(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                  children: [
                    // Header
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
                      children: [
                        _headerCell("Product"),
                        _headerCell(isSmallScreen ? "Del/Rec" : "Del / Rec"),
                        _headerCell("Qty"),
                      ],
                    ),

                    // Rows
                    ...allGoods.map((goods) {
                      final String id = goods.id.toString();
                      _qtyControllers.putIfAbsent(
                        id,
                        () => TextEditingController(),
                      );
                      // _goodsSignMap.putIfAbsent(id, () => "+");

                      return TableRow(
                        decoration: BoxDecoration(
                          color: allGoods.indexOf(goods) % 2 == 0
                              ? Colors.white
                              : Colors.grey.shade50,
                        ),
                        children: [
                          // Product Name - wraps on small screens
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: isSmallScreen ? 8 : 12,
                            ),
                            child: Text(
                              goods.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // D/R Dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: SizedBox(
                              height: 42,
                              child: DropdownButtonFormField<String>(
                                dropdownColor: Colors.white,
                                initialValue: _goodsSignMap[id],
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Del',
                                    child: Text(
                                      'Del',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Rec',
                                    child: Text(
                                      'Rec',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _goodsSignMap[id] = v!),
                              ),
                            ),
                          ),

                          // Quantity Field
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: SizedBox(
                              height: 48,
                              child: TextField(
                                controller: _qtyControllers[id],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  hintText: "0",
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: const Color.fromRGBO(
                                        156,
                                        156,
                                        156,
                                        1,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.accentBlue,
                                      width: 2.0,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value.isEmpty) {
                                      _goodsQtyMap[id] = '';
                                    } else {
                                      _goodsQtyMap[id] = value;
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        title: Text(
          _isEditMode ? 'Edit Customer' : 'Create Customer',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditMode
                          ? 'Update customer details'
                          : 'Add a new customer to the system',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
            
                    // Name Field
                    _buildTextField(
                      label: 'Customer Name',
                      controller: _nameController,
                      icon: Icons.person,
                      errorText: _nameError,
                      onChanged: _updateNameError,
                      keyboardType: TextInputType.name,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      ],
                    ),
                    const SizedBox(height: 16),
            
                    // Mobile Field
                    _buildTextField(
                      label: 'Mobile',
                      controller: _mobileController,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      errorText: _mobileError,
                      onChanged: (value) {
                        // Clean value (remove non-digits & leading zeros)
                        final cleaned = value
                            .replaceAll(RegExp(r'\D'), '')
                            .replaceFirst(RegExp(r'^0+'), '');
            
                        // Update error in real-time
                        setState(() {
                          if (cleaned.isEmpty) {
                            _mobileError = 'Please enter mobile number';
                          } else if (cleaned.length != 10) {
                            _mobileError = 'Mobile must be exactly 10 digits';
                          } else if (!RegExp(r'^[5-9]\d{9}$').hasMatch(cleaned)) {
                            _mobileError = 'Must start with 5, 6, 7, 8 or 9';
                          } else {
                            _mobileError = null;
                          }
                        });
                      },
                      inputFormatters: [
                        MobileNumberInputFormatter(),
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 16),
            
                    // Email Field
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: _onEmailChanged,
                    ),
                    const SizedBox(height: 16),
            
                    // Address Field
                    _buildTextField(
                      label: 'Address',
                      controller: _addressController,
                      icon: Icons.location_on,
                      isMultiLine: true,
                      errorText: _addressError,
                      onChanged: _updateAddressError,
                    ),
                    const SizedBox(height: 16),
            
                    // Deposite opening balance
                    _buildTextField(
                      label: 'Deposit Opening Balance',
                      controller: depositOpeningBalanceController,
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        FilteringTextInputFormatter.deny(RegExp(r'\.{2,}')),
                      ],
                      compulsary: false,
                    ),
                    const SizedBox(height: 16),
                    //set reminder
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_alarm,
                                color: AppColors.accentBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Set Reminder",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: isMobile ? screenWidth * 0.4 : 200,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade50,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  value: setReminder,
                                  hint: const Text('Select Type'),
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  items: ['None', 'Daily', 'Weekly', 'Monthly']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => setReminder = value),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            
                    // Goods Selection Table
                    _buildGoodsSelectionTable(),
                    const SizedBox(height: 12),
            
                    // Submit Button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _resetForm();
                            },
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: AppColors.accentBlue),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              "Reset",
                              style: GoogleFonts.inter(
                                color: AppColors.accentBlue,
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitCustomer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                0,
                                140,
                                192,
                                1,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _isEditMode ? 'Update Customer' : 'Create Customer',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading || _goodsLoading || _customerLoading) customLoader(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    bool isMultiLine = false,
    String? errorText,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    bool compulsary = true,
    int? lengthLimit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            if (compulsary)
              Text(
                '*',
                style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: lengthLimit,
          cursorColor: AppColors.accentBlue,
          keyboardType:
              keyboardType ??
              (isMultiLine ? TextInputType.multiline : TextInputType.text),
          maxLines: isMultiLine ? 3 : 1,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : const Color.fromRGBO(0, 140, 192, 1),
              ),
            ),
            errorText: null, // We show error below manually
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
        ),
        // Dynamic Error Message with Animation
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: AnimatedOpacity(
              opacity: errorText.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                errorText,
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (errorText != null) const SizedBox(height: 8),
      ],
    );
  }
}
