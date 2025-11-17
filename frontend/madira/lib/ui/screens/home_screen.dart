import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/ui/screens/clients_screen.dart';
import 'package:madira/ui/screens/dashbord_screen.dart';
import 'package:madira/ui/screens/input_screen.dart';
import 'package:madira/ui/screens/order_screen.dart';
import 'package:madira/ui/screens/outputs_list_screen.dart';
import 'package:madira/ui/screens/products_screen.dart';
import 'package:madira/ui/screens/workshop_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/top_bar_widget.dart';
import '../widgets/side_bar_widget.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../providers/login_provider.dart';
import 'users_screen.dart' as users_management;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  // List of screens for navigation
  late final List<Widget> screens;

  // List of screen titles
  final List<String> screenTitles = [
    'Dashboard',
    'Projects',
    'Orders',
    'Clients',
    'Inputs',
    'Outputs',
    'Workshops',
    'Products',
    'Inventory',
    'Reports',
    'Users',
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    screens = [
      const DashboardScreen(),
      const ProjectsScreen(),
      const OrdersScreen(),
      const ClientsScreen(),
      const InputsScreen(),
      const OutputsListScreen(),
      const WorkshopsScreen(),
      const ProductsScreen(),
      const InventoryScreen(),
      const ReportsScreen(),
      const users_management.UsersScreen(),
    ];
  }

  void onItemSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);

    return Scaffold(
      appBar: TopBarWidget(title: screenTitles[selectedIndex]),
      body: Row(
        children: [
          SideBarWidget(
            selectedIndex: selectedIndex,
            onItemSelected: onItemSelected,
            isAdmin: loginProvider.user?.role == 'admin',
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = ResponsiveHelper.getResponsivePadding(context);
                return Container(
                  color: AppColors.background,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: screens[selectedIndex],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Simple, clean placeholder screens
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSimplePlaceholder(
      title: 'Projects',
      subtitle: 'Manage your kitchen fabrication projects',
      icon: Icons.construction,
      description:
          'This section will help you manage all your kitchen fabrication projects, track progress, and coordinate with your team.',
      features: [
        'Track project milestones and deadlines',
        'Manage project budgets and expenses',
        'Coordinate with team members',
        'Monitor project progress in real-time',
      ],
    );
  }
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSimplePlaceholder(
      title: 'Inventory',
      subtitle: 'Track materials and supplies',
      icon: Icons.inventory,
      description:
          'Monitor your material stock levels, track usage, and manage supplier relationships.',
      features: [
        'Track stock levels in real-time',
        'Set low stock alerts',
        'Manage supplier information',
        'Record material usage per project',
      ],
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSimplePlaceholder(
      title: 'Reports',
      subtitle: 'View analytics and generate reports',
      icon: Icons.analytics,
      description:
          'Generate business reports, view performance analytics, and track your company growth.',
      features: [
        'Financial reports and summaries',
        'Project performance analytics',
        'Client activity reports',
        'Export data to PDF and Excel',
      ],
    );
  }
}

Widget _buildSimplePlaceholder({
  required String title,
  required String subtitle,
  required IconData icon,
  required String description,
  required List<String> features,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Main Content Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                // Icon Container
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 32),

                // Coming Soon Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                SizedBox(
                  width: 600,
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Features Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Upcoming Features',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...features.map((feature) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.info),
                      const SizedBox(width: 12),
                      Text(
                        'This feature is under development and will be available soon.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
