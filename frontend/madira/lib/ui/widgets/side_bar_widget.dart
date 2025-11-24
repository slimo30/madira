import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/ui/screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/login_provider.dart';

class SideBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isAdmin;

  const SideBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);

    return Container(
      width: 240,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Navigation Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation Label
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'NAVIGATION',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Main Navigation Items
                  // Index 0: Dashboard
                  _buildSidebarItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    title: 'Dashboard',
                  ),

                  // Index 1: Orders (Was 2)
                  _buildSidebarItem(
                    index: 1,
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    title: 'Orders',
                  ),

                  // Index 2: Clients (Was 3)
                  _buildSidebarItem(
                    index: 2,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    title: 'Clients',
                  ),

                  // Index 3: Inputs (Currently hidden in your code, but occupies index 3 in HomeScreen list)
                  // If you want to show it, uncomment below:
                  _buildSidebarItem(
                    index: 3,
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    title: 'Inputs',
                  ),

                  // Index 4: Outputs (Was 5)
                  _buildSidebarItem(
                    index: 4,
                    icon: Icons.output_outlined,
                    activeIcon: Icons.output,
                    title: 'Outputs',
                  ),

                  // Index 5: Workshops (Was 6)
                  _buildSidebarItem(
                    index: 5,
                    icon: Icons.factory_outlined,
                    activeIcon: Icons.factory,
                    title: 'Workshops',
                  ),

                  // Index 6: Products (Was 7)
                  _buildSidebarItem(
                    index: 6,
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2,
                    title: 'Products',
                  ),

                  // Index 7: Reports (Was 9)
                  _buildSidebarItem(
                    index: 7,
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics,
                    title: 'Reports',
                  ),

                  // Admin Section
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(
                        color: AppColors.surfaceVariant,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        'ADMINISTRATION',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Index 8: Users (Was 10 - THIS CAUSED THE ERROR)
                    _buildSidebarItem(
                      index: 8,
                      icon: Icons.admin_panel_settings_outlined,
                      activeIcon: Icons.admin_panel_settings,
                      title: 'Users',
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Logout Button at Bottom
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.surfaceVariant, width: 1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () async {
                  await loginProvider.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
  }) {
    final isActive = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border:
                  isActive
                      ? Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      )
                      : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
