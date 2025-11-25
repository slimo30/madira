import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/models/input_model.dart';
import 'package:madira/providers/input_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../models/order_model.dart';
import '../../models/client_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/client_provider.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dropdown_widget.dart';
import '../widgets/custom_dialog_widget.dart';
import '../widgets/responsive_table_widget.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _paymentFilter = 'all';
  String _clientFilter = 'all';
  String _sortBy = '-created_at'; // Default sorting

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Apply filters to the server
  Future<void> _applyFilters() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    await orderProvider.fetchOrders(
      page: 1, // Reset to first page when filters change
      search: _searchController.text,
      status: _statusFilter == 'all' ? null : _statusFilter,
      paymentStatus: _paymentFilter == 'all' ? null : _paymentFilter,
      clientId: _clientFilter == 'all' ? null : int.tryParse(_clientFilter),
      ordering: _sortBy,
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
              Consumer<OrderProvider>(
                builder: (context, orderProvider, _) {
                  if (orderProvider.error != null) {
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
                            'Error: ${orderProvider.error}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedCustomButton(
                            text: 'Retry',
                            onPressed: () => orderProvider.fetchOrders(),
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
                        'Orders Management',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track and manage all customer orders',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  PrimaryButton(
                    size: ButtonSize.medium,
                    text: 'New Order',
                    onPressed: () {
                      _showCreateOrderDialog(context);
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      size: 16,
                      color: Colors.white,
                    ),
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
                          hintText: 'Search by order number or client...',
                          onChanged: (value) {
                            Future.delayed(
                              const Duration(milliseconds: 800),
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
                    child: _SearchableClientDropdownWidget(
                      labelText: 'Client',
                      selectedId: _clientFilter,
                      onChanged: (clientId) {
                        setState(() {
                          _clientFilter = clientId;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdownWidget<String>(
                      labelText: 'Status',
                      value: _statusFilter,
                      required: false,
                      prefixIcon: Icons.assignment,
                      hintText: 'All Status',
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All Status'),
                        ),
                        const DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        const DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('In Progress'),
                        ),
                        const DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        const DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value ?? 'all';
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdownWidget<String>(
                      labelText: 'Payment',
                      value: _paymentFilter,
                      required: false,
                      prefixIcon: Icons.payment,
                      hintText: 'All Payments',
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All Payments'),
                        ),
                        const DropdownMenuItem(
                          value: 'fully_paid',
                          child: Text('Fully Paid'),
                        ),
                        const DropdownMenuItem(
                          value: 'partially_paid',
                          child: Text('Partially Paid'),
                        ),
                        const DropdownMenuItem(
                          value: 'unpaid',
                          child: Text('Unpaid'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _paymentFilter = value ?? 'all';
                        });
                        _applyFilters();
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
                      items: [
                        const DropdownMenuItem(
                          value: '-created_at',
                          child: Text('Newest First'),
                        ),
                        const DropdownMenuItem(
                          value: 'created_at',
                          child: Text('Oldest First'),
                        ),
                        const DropdownMenuItem(
                          value: '-total_amount',
                          child: Text('Highest Amount'),
                        ),
                        const DropdownMenuItem(
                          value: 'total_amount',
                          child: Text('Lowest Amount'),
                        ),
                        const DropdownMenuItem(
                          value: 'delivery_date',
                          child: Text('Delivery Date (Asc)'),
                        ),
                        const DropdownMenuItem(
                          value: '-delivery_date',
                          child: Text('Delivery Date (Desc)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value ?? '-created_at';
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Consumer<OrderProvider>(
                builder: (context, orderProvider, _) {
                  if (orderProvider.isLoading) {
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

                  if (orderProvider.orders.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Orders (${orderProvider.orders.length} of ${orderProvider.totalCount})',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Page ${orderProvider.currentPage} of ${orderProvider.totalPages}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ResponsiveTable(
                        columns: [
                          'Order #',
                          'Client',
                          'Total',
                          'Paid',
                          'Remaining',
                          'Status',
                          'Payment',
                          'Created',
                          'Actions',
                        ],
                        minColumnWidth: 100,
                        rows:
                            orderProvider.orders
                                .map(
                                  (order) => _buildOrderRow(
                                    context,
                                    order,
                                    orderProvider,
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 32),
                      _PaginationControls(orderProvider: orderProvider),
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
            'No Orders Found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first order to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderRow(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
  ) {
    return [
      Text(
        order.orderNumber,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        order.clientName,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        '${order.totalAmount} DA',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      Text(
        '${order.paidAmount.toStringAsFixed(2)} DA',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
        ),
      ),
      Text(
        '${order.remainingAmount} DA',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: order.isFullyPaid ? AppColors.success : AppColors.warning,
        ),
      ),
      GestureDetector(
        onTap: () => _showStatusUpdateDialog(context, order, orderProvider),
        child: _OrderStatusBadge(status: order.status),
      ),
      _PaymentStatusBadge(
        paymentStatus: order.paymentStatus,
        isFullyPaid: order.isFullyPaid,
      ),
      Text(order.formattedCreatedAt, style: GoogleFonts.inter(fontSize: 12)),
      SizedBox(
        width: 140,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 16),
              color: AppColors.primary,
              tooltip: 'View',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                _showOrderDetailDialog(context, order);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              color: AppColors.success,
              tooltip: 'Add Payment',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                _showAddPaymentDialog(context, order);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16),
              color: AppColors.info,
              tooltip: 'Edit',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                _showEditOrderDialog(context, order, orderProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, size: 16),
              color: AppColors.warning,
              tooltip: 'Cancel',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                _showCancelConfirm(context, order, orderProvider);
              },
            ),
          ],
        ),
      ),
    ];
  }

  void _showStatusUpdateDialog(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
  ) {
    String selectedStatus = order.status;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'Update Status',
                  size: DialogSize.small,
                  isScrollable: false,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order: ${order.orderNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomDropdownWidget<String>(
                        labelText: 'New Status',
                        value: selectedStatus,
                        required: true,
                        prefixIcon: Icons.assignment,
                        items: [
                          const DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          const DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('In Progress'),
                          ),
                          const DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                          const DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Cancelled'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
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
                        try {
                          await orderProvider.updateOrder(
                            order.id,
                            client: order.client,
                            totalAmount: order.totalAmount,
                            description: order.description,
                            deliveryDate: order.deliveryDate,
                            status: selectedStatus,
                          );
                          if (mounted) {
                            Navigator.pop(context);
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

  void _showCreateOrderDialog(BuildContext context) {
    final totalAmountController = TextEditingController();
    final descriptionController = TextEditingController();
    final deliveryDateController = TextEditingController();
    String selectedClientId = 'none';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'New Order',
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SearchableClientDropdownWidget(
                        labelText: 'Select Client',
                        selectedId: selectedClientId,
                        onChanged: (clientId) {
                          setState(() {
                            selectedClientId = clientId;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AmountInputWidget(
                        controller: totalAmountController,
                        labelText: 'Total Amount (DA)',
                        hintText: '0.00',
                        required: true,
                      ),
                      // CustomInputWidget(
                      //   controller: totalAmountController,
                      //   labelText: ' Amount (DA)',
                      //   hintText: '0.00',
                      //   prefixIcon: const Icon(Icons.attach_money),
                      //   keyboardType: const TextInputType.numberWithOptions(
                      //     decimal: true,
                      //   ),
                      //   required: true,
                      // ),
                      const SizedBox(height: 16),
                      _DescriptionFieldWithStyling(
                        controller: descriptionController,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            deliveryDateController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(selectedDate);
                          }
                        },
                        child: CustomInputWidget(
                          controller: deliveryDateController,
                          labelText: 'Delivery Date',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: const Icon(Icons.calendar_today),
                          required: true,
                          readOnly: true,
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              deliveryDateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate);
                            }
                          },
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
                      text: 'Create',
                      onPressed: () async {
                        if (selectedClientId == 'none' ||
                            totalAmountController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            deliveryDateController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please fill in all required fields',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final orderProvider = Provider.of<OrderProvider>(
                            context,
                            listen: false,
                          );
                          await orderProvider.createOrder(
                            client: int.parse(selectedClientId),
                            totalAmount: totalAmountController.text,
                            description: descriptionController.text,
                            deliveryDate: deliveryDateController.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order created successfully',
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

  void _showEditOrderDialog(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
  ) {
    final totalAmountController = TextEditingController(
      text: order.totalAmount,
    );
    final descriptionController = TextEditingController(
      text: order.description,
    );
    final deliveryDateController = TextEditingController(
      text: order.deliveryDate,
    );
    String selectedClientId = order.client.toString();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'Edit Order',
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SearchableClientDropdownWidget(
                        labelText: 'Client',
                        selectedId: selectedClientId,
                        onChanged: (clientId) {
                          setState(() {
                            selectedClientId = clientId;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AmountInputWidget(
                        controller: totalAmountController,
                        labelText: 'Total Amount (DA)',
                        hintText: '0.00',
                        required: true,
                      ),
                      // CustomInputWidget(
                      //   controller: totalAmountController,
                      //   labelText: 'Total Amount (DA)',
                      //   hintText: '0.00',
                      //   prefixIcon: const Icon(Icons.attach_money),
                      //   keyboardType: const TextInputType.numberWithOptions(
                      //     decimal: true,
                      //   ),
                      //   required: true,
                      // ),
                      // const SizedBox(height: 16),
                      _DescriptionFieldWithStyling(
                        controller: descriptionController,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(order.deliveryDate),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            deliveryDateController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(selectedDate);
                          }
                        },
                        child: CustomInputWidget(
                          controller: deliveryDateController,
                          labelText: 'Delivery Date',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: const Icon(Icons.calendar_today),
                          required: true,
                          readOnly: true,
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(order.deliveryDate),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              deliveryDateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate);
                            }
                          },
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
                      text: 'Update',
                      onPressed: () async {
                        if (selectedClientId == 'none' ||
                            totalAmountController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            deliveryDateController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please fill in all required fields',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          await orderProvider.updateOrder(
                            order.id,
                            client: int.parse(selectedClientId),
                            totalAmount: totalAmountController.text,
                            description: descriptionController.text,
                            deliveryDate: deliveryDateController.text,
                            status: order.status,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order updated successfully',
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

  void _showCancelConfirm(
    BuildContext context,
    OrderModel order,
    OrderProvider orderProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Cancel Order',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to cancel order ${order.orderNumber}?',
                  style: GoogleFonts.inter(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Client: ${order.clientName}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              OutlinedCustomButton(
                text: 'Keep Order',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Cancel Order',
                onPressed: () async {
                  try {
                    await orderProvider.cancelOrder(order.id);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order cancelled successfully',
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

  void _showAddPaymentDialog(BuildContext context, OrderModel order) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            title: 'Add Payment',
            size: DialogSize.small,
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order: ${order.orderNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount Due: ${order.remainingAmount} DA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                AmountInputWidget(
                  controller: amountController,
                  labelText: 'Payment Amount (DA)',
                  hintText: '0.00',
                  required: true,
                ),
                // CustomInputWidget(
                //   controller: amountController,
                //   labelText: 'Payment Amount (DA)',
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
                  hintText: 'Payment description...',
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
                text: 'Add Payment',
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
                    final orderProvider = Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    );

                    final success = await inputProvider.createInput(
                      type: 'client_payment',
                      amount: double.parse(amountController.text),
                      order: order.id,
                      description: descriptionController.text,
                    );

                    if (mounted) {
                      if (success) {
                        // Refresh order data after payment is added
                        await orderProvider.fetchOrders();
                        await inputProvider.fetchInputsByOrder(order.id);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Payment added successfully',
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
    );
  }

  void _showOrderDetailDialog(BuildContext context, OrderModel order) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InputProvider>(
        context,
        listen: false,
      ).fetchInputsByOrder(order.id);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => OrderDetailsDialog(
            order: order,
            onAddPaymentPressed: () {
              // Don't pop the order dialog, show payment dialog on top
              _showAddPaymentDialogInside(context, order);
            },
            onEditOrderPressed: () {
              Navigator.pop(context);
              _showEditOrderDialog(
                context,
                order,
                Provider.of<OrderProvider>(context, listen: false),
              );
            },
            onEditPaymentPressed: (payment) {
              _showEditPaymentDialogInside(context, payment, order);
            },
            onDeletePaymentPressed: (payment) {
              _showDeletePaymentConfirmInside(context, payment, order);
            },
          ),
    );
  }

  void _showAddPaymentDialogInside(BuildContext context, OrderModel order) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            title: 'Add Payment',
            size: DialogSize.small,
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order: ${order.orderNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount Due: ${order.remainingAmount} DA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                AmountInputWidget(
                  controller: amountController,
                  labelText: 'Payment Amount (DA)',
                  hintText: '0.00',
                  required: true,
                ),
                // CustomInputWidget(
                //   controller: amountController,
                //   labelText: 'Payment Amount (DA)',
                //   hintText: '0.00',
                //   prefixIcon: const Icon(Icons.attach_money),
                //   keyboardType: const TextInputType.numberWithOptions(
                //     decimal: true,
                //   ),
                //   required: true,
                // ),
                // const SizedBox(height: 16),
                CustomInputWidget(
                  controller: descriptionController,
                  labelText: 'Description',
                  hintText: 'Payment description...',
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
                text: 'Add Payment',
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
                    final orderProvider = Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    );

                    final success = await inputProvider.createInput(
                      type: 'client_payment',
                      amount: double.parse(amountController.text),
                      order: order.id,
                      description: descriptionController.text,
                    );

                    if (mounted) {
                      if (success) {
                        // Refresh order data after payment is added
                        await orderProvider.fetchOrders();
                        await inputProvider.fetchInputsByOrder(order.id);

                        Navigator.pop(context); // Close add payment dialog only
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Payment added successfully',
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
    );
  }

  void _showEditPaymentDialogInside(
    BuildContext context,
    InputModel payment,
    OrderModel order,
  ) {
    final amountController = TextEditingController(text: payment.amount);
    final descriptionController = TextEditingController(
      text: payment.description,
    );

    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            title: 'Edit Payment',
            size: DialogSize.small,
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  payment.reference,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                CustomInputWidget(
                  controller: amountController,
                  labelText: 'Amount (DA)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  required: true,
                ),
                const SizedBox(height: 16),
                CustomInputWidget(
                  controller: descriptionController,
                  labelText: 'Description',
                  hintText: 'Payment description...',
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
                    final inputProvider = Provider.of<InputProvider>(
                      context,
                      listen: false,
                    );
                    final orderProvider = Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    );

                    final success = await inputProvider.updateInput(
                      payment.id,
                      type: 'client_payment',
                      amount: double.parse(amountController.text),
                      order: order.id,
                      description: descriptionController.text,
                    );

                    if (mounted) {
                      if (success) {
                        // Refresh order data after payment is updated
                        await orderProvider.fetchOrders();
                        await inputProvider.fetchInputsByOrder(order.id);

                        Navigator.pop(
                          context,
                        ); // Close edit payment dialog only
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Payment updated successfully',
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

  void _showDeletePaymentConfirmInside(
    BuildContext context,
    InputModel payment,
    OrderModel order,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Delete Payment',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Delete this payment?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${payment.reference}\n${payment.formattedAmount}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
                    final inputProvider = Provider.of<InputProvider>(
                      context,
                      listen: false,
                    );
                    final orderProvider = Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    );

                    final success = await inputProvider.deleteInput(
                      payment.id,
                      order.id,
                    );

                    if (mounted) {
                      Navigator.pop(
                        context,
                      ); // Close delete confirm dialog only
                      if (success) {
                        // Refresh order data after payment is deleted
                        await orderProvider.fetchOrders();
                        await inputProvider.fetchInputsByOrder(order.id);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Payment deleted successfully',
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
}

// ✅ Order Details Dialog Widget
class OrderDetailsDialog extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onAddPaymentPressed;
  final VoidCallback onEditOrderPressed;
  final Function(InputModel) onEditPaymentPressed;
  final Function(InputModel) onDeletePaymentPressed;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    required this.onAddPaymentPressed,
    required this.onEditOrderPressed,
    required this.onEditPaymentPressed,
    required this.onDeletePaymentPressed,
  });

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the updated order from provider
    final orderProvider = Provider.of<OrderProvider>(context);
    final updatedOrder = orderProvider.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

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
            _buildHeader(updatedOrder),
            const SizedBox(height: 16),
            _buildInfoCards(updatedOrder),
            const SizedBox(height: 16),
            _buildOrderInfoSection(updatedOrder),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(updatedOrder),
                  _buildPaymentsTab(),
                  _buildDescriptionTab(updatedOrder),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(OrderModel order) {
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
                'Order ${order.orderNumber}',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Client: ${order.clientName}',
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
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _getStatusColor(order.status)),
          ),
          child: Text(
            order.statusDisplay.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _getStatusColor(order.status),
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

  Widget _buildInfoCards(OrderModel order) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Amount',
            '${order.totalAmount} DA',
            AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Total Paid',
            '${order.paidAmount.toStringAsFixed(2)} DA',
            AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Remaining',
            '${order.remainingAmount} DA',
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Payment %',
            order.percentagePaid,
            AppColors.secondary,
          ),
        ),
        if (order.totalBenefit != '0') ...[
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              'Net Profit',
              '${order.totalBenefit} DA',
              AppColors.success,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          _buildInfoItem(Icons.person, 'Client', order.clientName),
          const SizedBox(width: 20),
          Expanded(
            child: _buildInfoItem(
              Icons.description,
              'Description',
              order.description,
            ),
          ),
          const SizedBox(width: 20),
          _buildInfoItem(Icons.calendar_today, 'Delivery', order.deliveryDate),
          const SizedBox(width: 20),
          _buildInfoItem(
            Icons.access_time,
            'Created',
            order.formattedCreatedAt,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
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
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
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
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Payments'),
          Tab(text: 'Description'),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                _buildTableHeader('Field', flex: 2),
                _buildTableHeader('Value', flex: 3),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDetailRow(
                  'Order Number',
                  order.orderNumber,
                  isHighlight: true,
                ),
                Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDetailRow('Client Name', order.clientName),
                Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDetailRow('Status', order.statusDisplay),
                Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDetailRow('Delivery Date', order.deliveryDate),
                Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDetailRow('Created At', order.formattedCreatedAt),
                Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDetailRow(
                  'Total Amount',
                  '${order.totalAmount} DA',
                  isHighlight: true,
                ),
                Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDetailRow(
                  'Total Paid',
                  '${order.paidAmount.toStringAsFixed(2)} DA',
                ),
                Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDetailRow(
                  'Remaining',
                  '${order.remainingAmount} DA',
                  isHighlight: true,
                ),
                Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDetailRow('Payment Percentage', order.percentagePaid),
                if (order.totalExpenses != '0') ...[
                  Divider(height: 1, color: AppColors.surfaceVariant),
                  _buildDetailRow(
                    'Total Expenses',
                    '${order.totalExpenses} DA',
                  ),
                ],
                if (order.totalBenefit != '0') ...[
                  Divider(height: 1, color: AppColors.surfaceVariant),
                  _buildDetailRow(
                    'Total Benefit',
                    '${order.totalBenefit} DA',
                    isHighlight: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return Consumer<InputProvider>(
      builder: (context, inputProvider, _) {
        // Calculate total payments
        double totalPayments = 0;
        for (var payment in inputProvider.orderInputs) {
          totalPayments += double.tryParse(payment.amount) ?? 0;
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payments (${inputProvider.orderTotalCount})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onAddPaymentPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          border: Border.all(color: AppColors.success),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'Add Payment',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (inputProvider.isLoading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (inputProvider.orderInputs.isEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No payments recorded',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.5),
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.surfaceVariant,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildTableHeader('Reference', flex: 2),
                            _buildTableHeader('Date', flex: 2),
                            _buildTableHeader('Amount', flex: 2),
                            _buildTableHeader('Description', flex: 3),
                            _buildTableHeader('Actions', flex: 1),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: inputProvider.orderInputs.length,
                          separatorBuilder:
                              (_, __) => Divider(
                                height: 1,
                                color: AppColors.surfaceVariant,
                              ),
                          itemBuilder: (context, index) {
                            final payment = inputProvider.orderInputs[index];
                            return _buildPaymentRowTable(payment);
                          },
                        ),
                      ),
                      // Total Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          border: Border(
                            top: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'TOTAL',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${inputProvider.orderInputs.length} payment(s)',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${totalPayments.toStringAsFixed(2)} DA',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(flex: 3, child: const SizedBox()),
                            Expanded(flex: 1, child: const SizedBox()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentRowTable(InputModel payment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              payment.reference,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              payment.formattedDate,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              payment.formattedAmount,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              payment.description.isEmpty ? '-' : payment.description,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 16, color: AppColors.info),
                  tooltip: 'Edit',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () {
                    widget.onEditPaymentPressed(payment);
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  tooltip: 'Delete',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () {
                    widget.onDeletePaymentPressed(payment);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Order Description',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceVariant, width: 1),
              ),
              child: Text(
                order.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedCustomButton(
          text: 'Edit',
          onPressed: widget.onEditOrderPressed,
        ),
        const SizedBox(width: 8),
        PrimaryButton(text: 'Close', onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.info;
      case 'cancelled':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ✅ Searchable Client Dropdown - Using API Search
class _SearchableClientDropdownWidget extends StatefulWidget {
  final String labelText;
  final String selectedId;
  final Function(String) onChanged;

  const _SearchableClientDropdownWidget({
    required this.labelText,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  State<_SearchableClientDropdownWidget> createState() =>
      _SearchableClientDropdownWidgetState();
}

class _SearchableClientDropdownWidgetState
    extends State<_SearchableClientDropdownWidget> {
  late String _currentValue;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  late GlobalKey _containerKey;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  List<ClientModel> _filteredItems = [];
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

  Future<void> _updateFilteredListWithAPI(String query) async {
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

    try {
      final results = await context.read<ClientProvider>().searchClientsAPI(
        query,
      );

      setState(() {
        _filteredItems = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching: $e');
      setState(() {
        _filteredItems = [];
        _isSearching = false;
      });
    }
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
                            onChanged: (value) async {
                              await _updateFilteredListWithAPI(value);
                              setStateOverlay(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name, ID, or phone...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon:
                                  _isSearching
                                      ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                        ),
                                      )
                                      : const Icon(Icons.search, size: 16),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _updateFilteredListWithAPI('');
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
                                      Icons.public,
                                      size: 14,
                                      color:
                                          _currentValue == 'all'
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'All Clients',
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
                                          'No clients found',
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
                                                      item.name,
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
                                                      'ID: ${item.id} • ${item.phone}',
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
    if (_currentValue == 'all') return 'All Clients';
    try {
      final client = context.read<ClientProvider>().clients.firstWhere(
        (c) => c.id.toString() == _currentValue,
      );
      return client.name;
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
                          Icons.person,
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
                                  _currentValue == 'all'
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

// ✅ Simple Description Field with Optional Auto-Numbering
class _DescriptionFieldWithStyling extends StatefulWidget {
  final TextEditingController controller;

  const _DescriptionFieldWithStyling({required this.controller});

  @override
  State<_DescriptionFieldWithStyling> createState() =>
      _DescriptionFieldWithStylingState();
}

class _DescriptionFieldWithStylingState
    extends State<_DescriptionFieldWithStyling> {
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  bool _autoNumberingEnabled = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (!_autoNumberingEnabled) return;

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      final text = widget.controller.text;
      final cursorPos = widget.controller.selection.baseOffset;

      if (cursorPos == -1) return;

      final lines = text.split('\n');
      int currentLineIndex = 0;
      int charCount = 0;

      for (int i = 0; i < lines.length; i++) {
        if (charCount + lines[i].length >= cursorPos) {
          currentLineIndex = i;
          break;
        }
        charCount += lines[i].length + 1;
      }

      String currentLine = lines[currentLineIndex];

      RegExp numberedPattern = RegExp(r'^(\d+)-\s*(.*)$');
      Match? match = numberedPattern.firstMatch(currentLine.trim());

      if (match != null) {
        int currentNumber = int.parse(match.group(1)!);
        String nextNumber = (currentNumber + 1).toString();

        int lineEndPos = charCount + currentLine.length;

        final newText =
            '${text.substring(0, lineEndPos)}\n$nextNumber- ${text.substring(lineEndPos)}';

        widget.controller.text = newText;

        int newCursorPos = lineEndPos + 1 + nextNumber.length + 2;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: newCursorPos),
          );
          _keepCurrentScroll();
        });
      } else if (currentLineIndex == 0 && currentLine.trim().isNotEmpty) {
        int lineEndPos = charCount + currentLine.length;

        final newText =
            '${text.substring(0, lineEndPos)}\n1- ${text.substring(lineEndPos)}';

        widget.controller.text = newText;

        int newCursorPos = lineEndPos + 1 + 3;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: newCursorPos),
          );
          _keepCurrentScroll();
        });
      }
    }
  }

  void _keepCurrentScroll() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 10), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.offset);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: 'Description',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                children: [
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
            GestureDetector(
              onTap: () {
                setState(() {
                  _autoNumberingEnabled = !_autoNumberingEnabled;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _autoNumberingEnabled
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.surfaceVariant.withOpacity(0.5),
                  border: Border.all(
                    color:
                        _autoNumberingEnabled
                            ? AppColors.success
                            : AppColors.surfaceVariant,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      _autoNumberingEnabled
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color:
                          _autoNumberingEnabled
                              ? AppColors.success
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _autoNumberingEnabled ? 'Numbering ON' : 'Numbering OFF',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            _autoNumberingEnabled
                                ? AppColors.success
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  _autoNumberingEnabled
                      ? AppColors.success.withOpacity(0.5)
                      : AppColors.surfaceVariant,
              width: _autoNumberingEnabled ? 1.5 : 1,
            ),
          ),
          child: RawKeyboardListener(
            focusNode: _focusNode,
            onKey: _handleKeyEvent,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                minLines: 15,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText:
                      _autoNumberingEnabled
                          ? 'Auto-numbering is ACTIVE\n\nPress Enter to auto-generate: 1-\nPress Enter again for: 2-\nContinue for: 3-, 4-...'
                          : 'Enter your description here...\n\nToggle "Numbering" button above to enable auto-numbering',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                _autoNumberingEnabled
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.info.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  _autoNumberingEnabled
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.info.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _autoNumberingEnabled
                        ? Icons.check_circle
                        : Icons.info_outline,
                    size: 16,
                    color:
                        _autoNumberingEnabled
                            ? AppColors.success
                            : AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _autoNumberingEnabled
                        ? 'Auto-Numbering Active'
                        : 'Auto-Numbering Inactive',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color:
                          _autoNumberingEnabled
                              ? AppColors.success
                              : AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _autoNumberingEnabled
                    ? '✓ Auto-numbering is ON\n• Write any text on first line\n• Press Enter to start: 1-\n• Press Enter again for: 2-, 3-, etc.'
                    : '○ Auto-numbering is OFF\n• Click the button above to enable\n• Then write text and press Enter',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color:
                      _autoNumberingEnabled
                          ? AppColors.success
                          : AppColors.info,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Order Status Badge
class _OrderStatusBadge extends StatelessWidget {
  final String status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        borderColor = AppColors.warning.withOpacity(0.3);
        textColor = AppColors.warning;
        displayText = 'Pending';
        break;
      case 'in_progress':
        backgroundColor = AppColors.info.withOpacity(0.1);
        borderColor = AppColors.info.withOpacity(0.3);
        textColor = AppColors.info;
        displayText = 'In Progress';
        break;
      case 'completed':
        backgroundColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success.withOpacity(0.3);
        textColor = AppColors.success;
        displayText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        borderColor = AppColors.primary.withOpacity(0.3);
        textColor = AppColors.primary;
        displayText = 'Cancelled';
        break;
      default:
        backgroundColor = AppColors.info.withOpacity(0.1);
        borderColor = AppColors.info.withOpacity(0.3);
        textColor = AppColors.info;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// Payment Status Badge
class _PaymentStatusBadge extends StatelessWidget {
  final String paymentStatus;
  final bool isFullyPaid;

  const _PaymentStatusBadge({
    required this.paymentStatus,
    required this.isFullyPaid,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isFullyPaid) {
      backgroundColor = AppColors.success.withOpacity(0.1);
      borderColor = AppColors.success.withOpacity(0.3);
      textColor = AppColors.success;
    } else if (paymentStatus == 'Unpaid') {
      backgroundColor = AppColors.warning.withOpacity(0.1);
      borderColor = AppColors.warning.withOpacity(0.3);
      textColor = AppColors.warning;
    } else {
      backgroundColor = AppColors.info.withOpacity(0.1);
      borderColor = AppColors.info.withOpacity(0.3);
      textColor = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        paymentStatus,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// Pagination Controls
class _PaginationControls extends StatelessWidget {
  final OrderProvider orderProvider;

  const _PaginationControls({required this.orderProvider});

  @override
  Widget build(BuildContext context) {
    if (orderProvider.totalPages <= 1) return Container();

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
            'Page ${orderProvider.currentPage} of ${orderProvider.totalPages} '
            '(${orderProvider.totalCount} total)',
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
                    orderProvider.currentPage > 1
                        ? () => orderProvider.goToPage(1)
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    orderProvider.hasPreviousPage
                        ? () => orderProvider.previousPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              const SizedBox(width: 8),
              ...List.generate(
                orderProvider.totalPages > 5 ? 5 : orderProvider.totalPages,
                (index) {
                  int pageNum;
                  if (orderProvider.totalPages <= 5) {
                    pageNum = index + 1;
                  } else {
                    if (orderProvider.currentPage <= 3) {
                      pageNum = index + 1;
                    } else if (orderProvider.currentPage >=
                        orderProvider.totalPages - 2) {
                      pageNum = orderProvider.totalPages - 4 + index;
                    } else {
                      pageNum = orderProvider.currentPage - 2 + index;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: () => orderProvider.goToPage(pageNum),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            pageNum == orderProvider.currentPage
                                ? AppColors.primary
                                : Colors.transparent,
                        foregroundColor:
                            pageNum == orderProvider.currentPage
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
                    orderProvider.hasNextPage
                        ? () => orderProvider.nextPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed:
                    orderProvider.currentPage < orderProvider.totalPages
                        ? () => orderProvider.goToPage(orderProvider.totalPages)
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
