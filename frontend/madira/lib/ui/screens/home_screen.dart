import 'package:flutter/material.dart';
import 'package:madira/ui/screens/clients_screen.dart';
import 'package:madira/ui/screens/dashbord_screen.dart';
import 'package:madira/ui/screens/input_screen.dart';
import 'package:madira/ui/screens/order_screen.dart';
import 'package:madira/ui/screens/outputs_list_screen.dart';
import 'package:madira/ui/screens/products_screen.dart';
import 'package:madira/ui/screens/reports_screen.dart';
import 'package:madira/ui/screens/workshop_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/top_bar_widget.dart';
import '../widgets/side_bar_widget.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/responsive_helper.dart';
import '../../providers/login_provider.dart';
import 'users_screen.dart' as users_management;
import 'backup_settings_screen.dart';

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
    'Orders',
    'Clients',
    'Inputs',
    'Outputs',
    'Workshops',
    'Products',
    'Reports',
    'Users',
    'Backup Settings',
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    screens = [
      const DashboardScreen(),
      const OrdersScreen(),
      const ClientsScreen(),
      const InputsScreen(),
      const OutputsListScreen(),
      const WorkshopsScreen(),
      const ProductsScreen(),
      const ReportsScreen(),
      const users_management.UsersScreen(),
      const BackupSettingsScreen(),
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
