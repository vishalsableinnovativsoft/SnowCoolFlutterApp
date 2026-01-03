import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/setting_screen.dart';
import 'package:snow_trading_cool/screens/user_create_screen.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import '../services/profile_api.dart';
import '../services/application_settings_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _profileExists = false;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  final ProfileApi _profileApi = ProfileApi();
  ApplicationSettingsDTO? _appSettings;
  ImageProvider? _logoImage;

  String? _nameError;
  String? _emailError;
  String? _phoneError;

  String _userRole = 'Employee';
  late bool isAdmin = _userRole == 'ADMIN';

  void _loadUserRole() {
    final savedRole = TokenManager().getRole();
    _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_validateName);
    _emailController = TextEditingController()..addListener(_validateEmail);
    _phoneController = TextEditingController()..addListener(_validatePhone);
    _addressController = TextEditingController();
    _loadUserRole();

    _loadProfile();
    _loadAppSettingsLogo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _validateName() => setState(
    () => _nameError = _nameController.text.trim().isEmpty ? 'Required' : null,
  );

  void _validateEmail() {
    final text = _emailController.text.trim();
    setState(() {
      _emailError = text.isEmpty
          ? 'Required'
          : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)
          ? 'Invalid email'
          : null;
    });
  }

  void _validatePhone() {
    final text = _phoneController.text.trim();
    setState(() {
      _phoneError = text.isEmpty
          ? 'Required'
          : text.length < 10
          ? 'At least 10 digits'
          : !RegExp(r'^[5-9]').hasMatch(text)
          ? 'Must start with 5-9'
          : null;
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await _profileApi.getProfile(1);

      if (response.success && response.data != null) {
        final data = response.data!;
        setState(() {
          _profileExists = true;
          _nameController.text = data['name'] ?? data['businessName'] ?? '';
          _emailController.text = data['email'] ?? data['emailId'] ?? '';
          _phoneController.text = data['phone'] ?? data['mobileNumber'] ?? '';
          _addressController.text = data['address'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _profileExists = false;
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _addressController.clear();
          _isLoading = false;
        });
        showWarningToast(
          context,
          "Welcome! Please create your business profile.",
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showWarningToast(context, "Connection error");
    }
  }

  Future<void> _loadAppSettingsLogo() async {
    try {
      final token = TokenManager().getToken();
      if (token == null) return;
      final api = ApplicationSettingsApi(token: token);
      final settings = await api.getSettings(context);
      if (!mounted) return;
      setState(() {
        _appSettings = settings;
        if (settings?.logoBase64 != null && settings!.logoBase64!.isNotEmpty) {
          _logoImage = MemoryImage(base64Decode(settings.logoBase64!));
        }
      });
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    if (!_isEditing) {
      setState(() => _isEditing = true);
      return;
    }

    _validateName();
    _validateEmail();
    _validatePhone();

    if (_nameError != null || _emailError != null || _phoneError != null) {
      showWarningToast(context, "Please fix the errors");
      return;
    }

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    try {
      ProfileResponse response;

      if (_profileExists) {
        response = await _profileApi.updateProfile(1, {
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'company': name,
        });
      } else {
        response = await _profileApi.createProfile(
          name,
          email,
          phone,
          address,
          name,
        );
      }

      if (response.success) {
        showSuccessToast(
          context,
          _profileExists
              ? "Profile updated successfully!"
              : "Profile created successfully!",
        );
        setState(() {
          _profileExists = true;
          _isEditing = false;
        });
        await _loadProfile();
      } else {
        showWarningToast(context, response.message ?? "Failed to save profile");
      }
    } catch (e) {
      showWarningToast(context, "Network error: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if(isAdmin)
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserCreateScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileApplicationSettingScreen(),
              ),
            ).then((_) => _loadAppSettingsLogo()),
          ),
          if (isAdmin)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: Colors.white,
              ),
              onPressed: _isSaving ? null : _saveProfile,
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _logoImage,
                        child: _logoImage == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field(
                      'Business Name',
                      _nameController,
                      Icons.business,
                      _nameError,
                    ),
                    const SizedBox(height: 16),
                    _field('Email', _emailController, Icons.email, _emailError),
                    const SizedBox(height: 16),
                    _field(
                      'Phone',
                      _phoneController,
                      Icons.phone,
                      _phoneError,
                      length: 10,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Address',
                      _addressController,
                      Icons.location_on,
                      null,
                      isMultiLine: true,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Full-screen loaders
            if (_isLoading || _isSaving) customLoader(),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon,
    String? error, {
    bool isMultiLine = false,
    int? length,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color.fromRGBO(0, 140, 192, 1),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isEditing
                ? TextFormField(
                    controller: controller,
                    maxLines: isMultiLine ? 3 : 1,
                    maxLength: length,
                    keyboardType: label == 'Email'
                        ? TextInputType.emailAddress
                        : label == 'Phone'
                        ? TextInputType.phone
                        : TextInputType.text,
                    inputFormatters: label == 'Phone'
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    decoration: InputDecoration(
                      isDense: true,
                      errorText: error,
                      errorStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(156, 156, 156, 1),
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.accentBlue,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  )
                : Text(
                    controller.text.isEmpty ? 'Not set' : controller.text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: controller.text.isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
