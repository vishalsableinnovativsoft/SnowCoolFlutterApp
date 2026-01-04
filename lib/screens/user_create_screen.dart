import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import '../models/user_model.dart';
import '../services/user_api.dart';

class UserCreateScreen extends StatefulWidget {
  final int? userId;
  final int? index;
  const UserCreateScreen({super.key, this.userId, this.index});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Employee';
  bool _isLoading = false;
  bool _active = true;
  bool _canManageCustomer = false;
  bool _canCreateCustomer = false;
  bool _canManageGoodsItem = false;
  bool _canManageChallan = true;
  bool _canManageProfile = false;
  bool _canManageSetting = false;
  bool _canManagePassbook = true;
  bool _showPassword = false;
  final UserApi _userApi = UserApi();
  bool get _isEditing => widget.userId != null;
  User? _fetchedUser;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
    _fetchUserDetails();
  } else {
    _isLoading = false;
  }
    // if (_isEditing) {
    //   final user = widget.user!;
    //   _usernameController.text = user.username;
    //   _selectedRole = ['Employee', 'Admin'].contains(user.role)
    //       ? user.role
    //       : 'Employee';
    //   _active = user.active;
    //   _canCreateCustomer = user.canCreateCustomer ?? false;
    //   _canManageGoodsItem = user.canManageGoodsItem ?? false;
    //   _canManageChallan = user.canManageChallan ?? false;
    //   _canManageProfile = user.canManageProfile ?? false;
    //   _canManageSetting = user.canManageSetting ?? false;
    //   _canManagePassbook = user.canManagePassbook ?? false;
    //   _canManageCustomer = user.canManageCustomer ?? false;
    //   _passwordController.text = user.password;

    // }
  }
  Future<void> _fetchUserDetails() async {
  try {
    setState(() => _isLoading = true);

    final User fetchedUser = await _userApi.getUserById(widget.userId!);

    if (!mounted) return;

    setState(() {
      _fetchedUser = fetchedUser;

      _usernameController.text = fetchedUser.username;
      _selectedRole = fetchedUser.role == 'ADMIN' ? 'Admin' : 'Employee';
      _active = fetchedUser.active;

      // Safely handle null permissions (as in your API response)
      _canCreateCustomer = fetchedUser.canCreateCustomer ?? false;
      _canManageCustomer = fetchedUser.canManageCustomer ?? false;
      _canManageGoodsItem = fetchedUser.canManageGoodsItem ?? false;
      _canManageChallan = fetchedUser.canManageChallan ?? false;
      _canManageProfile = fetchedUser.canManageProfile ?? false;
      _canManageSetting = fetchedUser.canManageSetting ?? false;
      _canManagePassbook = fetchedUser.canManagePassbook ?? false;

      // Do NOT pre-fill password (security best practice)
      _passwordController.clear();
    });
  } catch (e) {
    if (mounted) {
      showErrorToast(context, "Failed to load user: $e");
      Navigator.pop(context); // Go back if failed to load
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _submitUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await _userApi.createOrUpdateUser(
        id: _isEditing ? widget.userId  : null,
        username: _usernameController.text.trim(),
        password: _passwordController.text.isEmpty
            ? _fetchedUser!.password
            : _passwordController.text.trim(),
        role: _selectedRole,
        active: _active,
        canCreateCustomer: _canCreateCustomer,
        canManageGoodsItem: _canManageGoodsItem,
        canManageChallan: _canManageChallan,
        canManageProfile: _canManageProfile,
        canManageSetting: _canManageSetting,
        canManagePassbook: _canManagePassbook,
        canManageCustomer: _canManageCustomer,
      );
      if (response.success && mounted) {
        showSuccessToast(
          context,
          _isEditing
              ? 'User updated successfully!'
              : 'User created successfully!',
        );
        // Build a User object to return to the caller so it can update the list in-place
        final updatedUser = User(
          id: widget.userId ?? -1,
          username: _usernameController.text.trim(),
          password: _passwordController.text.isEmpty
              ? ''
              : _passwordController.text.trim(),
          role: _selectedRole,
          active: _active,
          canCreateCustomer: _canCreateCustomer,
          canManageGoodsItem: _canManageGoodsItem,
          canManageChallan: _canManageChallan,
          canManageProfile: _canManageProfile,
          canManageSetting: _canManageSetting,
          canManagePassbook: _canManagePassbook,
          canManageCustomer: _canManageCustomer,
        );

        Navigator.pop(context, {'index': widget.index, 'user': updatedUser});
      } else if (mounted) {
        showErrorToast(context, "Error: ${response.message}");
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, "Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        title: Text(
          _isEditing ? 'Edit User' : 'Create User',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 14 : 16,
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
                horizontal: isMobile ? 8 : 16,
                vertical: 8,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing
                            ? 'Update user details'
                            : 'Add a new user to the system',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Username',
                        _usernameController,
                        Icons.person,
                        true,
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordField(),
                      const SizedBox(height: 8),
                      _buildRoleDropdown(),
                      const SizedBox(height: 12),
                      _buildPermissionRow(
                        'Active',
                        _active,
                        (v) => setState(() => _active = v),
                      ),
                      _buildPermissionRow(
                        'Can Manage Customer',
                        _canManageCustomer,
                        (v) => setState(() => _canManageCustomer = v),
                      ),
                      _buildPermissionRow(
                        'Can Create Customer',
                        _canCreateCustomer,
                        (v) => setState(() => _canCreateCustomer = v),
                      ),
                      _buildPermissionRow(
                        'Can Manage Goods',
                        _canManageGoodsItem,
                        (v) => setState(() => _canManageGoodsItem = v),
                      ),
                      _buildPermissionRow(
                        'Can Manage Challans',
                        _canManageChallan,
                        (v) => setState(() => _canManageChallan = v),
                      ),
                      _buildPermissionRow(
                        'Can Manage Profiles',
                        _canManageProfile,
                        (v) => setState(() => _canManageProfile = v),
                      ),
                      _buildPermissionRow(
                        'Can Manage Settings',
                        _canManageSetting,
                        (v) => setState(() => _canManageSetting = v),
                      ),
                      _buildPermissionRow(
                        'Can Manage Passbook',
                        _canManagePassbook,
                        (v) => setState(() => _canManagePassbook = v),
                      ), // ← NEW ROW
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isEditing ? 'Update User' : 'Create User',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) customLoader(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isRequired, {
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              Text(
                '*',
                style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          cursorColor: AppColors.accentBlue,
          obscureText: obscureText,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            // Default border
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            // Enabled border (when field is active but not focused)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
            ),
            // Focused border
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color.fromRGBO(0, 140, 192, 1),
                width: 2,
              ),
            ),
            // Error border
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            // Focused + error border
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'Please enter $label';
            }
            if (value!.length < 2) {
              return 'Username must be at least 2 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Enhanced password field with same border theme
  Widget _buildPasswordField() {
    final hintText = _isEditing
        ? 'Leave blank to keep current password'
        : 'Enter password';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.lock, color: Color.fromRGBO(0, 140, 192, 1), size: 16),
            SizedBox(width: 4),
            Text(
              'Password',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text('*', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            // Same border styles as above
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color.fromRGBO(0, 140, 192, 1),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: (value) {
            if (!_isEditing && (value == null || value.isEmpty)) {
              return 'Please enter password';
            }
            if (value != null && value.isNotEmpty && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Enhanced dropdown with matching border style
  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.supervised_user_circle,
              color: Color.fromRGBO(0, 140, 192, 1),
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Role',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text('*', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color.fromRGBO(0, 140, 192, 1),
                width: 2,
              ),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Employee',
              child: Text('Employee', style: TextStyle(color: Colors.black87)),
            ),
            DropdownMenuItem(
              value: 'Admin',
              child: Text('Admin', style: TextStyle(color: Colors.black87)),
            ),
          ],
          onChanged: (value) =>
              setState(() => _selectedRole = value ?? 'Employee'),
          validator: (value) => value == null ? 'Please select a role' : null,
        ),
      ],
    );
  }

  // Helper for permission toggle row
  Widget _buildPermissionRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(!value),
            icon: Icon(
              value ? Icons.toggle_on : Icons.toggle_off,
              color: value ? const Color.fromRGBO(0, 140, 192, 1) : Colors.grey,
              size: 60,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
