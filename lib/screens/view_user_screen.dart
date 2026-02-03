import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/services/user_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import '../services/view_user_api.dart';
import '../models/user_model.dart';
import 'user_create_screen.dart';

class UserViewScreen extends StatefulWidget {
  const UserViewScreen({super.key});

  @override
  State<UserViewScreen> createState() => _UserViewScreenState();
}

class _UserViewScreenState extends State<UserViewScreen> {
  bool _isLoading = true;
  List<User> _users = [];
  final ViewUserApi _api = ViewUserApi();
  final Map<int, bool> _passwordVisibility = {};

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
    _loadUserRole();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _api.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // _users = _getDemoUsers();
        _isLoading = true;
      });
    }
  }

  Future<void> _toggleUserStatus(User user, bool newStatus) async {
    if (user.id == 1) {
      // Prevent toggling the primary user; revert UI to previous state
      showWarningToast(
        context,
        "Primary user cannot be deactivated/activated.",
      );
      return;
    }
    final oldStatus = user.active;

    // ── Optimistic UI update ─────────────────────────────────────
    setState(() {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user.copyWith(active: newStatus);
      }
    });

    try {
      // ← HERE IS THE FIX: pass user.id (int), not username
      final response = await _api.updateUserStatus(user.username, newStatus);

      if (!mounted) return;

      if (response.success) {
        showSuccessToast(context, "Status updated successfully!");
      } else {
        throw Exception(response.message ?? "Update failed");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = user.copyWith(active: oldStatus);
          }
        });
        showErrorToast(context, "Failed to update status: $e");
      }
    }
  }

  Widget _buildPermissionRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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

  // EDIT: Navigate to UserCreateScreen with user data
  Future<void> _editUser(int index, int userId) async {
    // if (userId == 1) {
    //   showWarningToast(context, "The primary user cannot be edited.");
    //   return;
    // }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCreateScreen(userId: userId, index: index),
      ),
    );

    if (result is Map<String, dynamic>) {
      final updatedUser = result['user'] as User?;
      final updatedIndex = result['index'] as int?;
      if (updatedUser != null && updatedIndex != null && mounted) {
        setState(() {
          _users[updatedIndex] = updatedUser;
        });
        return;
      }
    }

    // Fallback: refresh entire list
    _loadUsers();
  }

  // DELETE: Safe context handling
  Future<void> _deleteUser(User user) async {
    if (user.id == 1) {
      showWarningToast(context, "The primary user cannot be deleted.");
      return;
    }
    final BuildContext dialogContext = context;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final userApi = UserApi();
              try {
                final response = await userApi.deleteUser(user.id);
                if (!dialogContext.mounted) return;

                if (response.success) {
                  setState(() {
                    _users.remove(user);
                  });
                  showSuccessToast(context, "User deleted successfully!");
                } else {
                  showErrorToast(
                    context,
                    "Failed to delete user: ${response.message}",
                  );
                }
              } catch (e) {
                if (!dialogContext.mounted) return;
                showErrorToast(context, "Error deleting user: $e");
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserCreateScreen()),
    ).then((_) => _loadUsers());
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
          'View Users',
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
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        color: AppColors.accentBlue,
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: isMobile ? 16 : 24,
                  right: isMobile ? 16 : 24,
                  top: 16,
                  bottom: 80,
                ),
                child: _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserCard(user, isMobile, index);
                        },
                      ),
              ),
            ),

            if (_isLoading) customLoader(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddUser,
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'Add User',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        tooltip: 'Add New User',
      ),
    );
  }

  Widget _buildUserCard(User user, bool isMobile, int index) {
    final initials = (user.username.isNotEmpty)
        ? user.username
              .trim()
              .split(' ')
              .map((s) => s.isNotEmpty ? s[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 14,
          horizontal: isMobile ? 10 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: isMobile ? 44 : 52,
                  height: isMobile ? 44 : 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A3D9), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.role,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // if (user.id != 1)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black54),
                    tooltip: 'More options',
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') _editUser(index, user.id);
                      if (value == 'delete') _deleteUser(user);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.manage_accounts,
                              color: Color(0xFF1976D2),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                        if (user.id != 1)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_remove,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 12),
            _buildUserField('Username', user.username, Icons.person, isMobile),
            SizedBox(height: isMobile ? 8 : 10),
            _buildPasswordField(user, isMobile),
            SizedBox(height: isMobile ? 8 : 10),
            _buildUserField(
              'Role',
              user.role,
              Icons.admin_panel_settings,
              isMobile,
            ),
            SizedBox(height: isMobile ? 10 : 12),
            // Active toggle is only interactive for non-primary users
            if (user.id != 1)
              _buildPermissionRow(
                'Active',
                user.active,
                (newValue) => _toggleUserStatus(user, newValue),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserField(
    String label,
    String value,
    IconData icon,
    bool isMobile,
  ) {
    return Row(
      children: [
        Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 16),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value.isEmpty ? 'Not set' : value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: value.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(User user, bool isMobile) {
    final bool isVisible = _passwordVisibility[user.id] ?? false;
    final String displayPassword = isVisible
        ? user.password
        : '*' * user.password.length;

    return Row(
      children: [
        const Icon(Icons.lock, color: Color.fromRGBO(0, 140, 192, 1), size: 16),
        const SizedBox(width: 3),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _passwordVisibility[user.id] = !isVisible;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayPassword,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isVisible ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
