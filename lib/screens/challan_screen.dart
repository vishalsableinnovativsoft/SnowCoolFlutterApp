import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/view_challan.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:snow_trading_cool/services/customer_api.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:collection/collection.dart';

enum ChallanMode { received, delivered }

class ChallanScreen extends StatefulWidget {
  final Map<String, dynamic>? challanData;
  final ChallanMode mode;

  const ChallanScreen({super.key, this.challanData, required this.mode});

  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  final ChallanApi _api = ChallanApi();
  final CustomerApi _customerApi = CustomerApi();
  final GoodsApi _goodsApi = GoodsApi();

  late final ChallanMode mode;

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController transporterController = TextEditingController();
  final TextEditingController vehicleDriverDetailsController =
      TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  late final TextEditingController dateController;
  final TextEditingController purchaseOrderNoController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController deliveryDetailsController =
      TextEditingController();
  final TextEditingController depositeNarrationController =
      TextEditingController();

  late DateTime? picked;

  late bool isReceivedChallan = mode == ChallanMode.received;

  String _amounttype = 'Deposite';

  List<GoodsDTO> goods = [];
  bool _goodsLoading = true;

  final List<Map<String, dynamic>> _productEntries = [];
  List<Map<String, dynamic>> _inventoryItemsForReceivedChallan = [];
  bool _showProductTable = false;

  int? selectedCustomerId;
  int? _challanId;
  int? _originalCustomerId;

  final GlobalKey _customerFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isSearching = false;

  String? _vehicleNumberError;
  String? _driverDetailsError;

  bool _loading = false;
  bool _saving = false;

  double? remaining;

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    _amounttype = isReceivedChallan ? 'Returned' : 'Deposite';

    // 1. INSTANT DISPLAY — use data from list row
    if (widget.challanData != null) {
      final data = widget.challanData!;
      _challanId = data['id'] as int?;

      setState(() {
        selectedCustomerId = data['customerId'];
        customerNameController.text = data['customerName'] ?? '';
        locationController.text = data['siteLocation'] ?? '';
      });
    }

    dateController = TextEditingController();

    _loadGoods();
    if (_challanId != null) {
      _loadChallanForEdit();
    }
  }

  @override
  void dispose() {
    customerNameController.dispose();
    locationController.dispose();
    transporterController.dispose();
    vehicleDriverDetailsController.dispose();
    vehicleNumberController.dispose();
    dateController.dispose();
    purchaseOrderNoController.dispose();
    amountController.dispose();
    deliveryDetailsController.dispose();
    depositeNarrationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _loadGoods() async {
    try {
      final list = await _goodsApi.getAllGoods();
      setState(() {
        goods = list;
        _goodsLoading = false;
      });
    } catch (e) {
      showErrorToast(context, "Failed to load goods: $e");
      setState(() => _goodsLoading = false);
    }
  }

  Future<void> _loadChallanForEdit() async {
    _originalCustomerId = selectedCustomerId;

    if (_challanId == null) return;
    setState(() => _loading = true);

    try {
      if (_goodsLoading) {
        await _loadGoods();
      }
      final data = await _api.getChallan(_challanId!, context);
      if (data == null) throw Exception("Not found");

      // final int? newCustomerId = data['customerId'];

      // Handle amount with sign logic
      final dynamic rawAmount = data['returnedAmount'];
      double amountValue = 0.0;

      if (rawAmount is num) {
        amountValue = rawAmount.toDouble();
      } else if (rawAmount is String) {
        amountValue = double.tryParse(rawAmount) ?? 0.0;
      }

      // Determine type based on sign
      if (amountValue < 0) {
        setState(() {
          _amounttype = 'Returned';
          amountController.text = (-amountValue).toStringAsFixed(
            2,
          ); // Show positive value
        });
      } else {
        setState(() {
          _amounttype = 'Deposite';
          amountController.text = amountValue.toStringAsFixed(2);
        });
      }
      String driverName = (data['driverName'] ?? '').toString().trim();
      String driverNumber = (data['driverNumber'] ?? '').toString().trim();

      vehicleDriverDetailsController.text = [
        if (driverName.isNotEmpty) driverName,
        if (driverNumber.isNotEmpty) driverNumber,
      ].join(' - ');

      setState(() {
        selectedCustomerId = data['customerId'];
        _originalCustomerId = selectedCustomerId;
        customerNameController.text = data['customerName'] ?? '';
        locationController.text = data['siteLocation'] ?? '';
        transporterController.text = data['transporter'] ?? '';
        vehicleNumberController.text = data['vehicleNumber'] ?? '';
        vehicleDriverDetailsController.text = [
          if (driverName.isNotEmpty) driverName,
          if (driverNumber.isNotEmpty) driverNumber,
        ].join(' - ');
        // vehicleDriverDetailsController.text =
        //     '${data['driverName']} - ${data['driverNumber']}' ?? '';
        dateController.text = data['date'] ?? '';
        purchaseOrderNoController.text = data['purchaseOrderNo'] ?? '';
        // amountController.text = data['returnedAmount'].toString();
        deliveryDetailsController.text = data['deliveryDetails'] ?? '';
        depositeNarrationController.text = data['depositeNarration'] ?? '';
        remaining = data['runningBalance'] ?? 0.0;

        log(data.toString());

        _productEntries.clear();
        final List items = data['items'] ?? [];
        for (var item in items) {
          final String? name = item['name'] as String?;
          final goodsItem = goods.firstWhereOrNull((g) => g.name == name);
          if (goodsItem == null) continue;

          dynamic srNoRaw = item['srNo'] ?? item['sr_no'];
          String srNoString = '';
          if (srNoRaw is List) {
            srNoString = srNoRaw.map((e) => e.toString().trim()).join('/');
          } else if (srNoRaw is String) {
            srNoString = srNoRaw.trim();
          }

          _productEntries.add({
            'id': item['id'],
            'goods': goodsItem,
            'type': (item['type']?.toString() ?? '').trim(),
            'deliveredQty': item['deliveredQty']?.toString() ?? '00',
            'receivedQty': item['receivedQty']?.toString() ?? '00',
            // 'deliveredQty': (item['deliveredQty']?.toString() ?? '').trim(),
            // 'receivedQty': (item['receivedQty']?.toString() ?? '').trim(),
            'srNo': srNoString,
            'originalItemId': item['id'],
          });
        }

        _showProductTable = _productEntries.isNotEmpty;
      });
    } catch (e) {
      showErrorToast(context, "Failed to load challan");
    } finally {
      setState(() => _loading = false);
    }
  }

  bool get _isFormValid {
    // Reset any previous optional field errors
    setState(() {
      _vehicleNumberError = null;
      _driverDetailsError = null;
    });

    // === Required Fields ===
    if (customerNameController.text.trim().isEmpty) {
      _showError("Customer required");
      return false;
    }
    if (dateController.text.isEmpty) {
      _showError("Date required");
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      _showError("Location required");
      return false;
    }
    if (_productEntries.isEmpty || !_showProductTable) {
      _showError("Add at least one product");
      return false;
    }

    // === Product Entries Validation ===
    for (var e in _productEntries) {
      final goods = e['goods'] as GoodsDTO?;
      if (goods == null) {
        _showError("Select product");
        return false;
      }

      final deliveredQtyStr = (e['deliveredQty'] as String? ?? '').trim();
      final receivedQtyStr = (e['receivedQty'] as String? ?? '').trim();

      final deliveredQty = int.tryParse(deliveredQtyStr);
      final receivedQty = int.tryParse(receivedQtyStr);

      if (mode == ChallanMode.delivered) {
        if (deliveredQty == null || deliveredQty <= 0) {
          _showError("Delivered Qty must be ≥ 1 for ${goods.name}");
          return false;
        }
      }

      if (isReceivedChallan) {
        if (receivedQty == null || receivedQty <= 0) {
          _showError("Received Qty must be ≥ 1 for ${goods.name}");
          return false;
        }
      }
    }

    // Vehicle Number
    final vehicleNum = vehicleNumberController.text.trim();
    if (vehicleNum.isNotEmpty) {
      _validateVehicleNumber(
        vehicleNum,
      ); // This sets _vehicleNumberError if invalid
      if (_vehicleNumberError != null) {
        _showError(_vehicleNumberError!);
        return false;
      }
    }

    // Driver Details
    final driverText = vehicleDriverDetailsController.text.trim();
    if (driverText.isNotEmpty) {
      _validateDriverDetails(
        driverText,
      ); // This sets _driverDetailsError if invalid
      if (_driverDetailsError != null) {
        _showError(_driverDetailsError!);
        return false;
      }
    }

    // Deposit / Returned Amount
    final amountText = amountController.text.trim();
    if (amountText.isNotEmpty) {
      final amount = double.tryParse(amountText);
      if (amount == null || amount < 0) {
        _showError("Please enter a valid amount (≥ 0)");
        return false;
      }
    }

    // Transporter, Delivery Details, PO No., Narration → free text, no validation needed

    return true;
  }

  void _showError(String msg) => showErrorToast(context, msg);

  Future<void> _saveChallanData() async {
    if (!_isFormValid) {
      return;
    }

    setState(() => _saving = true);
    try {
      final createitems = _productEntries.map((e) {
        // final id = e['id'] as int?;
        final goods = e['goods'] as GoodsDTO;
        final rawSrNo = (e['srNo'] as String?)?.trim() ?? '';
        final srNoList = rawSrNo
            .split(RegExp(r'[/,;\\]'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        final Map<String, dynamic> item = {
          // 'id' :id,
          'goodsItemId': goods.id,
          'name': goods.name,
          'type': (e['type'] as String).trim(),
          'deliveredQty': !isReceivedChallan
              ? int.tryParse((e['deliveredQty'] as String).trim())
              : 0,
          'receivedQty': isReceivedChallan
              ? int.tryParse((e['receivedQty'] as String).trim())
              : 0,
          // 'deliveredQty':
          //     int.tryParse((e['deliveredQty'] as String).trim()) ?? 0,
          // 'receivedQty': int.tryParse((e['receivedQty'] as String).trim()) ?? 0,
          'srNo': srNoList,
        };

        // Preserve original item ID for update (especially in Received → edit)
        if (isReceivedChallan) {
          final originalId = e['originalItemId'] ?? e['id'];
          if (originalId != null) item['id'] = originalId;
        }

        return item;
      }).toList();

      final updateItems = _productEntries.map((e) {
        final goods = e['goods'] as GoodsDTO;
        final rawSrNo = (e['srNo'] as String?)?.trim() ?? '';
        final srNoList = rawSrNo
            .split(RegExp(r'[/,;\\]'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        final Map<String, dynamic> item = {
          'id': e['id'],
          'goodsItemId': goods.id,
          'name': goods.name,
          'type': (e['type'] as String).trim(),
          'deliveredQty': !isReceivedChallan
              ? int.tryParse((e['deliveredQty'] as String).trim())
              : 0,
          'receivedQty': isReceivedChallan
              ? int.tryParse((e['receivedQty'] as String).trim())
              : 0,
          // 'deliveredQty':
          //     int.tryParse((e['deliveredQty'] as String).trim()) ?? 0,
          // 'receivedQty': int.tryParse((e['receivedQty'] as String).trim()) ?? 0,
          'srNo': srNoList,
        };

        return item;
      }).toList();

      final driverText = vehicleDriverDetailsController.text.trim();
      final parts = driverText.split('-').map((e) => e.trim()).toList();
      final driverName = parts.isNotEmpty ? parts[0] : '';
      final driverNumber = parts.length > 1
          ? parts.sublist(1).join('').replaceAll(RegExp(r'[^0-9]'), '')
          : '';

      final challanType = isReceivedChallan ? "RECEIVED" : "DELIVERED";

      // Parse and apply sign based on dropdown selection
      final String amountText = amountController.text.trim();
      final double enteredAmount = double.tryParse(amountText) ?? 0.0;
      final double signedAmount = _amounttype == "Returned"
          ? -enteredAmount
          : enteredAmount;

      final success = _challanId == null
          ? await _api.createChallan(
              customerId: selectedCustomerId,
              customerName: customerNameController.text.trim(),
              challanType: challanType,
              location: locationController.text.trim(),
              transporter: transporterController.text.trim(),
              vehicleNumber: vehicleNumberController.text.trim().toUpperCase(),
              driverName: driverName,
              driverNumber: driverNumber,
              items: createitems,
              // receivedChallanNos: _receivedChallanNos,
              date: dateController.text,
              purchaseOrderNo: purchaseOrderNoController.text.trim().isEmpty
                  ? ''
                  : purchaseOrderNoController.text.trim(),
              // deposite: double.tryParse(
              //   depositeController.text.trim().isEmpty
              //       ? '0'
              //       : depositeController.text.trim(),
              // ),
              // returnedAmount: double.tryParse(
              //   returnedAmountController.text.trim().isEmpty
              //       ? '0'
              //       : returnedAmountController.text.trim(),
              // ),
              returnedAmount: signedAmount,
              deposite: remaining,
              deliveryDetails: deliveryDetailsController.text.trim(),
              depositeNarration: depositeNarrationController.text.trim().isEmpty
                  ? ''
                  : depositeNarrationController.text.trim(),
              context: context,
            )
          : await _api.updateChallan(
              challanId: _challanId!,
              customerId: selectedCustomerId,
              customerName: customerNameController.text.trim(),
              challanType: challanType,
              location: locationController.text.trim(),
              transporter: transporterController.text.trim(),
              vehicleNumber: vehicleNumberController.text.trim().toUpperCase(),
              driverName: driverName,
              driverNumber: driverNumber,
              items: updateItems,
              date: dateController.text,
              deliveryDetails: deliveryDetailsController.text.trim(),
              purchaseOrderNo: purchaseOrderNoController.text.trim().isEmpty
                  ? ''
                  : purchaseOrderNoController.text.trim(),
              // deposite: double.tryParse(
              //   depositeController.text.trim().isEmpty
              //       ? '0'
              //       : depositeController.text.trim(),
              // ),
              // returnedAmount: double.tryParse(
              //   returnedAmountController.text.trim().isEmpty
              //       ? '0'
              //       : returnedAmountController.text.trim(),
              // ),
              returnedAmount: signedAmount,
              deposite: remaining,
              depositeNarration: depositeNarrationController.text.trim().isEmpty
                  ? ''
                  : depositeNarrationController.text.trim(),
              context: context,
            );

      if (!mounted) return;

      if (success) {
        showSuccessToast(
          context,
          _challanId == null
              ? "Challan created successfully!"
              : "Challan updated!",
        );
        if (_challanId == null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ViewChallanScreen()),
            (route) => false,
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        // showErrorToast(context, "Failed to save challan");
        debugPrint("Challan save failed — error already shown to user");
      }
    } catch (e) {
      log("Save error: $e");
      showErrorToast(context, "Error: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addEmptyRow() {
    setState(() {
      _productEntries.add({
        'goods': null,
        'type': '',
        // 'deliveredQty': '',
        'deliveredQty': isReceivedChallan ? '0' : '',
        'receivedQty': isReceivedChallan ? '' : '0',
        'srNo': '',
      });
      _showProductTable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = EdgeInsets.symmetric(
      horizontal: size.width * 0.04,
      vertical: 8,
    );
    final isEditMode = _challanId != null;
    final title = isReceivedChallan ? "Received" : "Delivered";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditMode ? "Edit $title Challan Entry" : "$title Challan Entry",
        ),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      body: GestureDetector(
        onTap: () {
          _removeOverlay();
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: padding,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCustomerSearchField(isEditMode),
                            const SizedBox(height: 8),
                            Text(
                              "Challan Type",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color.fromRGBO(20, 20, 20, 1),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color.fromRGBO(156, 156, 156, 1),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.all(10),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "$title Challan",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: "Date",
                              required: true,
                              controller: dateController,
                              enabled: !isEditMode,
                              hint: "2025-11-29",
                              prefixIcon: const Icon(Icons.calendar_month),
                              maxlines: 1,
                              onTap: () async {
                                picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2005),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: AppColors
                                              .accentBlue, // Header background & selected day
                                          onPrimary: Colors
                                              .white, //  Text on header & selected day
                                          surface:
                                              Colors.white, //Calendar background
                                          onSurface: Colors.black87, //Normal text
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors
                                                .accentBlue, // OK / Cancel buttons
                                            textStyle: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  dateController.text = picked!
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0];
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: 'Site Location',
                              required: true,
                              enabled: true,
                              controller: locationController,
                              hint: "Enter Site location",
                              maxlines: 1,
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: 'Vehicle Number',
                              enabled: true,
                              controller: vehicleNumberController,
                              hint: "MH12AB1234",
                              onChanged: _validateVehicleNumber,
                              errorText: _vehicleNumberError,
                              inputFormatters: [UpperCaseTextFormatter()],
                              maxlines: 1,
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: 'Transporter',
                              enabled: true,
                              controller: transporterController,
                              hint: "Enter Transporter Details",
                              maxlines: 1,
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: 'Driver Details',
                              enabled: true,
                              controller: vehicleDriverDetailsController,
                              hint: "Name - 9876543210",
                              onChanged: _validateDriverDetails,
                              errorText: _driverDetailsError,
                              maxlines: 1,
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: "Delivery Details",
                              controller: deliveryDetailsController,
                              hint: "Gate/Floor",
                              maxlines: 3,
                              enabled: true,
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: "PO No.",
                              controller: purchaseOrderNoController,
                              hint: "Purchase order number (if any)",
                              enabled: true,
                              maxlines: 1,
                            ),
                            const SizedBox(height: 12),
                            _buildDepositeAmountField(
                              onChanged: (value) {},
                              controller: amountController,
                              // controller: isReceivedChallan
                              //     ? returnedAmountController
                              //     : depositeController,
                              hint: "0.00",
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              enabled: true,
                              maxlines: 1,
                              // errorText:
                              //     isReceivedChallan && !_isReturnedAmountValid
                              //     ? _returnedAmountError
                              //     : null,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                                TextInputFormatter.withFunction((old, newVal) {
                                  if (newVal.text.isEmpty) return newVal;
                                  final parts = newVal.text.split('.');
                                  if (parts.length > 2 ||
                                      (parts.length == 2 && parts[1].length > 2)) {
                                    return old;
                                  }
                                  return newVal;
                                }),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: "Deposit Narration",
                              enabled: true,
                              controller: depositeNarrationController,
                              maxlines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildProductTable(),
                          ],
                        ),
                      ),
                    ),
                    _buildActionButtons(isEditMode),
                  ],
                ),
              ),
            ),
            if (_loading || _goodsLoading || _saving) customLoader(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSearchField(bool isEditMode) {
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
          enabled: !isEditMode,
          cursorColor: AppColors.accentBlue,
          key: _customerFieldKey,
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
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentBlue,
                    ),
                  )
                : const Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ],
    );
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

  void _validateVehicleNumber(String value) {
    final cleaned = value.trim().toUpperCase();
    final p1 = RegExp(r'^[A-Z]{2}\d{1,2}[A-Z]{1,2}\d{4}$');
    final p2 = RegExp(r'^\d{2}BH\d{4}[A-Z]{1,2}$');

    setState(() {
      if (cleaned.isEmpty) {
        _vehicleNumberError = null;
      } else if (p1.hasMatch(cleaned) || p2.hasMatch(cleaned)) {
        _vehicleNumberError = null;
        if (value != cleaned) {
          vehicleNumberController.text = cleaned;
          vehicleNumberController.selection = TextSelection.fromPosition(
            TextPosition(offset: cleaned.length),
          );
        }
      } else {
        _vehicleNumberError = 'Vehicle Number Format: MH12AB1234 or 22BH1234AA';
      }
    });
  }

  void _validateDriverDetails(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _driverDetailsError = 'Driver name and number required';
      });
      return;
    }

    if (!trimmed.contains('-')) {
      setState(() {
        _driverDetailsError =
            'Driver Details Format: Driver Name - Mobile Number';
      });
      return;
    }

    final parts = trimmed.split('-').map((e) => e.trim()).toList();
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      setState(() {
        _driverDetailsError = 'Enter name and number separated by -';
      });
      return;
    }

    final numberPart = parts[1].replaceAll(
      RegExp(r'\D'),
      '',
    ); // Remove non-digits
    if (numberPart.length != 10) {
      setState(() {
        _driverDetailsError = 'Mobile number must be exactly 10 digits';
      });
      return;
    }

    // Valid
    setState(() {
      _driverDetailsError = null;
    });
  }

  Widget _buildDepositeAmountField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? errorText,
    required bool enabled,
    Future<Null> Function()? onTap,
    // Icon? prefixIcon,
    int? maxlines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isReceivedChallan ? "Returned Amount (₹)" : "Deposit Amount (₹)",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(20, 20, 20, 1),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              height: 56,
              width: 130,
              child: DropdownButtonFormField<String>(
                initialValue: _amounttype,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.accentBlue,
                      width: 2,
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: "Returned", child: Text("Returned")),
                  DropdownMenuItem(value: "Deposite", child: Text("Deposite")),
                ],
                onChanged: enabled
                    ? (value) {
                        setState(() {
                          _amounttype = value!;
                        });
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Amount Field
            Expanded(
              child: SizedBox(
                height: 56,
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onChanged: (value) {
                    onChanged?.call(value);
                    // _validateReturnedAmount();
                  },
                  enabled: enabled,
                  onTap: onTap,
                  readOnly: onTap != null,
                  maxLines: maxlines,
                  decoration: InputDecoration(
                    prefixText: _amounttype == "Returned" ? "- ₹" : "+ ₹",
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Color.fromRGBO(156, 156, 156, 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color.fromRGBO(156, 156, 156, 1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.accentBlue,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: errorText,
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Show remaining balance
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Remaining Balance: ₹${remaining?.toStringAsFixed(2) ?? '0.00'}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    bool? required,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? errorText,
    required bool enabled,
    Future<Null> Function()? onTap,
    Icon? prefixIcon,
    int? maxlines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(20, 20, 20, 1),
              ),
            ),
            if (required == true) const SizedBox(width: 4),
            if (required == true)
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
          cursorColor: AppColors.accentBlue,
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          enabled: enabled,
          onTap: onTap,
          maxLines: maxlines,
          readOnly: onTap != null,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            prefixIcon: prefixIcon,
            hintText: hint,
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
                color: enabled
                    ? const Color.fromRGBO(156, 156, 156, 1)
                    : Colors.grey.shade300,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTable() {
    final bool showReceivedQty = isReceivedChallan;

    final screenWidth = MediaQuery.of(context).size.width;
    const double mobileMax = 600; // phones
    const double tabletMax = 1024; // tablets / small laptops

    // Determine device type / size category
    // bool isMobile = screenWidth < mobileMax;
    // bool isTablet = screenWidth >= mobileMax && screenWidth < tabletMax;

    Map<int, TableColumnWidth> columnWidths;

    if (screenWidth < mobileMax) {
      // Mobile (your original values)
      columnWidths = {
        0: const FixedColumnWidth(180),
        1: const FixedColumnWidth(140),
        2: const FixedColumnWidth(130),
        if (showReceivedQty) 3: const FixedColumnWidth(130),
        if (showReceivedQty) 4: const FixedColumnWidth(130),
        if (showReceivedQty) 5: const FixedColumnWidth(70),
        if (!showReceivedQty) 3: const FixedColumnWidth(130),
        if (!showReceivedQty) 4: const FixedColumnWidth(70),
      };
    } else if (screenWidth < tabletMax) {
      // Tablet – slightly wider columns
      columnWidths = {
        0: const FixedColumnWidth(180),
        1: const FixedColumnWidth(140),
        2: const FixedColumnWidth(130),
        if (showReceivedQty) 3: const FixedColumnWidth(130),
        if (showReceivedQty) 4: const FixedColumnWidth(130),
        if (showReceivedQty) 5: const FixedColumnWidth(70),
        if (!showReceivedQty) 3: const FixedColumnWidth(130),
        if (!showReceivedQty) 4: const FixedColumnWidth(70),
      };
    } else {
      // Desktop/large screen – most spacious
      columnWidths = {
        0: const FixedColumnWidth(310),
        1: const FixedColumnWidth(300),
        2: const FixedColumnWidth(260),
        if (showReceivedQty) 3: const FixedColumnWidth(260),
        if (showReceivedQty) 4: const FixedColumnWidth(260),
        if (showReceivedQty) 5: const FixedColumnWidth(210),
        if (!showReceivedQty) 3: const FixedColumnWidth(260),
        if (!showReceivedQty) 4: const FixedColumnWidth(200),
      };
    }

    if (goods.isEmpty) return const Center(child: Text("No goods available"));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mode == ChallanMode.delivered)
          const Text(
            "Products",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 12),

        if (!_showProductTable)
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showProductTable = true;
                  if (_productEntries.isEmpty) _addEmptyRow();
                });
              },
              icon: const Icon(Icons.add_box_rounded),
              label: const Text("Insert Products"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accentBlue,
                side: const BorderSide(color: AppColors.accentBlue, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),

        if (_showProductTable)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  columnWidths: columnWidths,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(238, 238, 238, 1),
                      ),
                      children: [
                        _headerCell('Product', true),
                        _headerCell('Type', false),
                        _headerCell('Delivered Qty', true),
                        if (showReceivedQty) _headerCell('Received Qty', true),
                        _headerCell('Sr. No', false),
                        _headerCell("Action", false),
                      ],
                    ),
                    ..._productEntries.asMap().entries.map((e) {
                      final index = e.key;
                      final entry = e.value;
                      final selectedGoods = entry['goods'] as GoodsDTO?;
                      final bool isEvenRow = index % 2 == 0;
                      final String type =
                          (entry['type'] as String?)?.trim() ?? '';
                      final String deliveredQtyStr =
                          (entry['deliveredQty'] as String?)?.trim() ?? '';
                      final String receivedQtyStr =
                          (entry['receivedQty']?.toString() ?? '').trim();
                      final String srNoStr =
                          (entry['srNo'] as String?)?.trim() ?? '';

                      final int? deliveredQty = deliveredQtyStr.isEmpty
                          ? null
                          : int.tryParse(deliveredQtyStr);
                      final int? receivedQty = receivedQtyStr.isEmpty
                          ? null
                          : int.tryParse(receivedQtyStr);

                      return TableRow(
                        decoration: BoxDecoration(
                          color: isEvenRow ? Colors.white : Colors.grey.shade50,
                        ),
                        children: [
                          // Product
                          _editableCell(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                // color: Color.fromRGBO(156, 156, 156, 1),
                                border: Border.all(
                                  color: Color.fromRGBO(156, 156, 156, 1),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<GoodsDTO>(
                                  dropdownColor: Colors.white,
                                  isExpanded: true,
                                  hint: const Text(
                                    "Select Product *",
                                    // style: TextStyle(color: Colors.red),
                                  ),
                                  value: selectedGoods,
                                  items: goods
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(g.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (GoodsDTO? selectedGoods) {
                                    if (selectedGoods == null) {
                                      entry['goods'] = null;
                                      entry['type'] = '';
                                      entry['deliveredQty'] = isReceivedChallan
                                          ? '0'
                                          : '';
                                      entry['srNo'] = '';
                                      entry['originalItemId'] = null;
                                    } else {
                                      // Look for matching pending item
                                      final matchingPending =
                                          _inventoryItemsForReceivedChallan
                                              .firstWhereOrNull(
                                                (pending) =>
                                                    pending['goods']?.id ==
                                                    selectedGoods.id,
                                              );

                                      setState(() {
                                        entry['goods'] = selectedGoods;

                                        if (isReceivedChallan &&
                                            matchingPending != null) {
                                          entry['type'] =
                                              matchingPending['type'] ?? '';
                                          entry['deliveredQty'] =
                                              matchingPending['deliveredQty'] ??
                                              '0';
                                          entry['srNo'] =
                                              matchingPending['srNo'] ?? '';
                                          entry['originalItemId'] =
                                              matchingPending['originalItemId'];
                                        } else {
                                          // For Delivered mode or no match → leave blank or default
                                          entry['type'] = '';
                                          entry['deliveredQty'] =
                                              isReceivedChallan ? '0' : '';
                                          entry['srNo'] = '';
                                          entry['originalItemId'] = null;
                                        }
                                      });
                                    }
                                  },
                                  // onChanged: (value) =>
                                  //     setState(() => entry['goods'] = value),
                                ),
                              ),
                            ),
                          ),

                          // Type
                          _editableCell(
                            child: TextField(
                              controller: type.isNotEmpty
                                  ? (TextEditingController(text: type)
                                      ..selection = TextSelection.fromPosition(
                                        TextPosition(offset: type.length),
                                      ))
                                  : null,
                              cursorColor: AppColors.accentBlue,
                              maxLines: 1,
                              decoration: InputDecoration(
                                hintText: "Type",
                                isDense: true,
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: const Color.fromRGBO(
                                      156,
                                      156,
                                      156,
                                      1,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
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
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (v) =>
                                  setState(() => entry['type'] = v),
                            ),
                          ),

                          // deliveredQty
                          _editableCell(
                            child: Builder(
                              builder: (context) {
                                final String displayText = isReceivedChallan
                                    ? (entry['deliveredQty']?.toString() ?? '0')
                                    : (entry['deliveredQty']?.toString() ?? '');

                                final controller = TextEditingController(
                                  text: displayText,
                                );
                                controller
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(offset: controller.text.length),
                                );

                                return TextField(
                                  controller: controller,
                                  cursorColor: AppColors.accentBlue,
                                  keyboardType: TextInputType.number,
                                  enabled: mode == ChallanMode.delivered,
                                  readOnly: isReceivedChallan,
                                  style: TextStyle(
                                    color: isReceivedChallan
                                        ? Colors.grey.shade700
                                        : null,
                                    fontWeight: isReceivedChallan
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    hintText: isReceivedChallan
                                        ? "0"
                                        : "Delivered Qty *",
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.accentBlue,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: mode == ChallanMode.delivered
                                      ? (v) => setState(
                                          () => entry['deliveredQty'] = v,
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                          // Received deliveredQty
                          if (showReceivedQty)
                            _editableCell(
                              child: Builder(
                                builder: (context) {
                                  final controller = TextEditingController(
                                    text: receivedQtyStr,
                                  );
                                  controller
                                      .selection = TextSelection.fromPosition(
                                    TextPosition(offset: receivedQtyStr.length),
                                  );
                                  return TextField(
                                    controller: controller,
                                    cursorColor: AppColors.accentBlue,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                      hintText: "Received Qty *",
                                      isDense: true,
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.red,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: const Color.fromRGBO(
                                            156,
                                            156,
                                            156,
                                            1,
                                          ),
                                        ),
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
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
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.red,
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 14,
                                          ),
                                      errorText:
                                          selectedGoods != null &&
                                              (receivedQty == null ||
                                                  receivedQty <= 0)
                                          ? 'Invalid'
                                          : null,
                                    ),
                                    onChanged: (v) => setState(
                                      () => entry['receivedQty'] = v,
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Sr. No
                          _editableCell(
                            child: TextField(
                              cursorColor: AppColors.accentBlue,
                              controller: srNoStr.isNotEmpty
                                  ? (TextEditingController(text: srNoStr)
                                      ..selection = TextSelection.fromPosition(
                                        TextPosition(offset: srNoStr.length),
                                      ))
                                  : null,
                              maxLines: 1,
                              inputFormatters: [UpperCaseTextFormatter()],
                              decoration: InputDecoration(
                                hintText: "Sr No",
                                isDense: true,
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: const Color.fromRGBO(
                                      156,
                                      156,
                                      156,
                                      1,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
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
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (v) =>
                                  setState(() => entry['srNo'] = v),
                            ),
                          ),
                          // Action

                          // Action Column - Remove Row
                          _editableCell(
                            child: Center(
                              child: IconButton(
                                onPressed: _productEntries.length > 1
                                    ? () {
                                        setState(() {
                                          _productEntries.removeAt(index);
                                        });
                                        showErrorToast(
                                          context,
                                          "Product Deleted",
                                        );
                                      }
                                    : null,
                                icon: Icon(
                                  Icons.delete_forever,
                                  color: _productEntries.length > 1
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                  size: 26,
                                ),
                                tooltip: _productEntries.length > 1
                                    ? "Remove this row"
                                    : "At least one product required",
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),

        if (_showProductTable) const SizedBox(height: 16),
        if (_showProductTable)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _addEmptyRow,
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              label: const Text(
                "Add Product",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _headerCell(String text, bool? required) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (required == true) const SizedBox(width: 4),
        if (required == true)
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
  );

  Widget _editableCell({required Widget child}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: child,
  );

  get returnedAmount => null;

  Widget _buildActionButtons(bool isEditMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _clearAllFields,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accentBlue, width: 2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    "Reset",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _saving ? null : _saveChallanData,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.accentBlue,
                ),
                child: Center(
                  child: Text(
                    isEditMode ? "Update" : "Save",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFields() {
    setState(() {
      _loading = false;
      _saving = false;
      _challanId = null;
      selectedCustomerId = null;
      customerNameController.clear();
      locationController.clear();
      transporterController.clear();
      vehicleDriverDetailsController.clear();
      vehicleNumberController.clear();
      purchaseOrderNoController.clear();
      dateController.clear();
      amountController.clear();
      // depositeController.clear();
      // returnedAmountController.clear();
      depositeNarrationController.clear();
      deliveryDetailsController.clear();
      _showProductTable = false;
      _productEntries.clear();
      dateController.text = DateTime.now().toIso8601String().split('T').first;
      _vehicleNumberError = null;
      _driverDetailsError = null;
      remaining = 0;
      picked = null;
      _inventoryItemsForReceivedChallan = [];
    });
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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

  void selectCustomer(CustomerDTO customer) async {
    setState(() {
      selectedCustomerId = customer.id;
      customerNameController.text = customer.name;
      _originalCustomerId = customer.id;
      remaining = customer.runningBalance;
    });

    _removeOverlay();

    if (isReceivedChallan) {
      setState(() => _loading = true);

      final inventoryItems = await _api.getCustomerPendingInventoryItems(
        customer.id,
        context,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (inventoryItems == null) {
        showErrorToast(context, "Failed to load customer inventory");
        _inventoryItemsForReceivedChallan = [];
        return;
      }

      if (inventoryItems.isEmpty) {
        // showInfoToast(context, "No pending items to receive for this customer");
        _inventoryItemsForReceivedChallan = [];
        return;
      }

      // Store in memory, but DO NOT auto-add to table
      _inventoryItemsForReceivedChallan = inventoryItems
          .map((item) {
            final String name = item['name'] ?? '';
            final GoodsDTO? goodsItem = goods.firstWhereOrNull(
              (g) => g.name == name,
            );

            String srNoStr = '';
            final srNoRaw = item['srNo'];
            if (srNoRaw is List && srNoRaw.isNotEmpty) {
              srNoStr = srNoRaw.map((e) => e.toString().trim()).join('/');
            }

            return {
              'goods': goodsItem,
              'type': (item['type']?.toString() ?? '').trim(),
              'deliveredQty': item['deliveredQty'].toString(),
              'srNo': srNoStr,
              'originalItemId': item['id'],
            };
          })
          .where((item) => item['goods'] != null)
          .toList();
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
