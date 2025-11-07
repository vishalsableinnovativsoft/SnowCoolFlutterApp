import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/addinventoryscreen.dart';
import 'package:snow_trading_cool/screens/profile_screen.dart';
import 'package:snow_trading_cool/screens/user_create_screen.dart'; // Import for User Create
import 'package:snow_trading_cool/screens/view_customer_screen.dart'; // Changed import to ViewCustomerScreen
import 'package:snow_trading_cool/screens/view_user_screen.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/services/profile_api.dart'; // Import for profile check
import 'package:snow_trading_cool/screens/view_challan.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'challan_screen.dart';
import 'create_customer_screen.dart';
import 'login_screen.dart';
import '../services/logout_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LogoutApi _logoutApi = LogoutApi();
  bool _isLoggingOut = false;
  bool _showCustomerSubMenu = false;

  Future<void> _handleLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Get the stored token and call logout API
      final token = TokenManager().getToken();
      print('Using token for logout: $token');
      final response = await _logoutApi.logout(token);

      // Clear the stored token regardless of API response
      TokenManager().clearToken();

      // Show appropriate message based on response
      if (mounted) {
        showSuccessToast(context, response.message ?? 'Logged out successfully');
        
        // Always navigate to login for security (whether API succeeded or not)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Handle any unexpected errors - always logout locally for security
      print('Logout error: $e');

      // Clear token even on error
      TokenManager().clearToken();

      if (mounted) {
        showWarningToast(context, 'Logout failed due to network error');

        // Always navigate to login for security
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleProfile() async {
    final bool hasProfile = await _checkProfileExists();
    
    if (hasProfile) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  Future<bool> _checkProfileExists() async {
    final ProfileApi profileApi = ProfileApi();
    try {
      final response = await profileApi.getProfile(); // Real API call
      return response.success && response.data != null;
    } catch (e) {
      print('Profile check error: $e');
      return false; // Default to form if error
    }
  }

  void _showLogoutConfirmation() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoggingOut
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _handleLogout();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008CC0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Responsive values
    final double horizontalPadding = isMobile ? 16.0 : 24.0;
    final double cardRadius = 12.0;
    final double titleFontSize = 12.0;
    final double countFontSize = isMobile ? 22.0 : 26.0;
    final double labelFontSize = isMobile ? 13.0 : 15.0;
    final double typeFontSize = isMobile ? 14.0 : 16.0;
    final double orderCountFontSize = isMobile ? 18.0 : 22.0;
    final double orderLabelFontSize = isMobile ? 12.0 : 13.0;
    final double iconSize = isMobile ? 15.0 : 17.0;
    final double verticalGap = isMobile ? 6.0 : 8.0;
    final double sectionGap = isMobile ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        leadingWidth: isMobile ? 44 : 48,
        titleSpacing: isMobile ? 6 : 8,
        leading: Builder(
          builder: (context) => IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: Icon(
              Icons.menu,
              color: Colors.white,
              size: isMobile ? 22 : 24,
            ),
            onPressed: () {
              showGeneralDialog<void>(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Menu',
                barrierColor: Colors.black54,
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (ctx, anim1, anim2) {
                  return const SizedBox.shrink();
                },
                transitionBuilder: (ctx, animation, secondaryAnimation, child) {
                  final width = MediaQuery.of(context).size.width;
                  final panelWidth = (width * 0.5).clamp(260.0, width);

                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: Material(
                            color: Colors.white,
                            elevation: 4,
                            child: SizedBox(
                              width: panelWidth,
                              height: double.infinity,
                              child: SafeArea(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    ListTile(
                                      title: const Text('Challan'),
                                      trailing: const Icon(Icons.add),
                                      onTap: () {
                                        Navigator.of(ctx).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const ChallanScreen(),
                                          ),
                                        );
                                      },
                                    ),

                                    const Divider(height: 1),
                                    ListTile(
                                      title: const Text('Customers'),
                                      trailing: Icon(_showCustomerSubMenu ? Icons.remove : Icons.add),
                                      onTap: () {
                                        setState(() {
                                          _showCustomerSubMenu = !_showCustomerSubMenu;
                                        });
                                      },
                                    ),
                                    if (_showCustomerSubMenu) ...[
                                      ListTile(
                                        title: const Text('Create Customer'),
                                        leading: const SizedBox(width: 24), // Indent
                                        trailing: const Icon(Icons.add),
                                        onTap: () {
                                          Navigator.of(ctx).pop(); // Close the drawer
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const CreateCustomerScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('View Customers'),
                                        leading: const SizedBox(width: 24), // Indent
                                        trailing: const Icon(Icons.add),
                                        onTap: () {
                                          Navigator.of(ctx).pop(); // Close the drawer
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const ViewCustomerScreenFixed(), // Changed to ViewCustomerScreen
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    const Divider(height: 1),
                                    ListTile(
                                      title: const Text('Items/Goods'),
                                      trailing: const Icon(Icons.add),
                                      onTap: () {
                                        Navigator.of(ctx).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const Addinventoryscreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const Spacer(),
                                    const Divider(height: 1),
                                    ListTile(
                                      title: const Text('Logout'),
                                      leading: const Icon(
                                        Icons.logout,
                                        color: Colors.red,
                                      ),
                                      textColor: Colors.red,
                                      onTap: () {
                                        Navigator.of(ctx).pop();
                                        _showLogoutConfirmation();
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        title: Text(
          'SnowCool Trading CO.',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          // Profile icon with popup menu - Logout replaced with User Create
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8 : 12),
            child: PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: isMobile ? 16 : 18,
                backgroundColor: Colors.grey.shade300,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: isMobile ? 20 : 22,
                ),
              ),
              onSelected: (value) {
                if (value == 'profile') {
                  _handleProfile();
                } else if (value == 'user_create') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserCreateScreen()),
                  );
                } else if (value == 'view_users') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserViewScreen()),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profile'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_users',
                  child: ListTile(
                    leading: Icon(Icons.group),
                    title: Text('Users'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: verticalGap),

            // Total Inventory Title
            Text(
              'Total Inventory',
              style: GoogleFonts.inter(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF515151),
              ),
            ),
            SizedBox(height: verticalGap),

            // Inventory Card
            Container(
              width: double.infinity,
              height: isMobile ? 60 : 70,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 228, 228, 1),
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: const Color(0xFFF0D0D0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(255, 228, 228, 1).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '1000',
                      style: GoogleFonts.inter(
                        fontSize: countFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(0, 140, 192, 1),
                      ),
                    ),
                    Text(
                      'Empty',
                      style: GoogleFonts.inter(
                        fontSize: labelFontSize,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: sectionGap),

            // Types List
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 228, 228, 1),
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: const Color(0xFFF0D0D0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(255, 228, 228, 1).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTypeRow('Small Regular', '2000', typeFontSize),
                  _buildTypeRow('Small Floron', '2000', typeFontSize),
                  _buildTypeRow('Big Regular', '2000', typeFontSize),
                  _buildTypeRow('Big Floron', '2000', typeFontSize),
                ],
              ),
            ),
            SizedBox(height: sectionGap),

            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: sectionGap),

            // Customers Title
            Text(
              'Customers',
              style: GoogleFonts.inter(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF515151),
              ),
            ),
            SizedBox(height: verticalGap),

            // Customers Card
            Container(
              height: isMobile ? 56 : 64,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '1000',
                            style: GoogleFonts.inter(
                              fontSize: countFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromRGBO(0, 140, 192, 1),
                            ),
                          ),
                          Text(
                            'Customers',
                            style: GoogleFonts.inter(
                              fontSize: labelFontSize,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: iconSize,
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGap),

            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: sectionGap),

            // Orders/Challans Title
            Text(
              'Orders/Challans',
              style: GoogleFonts.inter(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF515151),
              ),
            ),
            SizedBox(height: verticalGap),

            // Received & Delivered Cards
            Row(
              children: [
                Expanded(
                  child: _buildOrderCard(
                    '1000',
                    'Received',
                    orderCountFontSize,
                    orderLabelFontSize,
                    cardRadius,
                    isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 14),
                Expanded(
                  child: _buildOrderCard(
                    '1000',
                    'Delivered',
                    orderCountFontSize,
                    orderLabelFontSize,
                    cardRadius,
                    isMobile,
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        onPressed: () async {
          final size = MediaQuery.of(context).size;
          final left = (size.width - 200).clamp(0.0, size.width - 80.0);
          final top = size.height - 200;

          final selected = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(left, top, 16, 16),
            items: [
              PopupMenuItem(
                value: 'challan',
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Challan'),
                ),
              ),
              PopupMenuItem(
                value: 'customers',
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Customers'),
                ),
              ),
              PopupMenuItem(
                value: 'items',
                child: ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('Items/Goods'),
                ),
              ),
            ],
          );

          if (selected == null) return;
          if (selected == 'challan') {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ViewChallanScreen()));
            return;
          }

          if (selected == 'customers') {
            final sub = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(left, top - 120, 16, 16),
              items: [
                const PopupMenuItem(
                  value: 'create_customer',
                  child: Text('Create Customer'),
                ),
                const PopupMenuItem(
                  value: 'view_customers',
                  child: Text('View Customers'),
                ),
              ],
            );
            if (sub == 'create_customer') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateCustomerScreen()),
              );
            }
            if (sub == 'view_customers') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ViewCustomerScreenFixed()), // Changed to ViewCustomerScreenFixed
              );
            }
            return;
          }

          if (selected == 'items') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const Addinventoryscreen()),
            );
            return;
          }
        },
        child: Icon(Icons.add, color: Colors.white, size: isMobile ? 22 : 26),
      ),
    );
  }

  Widget _buildTypeRow(String title, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: fontSize + 2,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    String count,
    String label,
    double countSize,
    double labelSize,
    double radius,
    bool isMobile,
  ) {
    return Container(
      height: isMobile ? 52 : 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: GoogleFonts.inter(
                      fontSize: countSize,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(0, 140, 192, 1),
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: labelSize,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: isMobile ? 14 : 16,
          ),
        ],
      ),
    );
  }
}