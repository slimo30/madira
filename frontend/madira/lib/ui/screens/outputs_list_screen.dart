//  Outputs List Screen - General outputs with CRUD operations and statistics
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/output_model.dart';
import '../../models/order_model.dart';
import '../../models/input_model.dart';
import '../../providers/output_proviider.dart';
import '../../providers/input_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/product_provider.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dropdown_widget.dart';
import '../widgets/custom_dialog_widget.dart';
import '../widgets/responsive_table_widget.dart';
import '../dialogs/output_form_dialog.dart';

class OutputsListScreen extends StatefulWidget {
  const OutputsListScreen({super.key});

  @override
  State<OutputsListScreen> createState() => _OutputsListScreenState();
}

class _OutputsListScreenState extends State<OutputsListScreen> {
  String _typeFilter = 'all';
  String _orderFilter = 'all';
  String _inputFilter = 'all';
  String _sortBy = 'date_desc';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final outputProvider = Provider.of<OutputProvider>(
        context,
        listen: false,
      );
      outputProvider.fetchOutputs();
      outputProvider.fetchStatistics();

      // Load related data for dropdowns
      Provider.of<InputProvider>(context, listen: false).fetchInputs();
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
      Provider.of<SupplierProvider>(context, listen: false).fetchSuppliers();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OutputModel> _getFilteredAndSortedOutputs(List<OutputModel> outputs) {
    var filtered = outputs;

    // Apply type filter
    if (_typeFilter != 'all') {
      filtered = filtered.where((o) => o.type == _typeFilter).toList();
    }

    // Apply order filter
    if (_orderFilter != 'all') {
      filtered =
          filtered.where((o) => o.order?.toString() == _orderFilter).toList();
    }

    // Apply input filter
    if (_inputFilter != 'all') {
      filtered =
          filtered
              .where((o) => o.sourceInput?.toString() == _inputFilter)
              .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 1.5,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Message
              Consumer<OutputProvider>(
                builder: (context, outputProvider, _) {
                  if (outputProvider.errorMessage != null) {
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
                            'Error: ${outputProvider.errorMessage}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedCustomButton(
                            text: 'Retry',
                            onPressed: () => outputProvider.fetchOutputs(),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Output Management',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track and manage all business expenses and transactions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  PrimaryButton(
                    size: ButtonSize.medium,
                    text: 'New Output',
                    onPressed: () => _showCreateOutputDialog(context),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Statistics Section
              Consumer<OutputProvider>(
                builder: (context, provider, _) {
                  if (provider.statistics == null) {
                    return const SizedBox.shrink();
                  }

                  final stats = provider.statistics!;
                  return _buildStatisticsCards(stats);
                },
              ),

              const SizedBox(height: 24),

              // Filters and Search Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: "Search",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SearchInputWidget(
                          controller: _searchController,
                          hintText: 'Search by reference or description...',
                          onChanged: (value) {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                if (_searchController.text == value) {
                                  context.read<OutputProvider>().searchOutputs(
                                    value,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdownWidget<String>(
                      labelText: 'Type',
                      value: _typeFilter,
                      required: false,
                      prefixIcon: Icons.category,
                      hintText: 'All Types',
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Types'),
                        ),
                        DropdownMenuItem(
                          value: 'withdrawal',
                          child: Text('Withdrawal'),
                        ),
                        DropdownMenuItem(
                          value: 'supplier_payment',
                          child: Text('Supplier Payment'),
                        ),
                        DropdownMenuItem(
                          value: 'consumable',
                          child: Text('Consumable'),
                        ),
                        DropdownMenuItem(
                          value: 'global_stock_purchase',
                          child: Text('Global Stock Purchase'),
                        ),
                        DropdownMenuItem(
                          value: 'client_stock_usage',
                          child: Text('Client Stock Usage'),
                        ),
                        DropdownMenuItem(
                          value: 'other_expense',
                          child: Text('Other Expense'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _typeFilter = value ?? 'all';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SearchableOrderDropdownWidget(
                      labelText: 'Order',
                      selectedId: _orderFilter,
                      onChanged: (orderId) {
                        setState(() {
                          _orderFilter = orderId;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SearchableInputDropdownWidget(
                      labelText: 'Source Input',
                      selectedId: _inputFilter,
                      onChanged: (inputId) {
                        setState(() {
                          _inputFilter = inputId;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdownWidget<String>(
                      labelText: 'Sort By',
                      value: _sortBy,
                      required: false,
                      prefixIcon: Icons.sort,
                      hintText: 'Sort By',
                      items: const [
                        DropdownMenuItem(
                          value: 'date_desc',
                          child: Text('Date (Newest)'),
                        ),
                        DropdownMenuItem(
                          value: 'date_asc',
                          child: Text('Date (Oldest)'),
                        ),
                        DropdownMenuItem(
                          value: 'amount_desc',
                          child: Text('Amount (High to Low)'),
                        ),
                        DropdownMenuItem(
                          value: 'amount_asc',
                          child: Text('Amount (Low to High)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value ?? 'date_desc';
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Outputs Table
              Consumer<OutputProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
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

                  if (provider.outputs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredOutputs = _getFilteredAndSortedOutputs(
                    provider.outputs,
                  );

                  if (filteredOutputs.isEmpty) {
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
                            Icons.filter_list_off,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Outputs Match Filters',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Calculate total amount for filtered outputs
                  double totalAmount = 0;
                  for (var output in filteredOutputs) {
                    totalAmount +=
                        double.tryParse(output.amount.toString()) ?? 0.0;
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Outputs (${filteredOutputs.length}/${provider.outputs.length})',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.payments,
                                  size: 18,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total: ${totalAmount.toStringAsFixed(2)} DA',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ResponsiveTable(
                        columns: [
                          'Reference',
                          'Type',
                          'Amount',
                          'Details',
                          'Source',
                          'Created By',
                          'Date',
                          'Actions',
                        ],
                        minColumnWidth: 160,
                        rows:
                            filteredOutputs
                                .map(
                                  (output) => _buildOutputRow(
                                    context,
                                    output,
                                    provider,
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 32),
                      _PaginationControls(outputProvider: provider),
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

  Widget _buildEmptyState() {
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
          Icon(Icons.output_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No Outputs Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first output to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Build Statistics Cards
  Widget _buildStatisticsCards(OutputStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 24,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Output Statistics',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Outputs',
                  stats.totalCount.toString(),
                  AppColors.info,
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Amount',
                  '${stats.formattedTotalAmount} DA',
                  AppColors.warning,
                  Icons.payments,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Output Types',
                  stats.byType.length.toString(),
                  AppColors.success,
                  Icons.category,
                ),
              ),
            ],
          ),
          // if (stats.byType.isNotEmpty) ...[
          //   const SizedBox(height: 24),
          //   Text(
          //     'By Type',
          //     style: GoogleFonts.inter(
          //       fontSize: 14,
          //       fontWeight: FontWeight.w600,
          //       color: AppColors.textSecondary,
          //     ),
          //   ),
          //   const SizedBox(height: 12),
          //   Wrap(
          //     spacing: 12,
          //     runSpacing: 12,
          //     children:
          //         (stats.byType.entries.toList())
          //             .map((entry) => _buildTypeChip(entry.key, entry.value))
          //             .toList(),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildTypeChip(String type, dynamic data) {
  //   // Handle both Map and individual values
  //   final count = data is Map ? (data['count'] ?? 0) : 0;
  //   final totalAmount =
  //       data is Map ? ((data['total_amount'] as num?)?.toDouble() ?? 0.0) : 0.0;

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: AppColors.primary.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: AppColors.primary.withOpacity(0.3)),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Text(
  //           type.replaceAll('_', ' ').toUpperCase(),
  //           style: GoogleFonts.inter(
  //             fontSize: 10,
  //             fontWeight: FontWeight.w600,
  //             color: AppColors.primary,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           'Count: $count | Total: ${totalAmount.toStringAsFixed(2)} DA',
  //           style: GoogleFonts.inter(
  //             fontSize: 9,
  //             color: AppColors.textSecondary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Build Output Row
  List<Widget> _buildOutputRow(
    BuildContext context,
    OutputModel output,
    OutputProvider provider,
  ) {
    // Get input details from InputProvider if source input exists
    String sourceInfo = 'N/A';
    String sourceAmount = '';

    if (output.sourceInput != null) {
      try {
        final inputProvider = context.read<InputProvider>();
        final sourceInput = inputProvider.inputs.firstWhere(
          (input) => input.id == output.sourceInput,
        );

        // Determine if it's shop deposit or client name
        if (sourceInput.type == 'shop_deposit') {
          sourceInfo = 'Shop Deposit';
        } else if (sourceInput.clientName != null &&
            sourceInput.clientName!.isNotEmpty) {
          sourceInfo = sourceInput.clientName!;
        }

        sourceAmount = '${sourceInput.formattedAmount} DA';
      } catch (e) {
        // Input not found, keep N/A
      }
    }

    // Build Details Column Content
    List<Widget> detailWidgets = [];

    // Helper to add detail row
    void addDetailRow(IconData icon, String text, {bool isSecondary = false}) {
      detailWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color:
                    isSecondary
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSecondary ? FontWeight.w400 : FontWeight.w500,
                    color:
                        isSecondary
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (output.isSupplierPayment) {
      if (output.supplierName != null) {
        addDetailRow(Icons.store, output.supplierName!);
      }
      if (output.orderNumber != null) {
        addDetailRow(Icons.receipt_long, 'Order: ${output.orderNumber}');
      }
      if (output.clientName != null) {
        addDetailRow(Icons.person, output.clientName!);
      }
    } else if (output.isGlobalStockPurchase) {
      if (output.productName != null) {
        addDetailRow(Icons.inventory_2, output.productName!);
      }
      if (output.quantity != null) {
        addDetailRow(Icons.numbers, 'Qty: ${output.quantity}');
      }
    } else if (output.isClientStockUsage) {
      if (output.productName != null) {
        addDetailRow(Icons.inventory_2, output.productName!);
      }
      if (output.clientName != null) {
        addDetailRow(Icons.person, output.clientName!);
      }
      if (output.orderNumber != null) {
        addDetailRow(Icons.receipt_long, output.orderNumber!);
      }
      if (output.quantity != null) {
        addDetailRow(Icons.numbers, 'Qty: ${output.quantity}');
      }
    } else if (output.type == 'other_expense') {
      if (output.orderNumber != null) {
        addDetailRow(Icons.receipt_long, 'Order: ${output.orderNumber}');
      }
      if (output.clientName != null) {
        addDetailRow(Icons.person, output.clientName!);
      }
      if (output.description.isNotEmpty) {
        addDetailRow(Icons.description, output.description);
      }
    } else {
      // Withdrawal, Consumable
      if (output.description.isNotEmpty) {
        addDetailRow(Icons.description, output.description);
      } else {
        addDetailRow(Icons.info_outline, '-', isSecondary: true);
      }
    }

    Widget detailsContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: detailWidgets,
    );

    return [
      // Reference
      Text(
        output.reference,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      // Type
      _OutputTypeBadge(output: output),
      // Amount
      Text(
        '${output.formattedAmount} DA',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
        ),
      ),
      // Details (Smart Column)
      detailsContent,
      // Source (Combined)
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            sourceInfo,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (sourceAmount.isNotEmpty)
            Text(
              sourceAmount,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      // Created By
      Text(
        output.createdByUsername ?? 'N/A',
        style: GoogleFonts.inter(
          fontSize: 12,
          color:
              output.createdByUsername != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Date
      Text(output.formattedDate, style: GoogleFonts.inter(fontSize: 12)),
      // Actions
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 16),
            color: AppColors.info,
            tooltip: 'View Details',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _showOutputDetailsDialog(context, output),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: AppColors.success,
            tooltip: 'Edit',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _showEditOutputDialog(context, output),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: AppColors.primary,
            tooltip: 'Delete',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed:
                () => _showDeleteConfirmDialog(context, output, provider),
          ),
        ],
      ),
    ];
  }

  // Dialog Methods
  void _showCreateOutputDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const CreateOutputDialog(),
    );

    // Refresh data after dialog closes (whether created or cancelled)
    if (mounted) {
      final outputProvider = Provider.of<OutputProvider>(
        context,
        listen: false,
      );
      outputProvider.fetchOutputs();
      outputProvider.fetchStatistics();

      // Also refresh related data
      Provider.of<InputProvider>(context, listen: false).fetchInputs();
    }
  }

  void _showEditOutputDialog(BuildContext context, OutputModel output) async {
    await showDialog(
      context: context,
      builder: (context) => EditOutputDialog(output: output),
    );

    // Refresh data after dialog closes
    if (mounted) {
      final outputProvider = Provider.of<OutputProvider>(
        context,
        listen: false,
      );
      outputProvider.fetchOutputs();
      outputProvider.fetchStatistics();

      // Also refresh related data
      Provider.of<InputProvider>(context, listen: false).fetchInputs();
    }
  }

  void _showOutputDetailsDialog(BuildContext context, OutputModel output) {
    showDialog(
      context: context,
      builder: (context) => _OutputDetailsDialog(output: output),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    OutputModel output,
    OutputProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Delete Output',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete this output?',
                  style: GoogleFonts.inter(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  output.reference,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
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
                text: 'Delete',
                onPressed: () async {
                  final success = await provider.deleteOutput(output.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Output deleted successfully',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      provider.fetchStatistics(); // Refresh statistics
                    }
                  }
                },
              ),
            ],
          ),
    );
  }
}

// Output Type Badge Widget
class _OutputTypeBadge extends StatelessWidget {
  final OutputModel output;

  const _OutputTypeBadge({required this.output});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (output.isWithdrawal) {
      color = AppColors.primary;
      icon = Icons.money_off;
    } else if (output.isSupplierPayment) {
      color = AppColors.warning;
      icon = Icons.payment;
    } else if (output.isConsumable) {
      color = AppColors.info;
      icon = Icons.shopping_bag;
    } else if (output.isGlobalStockPurchase) {
      color = AppColors.success;
      icon = Icons.inventory_2;
    } else if (output.isClientStockUsage) {
      color = const Color(0xFF9C27B0); // Purple
      icon = Icons.person_outline;
    } else {
      color = AppColors.textSecondary;
      icon = Icons.more_horiz;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              output.typeDisplay,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Dialogs will be in separate files for better organization
// For now, I'll create placeholder dialogs

class _OutputDetailsDialog extends StatelessWidget {
  final OutputModel output;

  const _OutputDetailsDialog({required this.output});

  @override
  Widget build(BuildContext context) {
    return CustomDialogWidget(
      size: DialogSize.big,
      title: 'Output Details',
      isScrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailRow('Reference', output.reference, isHighlight: true),
          const Divider(),
          _buildDetailRow('Type', output.typeDisplay),
          const Divider(),
          _buildDetailRow(
            'Amount',
            '${output.formattedAmount} DA',
            isHighlight: true,
          ),
          const Divider(),
          if (output.productName != null) ...[
            _buildDetailRow('Product', output.productName!),
            const Divider(),
          ],
          if (output.orderNumber != null) ...[
            _buildDetailRow('Order', output.orderNumber!),
            const Divider(),
          ],
          if (output.supplierName != null) ...[
            _buildDetailRow('Supplier', output.supplierName!),
            const Divider(),
          ],
          if (output.sourceInputReference != null) ...[
            _buildDetailRow('Source Input', output.sourceInputReference!),
            const Divider(),
          ],
          _buildDetailRow('Date', output.formattedDate),
          const Divider(),
          _buildDetailRow('Created At', output.formattedCreatedAt),
          if (output.description.isNotEmpty) ...[
            const Divider(),
            _buildDetailRow('Description', output.description),
          ],
        ],
      ),
      actions: [
        PrimaryButton(text: 'Close', onPressed: () => Navigator.pop(context)),
      ],
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
}

// Searchable Order Dropdown Widget
class _SearchableOrderDropdownWidget extends StatefulWidget {
  final String labelText;
  final String selectedId;
  final Function(String) onChanged;

  const _SearchableOrderDropdownWidget({
    required this.labelText,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  State<_SearchableOrderDropdownWidget> createState() =>
      _SearchableOrderDropdownWidgetState();
}

class _SearchableOrderDropdownWidgetState
    extends State<_SearchableOrderDropdownWidget> {
  late String _currentValue;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  late GlobalKey _containerKey;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  List<OrderModel> _filteredItems = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selectedId;
    _containerKey = GlobalKey();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _filteredItems = [];
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredList(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final orderProvider = context.read<OrderProvider>();
    final allOrders = orderProvider.orders;

    setState(() {
      _filteredItems =
          allOrders.where((order) {
            final searchLower = query.toLowerCase();
            return order.orderNumber.toLowerCase().contains(searchLower) ||
                order.clientName.toLowerCase().contains(searchLower) ||
                order.id.toString().contains(searchLower);
          }).toList();
      _isSearching = false;
    });
  }

  double _getInputWidth() {
    try {
      final RenderBox renderBox =
          _containerKey.currentContext?.findRenderObject() as RenderBox;
      return renderBox.size.width;
    } catch (e) {
      return 300;
    }
  }

  void _showDropdownMenu() {
    if (_isOpen) return;

    _filteredItems = [];

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final inputWidth = _getInputWidth();
        final RenderBox renderBox =
            _containerKey.currentContext?.findRenderObject() as RenderBox;
        final inputHeight = renderBox.size.height;

        return Positioned(
          width: inputWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, inputHeight + 6),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface,
              child: StatefulBuilder(
                builder: (context, setStateOverlay) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.surfaceVariant,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            onChanged: (value) {
                              _updateFilteredList(value);
                              setStateOverlay(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by order number or client...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(Icons.search, size: 16),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _updateFilteredList('');
                                          setStateOverlay(() {});
                                          _searchFocusNode.requestFocus();
                                        },
                                        child: Icon(
                                          Icons.clear,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppColors.surfaceVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppColors.surfaceVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: AppColors.surfaceVariant.withOpacity(0.5),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _currentValue = 'all';
                              _isOpen = false;
                            });
                            _overlayEntry?.remove();
                            _overlayEntry = null;
                            _searchController.clear();
                            _filteredItems = [];
                            widget.onChanged('all');
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color:
                                  _currentValue == 'all'
                                      ? AppColors.primary.withOpacity(0.08)
                                      : Colors.transparent,
                              border:
                                  _currentValue == 'all'
                                      ? Border(
                                        left: BorderSide(
                                          color: AppColors.primary,
                                          width: 3,
                                        ),
                                      )
                                      : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.all_inclusive,
                                      size: 14,
                                      color:
                                          _currentValue == 'all'
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'All Orders',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color:
                                            _currentValue == 'all'
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                        fontWeight:
                                            _currentValue == 'all'
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_currentValue == 'all')
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child:
                              _searchController.text.isEmpty
                                  ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search,
                                          size: 32,
                                          color: AppColors.textSecondary
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Start typing to search',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : _isSearching
                                  ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                    ),
                                  )
                                  : _filteredItems.isEmpty
                                  ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 32,
                                          color: AppColors.textSecondary
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No orders found',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    shrinkWrap: true,
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      final isSelected =
                                          item.id.toString() == _currentValue;

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _currentValue = item.id.toString();
                                            _isOpen = false;
                                          });
                                          _overlayEntry?.remove();
                                          _overlayEntry = null;
                                          _searchController.clear();
                                          _filteredItems = [];
                                          widget.onChanged(_currentValue);
                                        },
                                        child: Container(
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                        .withOpacity(0.08)
                                                    : Colors.transparent,
                                            border:
                                                isSelected
                                                    ? Border(
                                                      left: BorderSide(
                                                        color:
                                                            AppColors.primary,
                                                        width: 3,
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      item.orderNumber,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color:
                                                            isSelected
                                                                ? AppColors
                                                                    .primary
                                                                : AppColors
                                                                    .textPrimary,
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .w600
                                                                : FontWeight
                                                                    .w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      'Client: ${item.clientName}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        color:
                                                            AppColors
                                                                .textSecondary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 18,
                                                  color: AppColors.primary,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isOpen = false);
      _searchController.clear();
      _filteredItems = [];
      return;
    }

    _filteredItems = [];
    _showDropdownMenu();
  }

  String _getDisplayText() {
    if (_currentValue == 'all') return 'All Orders';
    if (_currentValue == 'none') return widget.labelText;
    try {
      final order = context.read<OrderProvider>().orders.firstWhere(
        (o) => o.id.toString() == _currentValue,
      );
      return order.orderNumber;
    } catch (e) {
      return widget.labelText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.labelText,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              key: _containerKey,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _getDisplayText(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color:
                                  (_currentValue == 'all' ||
                                          _currentValue == 'none')
                                      ? AppColors.textSecondary.withOpacity(0.7)
                                      : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isOpen
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Searchable Input Dropdown Widget
class _SearchableInputDropdownWidget extends StatefulWidget {
  final String labelText;
  final String selectedId;
  final Function(String) onChanged;

  const _SearchableInputDropdownWidget({
    required this.labelText,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  State<_SearchableInputDropdownWidget> createState() =>
      _SearchableInputDropdownWidgetState();
}

class _SearchableInputDropdownWidgetState
    extends State<_SearchableInputDropdownWidget> {
  late String _currentValue;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  late GlobalKey _containerKey;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  List<InputModel> _filteredItems = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selectedId;
    _containerKey = GlobalKey();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _filteredItems = [];
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredList(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final inputProvider = context.read<InputProvider>();
    final allInputs = inputProvider.inputs;

    setState(() {
      _filteredItems =
          allInputs.where((input) {
            final searchLower = query.toLowerCase();
            return input.reference.toLowerCase().contains(searchLower) ||
                (input.clientName?.toLowerCase().contains(searchLower) ??
                    false) ||
                input.id.toString().contains(searchLower);
          }).toList();
      _isSearching = false;
    });
  }

  double _getInputWidth() {
    try {
      final RenderBox renderBox =
          _containerKey.currentContext?.findRenderObject() as RenderBox;
      return renderBox.size.width;
    } catch (e) {
      return 300;
    }
  }

  void _showDropdownMenu() {
    if (_isOpen) return;

    _filteredItems = [];

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final inputWidth = _getInputWidth();
        final RenderBox renderBox =
            _containerKey.currentContext?.findRenderObject() as RenderBox;
        final inputHeight = renderBox.size.height;

        return Positioned(
          width: inputWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, inputHeight + 6),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface,
              child: StatefulBuilder(
                builder: (context, setStateOverlay) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.surfaceVariant,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            onChanged: (value) {
                              _updateFilteredList(value);
                              setStateOverlay(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by reference or client...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(Icons.search, size: 16),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _updateFilteredList('');
                                          setStateOverlay(() {});
                                          _searchFocusNode.requestFocus();
                                        },
                                        child: Icon(
                                          Icons.clear,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppColors.surfaceVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppColors.surfaceVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: AppColors.surfaceVariant.withOpacity(0.5),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _currentValue = 'all';
                              _isOpen = false;
                            });
                            _overlayEntry?.remove();
                            _overlayEntry = null;
                            _searchController.clear();
                            _filteredItems = [];
                            widget.onChanged('all');
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color:
                                  _currentValue == 'all'
                                      ? AppColors.primary.withOpacity(0.08)
                                      : Colors.transparent,
                              border:
                                  _currentValue == 'all'
                                      ? Border(
                                        left: BorderSide(
                                          color: AppColors.primary,
                                          width: 3,
                                        ),
                                      )
                                      : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.all_inclusive,
                                      size: 14,
                                      color:
                                          _currentValue == 'all'
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'All Inputs',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color:
                                            _currentValue == 'all'
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                        fontWeight:
                                            _currentValue == 'all'
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_currentValue == 'all')
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child:
                              _searchController.text.isEmpty
                                  ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search,
                                          size: 32,
                                          color: AppColors.textSecondary
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Start typing to search',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : _isSearching
                                  ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                    ),
                                  )
                                  : _filteredItems.isEmpty
                                  ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 32,
                                          color: AppColors.textSecondary
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No inputs found',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    shrinkWrap: true,
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      final isSelected =
                                          item.id.toString() == _currentValue;

                                      // Determine display text based on input type
                                      String displayText;
                                      if (item.type == 'shop_deposit') {
                                        displayText = 'Shop Deposit';
                                      } else if (item.clientName != null &&
                                          item.clientName!.isNotEmpty) {
                                        displayText = item.clientName!;
                                      } else {
                                        displayText = 'N/A';
                                      }

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _currentValue = item.id.toString();
                                            _isOpen = false;
                                          });
                                          _overlayEntry?.remove();
                                          _overlayEntry = null;
                                          _searchController.clear();
                                          _filteredItems = [];
                                          widget.onChanged(_currentValue);
                                        },
                                        child: Container(
                                          height: 60,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                        .withOpacity(0.08)
                                                    : Colors.transparent,
                                            border:
                                                isSelected
                                                    ? Border(
                                                      left: BorderSide(
                                                        color:
                                                            AppColors.primary,
                                                        width: 3,
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      item.reference,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color:
                                                            isSelected
                                                                ? AppColors
                                                                    .primary
                                                                : AppColors
                                                                    .textPrimary,
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .w600
                                                                : FontWeight
                                                                    .w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      displayText,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        color: AppColors.info,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Amount: ${item.formattedAmount}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 9,
                                                        color:
                                                            AppColors
                                                                .textSecondary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 18,
                                                  color: AppColors.primary,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isOpen = false);
      _searchController.clear();
      _filteredItems = [];
      return;
    }

    _filteredItems = [];
    _showDropdownMenu();
  }

  String _getDisplayText() {
    if (_currentValue == 'all') return 'All Inputs';
    if (_currentValue == 'none') return widget.labelText;
    try {
      final input = context.read<InputProvider>().inputs.firstWhere(
        (i) => i.id.toString() == _currentValue,
      );
      if (input.type == 'shop_deposit') {
        return 'Shop Deposit';
      } else if (input.clientName != null && input.clientName!.isNotEmpty) {
        return input.clientName!;
      } else {
        return 'N/A';
      }
    } catch (e) {
      return widget.labelText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.labelText,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              key: _containerKey,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _getDisplayText(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color:
                                  (_currentValue == 'all' ||
                                          _currentValue == 'none')
                                      ? AppColors.textSecondary.withOpacity(0.7)
                                      : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isOpen
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Pagination Controls
class _PaginationControls extends StatelessWidget {
  final OutputProvider outputProvider;

  const _PaginationControls({required this.outputProvider});

  @override
  Widget build(BuildContext context) {
    if (outputProvider.totalPages <= 1) return Container();

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
            'Page ${outputProvider.currentPage} of ${outputProvider.totalPages} '
            '(${outputProvider.totalCount} total)',
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
                    outputProvider.currentPage > 1
                        ? () => outputProvider.goToPage(1)
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    outputProvider.hasPreviousPage
                        ? () => outputProvider.previousPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              const SizedBox(width: 8),
              ...List.generate(
                outputProvider.totalPages > 5 ? 5 : outputProvider.totalPages,
                (index) {
                  int pageNum;
                  if (outputProvider.totalPages <= 5) {
                    pageNum = index + 1;
                  } else {
                    if (outputProvider.currentPage <= 3) {
                      pageNum = index + 1;
                    } else if (outputProvider.currentPage >=
                        outputProvider.totalPages - 2) {
                      pageNum = outputProvider.totalPages - 4 + index;
                    } else {
                      pageNum = outputProvider.currentPage - 2 + index;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: () => outputProvider.goToPage(pageNum),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            pageNum == outputProvider.currentPage
                                ? AppColors.primary
                                : Colors.transparent,
                        foregroundColor:
                            pageNum == outputProvider.currentPage
                                ? Colors.white
                                : AppColors.textPrimary,
                        minimumSize: const Size(36, 36),
                      ),
                      child: Text('$pageNum'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    outputProvider.hasNextPage
                        ? () => outputProvider.nextPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed:
                    outputProvider.currentPage < outputProvider.totalPages
                        ? () =>
                            outputProvider.goToPage(outputProvider.totalPages)
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
