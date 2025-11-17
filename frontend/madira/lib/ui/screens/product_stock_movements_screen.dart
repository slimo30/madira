import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/product_model.dart';
import '../../models/stock_movement_model.dart';
import '../../models/order_model.dart';
import '../../providers/stock_movement_provider.dart';
import '../../providers/order_provider.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dialog_widget.dart';
import '../widgets/responsive_table_widget.dart';

class ProductStockMovementsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductStockMovementsScreen({super.key, required this.product});

  @override
  State<ProductStockMovementsScreen> createState() =>
      _ProductStockMovementsScreenState();
}

class _ProductStockMovementsScreenState
    extends State<ProductStockMovementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockMovementProvider = Provider.of<StockMovementProvider>(
        context,
        listen: false,
      );
      stockMovementProvider.fetchMovementsByProduct(widget.product.id);

      // Fetch orders for the dropdown
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Stock Movements',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Summary Card
            Consumer<StockMovementProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.productSummary == null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }

                final summary = provider.productSummary;
                if (summary == null) {
                  return const SizedBox.shrink();
                }

                return _buildProductSummaryCard(summary);
              },
            ),

            const SizedBox(height: 24),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movement History',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                PrimaryButton(
                  size: ButtonSize.medium,
                  text: 'New OUT Movement',
                  onPressed: () {
                    _showCreateMovementDialog(context);
                  },
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Movements Table
            Consumer<StockMovementProvider>(
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

                if (provider.error != null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Error: ${provider.error}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedCustomButton(
                          text: 'Retry',
                          onPressed:
                              () => provider.fetchMovementsByProduct(
                                widget.product.id,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.movements.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Movements Found',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No stock movements recorded for this product',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Consumer<OrderProvider>(
                  builder: (context, orderProvider, _) {
                    return ResponsiveTable(
                      columns: [
                        'Type',
                        'Quantity',
                        'Price',
                        'Order',
                        'Client Name',
                        'Date',
                        'Created',
                        'Actions',
                      ],
                      minColumnWidth: 100,
                      rows:
                          provider.movements
                              .map(
                                (movement) => _buildMovementRow(
                                  context,
                                  movement,
                                  provider,
                                  orderProvider,
                                ),
                              )
                              .toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSummaryCard(ProductStockSummary summary) {
    return Container(
      width: double.infinity,
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
              Icon(Icons.inventory_2, size: 32, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.reference,
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Current Stock',
                  summary.formattedCurrentQuantity,
                  AppColors.info,
                  Icons.inventory,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total IN',
                  summary.formattedTotalIn,
                  AppColors.success,
                  Icons.arrow_circle_down,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total OUT',
                  summary.formattedTotalOut,
                  AppColors.warning,
                  Icons.arrow_circle_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMovementRow(
    BuildContext context,
    StockMovementModel movement,
    StockMovementProvider provider,
    OrderProvider orderProvider,
  ) {
    // Get client name from OrderProvider using the order ID
    String? clientName;
    if (movement.order != null) {
      try {
        final order = orderProvider.orders.firstWhere(
          (o) => o.id == movement.order,
        );
        clientName = order.clientName;
      } catch (e) {
        clientName = null;
      }
    }

    return [
      // Type
      _MovementTypeBadge(movement: movement),
      // Quantity
      Text(
        '${movement.formattedQuantity} ${provider.productSummary?.unit ?? ''}',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: movement.isInMovement ? AppColors.success : AppColors.warning,
        ),
      ),
      // Price
      Text(
        '${movement.formattedPrice} DA',
        style: GoogleFonts.inter(fontSize: 12),
      ),
      // Order
      Text(
        movement.orderNumber ?? 'N/A',
        style: GoogleFonts.inter(
          fontSize: 12,
          color:
              movement.orderNumber != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Client Name - fetched from OrderProvider
      Text(
        clientName ?? 'N/A',
        style: GoogleFonts.inter(
          fontSize: 12,
          color:
              clientName != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Date
      Text(movement.formattedDate, style: GoogleFonts.inter(fontSize: 12)),
      // Created
      Text(
        movement.formattedCreatedAt,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
      ),
      // Actions
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (movement.isOutMovement) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16),
              color: AppColors.info,
              tooltip: 'Edit',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                _showEditMovementDialog(context, movement);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              color: AppColors.primary,
              tooltip: 'Delete',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                _showDeleteConfirm(context, movement, provider);
              },
            ),
          ] else
            Text(
              'Input Only',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    ];
  }

  void _showCreateMovementDialog(BuildContext context) {
    final quantityController = TextEditingController();
    int? selectedOrderId;

    showDialog(
      context: context,
      builder:
          (context) => Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              return StatefulBuilder(
                builder:
                    (context, setState) => CustomDialogWidget(
                      title: 'New OUT Movement',
                      isScrollable: true,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.info.withOpacity(0.2),
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
                                    'Creating OUT movement for: ${widget.product.name}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SearchableOrderDropdownWidget(
                            labelText: 'Select Order',
                            selectedId: selectedOrderId?.toString() ?? 'none',
                            onChanged: (orderId) {
                              setState(() {
                                selectedOrderId =
                                    orderId == 'none'
                                        ? null
                                        : int.parse(orderId);
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomInputWidget(
                            controller: quantityController,
                            labelText: 'Quantity',
                            hintText: 'Enter quantity',
                            prefixIcon: const Icon(Icons.numbers),
                            keyboardType: TextInputType.number,
                            required: true,
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
                            if (selectedOrderId == null ||
                                quantityController.text.isEmpty) {
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
                              final stockMovementProvider =
                                  Provider.of<StockMovementProvider>(
                                    context,
                                    listen: false,
                                  );

                              final success = await stockMovementProvider
                                  .createMovement(
                                    productId: widget.product.id,
                                    orderId: selectedOrderId!,
                                    quantity:
                                        double.tryParse(
                                          quantityController.text,
                                        ) ??
                                        0,
                                  );

                              if (mounted) {
                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Movement created successfully',
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
                                        'Error: ${stockMovementProvider.error}',
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
            },
          ),
    );
  }

  void _showEditMovementDialog(
    BuildContext context,
    StockMovementModel movement,
  ) {
    final quantityController = TextEditingController(
      text: movement.quantity.toString(),
    );
    int? selectedOrderId = movement.order;

    showDialog(
      context: context,
      builder:
          (context) => Consumer2<OrderProvider, StockMovementProvider>(
            builder: (context, orderProvider, stockMovementProvider, _) {
              return StatefulBuilder(
                builder:
                    (context, setState) => CustomDialogWidget(
                      title: 'Edit Movement',
                      isScrollable: true,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_outlined,
                                  size: 18,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Stock: ${stockMovementProvider.productSummary?.formattedCurrentQuantity ?? "0"} ${stockMovementProvider.productSummary?.unit ?? ""}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Original Movement: ${movement.formattedQuantity} ${stockMovementProvider.productSummary?.unit ?? ""}',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SearchableOrderDropdownWidget(
                            labelText: 'Select Order',
                            selectedId: selectedOrderId?.toString() ?? 'none',
                            onChanged: (orderId) {
                              setState(() {
                                selectedOrderId =
                                    orderId == 'none'
                                        ? null
                                        : int.parse(orderId.toString());
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomInputWidget(
                            controller: quantityController,
                            labelText: 'Quantity',
                            hintText: 'Enter quantity',
                            prefixIcon: const Icon(Icons.numbers),
                            keyboardType: TextInputType.number,
                            required: true,
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
                            if (selectedOrderId == null ||
                                quantityController.text.isEmpty) {
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

                            final newQuantity =
                                double.tryParse(quantityController.text) ?? 0;
                            final oldQuantity =
                                double.tryParse(movement.quantity) ?? 0;
                            final currentStock =
                                stockMovementProvider
                                    .productSummary
                                    ?.currentQuantity ??
                                0.0;

                            // Calculate available stock: current stock + old movement quantity
                            final availableStock = currentStock + oldQuantity;

                            // Check if new quantity exceeds available stock
                            if (newQuantity > availableStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Insufficient stock! Available: ${availableStock.toStringAsFixed(2)} ${stockMovementProvider.productSummary?.unit ?? ""}',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                              return;
                            }

                            try {
                              final success = await stockMovementProvider
                                  .updateMovement(
                                    movement.id,
                                    productId: widget.product.id,
                                    orderId: selectedOrderId!,
                                    quantity: newQuantity,
                                  );

                              if (mounted) {
                                if (success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Movement updated successfully',
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
                                        'Error: ${stockMovementProvider.error}',
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
            },
          ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    StockMovementModel movement,
    StockMovementProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Delete Movement',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete this movement?',
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
                text: 'Delete',
                onPressed: () async {
                  try {
                    final success = await provider.deleteMovement(
                      movement.id,
                      widget.product.id,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Movement deleted successfully',
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

// Movement Type Badge Widget
class _MovementTypeBadge extends StatelessWidget {
  final StockMovementModel movement;

  const _MovementTypeBadge({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isInMovement;
    final backgroundColor =
        isIn
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1);
    final borderColor =
        isIn
            ? AppColors.success.withOpacity(0.3)
            : AppColors.warning.withOpacity(0.3);
    final textColor = isIn ? AppColors.success : AppColors.warning;
    final icon = isIn ? Icons.arrow_downward : Icons.arrow_upward;

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
          Text(
            movement.movementType.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
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
                                  _currentValue == 'none'
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
