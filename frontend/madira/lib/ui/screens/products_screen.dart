import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dropdown_widget.dart';
import '../widgets/custom_dialog_widget.dart';
import '../widgets/responsive_table_widget.dart';
import 'product_stock_movements_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _unitFilter = 'all';
  String _sortBy =
      '-created_at'; // Default to newest first - server-side format

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Apply filters to the server
  Future<void> _applyFilters() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    await productProvider.fetchProducts(
      page: 1, // Reset to first page when filters change
      search: _searchController.text,
      unit: _unitFilter == 'all' ? null : _unitFilter,
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
              // Error State
              Consumer<ProductProvider>(
                builder: (context, productProvider, _) {
                  if (productProvider.error != null) {
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
                            'Error: ${productProvider.error}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedCustomButton(
                            text: 'Retry',
                            onPressed: () => productProvider.fetchProducts(),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products Management',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your inventory products and materials',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  PrimaryButton(
                    size: ButtonSize.medium,
                    text: 'New Product',
                    onPressed: () {
                      _showCreateProductDialog(context);
                    },
                    icon: const Icon(
                      Icons.add_box,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search and Filters Row
              Row(
                children: [
                  // Search Input
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
                          hintText: 'Search by name or reference...',
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
                  // Unit Filter
                  Expanded(
                    child: CustomDropdownWidget<String>(
                      labelText: 'Unit Type',
                      value: _unitFilter,
                      prefixIcon: Icons.straighten,
                      hintText: 'Filter by unit',
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Units'),
                        ),
                        DropdownMenuItem(value: 'piece', child: Text('Piece')),
                        DropdownMenuItem(value: 'm', child: Text('Meter (m)')),
                        DropdownMenuItem(
                          value: 'm²',
                          child: Text('Square Meter (m²)'),
                        ),
                        DropdownMenuItem(
                          value: 'm³',
                          child: Text('Cubic Meter (m³)'),
                        ),
                        DropdownMenuItem(
                          value: 'kg',
                          child: Text('Kilogram (kg)'),
                        ),
                        DropdownMenuItem(value: 'l', child: Text('Liter (l)')),
                        DropdownMenuItem(value: 'box', child: Text('Box')),
                        DropdownMenuItem(value: 'pack', child: Text('Pack')),
                        DropdownMenuItem(value: 'roll', child: Text('Roll')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _unitFilter = value ?? 'all';
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Sort By
                  Expanded(
                    child: CustomDropdownWidget<String>(
                      labelText: 'Sort By',
                      value: _sortBy,
                      prefixIcon: Icons.sort,
                      hintText: 'Sort products',
                      items: const [
                        DropdownMenuItem(
                          value: 'name',
                          child: Text('Name (A-Z)'),
                        ),
                        DropdownMenuItem(
                          value: '-name',
                          child: Text('Name (Z-A)'),
                        ),
                        DropdownMenuItem(
                          value: '-current_quantity',
                          child: Text('Quantity (High-Low)'),
                        ),
                        DropdownMenuItem(
                          value: 'current_quantity',
                          child: Text('Quantity (Low-High)'),
                        ),
                        DropdownMenuItem(
                          value: '-created_at',
                          child: Text('Newest First'),
                        ),
                        DropdownMenuItem(
                          value: 'created_at',
                          child: Text('Oldest First'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value ?? '-created_at';
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Products Table
              Consumer<ProductProvider>(
                builder: (context, productProvider, _) {
                  if (productProvider.isLoading) {
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

                  // Get filtered and sorted products (active only)
                  final filteredProducts = productProvider.products;

                  if (filteredProducts.isEmpty) {
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
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Products Found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            productProvider.searchQuery.isNotEmpty
                                ? 'No products match your search criteria'
                                : 'Create your first product to get started',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Products Table
                      ResponsiveTable(
                        columns: [
                          'Reference',
                          'Name',
                          'Unit',
                          'Quantity',
                          'Description',
                          'Created',
                          'Actions',
                        ],
                        minColumnWidth: 100,
                        rows:
                            filteredProducts
                                .map(
                                  (product) => _buildProductRow(
                                    context,
                                    product,
                                    productProvider,
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 32),

                      // Pagination
                      _PaginationControls(productProvider: productProvider),
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

  List<Widget> _buildProductRow(
    BuildContext context,
    ProductModel product,
    ProductProvider productProvider,
  ) {
    return [
      // Reference
      Text(
        product.reference,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Name
      Text(
        product.name,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Unit
      _UnitBadge(unit: product.unit),
      // Quantity
      Text(
        product.formattedQuantity,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.info,
        ),
      ),
      // Description
      Text(
        product.description.isEmpty ? '-' : product.description,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Created
      Text(product.formattedCreatedAt, style: GoogleFonts.inter(fontSize: 12)),
      // Actions
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.history, size: 16),
            color: AppColors.success,
            tooltip: 'Stock History',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ProductStockMovementsScreen(product: product),
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
              _showProductDetailDialog(context, product);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: AppColors.info,
            tooltip: 'Edit',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              _showEditProductDialog(context, product, productProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.block, size: 16),
            color: AppColors.warning,
            tooltip: 'Deactivate',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              _showDeactivateConfirm(context, product, productProvider);
            },
          ),
        ],
      ),
    ];
  }

  void _showCreateProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final initialQuantityController = TextEditingController();
    final initialPriceController = TextEditingController();
    String selectedUnit = 'piece';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'New Product',
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomInputWidget(
                        controller: nameController,
                        labelText: 'Product Name',
                        hintText: 'Enter product name',
                        prefixIcon: const Icon(Icons.inventory_2),
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdownWidget<String>(
                        labelText: 'Unit',
                        value: selectedUnit,
                        required: true,
                        prefixIcon: Icons.straighten,
                        hintText: 'Select unit',
                        items: const [
                          DropdownMenuItem(
                            value: 'piece',
                            child: Text('Piece'),
                          ),
                          DropdownMenuItem(
                            value: 'm',
                            child: Text('Meter (m)'),
                          ),
                          DropdownMenuItem(
                            value: 'm²',
                            child: Text('Square Meter (m²)'),
                          ),
                          DropdownMenuItem(
                            value: 'm³',
                            child: Text('Cubic Meter (m³)'),
                          ),
                          DropdownMenuItem(
                            value: 'kg',
                            child: Text('Kilogram (kg)'),
                          ),
                          DropdownMenuItem(
                            value: 'l',
                            child: Text('Liter (l)'),
                          ),
                          DropdownMenuItem(value: 'box', child: Text('Box')),
                          DropdownMenuItem(value: 'pack', child: Text('Pack')),
                          DropdownMenuItem(value: 'roll', child: Text('Roll')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedUnit = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomInputWidget(
                              controller: initialQuantityController,
                              labelText: 'Initial Quantity',
                              hintText: 'Enter quantity',
                              prefixIcon: const Icon(Icons.numbers),
                              keyboardType: TextInputType.number,
                              required: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomInputWidget(
                              controller: initialPriceController,
                              labelText: 'Initial Price (DA)',
                              hintText: 'Price per unit',
                              prefixIcon: const Icon(Icons.attach_money),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              required: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                                'Initial price is required only when quantity is greater than 0.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomInputWidget(
                        controller: descriptionController,
                        labelText: 'Description',
                        hintText: 'Enter product description (optional)',
                        prefixIcon: const Icon(Icons.description),
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
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter product name',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          );
                          return;
                        }

                        final quantity =
                            double.tryParse(initialQuantityController.text) ??
                            0.0;
                        final price = double.tryParse(
                          initialPriceController.text,
                        );

                        // If quantity > 0, price field must be filled (but can be 0)
                        if (quantity > 0 && price == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Initial price is required when quantity is greater than 0',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final productProvider = Provider.of<ProductProvider>(
                            context,
                            listen: false,
                          );

                          final success = await productProvider.createProduct(
                            name: nameController.text,
                            unit: selectedUnit,
                            currentQuantity: quantity,
                            description: descriptionController.text,
                            initialPrice: quantity > 0 ? (price ?? 0.0) : null,
                          );

                          if (mounted) {
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Product created successfully',
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
                                    'Error: ${productProvider.error}',
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

  void _showEditProductDialog(
    BuildContext context,
    ProductModel product,
    ProductProvider productProvider,
  ) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(
      text: product.description,
    );
    String selectedUnit = product.unit;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'Edit Product',
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.reference,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomInputWidget(
                        controller: nameController,
                        labelText: 'Product Name',
                        hintText: 'Enter product name',
                        prefixIcon: const Icon(Icons.inventory_2),
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdownWidget<String>(
                        labelText: 'Unit',
                        value: selectedUnit,
                        required: true,
                        prefixIcon: Icons.straighten,
                        hintText: 'Select unit',
                        items: const [
                          DropdownMenuItem(
                            value: 'piece',
                            child: Text('Piece'),
                          ),
                          DropdownMenuItem(
                            value: 'm',
                            child: Text('Meter (m)'),
                          ),
                          DropdownMenuItem(
                            value: 'm²',
                            child: Text('Square Meter (m²)'),
                          ),
                          DropdownMenuItem(
                            value: 'm³',
                            child: Text('Cubic Meter (m³)'),
                          ),
                          DropdownMenuItem(
                            value: 'kg',
                            child: Text('Kilogram (kg)'),
                          ),
                          DropdownMenuItem(
                            value: 'l',
                            child: Text('Liter (l)'),
                          ),
                          DropdownMenuItem(value: 'box', child: Text('Box')),
                          DropdownMenuItem(value: 'pack', child: Text('Pack')),
                          DropdownMenuItem(value: 'roll', child: Text('Roll')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedUnit = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Display current quantity as read-only info
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Quantity',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.formattedQuantity,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.info,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity can only be changed via Input/Order transactions',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomInputWidget(
                        controller: descriptionController,
                        labelText: 'Description',
                        hintText: 'Enter product description (optional)',
                        prefixIcon: const Icon(Icons.description),
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
                        if (nameController.text.isEmpty) {
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
                          final success = await productProvider.updateProduct(
                            product.id,
                            name: nameController.text,
                            unit: selectedUnit,
                            currentQuantity: double.parse(
                              product.currentQuantity,
                            ),
                            description: descriptionController.text,
                            isActive: product.isActive,
                          );

                          if (mounted) {
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Product updated successfully',
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

  void _showProductDetailDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            title: 'Product Details',
            size: DialogSize.big,
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Reference',
                  product.reference,
                  isHighlight: true,
                ),
                const Divider(),
                _buildDetailRow('Name', product.name, isHighlight: true),
                const Divider(),
                _buildDetailRow('Unit', _getUnitDisplay(product.unit)),
                const Divider(),
                _buildDetailRow(
                  'Current Quantity',
                  product.formattedQuantity,
                  isHighlight: true,
                ),
                const Divider(),
                _buildDetailRow(
                  'Description',
                  product.description.isEmpty
                      ? 'No description'
                      : product.description,
                ),
                const Divider(),
                _buildDetailRow(
                  'Status',
                  product.isActive ? 'Active' : 'Inactive',
                  isHighlight: product.isActive,
                ),
                const Divider(),
                _buildDetailRow('Created At', product.formattedCreatedAt),
                const Divider(),
                _buildDetailRow('Updated At', product.formattedUpdatedAt),
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
            width: 140,
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

  String _getUnitDisplay(String unit) {
    switch (unit) {
      case 'piece':
        return 'Piece';
      case 'm':
        return 'Meter (m)';
      case 'm²':
        return 'Square Meter (m²)';
      case 'm³':
        return 'Cubic Meter (m³)';
      case 'kg':
        return 'Kilogram (kg)';
      case 'l':
        return 'Liter (l)';
      case 'box':
        return 'Box';
      case 'pack':
        return 'Pack';
      case 'roll':
        return 'Roll';
      default:
        return unit;
    }
  }

  void _showDeactivateConfirm(
    BuildContext context,
    ProductModel product,
    ProductProvider productProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Deactivate Product',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to deactivate ${product.name}?',
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
                    final success = await productProvider.deactivateProduct(
                      product.id,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Product deactivated successfully',
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

// Unit Badge Widget
class _UnitBadge extends StatelessWidget {
  final String unit;

  const _UnitBadge({required this.unit});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = AppColors.info.withOpacity(0.1);
    Color borderColor = AppColors.info.withOpacity(0.3);
    Color textColor = AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        unit,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// Pagination Controls
class _PaginationControls extends StatelessWidget {
  final ProductProvider productProvider;

  const _PaginationControls({required this.productProvider});

  @override
  Widget build(BuildContext context) {
    if (productProvider.totalPages <= 1) return Container();

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
            'Page ${productProvider.currentPage} of ${productProvider.totalPages} '
            '(${productProvider.totalCount} total)',
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
                    productProvider.currentPage > 1
                        ? () => productProvider.goToPage(1)
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    productProvider.hasPreviousPage
                        ? () => productProvider.previousPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              const SizedBox(width: 8),
              ...List.generate(
                productProvider.totalPages > 5 ? 5 : productProvider.totalPages,
                (index) {
                  int pageNum;
                  if (productProvider.totalPages <= 5) {
                    pageNum = index + 1;
                  } else {
                    if (productProvider.currentPage <= 3) {
                      pageNum = index + 1;
                    } else if (productProvider.currentPage >=
                        productProvider.totalPages - 2) {
                      pageNum = productProvider.totalPages - 4 + index;
                    } else {
                      pageNum = productProvider.currentPage - 2 + index;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: () => productProvider.goToPage(pageNum),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            pageNum == productProvider.currentPage
                                ? AppColors.primary
                                : Colors.transparent,
                        foregroundColor:
                            pageNum == productProvider.currentPage
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
                    productProvider.hasNextPage
                        ? () => productProvider.nextPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed:
                    productProvider.currentPage < productProvider.totalPages
                        ? () =>
                            productProvider.goToPage(productProvider.totalPages)
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
