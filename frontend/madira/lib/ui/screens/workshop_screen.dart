import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../models/supplier_model.dart';
import '../../providers/supplier_provider.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dialog_widget.dart';
import '../widgets/responsive_table_widget.dart';

class WorkshopsScreen extends StatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  State<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supplierProvider = Provider.of<SupplierProvider>(
        context,
        listen: false,
      );
      // Reset search in provider
      supplierProvider.searchSuppliers('');
      supplierProvider.fetchSuppliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 1.3,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error State - Display at TOP
              Consumer<SupplierProvider>(
                builder: (context, supplierProvider, _) {
                  if (supplierProvider.error != null) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error: ${supplierProvider.error}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedCustomButton(
                            text: 'Retry',
                            onPressed: () => supplierProvider.fetchSuppliers(),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Page Header with New Workshop Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workshops Management',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your fabrication workshops (Ateliers de Fabrication)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  PrimaryButton(
                    size: ButtonSize.medium,
                    text: 'New Workshop',
                    onPressed: () {
                      _showCreateWorkshopDialog(context);
                    },
                    icon: const Icon(
                      Icons.add_business,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search Input
              SearchInputWidget(
                controller: _searchController,
                hintText: 'Search by name, phone, or address...',
                onChanged: (value) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      context.read<SupplierProvider>().searchSuppliers(value);
                    }
                  });
                },
              ),

              const SizedBox(height: 32),

              // Workshops Table with Pagination
              Consumer<SupplierProvider>(
                builder: (context, supplierProvider, _) {
                  if (supplierProvider.isLoading) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }

                  if (supplierProvider.suppliers.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.factory_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Workshops Found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            supplierProvider.searchQuery.isNotEmpty
                                ? 'No workshops match your search criteria'
                                : 'Create your first workshop to get started',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final activeSuppliers =
                      supplierProvider.suppliers
                          .where((s) => s.isActive)
                          .toList();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Workshops Section
                      if (activeSuppliers.isNotEmpty) ...[
                        Text(
                          'Active Workshops (${activeSuppliers.length})',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ResponsiveTable(
                          columns: [
                            'Name',
                            'Phone',
                            'Address',
                            'Notes',
                            'Created',
                            'Actions',
                          ],
                          minColumnWidth: 100,
                          rows:
                              activeSuppliers
                                  .map(
                                    (supplier) => _buildWorkshopRow(
                                      context,
                                      supplier,
                                      supplierProvider,
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Pagination Controls
                      _PaginationControls(supplierProvider: supplierProvider),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWorkshopRow(
    BuildContext context,
    SupplierModel supplier,
    SupplierProvider supplierProvider,
  ) {
    return [
      // Name
      Text(
        supplier.name,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Phone
      Text(
        supplier.phone.isEmpty ? '-' : supplier.phone,
        style: GoogleFonts.inter(fontSize: 12),
      ),
      // Address
      Text(
        supplier.address.isEmpty ? '-' : supplier.address,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Notes
      Text(
        supplier.notes.isEmpty ? '-' : supplier.notes,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Created Date
      Text(supplier.formattedCreatedAt, style: GoogleFonts.inter(fontSize: 12)),
      // Actions
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 16),
            color: AppColors.primary,
            tooltip: 'View',
            onPressed: () {
              _showWorkshopDetailDialog(context, supplier);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: AppColors.info,
            tooltip: 'Edit',
            onPressed: () {
              _showEditWorkshopDialog(context, supplier, supplierProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.block, size: 16),
            color: AppColors.warning,
            tooltip: 'Deactivate',
            onPressed: () {
              _showDeactivateConfirm(context, supplier, supplierProvider);
            },
          ),
        ],
      ),
    ];
  }

  void _showCreateWorkshopDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            title: 'New Workshop',
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomInputWidget(
                  controller: nameController,
                  labelText: 'Workshop Name',
                  hintText: 'Enter workshop name',
                  prefixIcon: const Icon(Icons.business),
                  required: true,
                ),
                const SizedBox(height: 16),
                PhoneInputWidget(
                  controller: phoneController,
                  labelText: 'Phone',
                  required: true,
                ),
                const SizedBox(height: 16),
                CustomInputWidget(
                  controller: addressController,
                  labelText: 'Address',
                  hintText: 'Enter workshop address',
                  prefixIcon: const Icon(Icons.location_on),
                  required: true,
                ),
                const SizedBox(height: 16),
                CustomInputWidget(
                  controller: notesController,
                  labelText: 'Notes',
                  hintText: 'Enter any notes (optional)',
                  prefixIcon: const Icon(Icons.notes),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              OutlinedCustomButton(
                text: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Create',
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please fill in all required fields',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    final supplierProvider = Provider.of<SupplierProvider>(
                      context,
                      listen: false,
                    );
                    await supplierProvider.createSupplier(
                      name: nameController.text,
                      phone: phoneController.text,
                      address: addressController.text,
                      notes: notesController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Workshop created successfully',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showEditWorkshopDialog(
    BuildContext context,
    SupplierModel supplier,
    SupplierProvider supplierProvider,
  ) {
    final nameController = TextEditingController(text: supplier.name);
    final phoneController = TextEditingController(text: supplier.phone);
    final addressController = TextEditingController(text: supplier.address);
    final notesController = TextEditingController(text: supplier.notes);

    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            title: 'Edit Workshop',
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomInputWidget(
                  controller: nameController,
                  labelText: 'Workshop Name',
                  hintText: 'Enter workshop name',
                  prefixIcon: const Icon(Icons.business),
                  required: true,
                ),
                const SizedBox(height: 16),
                PhoneInputWidget(
                  controller: phoneController,
                  labelText: 'Phone',
                  required: true,
                ),
                const SizedBox(height: 16),
                CustomInputWidget(
                  controller: addressController,
                  labelText: 'Address',
                  hintText: 'Enter workshop address',
                  prefixIcon: const Icon(Icons.location_on),
                  required: true,
                ),
                const SizedBox(height: 16),
                CustomInputWidget(
                  controller: notesController,
                  labelText: 'Notes',
                  hintText: 'Enter any notes (optional)',
                  prefixIcon: const Icon(Icons.notes),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              OutlinedCustomButton(
                text: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Update',
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      phoneController.text.isEmpty ||
                      addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please fill in all required fields',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    await supplierProvider.updateSupplier(
                      supplier.id,
                      name: nameController.text,
                      phone: phoneController.text,
                      address: addressController.text,
                      notes: notesController.text,
                      isActive: supplier.isActive,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Workshop updated successfully',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showWorkshopDetailDialog(BuildContext context, SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (context) => WorkshopDetailsDialog(supplier: supplier),
    );
  }

  void _showDeactivateConfirm(
    BuildContext context,
    SupplierModel supplier,
    SupplierProvider supplierProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Deactivate Workshop',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to deactivate ${supplier.name}?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              OutlinedCustomButton(
                text: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Deactivate',
                onPressed: () async {
                  try {
                    await supplierProvider.deactivateSupplier(supplier.id);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Workshop deactivated successfully',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }
}

class WorkshopDetailsDialog extends StatefulWidget {
  final SupplierModel supplier;

  const WorkshopDetailsDialog({super.key, required this.supplier});

  @override
  State<WorkshopDetailsDialog> createState() => _WorkshopDetailsDialogState();
}

class _WorkshopDetailsDialogState extends State<WorkshopDetailsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<dynamic>? _orders;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supplierProvider = Provider.of<SupplierProvider>(
        context,
        listen: false,
      );
      final data = await supplierProvider.getSupplierSummary(
        widget.supplier.id,
      );

      if (mounted) {
        setState(() {
          _stats = data['stats'];
          _orders = data['orders'] as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.92,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Retry',
                        onPressed: _fetchData,
                        size: ButtonSize.small,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildInfoCards(),
              const SizedBox(height: 16),
              _buildWorkshopInfoSection(),
              const SizedBox(height: 16),
              _buildTabBar(),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildPaymentsTab()],
                ),
              ),
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.supplier.name,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'ID: ${widget.supplier.id} • WORKSHOP',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:
                widget.supplier.isActive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  widget.supplier.isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
            ),
          ),
          child: Text(
            widget.supplier.isActive ? 'ACTIVE' : 'INACTIVE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color:
                  widget.supplier.isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.pop(context),
          color: AppColors.textSecondary,
          splashRadius: 20,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    if (_stats == null) return const SizedBox();
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Paid (Output)',
            NumberFormat.currency(
              symbol: 'DZD ',
              decimalDigits: 0,
            ).format(_stats!['total_paid']),
            AppColors.primary, // Changed to Primary (Red) for Output
            icon: Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Transactions',
            _stats!['transaction_count'].toString(),
            AppColors.secondary,
            icon: Icons.receipt_long,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshopInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          if (widget.supplier.phone.isNotEmpty) ...[
            _buildInfoItem(
              Icons.phone,
              'Phone',
              widget.supplier.phone,
              isCopyable: true,
            ),
            const SizedBox(width: 20),
          ],
          if (widget.supplier.address.isNotEmpty) ...[
            Expanded(
              child: _buildInfoItem(
                Icons.location_on,
                'Address',
                widget.supplier.address,
                isCopyable: true,
              ),
            ),
            const SizedBox(width: 20),
          ],
          if (widget.supplier.notes.isNotEmpty) ...[
            Expanded(
              child: _buildInfoItem(
                Icons.notes,
                widget.supplier.notes,
                widget.supplier.notes,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return InkWell(
      onTap:
          isCopyable
              ? () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $label to clipboard'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    width: 200,
                  ),
                );
              }
              : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isCopyable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy,
                          size: 10,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [Tab(text: 'Payment History')],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (_orders == null || _orders!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No payments found',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _orders!.length,
      itemBuilder: (context, index) {
        final orderData = _orders![index];
        return _buildOrderGroup(orderData);
      },
    );
  }

  Widget _buildOrderGroup(Map<String, dynamic> orderData) {
    final payments = orderData['payments'] as List;
    final isMisc = orderData['order_number'] == 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          backgroundColor: AppColors.surface,
          collapsedBackgroundColor: AppColors.surface,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isMisc
                          ? AppColors.secondary.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isMisc
                      ? Icons.inventory_2_outlined
                      : Icons.shopping_bag_outlined,
                  size: 22,
                  color: isMisc ? AppColors.secondary : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMisc
                          ? 'Miscellaneous Payments'
                          : 'Order ${orderData['order_number']}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!isMisc) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            orderData['client_name'] ?? 'Unknown Client',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Paid',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                NumberFormat.currency(
                  symbol: 'DZD ',
                  decimalDigits: 0,
                ).format(orderData['total_paid']),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary, // Red for Output
                ),
              ),
            ],
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.5),
                border: Border(
                  top: BorderSide(color: AppColors.surfaceVariant),
                ),
              ),
              child: Column(
                children: [
                  // Table Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: [
                        _buildTableHeader(
                          'Date',
                          flex: 2,
                          align: TextAlign.left,
                        ),
                        _buildTableHeader(
                          'Reference',
                          flex: 3,
                          align: TextAlign.left,
                        ),
                        _buildTableHeader(
                          'Description',
                          flex: 4,
                          align: TextAlign.left,
                        ),
                        _buildTableHeader(
                          'Amount',
                          flex: 3,
                          align: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  // Payments List
                  ...payments.map<Widget>((p) => _buildPaymentRow(p)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    String text, {
    int flex = 1,
    TextAlign align = TextAlign.center,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        textAlign: align,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant.withOpacity(0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat(
                    'dd MMM yyyy',
                  ).format(DateTime.parse(payment['date'])),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Reference
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Text(
                payment['reference'] ?? '-',
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Description
          Expanded(
            flex: 4,
            child: Text(
              payment['description']?.toString().isNotEmpty == true
                  ? payment['description']
                  : '-',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle:
                    payment['description']?.toString().isNotEmpty == true
                        ? FontStyle.normal
                        : FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Amount
          Expanded(
            flex: 3,
            child: Text(
              '- ${NumberFormat.currency(symbol: 'DZD ', decimalDigits: 0).format(payment['amount'])}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary, // Red for Output
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Close',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// Pagination Controls Widget
class _PaginationControls extends StatelessWidget {
  final SupplierProvider supplierProvider;

  const _PaginationControls({required this.supplierProvider});

  @override
  Widget build(BuildContext context) {
    if (supplierProvider.totalPages <= 1) return Container();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${supplierProvider.currentPage} of ${supplierProvider.totalPages} '
            '(${supplierProvider.totalCount} total workshops)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed:
                    supplierProvider.currentPage > 1
                        ? () => supplierProvider.goToPage(1)
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    supplierProvider.hasPreviousPage
                        ? () => supplierProvider.previousPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              const SizedBox(width: 8),
              ...List.generate(
                supplierProvider.totalPages > 5
                    ? 5
                    : supplierProvider.totalPages,
                (index) {
                  int pageNum;
                  if (supplierProvider.totalPages <= 5) {
                    pageNum = index + 1;
                  } else {
                    if (supplierProvider.currentPage <= 3) {
                      pageNum = index + 1;
                    } else if (supplierProvider.currentPage >=
                        supplierProvider.totalPages - 2) {
                      pageNum = supplierProvider.totalPages - 4 + index;
                    } else {
                      pageNum = supplierProvider.currentPage - 2 + index;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: () => supplierProvider.goToPage(pageNum),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            pageNum == supplierProvider.currentPage
                                ? AppColors.primary
                                : Colors.transparent,
                        foregroundColor:
                            pageNum == supplierProvider.currentPage
                                ? Colors.white
                                : AppColors.textPrimary,
                        minimumSize: const Size(36, 36),
                      ),
                      child: Text(
                        '$pageNum',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    supplierProvider.hasNextPage
                        ? () => supplierProvider.nextPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed:
                    supplierProvider.currentPage < supplierProvider.totalPages
                        ? () => supplierProvider.goToPage(
                          supplierProvider.totalPages,
                        )
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Detail Row Widget
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
