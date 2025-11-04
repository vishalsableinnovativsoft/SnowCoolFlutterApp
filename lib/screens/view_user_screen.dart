import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/view_user_api.dart'; // Import the API
import '../models/user_model.dart'; // Assume User model is here
import 'user_create_screen.dart'; // Import for Add User navigation

class UserViewScreen extends StatefulWidget {
  const UserViewScreen({super.key});

  @override
  State<UserViewScreen> createState() => _UserViewScreenState();
}

class _UserViewScreenState extends State<UserViewScreen> {
  bool _isLoading = true;
  List<User> _users = [];
  final ViewUserApi _api = ViewUserApi();
  final Map<String, bool> _passwordVisibility = {}; // Per user password visibility state

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _api.getUsers();
      setState(() {
        _users = users.isNotEmpty ? users : _getDemoUsers(); // Use demo if API empty
        _isLoading = false;
      });
    } catch (e) {
      // On error, fallback to demo data
      setState(() {
        _users = _getDemoUsers();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e (using demo data)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Demo data function
  List<User> _getDemoUsers() {
    return [
      User(
        id: '1',
        username: 'demo_user1',
        password: 'demo123',
        role: 'Employee',
        active: true,
      ),
      User(
        id: '2',
        username: 'admin_demo',
        password: 'admin456',
        role: 'Admin',
        active: false,
      ),
      User(
        id: '3',
        username: 'test_emp',
        password: 'test789',
        role: 'Employee',
        active: true,
      ),
    ];
  }

  Future<void> _toggleUserStatus(User user) async {
    final isActive = !user.active;
    try {
      final response = await _api.updateUserStatus(user.id, isActive);
      if (response.success) {
        setState(() {
          user.active = isActive; // Update local model
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User status updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editUser(User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCreateScreen(user: user),
      ),
    );
    _loadUsers(); // Refresh the list after editing
  }

  Future<void> _deleteUser(User user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await _api.deleteUser(user.id);
                if (response.success) {
                  setState(() {
                    _users.remove(user);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully!'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response.message ?? 'Failed to delete user'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting user: $e'), backgroundColor: Colors.red),
                );
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
    ).then((_) => _loadUsers()); // Refresh list after add
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        // No actions here - unique button moved to FAB
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: isMobile ? 16 : 24,
          right: isMobile ? 16 : 24,
          top: 16,
          bottom: 80, // Extra bottom padding to avoid FAB overlap
        ),
        child: _users.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
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
            : ListView.builder( // Use ListView.builder for better performance and auto-scroll
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return _buildUserCard(user, isMobile);
                },
              ),
      ),
      // Unique Floating Action Button for Add User (custom styled)
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

  Widget _buildUserCard(User user, bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 8), // Smaller margin
      child: IntrinsicHeight( // Wrap in IntrinsicHeight to fit content tightly
        child: Padding(
          padding: const EdgeInsets.all(8), // Tighter padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Min size to prevent extra height
            children: [
              // Edit/Delete icons row (top-right, with space)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero, // No padding
                    constraints: const BoxConstraints(), // No constraints
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                    onPressed: () => _editUser(user),
                    tooltip: 'Edit User',
                  ),
                  const SizedBox(width: 8.0), // Space between edit and delete
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    onPressed: () => _deleteUser(user),
                    tooltip: 'Delete User',
                  ),
                ],
              ),
              // Username Field
              Expanded( // Use Expanded to force fit in available space
                child: _buildUserField('Username', user.username, Icons.person, isMobile),
              ),
              const SizedBox(height: 2), // Minimal
              // Password Field (with show/hide)
              Expanded(
                child: _buildPasswordField(user),
              ),
              const SizedBox(height: 2), // Minimal
              // Role Field
              Expanded(
                child: _buildUserField('Role', user.role, Icons.admin_panel_settings, isMobile),
              ),
              const SizedBox(height: 4), // Minimal
              // Active Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 11, // Smaller
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Switch(
                    value: user.active,
                    onChanged: (value) => _toggleUserStatus(user),
                    activeColor: const Color.fromRGBO(0, 140, 192, 1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Compact switch
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserField(String label, String value, IconData icon, bool isMobile) {
    return Row(
      children: [
        Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 14), // Smaller icon
        const SizedBox(width: 3), // Minimal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11, // Smaller
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 1), // Minimal
              FittedBox( // Use FittedBox to fit text if too long
                fit: BoxFit.scaleDown,
                child: Text(
                  value.isEmpty ? 'Not set' : value,
                  style: GoogleFonts.inter(
                    fontSize: 12, // Smaller
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

  Widget _buildPasswordField(User user) {
    final bool isVisible = _passwordVisibility[user.id] ?? false;
    final String displayPassword = isVisible ? user.password : '*' * user.password.length;

    return Row(
      children: [
        const Icon(Icons.lock, color: Color.fromRGBO(0, 140, 192, 1), size: 14),
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
                        size: 12,
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