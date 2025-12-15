import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.big,
            title: 'Workshop Details',
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Workshop ID',
                  supplier.id.toString(),
                  isHighlight: true,
                ),
                const Divider(),
                _buildDetailRow('Name', supplier.name, isHighlight: true),
                const Divider(),
                _buildDetailRow('Phone', supplier.phone),
                const Divider(),
                _buildDetailRow('Address', supplier.address),
                const Divider(),
                _buildDetailRow(
                  'Notes',
                  supplier.notes.isEmpty ? 'No notes provided' : supplier.notes,
                ),
                const Divider(),
                _buildDetailRow(
                  'Status',
                  supplier.isActive ? 'Active' : 'Inactive',
                  isHighlight: supplier.isActive,
                ),
                const Divider(),
                _buildDetailRow('Created At', supplier.formattedCreatedAt),
              ],
            ),
            actions: [
              PrimaryButton(
                text: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
