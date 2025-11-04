import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/user_api.dart';

class UserCreateScreen extends StatefulWidget {
  final User? user;
  const UserCreateScreen({super.key, this.user});

  @override
  State<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends State<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Employee'; // Default role
  bool _isLoading = false;
  late bool isEditing;

  // Permissions toggles (default false except Active true)
  bool _active = true;
  bool _canCreateCustomer = false;
  bool _canManageGoods = false;
    bool _canManageChallans = false;
    bool _canManageProfiles = false;
    bool _canManageSettings = false;
    bool _isPasswordObscured = true;
  
  
    final UserApi _userApi = UserApi();
  
    @override
    void initState() {
      super.initState();
      isEditing = widget.user != null;
      if (isEditing) {
        _usernameController.text = widget.user!.username;
        // Do not pre-fill password for security reasons.
        // _passwordController.text = widget.user!.password;
        _selectedRole = widget.user!.role;
        _active = widget.user!.active;
        // Note: The user model does not contain the other permissions.
        // You would need to add them to the model and the API response to pre-fill them.
      }
    }
  
    Future<void> _submitUser() async {
      if (!_formKey.currentState!.validate()) return;
  
      setState(() {
        _isLoading = true;
      });
  
      try {
        final response = isEditing
            ? await _userApi.updateUser(
                widget.user!.id,
                username: _usernameController.text,
                password: _passwordController.text, // Password can be empty for updates
                role: _selectedRole,
                active: _active,
                canCreateCustomer: _canCreateCustomer,
                canManageGoods: _canManageGoods,
                canManageChallans: _canManageChallans,
                canManageProfiles: _canManageProfiles,
                canManageSettings: _canManageSettings,
              )
            : await _userApi.createUser(
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
            SnackBar(
              content: Text(isEditing ? 'User updated successfully!' : 'User created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Back to home
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? (isEditing ? 'Failed to update user' : 'Failed to create user')),
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
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
          elevation: 0,
          title: Text(
            isEditing ? 'Edit User' : 'Create User',
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
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit the user details' : 'Add a new user to the system',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField('Username', _usernameController, Icons.person, true),
                const SizedBox(height: 8),
                _buildTextField('Password', _passwordController, Icons.lock, !isEditing, obscureText: _isPasswordObscured),
                const SizedBox(height: 8),
                _buildRoleDropdown(),
                const SizedBox(height: 12),
                Text(
                  'Instructions: Configure permissions below to enable/disable access.',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
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
                            isEditing ? 'Save Changes' : 'Save & Create',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const Spacer(),
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
            obscureText: obscureText,
            maxLines: maxLines,
            decoration: InputDecoration(
              suffixIcon: label == 'Password'
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color.fromRGBO(0, 140, 192, 1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              fillColor: Colors.grey.shade50,
              filled: true,
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'Please enter $label';
              }
              if (label == 'Password' && !isEditing && (value != null && value.length < 6)) {
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
              const Icon(Icons.admin_panel_settings, color: const Color.fromRGBO(0, 140, 192, 1), size: 16),
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
          const SizedBox(height: 4),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
  
    Widget _buildPermissionRow(String label, bool value, ValueChanged<bool> onChanged) {
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
  