import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/user_create_screen.dart';
import '../services/profile_api.dart'; // Assume this handles fetch/update API


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {}; // {name, email, phone, address, company}
  final ProfileApi _profileApi = ProfileApi();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Token line hata diya - ApiUtils handle karega
      final response = await _profileApi.getProfile(); // No token

      if (response.success && response.data != null) {
        setState(() {
          _profileData = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Profile not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    // TODO: Implement update logic similar to create
    // For now, just toggle edit mode
    setState(() {
      _isEditing = !_isEditing;
    });
    if (_isEditing) {
      // Save changes here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
    }
  }

  void _navigateToUserCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserCreateScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserCreateScreen()),
    );
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
          'Profile',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToUserCreate, // User Create icon
            tooltip: 'Create User',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: _navigateToSettings, // Settings icon
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Avatar
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Name
              _buildProfileField('Full Name', _profileData['name'] ?? '', Icons.person, _isEditing),
              const SizedBox(height: 16),
              // Email
              _buildProfileField('Email', _profileData['email'] ?? '', Icons.email, _isEditing),
              const SizedBox(height: 16),
              // Phone
              _buildProfileField('Phone', _profileData['phone'] ?? '', Icons.phone, _isEditing),
              const SizedBox(height: 16),
              // Address
              _buildProfileField('Address', _profileData['address'] ?? '', Icons.location_on, _isEditing, isMultiLine: true),
              const SizedBox(height: 16),
              // Company
              _buildProfileField('Company', _profileData['company'] ?? '', Icons.business, _isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon, bool isEditing, {bool isMultiLine = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              ],
            ),
            const SizedBox(height: 8),
            if (isEditing)
              TextFormField(
                initialValue: value,
                maxLines: isMultiLine ? 3 : 1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                onChanged: (newValue) {
                  // TODO: Update _profileData here
                },
              )
            else
              Text(
                value.isEmpty ? 'Not set' : value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: value.isEmpty ? Colors.grey : Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}