import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/addinventoryscreen.dart';
import 'package:snow_trading_cool/screens/challan_screen.dart';
import 'package:snow_trading_cool/screens/create_customer_screen.dart';
import 'package:snow_trading_cool/screens/login_screen.dart';
import 'package:snow_trading_cool/screens/passbook_screen.dart';
import 'package:snow_trading_cool/screens/profile_screen.dart';
import 'package:snow_trading_cool/screens/view_challan.dart';
import 'package:snow_trading_cool/screens/view_customer_screen.dart';
import 'package:snow_trading_cool/services/logout_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/secure_storage.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import 'package:snow_trading_cool/widgets/logout_animation.dart';
import 'package:snow_trading_cool/widgets/version.dart';

class ShowSideMenu extends StatefulWidget {
  const ShowSideMenu({super.key});

  @override
  State<ShowSideMenu> createState() => _ShowSideMenuState();
}

class _ShowSideMenuState extends State<ShowSideMenu> {
  final LogoutApi _logoutApi = LogoutApi();

  bool _isLoggingOut = false;
  bool _showCustomerSubMenu = false;
  bool _showChallanSubMenu = false;
  String _userRole = 'Employee';
  bool _showCreateChallanSubMenu = false;

  late bool isAdmin = _userRole == 'ADMIN';
  bool canManageSetting = TokenManager().canManageSetting;
  bool canManagePassbook = TokenManager().canManagePassbook;
  bool canCreateCustomer = TokenManager().canCreateCustomer;
  bool canManageCustomer = TokenManager().canManageCustomer;
  bool canManageChallan = TokenManager().canManageChallan;
  bool canManageGoodsItem = TokenManager().canManageGoodsItem;
  String _appVersion = 'v ?.?.?'; // Initial placeholder
  bool _versionLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadAppVersion();
  }

  void _loadUserRole() {
    final savedRole = TokenManager().getRole();
    _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
    debugPrint('User Role Loaded: $_userRole');
    setState(() {});
  }

  Future<void> _loadAppVersion() async {
    final version = await AppVersion.getAppVersion();
    if (mounted) {
      setState(() {
        _appVersion = version;
        _versionLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final panelWidth = isMobile
        ? screenWidth * 0.75
        : (screenWidth * 0.47).clamp(260.0, screenWidth);

    log("can Manage Customer:   ${canManageSetting.toString()}");
    log("can Manage Passbook:   ${canManagePassbook.toString()}");
    log("can Create Customer:   ${canCreateCustomer.toString()}");
    log("can Manage Customer:   ${canManageCustomer.toString()}");
    log("can Manage Challan:   ${canManageChallan.toString()}");
    log("can Manage Goods Item:   ${canManageGoodsItem.toString()}");

    return AnimatedBuilder(
      animation: ModalRoute.of(context)!.animation!,
      builder: (context, child) {
        final animation = ModalRoute.of(context)!.animation!;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.only(
                // topLeft: ,
                bottomRight: Radius.circular(isMobile ? 20 : 30),
                topRight: Radius.circular(isMobile ? 20 : 30),
              ), // Radius for professional look
              child: SizedBox(
                width: panelWidth,
                height: double.infinity,
                child: SafeArea(
                  child: StatefulBuilder(
                    builder: (context, setStateDialog) {
                      // final isAdmin = _userRole == 'ADMIN';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Professional Header with Logo centered & Name below left-aligned (responsive)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(isMobile ? 20 : 30),
                                bottomRight: Radius.circular(isMobile ? 20 : 30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Logo centered at top
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 20 : 30,
                                    ),
                                    child: Image.asset(
                                      'assets/images/logo.jpg',
                                      width: isMobile ? 50 : 80,
                                      height: isMobile ? 50 : 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: isMobile ? 50 : 80,
                                                height: isMobile ? 50 : 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.business,
                                                  color: Colors.grey[600],
                                                  size: isMobile ? 30 : 40,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Name below, left-aligned
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SnowCool Trading Co.',
                                        style: GoogleFonts.inter(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (canManageChallan || isAdmin)
                                    ListTile(
                                      title: const Text('Challan'),
                                      trailing: Icon(
                                        _showChallanSubMenu
                                            ? Icons.keyboard_arrow_down_rounded
                                            : Icons.arrow_forward_ios,
                                        color: AppColors.accentBlue,
                                      ),
                                      onTap: () => setStateDialog(() {
                                        _showChallanSubMenu =
                                            !_showChallanSubMenu;
                                        if (!_showChallanSubMenu) {
                                          _showCreateChallanSubMenu = false;
                                        }
                                      }),
                                    ),

                                  if (_showChallanSubMenu) ...[
                                    ListTile(
                                      leading: const SizedBox(
                                        width: 1,
                                      ), // Indent alignment
                                      title: const Text('Challan Entry'),
                                      trailing: Icon(
                                        _showCreateChallanSubMenu
                                            ? Icons.remove
                                            : Icons.add,
                                        // size: 20,
                                        color: AppColors.accentBlue,
                                      ),
                                      dense: true,
                                      onTap: () => setStateDialog(() {
                                        _showCreateChallanSubMenu =
                                            !_showCreateChallanSubMenu;
                                      }),
                                    ),

                                    if (_showCreateChallanSubMenu) ...[
                                      _subMenu('        Delivered Entry', () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const ChallanScreen(
                                              mode: ChallanMode.delivered,
                                            ),
                                          ),
                                        );
                                      }),
                                      _subMenu('        Received Entry', () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const ChallanScreen(
                                              mode: ChallanMode.received,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],

                                    // View Challan (separate item)
                                    _subMenu('    View Challan', () {
                                      Navigator.pop(context);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ViewChallanScreen(
                                                type: 'All',
                                              ),
                                        ),
                                      );
                                    }),
                                  ],

                                  ///////////////////////////
                                  const Divider(height: 1),
                                  if (canManageCustomer ||
                                      canCreateCustomer ||
                                      isAdmin)
                                    ListTile(
                                      title: const Text('Customers'),
                                      trailing: Icon(
                                        _showCustomerSubMenu
                                            ? Icons.keyboard_arrow_down_rounded
                                            : Icons.arrow_forward_ios,
                                        color: const Color(0xFF008CC0),
                                      ),
                                      onTap: () => setStateDialog(
                                        () => _showCustomerSubMenu =
                                            !_showCustomerSubMenu,
                                      ),
                                    ),
                                  if (_showCustomerSubMenu) ...[
                                    if (canCreateCustomer || isAdmin)
                                      _subMenu('    Create Customer', () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CreateCustomerScreen(),
                                          ),
                                        );
                                      }),
                                    if (canManageCustomer || isAdmin)
                                      _subMenu('    View Customers', () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ViewCustomerScreenFixed(),
                                          ),
                                        );
                                      }),
                                  ],
                                  const Divider(height: 1),
                                  if ((!isAdmin && canManagePassbook) ||
                                      isAdmin)
                                    ListTile(
                                      title: const Text('View Passbook'),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF008CC0),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PassBookScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  const Divider(height: 1),
                                  if ((!isAdmin && canManageGoodsItem) ||
                                      isAdmin)
                                    ListTile(
                                      tileColor: Colors.white,
                                      // enabled: isAdmin,
                                      title: Text('Items/Goods'),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF008CC0),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const Addinventoryscreen(),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // const Spacer(),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Logout takes most space
                                    Expanded(
                                      child: ListTile(
                                        title: const Text(
                                          'Logout',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        leading: const Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                        ),
                                        onTap: () async {
                                          _showLogoutConfirmation(context);
                                        },
                                      ),
                                    ),
                                    if (canManageSetting || isAdmin)
                                      if (isMobile)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.settings,
                                            size: 28,
                                            color: Colors.black,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ProfileScreen(),
                                              ),
                                            );
                                          },
                                        )
                                      else
                                        Expanded(
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.settings,
                                              color: Colors.black,
                                            ),
                                            title: const Text('Settings'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ProfileScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            "Design & Developed by Zerlak Technology",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          //       Text(
                                          //   "Version : 1.0.11",
                                          //   style: GoogleFonts.inter(
                                          //     fontSize: 12,
                                          //     color: Colors.grey,
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                    Image.asset(
                                      "assets/images/zerlak_logo.jpg",
                                      height: 30,
                                      // width: 30,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _appVersion,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(width: 30),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _subMenu(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        bottom: 4,
      ), // Indent for submenu, professional spacing
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
        ),
        onTap: onTap,
        dense: true, // Compact for pro look
      ),
    );
  }

  // bool _isLoggingOut = false; // Add this in your State class

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => !_isLoggingOut, // Prevent close during logout
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 20,
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);

                      await _handleLogoutWithAnimation(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // bool _isLoggingOut = false;

  Future<void> _handleLogoutWithAnimation(BuildContext context) async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    // Show full-screen animated overlay
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Logging out",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: const LogoutAnimationScreen(),
          ),
        );
      },
    );

    // Small delay for animation to feel smooth
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Get the current token
      final token = TokenManager().getToken();

      // Call the logout API
      final logoutResponse = await _logoutApi.logout(token);

      debugPrint(
        'Logout API Response: ${logoutResponse.success} - ${logoutResponse.message}',
      );

      // Even if API fails (timeout, network issue), we proceed with local logout for security
      // (which your LogoutApi already handles gracefully by returning success=true in such cases)
    } catch (e) {
      debugPrint('Exception during logout API call: $e');
      // No need to block logout - security first
    }

    // Always clear local data regardless of API result
    await SecureStorage().logout();
    TokenManager().logout();

    if (!context.mounted) return;

    // Navigate to login screen
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );

    showSuccessToast(context, "Logged out successfully");

    // Reset loading state (in case of future use)
    if (mounted) {
      setState(() => _isLoggingOut = false);
    }
  }
}
