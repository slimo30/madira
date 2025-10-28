import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaderaKitchenApp());
}

// ============================================================================
// COLORS - Logo-Based Palette
// ============================================================================
class AppColors {
  static const Color primary = Color(0xFFD32F2F);
  static const Color primaryLight = Color(0xFFE57373);
  static const Color secondary = Color(0xFF37474F);
  static const Color secondaryLight = Color(0xFF546E7A);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFECEFF1);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFF8F00);
  static const Color info = Color(0xFF1976D2);
}

// ============================================================================
// RESPONSIVE HELPER (Desktop Only)
// ============================================================================
class ResponsiveHelper {
  // Compact desktop (small monitors, windowed mode)
  static bool isCompactDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024 &&
      MediaQuery.of(context).size.width < 1440;

  // Standard desktop (normal monitors)
  static bool isStandardDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1440 &&
      MediaQuery.of(context).size.width < 1920;

  // Large desktop (wide monitors)
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1920;

  static double getResponsivePadding(BuildContext context) {
    if (isCompactDesktop(context)) return 24;
    if (isStandardDesktop(context)) return 32;
    return 40;
  }

  static int getGridColumns(BuildContext context) {
    if (isCompactDesktop(context)) return 2;
    if (isStandardDesktop(context)) return 4;
    return 4;
  }

  static double getSidebarWidth(BuildContext context) {
    if (isCompactDesktop(context)) return 220;
    return 260;
  }

  static double getFontSize(BuildContext context, double baseSize) {
    if (isCompactDesktop(context)) return baseSize * 0.95;
    if (isLargeDesktop(context)) return baseSize * 1.05;
    return baseSize;
  }
}

// ============================================================================
// MAIN APP
// ============================================================================
class MaderaKitchenApp extends StatelessWidget {
  const MaderaKitchenApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Madera Kitchen Fabrication',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppColors.surface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.surfaceVariant,
          thickness: 1,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ============================================================================
// DASHBOARD SCREEN
// ============================================================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = ResponsiveHelper.getResponsivePadding(context);
                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeader(),
                      const SizedBox(height: 32),
                      const _StatsSection(),
                      const SizedBox(height: 32),
                      const _OrdersSection(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'M',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('MADERA Kitchen Fabrication'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {},
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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

// ============================================================================
// SIDEBAR
// ============================================================================
class _Sidebar extends StatelessWidget {
  const _Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = ResponsiveHelper.getSidebarWidth(context);

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.surfaceVariant)),
      ),
      child: const SingleChildScrollView(child: _SidebarContent()),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 8),
        _SidebarItem(icon: Icons.dashboard, title: 'Dashboard', isActive: true),
        _SidebarItem(icon: Icons.shopping_cart, title: 'Orders'),
        _SidebarItem(icon: Icons.kitchen, title: 'Production'),
        _SidebarItem(icon: Icons.inventory_2, title: 'Materials'),
        _SidebarItem(icon: Icons.people, title: 'Clients'),
        _SidebarItem(icon: Icons.precision_manufacturing, title: 'Machines'),
        _SidebarItem(icon: Icons.analytics, title: 'Analytics'),
        Divider(),
        _SidebarItem(icon: Icons.settings, title: 'Settings'),
        _SidebarItem(icon: Icons.help_outline, title: 'Help'),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;

  const _SidebarItem({
    Key? key,
    required this.icon,
    required this.title,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

// ============================================================================
// PAGE HEADER
// ============================================================================
class _PageHeader extends StatelessWidget {
  const _PageHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Production Dashboard',
              style: GoogleFonts.inter(
                fontSize: ResponsiveHelper.getFontSize(context, 28),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monitor fabrication orders and production status',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download, size: 18),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: BorderSide(color: AppColors.surfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Order'),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// STATS SECTION
// ============================================================================
class _StatsSection extends StatelessWidget {
  const _StatsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveHelper.getGridColumns(context);
        final spacing = 16.0;
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _StatCard(
              title: 'Active Orders',
              value: '42',
              icon: Icons.shopping_cart_outlined,
              color: AppColors.primary,
              width: itemWidth,
            ),
            _StatCard(
              title: 'In Production',
              value: '18',
              icon: Icons.precision_manufacturing,
              color: AppColors.warning,
              width: itemWidth,
            ),
            _StatCard(
              title: 'Completed',
              value: '156',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              width: itemWidth,
            ),
            _StatCard(
              title: 'Monthly Revenue',
              value: '2,450,000 DA',
              icon: Icons.trending_up,
              color: AppColors.secondary,
              width: itemWidth,
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// STAT CARD
// ============================================================================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ORDERS SECTION
// ============================================================================
class _OrdersSection extends StatelessWidget {
  const _OrdersSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Fabrication Orders',
              style: GoogleFonts.inter(
                fontSize: ResponsiveHelper.getFontSize(context, 20),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(color: AppColors.surfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sort, size: 18),
                  label: const Text('Sort'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(color: AppColors.surfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _OrdersTable(),
      ],
    );
  }
}

// ============================================================================
// ORDERS TABLE
// ============================================================================
class _OrdersTable extends StatelessWidget {
  const _OrdersTable({Key? key}) : super(key: key);

  static const List<Map<String, String>> _orders = [
    {
      'id': 'FAB-001',
      'client': 'Residence Benali',
      'product': 'Custom Kitchen Cabinets',
      'qty': '12 units',
      'value': '450,000 DA',
      'status': 'In Production',
    },
    {
      'id': 'FAB-002',
      'client': 'Hotel El Djazair',
      'product': 'Commercial Kitchen Units',
      'qty': '8 units',
      'value': '680,000 DA',
      'status': 'Design Review',
    },
    {
      'id': 'FAB-003',
      'client': 'Villa Khelifi',
      'product': 'Wardrobe System',
      'qty': '6 units',
      'value': '320,000 DA',
      'status': 'Completed',
    },
    {
      'id': 'FAB-004',
      'client': 'Restaurant Le Gourmet',
      'product': 'Storage Cabinets',
      'qty': '15 units',
      'value': '280,000 DA',
      'status': 'Material Prep',
    },
    {
      'id': 'FAB-005',
      'client': 'Office Tower B',
      'product': 'Reception Desk',
      'qty': '1 unit',
      'value': '150,000 DA',
      'status': 'Completed',
    },
    {
      'id': 'FAB-006',
      'client': 'Boutique Saidi',
      'product': 'Display Units',
      'qty': '10 units',
      'value': '420,000 DA',
      'status': 'In Production',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.surfaceVariant),
          headingRowHeight: 52,
          dataRowHeight: 72,
          columnSpacing: 32,
          horizontalMargin: 24,
          columns: [
            DataColumn(
              label: SizedBox(
                width: 120,
                child: Text(
                  'Order ID',
                  style: _headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 150,
                child: Text(
                  'Client',
                  style: _headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 180,
                child: Text(
                  'Product',
                  style: _headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 100,
                child: Text(
                  'Quantity',
                  style: _headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 120,
                child: Text(
                  'Value',
                  style: _headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 130,
                child: Text(
                  'Status',
                  style: _headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 140,
                child: Text(
                  'Actions',
                  style: _headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          rows: _orders.map((order) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      order['id']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      order['client']!,
                      style: GoogleFonts.inter(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      order['product']!,
                      style: GoogleFonts.inter(fontSize: 14),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      order['qty']!,
                      style: GoogleFonts.inter(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      order['value']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 130,
                    child: Center(
                      child: _StatusBadge(status: order['status']!),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          color: AppColors.primary,
                          tooltip: 'View',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.primary,
                          tooltip: 'Edit',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.primary,
                          tooltip: 'Delete',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

// ============================================================================
// STATUS BADGE
// ============================================================================
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Completed':
        color = AppColors.success;
        break;
      case 'In Production':
        color = AppColors.warning;
        break;
      case 'Design Review':
        color = AppColors.info;
        break;
      case 'Material Prep':
        color = AppColors.primaryLight;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
