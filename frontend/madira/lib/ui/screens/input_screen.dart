import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/models/input_model.dart';
import 'package:madira/providers/input_provider.dart';
import 'package:madira/providers/login_provider.dart';
import 'package:madira/ui/screens/input_outputs_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dropdown_widget.dart';
import '../widgets/custom_dialog_widget.dart';
import '../widgets/responsive_table_widget.dart';

class InputsScreen extends StatefulWidget {
  const InputsScreen({super.key});

  @override
  State<InputsScreen> createState() => _InputsScreenState();
}

class _InputsScreenState extends State<InputsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'all';
  String _orderFilter = 'all';
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _searchController.clear();
    _typeFilter = 'all';
    _orderFilter = 'all';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inputProvider = Provider.of<InputProvider>(context, listen: false);
      // Fetch with explicit nulls to reset any persisted filters
      inputProvider.fetchInputs(search: null, type: null, orderId: null);

      // Fetch orders for the filter dropdown
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Apply filters using server-side filtering
  void _applyFilters() {
    final inputProvider = Provider.of<InputProvider>(context, listen: false);

    // Convert frontend sort values to Django ordering format
    String? ordering;
    switch (_sortBy) {
      case 'date_desc':
        ordering = '-date';
        break;
      case 'date_asc':
        ordering = 'date';
        break;
      case 'amount_desc':
        ordering = '-amount';
        break;
      case 'amount_asc':
        ordering = 'amount';
        break;
      default:
        ordering = '-date'; // Default to newest first
    }

    inputProvider.fetchInputs(
      page: 1, // Reset to first page when filters change
      type: _typeFilter != 'all' ? _typeFilter : null,
      orderId: _orderFilter != 'all' ? int.tryParse(_orderFilter) : null,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      ordering: ordering,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 1.2,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<InputProvider>(
                builder: (context, inputProvider, _) {
                  if (inputProvider.errorMessage != null) {
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
                            'Error: ${inputProvider.errorMessage}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedCustomButton(
                            text: 'Retry',
                            onPressed: () => inputProvider.fetchInputs(),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inputs Management',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track and manage all shop deposits and payments',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Consumer<LoginProvider>(
                    builder: (context, loginProvider, _) {
                      final userRole = loginProvider.user?.role;
                      if (userRole == 'admin' || userRole == 'responsible') {
                        return PrimaryButton(
                          size: ButtonSize.medium,
                          text: 'New Shop Deposit',
                          onPressed: () {
                            _showCreateInputDialog(context);
                          },
                          icon: const Icon(
                            Icons.add_card,
                            size: 16,
                            color: Colors.white,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                          hintText: 'Search by reference or order number...',
                          onChanged: (value) {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                if (_searchController.text == value) {
                                  _applyFilters();
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
                          value: 'shop_deposit',
                          child: Text('Shop Deposit'),
                        ),
                        DropdownMenuItem(
                          value: 'client_payment',
                          child: Text('Client Payment'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Expense'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _typeFilter = value ?? 'all';
                          _applyFilters();
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
                          _applyFilters();
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
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Consumer<InputProvider>(
                builder: (context, inputProvider, _) {
                  if (inputProvider.isLoading) {
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

                  if (inputProvider.inputs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredInputs = inputProvider.inputs;

                  if (filteredInputs.isEmpty) {
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
                            'No Inputs Match Filters',
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

                  // Calculate total amount for filtered inputs
                  double totalAmount = 0;
                  for (var input in filteredInputs) {
                    totalAmount += double.tryParse(input.amount) ?? 0;
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Inputs (${filteredInputs.length}/${inputProvider.inputs.length})',
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
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total: ${totalAmount.toStringAsFixed(2)} DA',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
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
                          'Client',
                          'Order',
                          'Amount',
                          'Remaining',
                          'Date',
                          'Created By',
                          'Description',
                          'Actions',
                        ],
                        minColumnWidth: 100,
                        rows:
                            filteredInputs
                                .map(
                                  (input) => _buildInputRow(
                                    context,
                                    input,
                                    inputProvider,
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 32),
                      _PaginationControls(inputProvider: inputProvider),
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
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Inputs Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first shop deposit to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInputRow(
    BuildContext context,
    InputModel input,
    InputProvider inputProvider,
  ) {
    final userRole =
        Provider.of<LoginProvider>(context, listen: false).user?.role;
    final canEditOrDelete = userRole == 'admin' || userRole == 'responsible';

    return [
      Text(
        input.reference,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      _InputTypeBadge(type: input.type),
      Text(
        input.clientName ?? 'N/A',
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        input.orderNumber ?? 'N/A',
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        input.formattedAmount,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
      Text(
        input.formattedRemainingAmount,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color:
              input.hasRemainingAmount
                  ? AppColors.info
                  : AppColors.textSecondary,
        ),
      ),
      Text(input.formattedDate, style: GoogleFonts.inter(fontSize: 12)),
      Text(
        input.createdByName,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        input.description.isEmpty ? '-' : input.description,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(
        width: 140, // Increased width to accommodate all buttons
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                color: AppColors.success,
                tooltip: 'View Transactions',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputOutputsScreen(input: input),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 16),
                color: AppColors.primary,
                tooltip: 'View',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  _showInputDetailDialog(context, input);
                },
              ),
              if (input.type == 'shop_deposit' && canEditOrDelete) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  color: AppColors.info,
                  tooltip: 'Edit',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () {
                    _showEditInputDialog(context, input, inputProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outlined, size: 16),
                  color: AppColors.primary,
                  tooltip: 'Delete',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () {
                    _showDeleteConfirm(context, input, inputProvider);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  void _showCreateInputDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'New Shop Deposit',
                  size: DialogSize.small,
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Shop deposits are not linked to any specific order',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AmountInputWidget(
                        controller: amountController,
                        labelText: 'Amount (DA)',
                        hintText: '0.00',
                      ),
                      // CustomInputWidget(
                      //   controller: amountController,
                      //   labelText: 'Amount (DA)',
                      //   hintText: '0.00',
                      //   prefixIcon: const Icon(Icons.attach_money),
                      //   keyboardType: const TextInputType.numberWithOptions(
                      //     decimal: true,
                      //   ),
                      //   required: true,
                      // ),
                      const SizedBox(height: 16),
                      CustomInputWidget(
                        controller: descriptionController,
                        labelText: 'Description',
                        hintText: 'Enter deposit description...',
                        prefixIcon: const Icon(Icons.description),
                        maxLines: 3,
                        required: false,
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
                        if (amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter amount',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final inputProvider = Provider.of<InputProvider>(
                            context,
                            listen: false,
                          );

                          final success = await inputProvider.createInput(
                            type: 'shop_deposit',
                            amount: double.parse(amountController.text),
                            order: null, // Always null for shop deposits
                            description: descriptionController.text,
                          );

                          if (mounted) {
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Shop deposit created successfully',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error: ${inputProvider.errorMessage}',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditInputDialog(
    BuildContext context,
    InputModel input,
    InputProvider inputProvider,
  ) {
    final amountController = TextEditingController(text: input.amount);
    final descriptionController = TextEditingController(
      text: input.description,
    );

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'Edit Shop Deposit',
                  size: DialogSize.small,
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        input.reference,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Shop deposits are not linked to any specific order',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AmountInputWidget(
                        controller: amountController,
                        labelText: 'Amount (DA)',
                        hintText: '0.00',
                      ),
                      const SizedBox(height: 16),
                      CustomInputWidget(
                        controller: descriptionController,
                        labelText: 'Description',
                        hintText: 'Enter deposit description...',
                        prefixIcon: const Icon(Icons.description),
                        maxLines: 3,
                        required: false,
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
                        if (amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter amount',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final success = await inputProvider.updateInput(
                            input.id,
                            type: 'shop_deposit',
                            amount: double.parse(amountController.text),
                            order: null, // Always null for shop deposits
                            description: descriptionController.text,
                          );

                          if (mounted) {
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Shop deposit updated successfully',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    InputModel input,
    InputProvider inputProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Delete Input',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete this input?',
                  style: GoogleFonts.inter(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${input.reference} - ${input.formattedAmount}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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
                text: 'Delete',
                onPressed: () async {
                  try {
                    final success = await inputProvider.deleteInput(
                      input.id,
                      input.order,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Input deleted successfully',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
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

  void _showInputDetailDialog(BuildContext context, InputModel input) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            title: 'Input Details',
            size: DialogSize.big,
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Reference',
                  input.reference,
                  isHighlight: true,
                ),
                const Divider(),
                _buildDetailRow('Type', _getTypeDisplay(input.type)),
                const Divider(),
                _buildDetailRow('Client Name', input.clientName ?? 'N/A'),
                const Divider(),
                _buildDetailRow('Order Number', input.orderNumber ?? 'N/A'),
                const Divider(),
                _buildDetailRow(
                  'Amount',
                  input.formattedAmount,
                  isHighlight: true,
                ),
                const Divider(),
                _buildDetailRow('Date', input.formattedDate),
                const Divider(),
                _buildDetailRow('Created By', input.createdByName),
                const Divider(),
                _buildDetailRow('Created At', _formatDateTime(input.createdAt)),
                const Divider(),
                _buildDetailRow(
                  'Description',
                  input.description.isEmpty
                      ? 'No description'
                      : input.description,
                ),
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

  String _getTypeDisplay(String type) {
    switch (type) {
      case 'shop_deposit':
        return 'Shop Deposit';
      case 'client_payment':
        return 'Client Payment';
      case 'expense':
        return 'Expense';
      default:
        return type;
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTime;
    }
  }
}

// Input Type Badge
class _InputTypeBadge extends StatelessWidget {
  final String type;

  const _InputTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String displayText;
    IconData icon;

    switch (type) {
      case 'shop_deposit':
        backgroundColor = AppColors.info.withOpacity(0.1);
        borderColor = AppColors.info.withOpacity(0.3);
        textColor = AppColors.info;
        displayText = 'Shop Deposit';
        icon = Icons.account_balance;
        break;
      case 'client_payment':
        backgroundColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success.withOpacity(0.3);
        textColor = AppColors.success;
        displayText = 'Client Payment';
        icon = Icons.payments;
        break;
      case 'expense':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        borderColor = AppColors.warning.withOpacity(0.3);
        textColor = AppColors.warning;
        displayText = 'Expense';
        icon = Icons.shopping_cart;
        break;
      default:
        backgroundColor = AppColors.textSecondary.withOpacity(0.1);
        borderColor = AppColors.textSecondary.withOpacity(0.3);
        textColor = AppColors.textSecondary;
        displayText = type;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              displayText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor,
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
            children: [
              if (widget.labelText.contains('Select'))
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
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

// Pagination Controls
class _PaginationControls extends StatelessWidget {
  final InputProvider inputProvider;

  const _PaginationControls({required this.inputProvider});

  @override
  Widget build(BuildContext context) {
    if (inputProvider.totalPages <= 1) return Container();

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
            'Page ${inputProvider.currentPage} of ${inputProvider.totalPages} '
            '(${inputProvider.totalCount} total)',
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
                    inputProvider.currentPage > 1
                        ? () => inputProvider.goToPage(1)
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    inputProvider.hasPreviousPage
                        ? () => inputProvider.previousPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              const SizedBox(width: 8),
              ...List.generate(
                inputProvider.totalPages > 5 ? 5 : inputProvider.totalPages,
                (index) {
                  int pageNum;
                  if (inputProvider.totalPages <= 5) {
                    pageNum = index + 1;
                  } else {
                    if (inputProvider.currentPage <= 3) {
                      pageNum = index + 1;
                    } else if (inputProvider.currentPage >=
                        inputProvider.totalPages - 2) {
                      pageNum = inputProvider.totalPages - 4 + index;
                    } else {
                      pageNum = inputProvider.currentPage - 2 + index;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: () => inputProvider.goToPage(pageNum),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            pageNum == inputProvider.currentPage
                                ? AppColors.primary
                                : Colors.transparent,
                        foregroundColor:
                            pageNum == inputProvider.currentPage
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
                    inputProvider.hasNextPage
                        ? () => inputProvider.nextPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed:
                    inputProvider.currentPage < inputProvider.totalPages
                        ? () => inputProvider.goToPage(inputProvider.totalPages)
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
