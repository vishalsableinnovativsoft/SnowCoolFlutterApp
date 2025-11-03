import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_api.dart'; // Assume you have this for user create API (similar to profile_api)

class UserCreateScreen extends StatefulWidget {
  const UserCreateScreen({super.key});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Employee'; // Default role
  bool _isLoading = false;

  // Permissions toggles (default false except Active true)
  bool _active = true;
  bool _canCreateCustomer = false;
  bool _canManageGoods = false;
  bool _canManageChallans = false;
  bool _canManageProfiles = false;
  bool _canManageSettings = false;

  final UserApi _userApi = UserApi(); // Assume this handles create API

  Future<void> _submitUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Token not passed - ApiUtils handles internally
      final response = await _userApi.createUser(
        username: _usernameController.text,
        password: _passwordController.text,
        role: _selectedRole,
        active: _active,
        canCreateCustomer: _canCreateCustomer,
        canManageGoods: _canManageGoods,
        canManageChallans: _canManageChallans,
        canManageProfiles: _canManageProfiles,
        canManageSettings: _canManageSettings,
      );

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Back to home
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to create user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      resizeToAvoidBottomInset: true, // Allow resize on keyboard, no scroll overflow
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        title: Text(
          'Create User',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 14 : 16, // Even smaller
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8), // Further reduced padding
        child: Form(
          key: _formKey,
          child: Column( // No SingleChildScrollView
            mainAxisSize: MainAxisSize.min, // Min size to fit
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a new user to the system',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14, // Smaller
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12), // Reduced
              _buildTextField('Username', _usernameController, Icons.person, true),
              const SizedBox(height: 8), // Reduced
              _buildTextField('Password', _passwordController, Icons.lock, true, obscureText: true),
              const SizedBox(height: 8), // Reduced
              _buildRoleDropdown(),
              const SizedBox(height: 12), // Reduced
              // Instructions Headline (one line to save space)
              Text(
                'Instructions: Configure permissions below to enable/disable access.',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14, // Combined into one line
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8), // Reduced
              // Permissions Toggles (ultra-compact)
              _buildPermissionRow(
                'Active',
                _active,
                (value) => setState(() => _active = value),
              ),
              _buildPermissionRow(
                'Can Create Customer',
                _canCreateCustomer,
                (value) => setState(() => _canCreateCustomer = value),
              ),
              _buildPermissionRow(
                'Can Manage Goods',
                _canManageGoods,
                (value) => setState(() => _canManageGoods = value),
              ),
              _buildPermissionRow(
                'Can Manage Challans',
                _canManageChallans,
                (value) => setState(() => _canManageChallans = value),
              ),
              _buildPermissionRow(
                'Can Manage Profiles',
                _canManageProfiles,
                (value) => setState(() => _canManageProfiles = value),
              ),
              _buildPermissionRow(
                'Can Manage Settings',
                _canManageSettings,
                (value) => setState(() => _canManageSettings = value),
              ),
              const SizedBox(height: 16), // Reduced
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12), // Shorter
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save & Create',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 14, // Smaller
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const Spacer(), // Fill space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isRequired, {
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 16), // Smaller icon
            const SizedBox(width: 4), // Reduced
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12, // Smaller
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
        const SizedBox(height: 4), // Reduced
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6), // Smaller radius
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color.fromRGBO(0, 140, 192, 1)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Tighter
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            if (label == 'Password' && value != null && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Color.fromRGBO(0, 140, 192, 1), size: 16), // Smaller
            const SizedBox(width: 4),
            Text(
              'Role',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '*',
              style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4), // Reduced
        DropdownButtonFormField<String>(
          value: _selectedRole,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color.fromRGBO(0, 140, 192, 1)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Tighter
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
          items: const [
            DropdownMenuItem(value: 'Employee', child: Text('Employee')),
            DropdownMenuItem(value: 'Admin', child: Text('Admin')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedRole = value;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a role';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Helper for permission toggle row (ultra-compact)
  Widget _buildPermissionRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0), // Minimal vertical
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11, // Smaller text
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color.fromRGBO(0, 140, 192, 1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}