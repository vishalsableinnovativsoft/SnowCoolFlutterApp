import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snow_trading_cool/screens/profile_screen.dart';
import 'package:snow_trading_cool/screens/view_customer_screen.dart';
import 'package:snow_trading_cool/screens/view_user_screen.dart';
import 'package:snow_trading_cool/services/challan_api.dart';
import 'package:snow_trading_cool/services/goods_api.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/screens/view_challan.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';
import 'package:snow_trading_cool/widgets/drawer.dart';
import '../services/application_settings_api.dart';
import '../services/homescreen_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'Employee';
  ImageProvider? _logoImage;

  List<GoodsDTO> _allGoods = [];
  bool _goodsLoading = true;

  final GoodsApi _api = GoodsApi();

  DashboardSummary? _dashboardData;
  bool _dashboardLoading = true;

  bool _isNavigating = false;

  late final isAdmin = _userRole == 'ADMIN';
  bool canManageSettings = TokenManager().canManageSetting;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadGoods();
    _loadDashboardData();
    if (isAdmin || canManageSettings) _loadAppSettingsLogo();
  }

  Future<void> _loadGoods() async {
    setState(() => _goodsLoading = true);
    try {
      final goods = await _api.getAllGoods();
      setState(() {
        _allGoods = goods;
        _goodsLoading = false;
      });
    } catch (e) {
      setState(() => _goodsLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await HomeScreenApi().getDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _dashboardLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _dashboardLoading = false);
    }
  }

  void _loadUserRole() {
    final savedRole = TokenManager().getRole();
    _userRole = (savedRole?.toUpperCase() == 'ADMIN') ? 'ADMIN' : 'Employee';
    setState(() {});
  }

  Future<void> _loadAppSettingsLogo() async {
    try {
      final token = TokenManager().getToken();
      if (token == null || token.isEmpty) return;
      final api = ApplicationSettingsApi(token: token);
      final settings = await api.getSettings(context);
      if (!mounted) return;
      if (settings?.logoBase64 != null && settings!.logoBase64!.isNotEmpty) {
        final bytes = base64Decode(settings.logoBase64!);
        setState(() => _logoImage = MemoryImage(bytes));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double horizontalPadding = isMobile ? 16.0 : 24.0;
    final double cardRadius = 12.0;
    final double titleFontSize = 20.0;
    final double countFontSize = isMobile ? 22.0 : 26.0;
    final double labelFontSize = isMobile ? 14.0 : 16.0;
    final double orderCountFontSize = isMobile ? 18.0 : 22.0;
    final double orderLabelFontSize = isMobile ? 14.0 : 16.0;
    final double iconSize = isMobile ? 16.0 : 18.0;
    final double verticalGap = isMobile ? 6.0 : 8.0;
    final double sectionGap = isMobile ? 12.0 : 16.0;

    bool canManageProfile = TokenManager().canManageProfile;
    bool canManageCustomer = TokenManager().canManageCustomer;
    bool canCreateCustomer = TokenManager().canCreateCustomer;
    bool canManageChallan = TokenManager().canManageChallan;

    // Calculate total delivered & received item quantities
    final int totalDeliveredItems =
        _dashboardData?.productSummaries.fold(
          0,
          (sum, p) => sum! + (p.totalDelivered ?? 0),
        ) ??
        0;
    final int totalReceivedItems =
        _dashboardData?.productSummaries.fold(
          0,
          (sum, p) => sum! + (p.totalReceived ?? 0),
        ) ??
        0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
        elevation: 0,
        leadingWidth: isMobile ? 44 : 48,
        titleSpacing: isMobile ? 6 : 8,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
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
          if (canManageProfile || isAdmin)
            Padding(
              padding: EdgeInsets.only(right: isMobile ? 8 : 12),
              child: PopupMenuButton<String>(
                color: Colors.white,
                icon: CircleAvatar(
                  radius: isMobile ? 16 : 18,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _logoImage,
                  child: _logoImage == null
                      ? Icon(
                          Icons.person,
                          color: Colors.white,
                          size: isMobile ? 20 : 22,
                        )
                      : null,
                ),
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  } else if (value == 'view_users') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserViewScreen()),
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (canManageProfile || isAdmin)
                    const PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Profile'),
                      ),
                    ),
                  if (isAdmin)
                    const PopupMenuItem(
                      value: 'view_users',
                      child: ListTile(
                        leading: Icon(Icons.group),
                        title: Text('View Users'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      drawer: const ShowSideMenu(),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          _loadGoods(),
          _loadDashboardData(),
          if (isAdmin || canManageSettings || canManageProfile)
            _loadAppSettingsLogo(),
        ]),
        color: AppColors.accentBlue,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: verticalGap),
                        Text(
                          'Total Inventory',
                          style: GoogleFonts.inter(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF515151),
                          ),
                        ),
                        SizedBox(height: verticalGap),

                        Row(
                          children: [
                            // LEFT: Total Delivered Items
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color.fromRGBO(0, 140, 192, 1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _dashboardLoading
                                                ? '—'
                                                : totalDeliveredItems
                                                      .toString(),
                                            style: GoogleFonts.inter(
                                              fontSize: isMobile ? 28 : 32,
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromRGBO(
                                                0,
                                                140,
                                                192,
                                                1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Delivered Items',
                                            style: GoogleFonts.inter(
                                              fontSize: isMobile ? 16 : 18,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.outbox_rounded,
                                      size: 40,
                                      color: Color.fromRGBO(0, 140, 192, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // RIGHT: Total Received Items
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color.fromRGBO(0, 140, 192, 1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _dashboardLoading
                                                ? '—'
                                                : totalReceivedItems.toString(),
                                            style: GoogleFonts.inter(
                                              fontSize: isMobile ? 28 : 32,
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromRGBO(
                                                0,
                                                140,
                                                192,
                                                1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Received Items',
                                            style: GoogleFonts.inter(
                                              fontSize: isMobile ? 16 : 18,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.move_to_inbox_rounded,
                                      size: 40,
                                      color: Color.fromRGBO(0, 140, 192, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: sectionGap),
                        _buildProductsTable(),

                        SizedBox(height: sectionGap),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        SizedBox(height: sectionGap),

                        Text(
                          'Customers',
                          style: GoogleFonts.inter(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF515151),
                          ),
                        ),
                        SizedBox(height: verticalGap),
                        GestureDetector(
                          onTap: () => canManageCustomer || isAdmin
                              ? Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ViewCustomerScreenFixed(),
                                  ),
                                )
                              : null,
                          child: Container(
                            height: isMobile ? 56 : 64,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(cardRadius),
                              border: Border.all(
                                color: const Color.fromRGBO(0, 140, 192, 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _dashboardLoading
                                              ? '—'
                                              : (_dashboardData?.totalCustomers
                                                        .toString() ??
                                                    '0'),
                                          style: GoogleFonts.inter(
                                            fontSize: countFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromRGBO(
                                              0,
                                              140,
                                              192,
                                              1,
                                            ),
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
                                  color: const Color.fromRGBO(0, 140, 192, 1),
                                  size: iconSize,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: sectionGap),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        SizedBox(height: sectionGap),

                        if ((!isAdmin && canManageChallan) || isAdmin)
                          Text(
                            'Orders/Challans',
                            style: GoogleFonts.inter(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF515151),
                            ),
                          ),
                        SizedBox(height: verticalGap),
                        if (canManageChallan || isAdmin)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    setState(() => _isNavigating = true);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ViewChallanScreen(type: "received"),
                                      ),
                                    );
                                    if (mounted) {
                                      setState(() => _isNavigating = false);
                                    }
                                  },
                                  child: _buildOrderCard(
                                    _dashboardLoading
                                        ? '—'
                                        : (_dashboardData?.totalReceivedChallans
                                                  .toString() ??
                                              '0'),
                                    'Received',
                                    orderCountFontSize,
                                    orderLabelFontSize,
                                    cardRadius,
                                    isMobile,
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 10 : 14),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    setState(() => _isNavigating = true);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ViewChallanScreen(
                                          type: "Delivered",
                                        ),
                                      ),
                                    );
                                    if (mounted) {
                                      setState(() => _isNavigating = false);
                                    }
                                  },
                                  child: _buildOrderCard(
                                    _dashboardLoading
                                        ? '—'
                                        : (_dashboardData
                                                  ?.totalDeliveredChallans
                                                  .toString() ??
                                              '0'),
                                    'Delivered',
                                    orderCountFontSize,
                                    orderLabelFontSize,
                                    cardRadius,
                                    isMobile,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_isNavigating || _goodsLoading || _dashboardLoading)
              customLoader(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable() {
    final products = _dashboardData?.productSummaries ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB3E0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmallScreen = constraints.maxWidth < 500;
            return Table(
              defaultColumnWidth: const FlexColumnWidth(),
              columnWidths: isSmallScreen
                  ? const {
                      0: FlexColumnWidth(1.8),
                      1: FlexColumnWidth(1.7),
                      2: FlexColumnWidth(1.7),
                    }
                  : const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(1.5),
                    },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFB3E0F2)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      child: Text(
                        "Products",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _headerCell("Delivered"),
                    _headerCell("Received"),
                  ],
                ),
                ...products
                    .map(
                      (p) => TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: isSmallScreen ? 8 : 12,
                            ),
                            child: Text(
                              p.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: isSmallScreen ? 8 : 12,
                            ),
                            child: Text(
                              p.totalDelivered.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: isSmallScreen ? 8 : 12,
                            ),
                            child: Text(
                              p.totalReceived.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
                if (products.isEmpty && !_dashboardLoading)
                  TableRow(
                    children: [
                      const SizedBox(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            "No data available",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      // const SizedBox(),
                      const SizedBox(),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _headerCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
    ),
  );

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
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color.fromRGBO(0, 140, 192, 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
            color: const Color.fromRGBO(0, 140, 192, 1),
            size: isMobile ? 16 : 18,
          ),
        ],
      ),
    );
  }
}
