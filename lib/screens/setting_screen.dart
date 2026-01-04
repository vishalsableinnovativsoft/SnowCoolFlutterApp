// setting_screen.dart
import 'dart:convert';
import 'dart:io' show File if (dart.library.io) 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:snow_trading_cool/screens/home_screen.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';
import '../services/application_settings_api.dart';
import '../utils/token_manager.dart';

class ProfileApplicationSettingScreen extends StatefulWidget {
  const ProfileApplicationSettingScreen({super.key});

  @override
  State<ProfileApplicationSettingScreen> createState() => _ProfileApplicationSettingScreenState();
}

class _ProfileApplicationSettingScreenState extends State<ProfileApplicationSettingScreen> {
  final ImagePicker picker = ImagePicker();
  bool _isLoading = false;
  bool _isExisting = false;

  // Control editability
  bool _isEditableInvoicePrefix = true;
  bool _isEditableChallanFormat = true;

  XFile? _logoXFile;
  XFile? _signatureXFile;

  String? _logoBase64;
  String? _signatureBase64;

  final TextEditingController _invoicePrefixController = TextEditingController();
  final TextEditingController _challanFormatController = TextEditingController();
  final TextEditingController _challanSequenceController = TextEditingController(text: "1");
  final TextEditingController _termsController = TextEditingController();

  ApplicationSettingsApi? _api;
  ApplicationSettingsDTO? _loadedSettings;

  // Validation
  String? _challanSequenceError;

  // Default values
  static const String _defaultInvoicePrefix = "INV-";
  late final String _defaultChallanFormat = "CH-${DateTime.now().year}-";

  @override
  void initState() {
    super.initState();
    _initApi();
    // _loadUserRole();
  }

  Future<void> _initApi() async {
    setState(() => _isLoading = true);
    final token = TokenManager().getToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        showErrorToast(context, "User not authenticated! Please log in again.");
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _api = ApplicationSettingsApi(token: token));
    await _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    if (_api == null) return;
    setState(() => _isLoading = true);
    try {
      final settings = await _api!.getSettings(context);
      if (settings != null) {
        setState(() {
          _isExisting = true;
          _loadedSettings = settings;

          _invoicePrefixController.text = settings.invoicePrefix ?? "";
          _challanFormatController.text = settings.challanNumberFormat ?? "";
          _challanSequenceController.text = (settings.challanSequence ?? 1).toString();
          _termsController.text = settings.termsAndConditions ?? "";

          _logoBase64 = settings.logoBase64;
          _signatureBase64 = settings.signatureBase64;

          _isEditableInvoicePrefix = true;
          _isEditableChallanFormat = true;

          _validateChallanSequence(_challanSequenceController.text);
        });
      } else {
        setState(() {
          _isExisting = false;
          _loadedSettings = null;
          _logoBase64 = null;
          _signatureBase64 = null;
          _validateChallanSequence("1");
          _isEditableInvoicePrefix = true;
          _isEditableChallanFormat = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, "Failed to load settings: $e");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _validateChallanSequence(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _challanSequenceError = 'Sequence is required');
      return;
    }
    final num = int.tryParse(trimmed);
    if (num == null || num < 1) {
      setState(() => _challanSequenceError = 'Must be a number ≥ 1');
    } else {
      setState(() => _challanSequenceError = null);
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final bytes = kIsWeb
        ? await pickedFile.readAsBytes()
        : await File(pickedFile.path).readAsBytes();

    final base64Str = base64Encode(bytes);

    setState(() {
      if (isLogo) {
        _logoXFile = pickedFile;
        _logoBase64 = base64Str;
      } else {
        _signatureXFile = pickedFile;
        _signatureBase64 = base64Str;
      }
    });
  }

  void _resetSequence() {
    setState(() {
      _challanSequenceController.text = "1";
      _challanSequenceError = null;
    });
  }

  // ✅ Fixed: Toggles default vs API-loaded values correctly
  void _applyDefaultValues(bool? isChecked) {
    setState(() {
      if (isChecked == true) {
        _invoicePrefixController.text = _defaultInvoicePrefix;
        _challanFormatController.text = _defaultChallanFormat;
        _isEditableInvoicePrefix = false;
        _isEditableChallanFormat = false;
      } else {
        _isEditableInvoicePrefix = true;
        _isEditableChallanFormat = true;
        _invoicePrefixController.text = _loadedSettings?.invoicePrefix ?? "";
        _challanFormatController.text = _loadedSettings?.challanNumberFormat ?? "";
      }
    });
  }

  Widget _buildLogoImage() {
    if (_logoBase64 == null || _logoBase64!.isEmpty) {
      return const Icon(Icons.add_a_photo, size: 40, color: Colors.grey);
    }
    try {
      final bytes = base64Decode(_logoBase64!);
      return CircleAvatar(radius: 50, backgroundImage: MemoryImage(bytes));
    } catch (e) {
      return const Icon(Icons.broken_image, size: 40, color: Colors.red);
    }
  }

  DecorationImage? _buildSignatureImage() {
    if (_signatureBase64 == null || _signatureBase64!.isEmpty) return null;
    try {
      final bytes = base64Decode(_signatureBase64!);
      return DecorationImage(image: MemoryImage(bytes), fit: BoxFit.contain);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveSettings() async {
    if (_api == null) {
      showErrorToast(context, "Not authenticated");
      return;
    }

    _validateChallanSequence(_challanSequenceController.text);
    if (_challanSequenceError != null) {
      showErrorToast(context, "Please fix the Challan Sequence");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sequenceNum = int.tryParse(_challanSequenceController.text) ?? 1;

      final dto = ApplicationSettingsDTO(
        logoBase64: _logoBase64,
        signatureBase64: _signatureBase64,
        invoicePrefix: _invoicePrefixController.text,
        challanNumberFormat: _challanFormatController.text,
        challanSequence: sequenceNum,
        termsAndConditions: _termsController.text,
      );

      ApplicationSettingsDTO? result;
      if (_isExisting) {
        result = await _api!.updateSettings(dto, context);
      } else {
        result = await _api!.createSettings(dto, context);
      }

      if (mounted) {
        showSuccessToast(context, _isExisting ? "Settings Updated Successfully" : "Settings Created Successfully");
        Navigator.of(context).pop();
      }

      await _fetchSettings();
    } catch (e) {
      if (mounted) {
        showErrorToast(context, "Error saving settings: $e");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _invoicePrefixController.dispose();
    _challanFormatController.dispose();
    _challanSequenceController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  //  String _userRole = 'Employee';

  // void _loadUserRole() {
  //   final savedRole = TokenManager().getRole();
  //   _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
  //   setState(() {});
  // }


  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromRGBO(0, 140, 192, 1);
        // bool isAdmin = _userRole == 'ADMIN';


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Application Settings"),
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        // backgroundColor: Colors.white,
        elevation: 0,
      leadingWidth: 96,
        leading: Row(
          children: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: Icon(Icons.menu), // color: Colors.black),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),

            // if (isAdmin)
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                icon: Icon(Icons.home),
              ),
          ],
        ),
      ),
      drawer: ShowSideMenu(),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Logo"),
                  const SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: () => _pickImage(true),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: _buildLogoImage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
            
                  _buildLabel("Invoice Prefix"),
                  _buildTextField(_isEditableInvoicePrefix, _invoicePrefixController, "e.g., INV-"),
                  const SizedBox(height: 16),
            
                  _buildLabel("Challan Number Format"),
                  _buildTextField(_isEditableChallanFormat, _challanFormatController, "e.g., CH-YYYY-####"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      Checkbox(
                        value: !_isEditableInvoicePrefix,
                        activeColor: blueColor,
                        onChanged: _applyDefaultValues,
                      ),
                      const Text(
                        "Default",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: blueColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
            
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Challan Sequence"),
                            _buildTextField(
                              true,
                              _challanSequenceController,
                              "e.g., 1",
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: _validateChallanSequence,
                              errorText: _challanSequenceError,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: [
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: _resetSequence,
                            child: Container(
                              width: 100,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: blueColor, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh_outlined, color: blueColor),
                                    SizedBox(width: 4),
                                    Text(
                                      "Reset",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: blueColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
            
                  _buildLabel("Terms & Conditions"),
                  _buildTextField(true, _termsController, "e.g.,", maxLines: 3),
                  const SizedBox(height: 20),
            
                  _buildLabel("Upload Signature"),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                        image: _buildSignatureImage(),
                      ),
                      child: _signatureBase64 == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_rounded, size: 40, color: Colors.blueGrey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap to upload signature",
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 25),
            
                  Center(
                    child: ElevatedButton(
                      onPressed: _challanSequenceError != null ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueColor,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _isExisting ? "Update" : "Save",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          if (_isLoading)
          customLoader()
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color.fromRGBO(20, 20, 20, 1)),
        ),
      );

  Widget _buildTextField(
    bool isEditable,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? errorText,
  }) {
    return TextField(
      readOnly: !isEditable,
      controller: controller,
      cursorColor: AppColors.accentBlue,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isEditable ? const Color.fromRGBO(20, 20, 20, 1) : Colors.grey.shade600,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color.fromRGBO(156, 156, 156, 1)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromRGBO(156, 156, 156, 1)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromRGBO(0, 140, 192, 1)),
          borderRadius: BorderRadius.circular(8),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
