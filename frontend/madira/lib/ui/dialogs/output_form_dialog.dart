// ✅ Output Form Dialogs - Create and Edit with type-based validation
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/storage/storage_service.dart';
import '../../models/output_model.dart';
import '../../models/input_model.dart';
import '../../models/order_model.dart';
import '../../models/supplier_model.dart';
import '../../models/product_model.dart';
import '../../providers/output_proviider.dart';
import '../../services/input_service.dart';
import '../../services/order_service.dart';
import '../../services/supplier_service.dart';
import '../../services/product_service.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dialog_widget.dart';

class CreateOutputDialog extends StatefulWidget {
  const CreateOutputDialog({super.key});

  @override
  State<CreateOutputDialog> createState() => _CreateOutputDialogState();
}

class _CreateOutputDialogState extends State<CreateOutputDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  // Selected values
  String _selectedType = 'consumable';
  InputModel? _selectedInput;
  OrderModel? _selectedOrder;
  SupplierModel? _selectedSupplier;
  ProductModel? _selectedProduct;

  bool _isSubmitting = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _quantityController.addListener(_updateTotal);
    _priceController.addListener(_updateTotal);
  }

  Future<void> _loadUserRole() async {
    final role = await StorageService().readRole();
    setState(() {
      _userRole = role;
      // If user is not admin/responsible and withdrawal was selected, change to consumable
      if (_selectedType == 'withdrawal' && !_canAccessWithdrawal()) {
        _selectedType = 'consumable';
      }
    });
  }

  bool _canAccessWithdrawal() {
    return _userRole == 'admin' || _userRole == 'responsible';
  }

  void _updateTotal() {
    setState(() {}); // Trigger rebuild to show updated total
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Output types with their requirements
  Map<String, Map<String, dynamic>> get outputTypeRequirements => {
    'withdrawal': {
      'label': 'Withdrawal',
      'icon': Icons.money_off,
      'requires': ['amount', 'source_input', 'description'],
      'optional': [],
    },
    'supplier_payment': {
      'label': 'Supplier Payment',
      'icon': Icons.payment,
      'requires': ['amount', 'supplier', 'source_input', 'description'],
      'optional': ['order'],
    },
    'consumable': {
      'label': 'Consumable',
      'icon': Icons.shopping_bag,
      'requires': ['amount', 'source_input', 'description'],
      'optional': [],
    },
    'global_stock_purchase': {
      'label': 'Global Stock Purchase',
      'icon': Icons.inventory_2,
      'requires': ['product', 'quantity', 'price', 'source_input'],
      'optional': ['description'],
    },
    'client_stock_usage': {
      'label': 'Client Stock Usage',
      'icon': Icons.person_outline,
      'requires': ['product', 'quantity', 'price', 'order', 'source_input'],
      'optional': ['description'],
    },
    'other_expense': {
      'label': 'Other Expense',
      'icon': Icons.more_horiz,
      'requires': ['amount', 'source_input', 'description'],
      'optional': ['order'],
    },
  };

  bool _fieldRequired(String field) {
    return outputTypeRequirements[_selectedType]?['requires']?.contains(
          field,
        ) ??
        false;
  }

  bool _fieldVisible(String field) {
    final config = outputTypeRequirements[_selectedType];
    return (config?['requires']?.contains(field) ?? false) ||
        (config?['optional']?.contains(field) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialogWidget(
      size: DialogSize.big,
      title: 'Create New Output',
      isScrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type Selection
            _buildTypeSelection(),

            const SizedBox(height: 24),

            // Type-specific info banner
            _buildTypeInfoBanner(),

            const SizedBox(height: 24),

            // Dynamic form fields based on type
            ..._buildDynamicFields(),
          ],
        ),
      ),
      actions: [
        OutlinedCustomButton(
          text: 'Cancel',
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        PrimaryButton(
          text: _isSubmitting ? 'Creating...' : 'Create Output',
          onPressed: _isSubmitting ? null : _handleSubmit,
        ),
      ],
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Output Type *',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              outputTypeRequirements.entries
                  .where((entry) {
                    // Filter out withdrawal if user is not admin/responsible
                    if (entry.key == 'withdrawal' && !_canAccessWithdrawal()) {
                      return false;
                    }
                    return true;
                  })
                  .map((entry) {
                    final isSelected = _selectedType == entry.key;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedType = entry.key;
                          // Clear fields when type changes
                          _selectedInput = null;
                          _selectedOrder = null;
                          _selectedSupplier = null;
                          _selectedProduct = null;
                          _amountController.clear();
                          _quantityController.clear();
                          _priceController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              entry.value['icon'],
                              size: 18,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.value['label'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildTypeInfoBanner() {
    final config = outputTypeRequirements[_selectedType]!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Required: ${(config['requires'] as List).join(', ').replaceAll('_', ' ')}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    final fields = <Widget>[];

    // Source Input (required for all types)
    if (_fieldVisible('source_input')) {
      fields.add(
        _SearchableInputDropdown(
          labelText:
              'Source Input ${_fieldRequired('source_input') ? '*' : ''}',
          selectedInput: _selectedInput,
          onChanged: (input) => setState(() => _selectedInput = input),
          isRequired: _fieldRequired('source_input'),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }

    // Amount (for types that need amount)
    if (_fieldVisible('amount')) {
      fields.add(
        AmountInputWidget(
          controller: _amountController,
          labelText: 'Amount (DA) ${_fieldRequired('amount') ? '*' : ''}',
          hintText: 'Enter amount',
          prefixIcon: Icons.attach_money,
          validator:
              _fieldRequired('amount')
                  ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  }
                  : null,
        ),
        // CustomInputWidget(
        //   controller: _amountController,
        //   labelText: 'Amount (DA) ${_fieldRequired('amount') ? '*' : ''}',
        //   hintText: 'Enter amount',
        //   prefixIcon: Icon(Icons.payments),
        //   keyboardType: TextInputType.number,
        //   validator:
        //       _fieldRequired('amount')
        //           ? (value) {
        //             if (value == null || value.isEmpty) {
        //               return 'Amount is required';
        //             }
        //             if (double.tryParse(value) == null) {
        //               return 'Enter a valid number';
        //             }
        //             return null;
        //           }
        //           : null,
        // ),
      );
      fields.add(const SizedBox(height: 16));
    }

    // Product (for stock-related types)
    if (_fieldVisible('product')) {
      fields.add(
        _SearchableProductDropdown(
          labelText: 'Product ${_fieldRequired('product') ? '*' : ''}',
          selectedProduct: _selectedProduct,
          onChanged: (product) => setState(() => _selectedProduct = product),
          isRequired: _fieldRequired('product'),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }

    // Quantity and Price (for stock purchases)
    if (_fieldVisible('quantity')) {
      fields.add(
        Row(
          children: [
            Expanded(
              child: CustomInputWidget(
                controller: _quantityController,
                labelText: 'Quantity ${_fieldRequired('quantity') ? '*' : ''}',
                hintText: 'Enter quantity',
                prefixIcon: Icon(Icons.inventory),
                keyboardType: TextInputType.number,
                validator:
                    _fieldRequired('quantity')
                        ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Quantity is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        }
                        : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomInputWidget(
                controller: _priceController,
                labelText: 'Price (DA) ${_fieldRequired('price') ? '*' : ''}',
                hintText: 'Enter price',
                prefixIcon: Icon(Icons.attach_money),
                keyboardType: TextInputType.number,
                validator:
                    _fieldRequired('price')
                        ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Price is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        }
                        : null,
              ),
            ),
          ],
        ),
      );
      fields.add(const SizedBox(height: 8));

      // Real-time total calculation
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0;
      final total = quantity * price;

      if (quantity > 0 || price > 0) {
        fields.add(
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.calculate, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Total: ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(2)} DA',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      fields.add(const SizedBox(height: 16));
    }

    // Supplier
    if (_fieldVisible('supplier')) {
      fields.add(
        _SearchableSupplierDropdown(
          labelText: 'Supplier ${_fieldRequired('supplier') ? '*' : ''}',
          selectedSupplier: _selectedSupplier,
          onChanged: (supplier) => setState(() => _selectedSupplier = supplier),
          isRequired: _fieldRequired('supplier'),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }

    // Order
    if (_fieldVisible('order')) {
      fields.add(
        _SearchableOrderDropdown(
          labelText: 'Order ${_fieldRequired('order') ? '*' : ''}',
          selectedOrder: _selectedOrder,
          onChanged: (order) => setState(() => _selectedOrder = order),
          isRequired: _fieldRequired('order'),
        ),
      );
      fields.add(const SizedBox(height: 16));
    }

    // Description
    if (_fieldVisible('description')) {
      fields.add(
        CustomInputWidget(
          controller: _descriptionController,
          labelText: 'Description ${_fieldRequired('description') ? '*' : ''}',
          hintText: 'Enter description',
          prefixIcon: Icon(Icons.description),
          maxLines: 3,
          validator:
              _fieldRequired('description')
                  ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  }
                  : null,
        ),
      );
    }

    return fields;
  }

  Future<void> _handleSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required dropdowns
    if (_fieldRequired('source_input') && _selectedInput == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a source input',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (_fieldRequired('product') && _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a product',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (_fieldRequired('supplier') && _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a supplier',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (_fieldRequired('order') && _selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select an order',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    // Calculate the output amount
    double outputAmount = 0;
    if (_amountController.text.isNotEmpty) {
      outputAmount = double.parse(_amountController.text);
    } else if (_quantityController.text.isNotEmpty &&
        _priceController.text.isNotEmpty) {
      final quantity = double.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      outputAmount = quantity * price;
    }

    // Validate that output amount doesn't exceed remaining amount of selected input
    if (_selectedInput != null && outputAmount > 0) {
      final remainingAmount = _selectedInput!.remainingAmount;
      if (outputAmount > remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Output amount (${outputAmount.toStringAsFixed(2)} DA) exceeds the remaining amount (${remainingAmount.toStringAsFixed(2)} DA) of the selected input',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    // Build request data based on type
    final data = <String, dynamic>{
      'type': _selectedType,
      if (_selectedInput != null) 'source_input': _selectedInput!.id,
      if (_descriptionController.text.isNotEmpty)
        'description': _descriptionController.text,
    };

    // Add amount or calculate from quantity * price
    if (_amountController.text.isNotEmpty) {
      data['amount'] = _amountController.text;
    } else if (_quantityController.text.isNotEmpty &&
        _priceController.text.isNotEmpty) {
      final quantity = double.parse(_quantityController.text);
      final price = double.parse(_priceController.text);
      data['amount'] = (quantity * price).toString();
    }

    // Add type-specific fields
    if (_selectedProduct != null) {
      data['product'] = _selectedProduct!.id;
    }
    if (_quantityController.text.isNotEmpty) {
      data['quantity'] = _quantityController.text;
    }
    if (_priceController.text.isNotEmpty) {
      data['price'] = _priceController.text;
    }
    if (_selectedSupplier != null) {
      data['supplier'] = _selectedSupplier!.id;
    }
    if (_selectedOrder != null) {
      data['order'] = _selectedOrder!.id;
    }

    // Create output
    final provider = Provider.of<OutputProvider>(context, listen: false);
    final success = await provider.createOutput(data);

    setState(() => _isSubmitting = false);

    if (context.mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Output created successfully',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Failed to create output',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}

// Searchable Input Dropdown Widget with Server-Side Search
class _SearchableInputDropdown extends StatefulWidget {
  final String labelText;
  final InputModel? selectedInput;
  final Function(InputModel?) onChanged;
  final bool isRequired;

  const _SearchableInputDropdown({
    required this.labelText,
    required this.selectedInput,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  State<_SearchableInputDropdown> createState() =>
      _SearchableInputDropdownState();
}

class _SearchableInputDropdownState extends State<_SearchableInputDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<InputModel> _filteredItems = [];
  bool _isSearching = false;
  Timer? _debounce;
  final _inputService = InputService();

  @override
  void dispose() {
    _overlayEntry?.remove();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
    _searchController.clear();
    _filteredItems = [];
    _debounce?.cancel();
  }

  Future<void> _searchInputs(String query, StateSetter setStateOverlay) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      setStateOverlay(() => _isSearching = true);

      try {
        final response = await _inputService.getInputs(
          page: 1,
          pageSize: 50,
          search: query.isEmpty ? null : query,
          ordering: '-created_at',
        );

        _filteredItems = response['results'] as List<InputModel>;
        setState(() => _isSearching = false);
        setStateOverlay(() => _isSearching = false);
      } catch (e) {
        print('Error searching inputs: $e');
        setState(() => _isSearching = false);
        setStateOverlay(() => _isSearching = false);
      }
    });
  }

  void _openDropdown() {
    if (_isOpen) return;

    // Load initial data
    _searchInputs('', (fn) {});

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: 600,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 50),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search field
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              onChanged: (value) {
                                _searchInputs(value, setStateOverlay);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by reference or client...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                prefixIcon:
                                    _isSearching
                                        ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                        : const Icon(Icons.search, size: 16),
                                suffixIcon:
                                    _searchController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _searchInputs('', setStateOverlay);
                                          },
                                        )
                                        : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: AppColors.surfaceVariant,
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
                          // List of inputs
                          Expanded(
                            child:
                                _isSearching
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : _filteredItems.isEmpty
                                    ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'No inputs found',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      itemCount: _filteredItems.length,
                                      itemBuilder: (context, index) {
                                        final input = _filteredItems[index];
                                        final isSelected =
                                            widget.selectedInput?.id ==
                                            input.id;

                                        String displayText;
                                        if (input.type == 'shop_deposit') {
                                          displayText = 'Shop Deposit';
                                        } else if (input.clientName != null &&
                                            input.clientName!.isNotEmpty) {
                                          displayText = input.clientName!;
                                        } else {
                                          displayText = 'N/A';
                                        }

                                        return InkWell(
                                          onTap: () {
                                            widget.onChanged(input);
                                            _closeDropdown();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
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
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        input.reference,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              isSelected
                                                                  ? FontWeight
                                                                      .w600
                                                                  : FontWeight
                                                                      .w500,
                                                          color:
                                                              isSelected
                                                                  ? AppColors
                                                                      .primary
                                                                  : AppColors
                                                                      .textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        displayText,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 10,
                                                              color:
                                                                  AppColors
                                                                      .info,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Amount: ${input.formattedAmount} DA',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 9,
                                                              color:
                                                                  AppColors
                                                                      .textSecondary,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Text(
                                                            'Remaining: ${input.formattedRemainingAmount} DA',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  input.hasRemainingAmount
                                                                      ? AppColors
                                                                          .success
                                                                      : AppColors
                                                                          .textSecondary,
                                                            ),
                                                          ),
                                                        ],
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
          ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
              ),
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
                      widget.selectedInput != null
                          ? '${widget.selectedInput!.reference} - ${widget.selectedInput!.formattedAmount} DA'
                          : 'Select source input',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color:
                            widget.selectedInput != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isRequired && widget.selectedInput == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Source input is required',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// Searchable Order Dropdown Widget with Server-Side Search
class _SearchableOrderDropdown extends StatefulWidget {
  final String labelText;
  final OrderModel? selectedOrder;
  final Function(OrderModel?) onChanged;
  final bool isRequired;

  const _SearchableOrderDropdown({
    required this.labelText,
    required this.selectedOrder,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  State<_SearchableOrderDropdown> createState() =>
      _SearchableOrderDropdownState();
}

class _SearchableOrderDropdownState extends State<_SearchableOrderDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<OrderModel> _filteredItems = [];
  bool _isSearching = false;
  Timer? _debounce;
  final _orderService = OrderService();

  @override
  void dispose() {
    _overlayEntry?.remove();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
    _searchController.clear();
    _filteredItems = [];
    _debounce?.cancel();
  }

  Future<void> _searchOrders(String query, StateSetter setStateOverlay) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      setStateOverlay(() => _isSearching = true);

      try {
        final response = await _orderService.getOrders(
          page: 1,
          pageSize: 50,
          search: query,
          ordering: '-created_at',
        );

        _filteredItems = response['results'] as List<OrderModel>;
        setState(() => _isSearching = false);
        setStateOverlay(() => _isSearching = false);
      } catch (e) {
        print('Error searching orders: $e');
        setState(() => _isSearching = false);
        setStateOverlay(() => _isSearching = false);
      }
    });
  }

  void _openDropdown() {
    if (_isOpen) return;

    // Load initial data
    _searchOrders('', (fn) {});

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: 600,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 50),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search field
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              onChanged: (value) {
                                _searchOrders(value, setStateOverlay);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by order number or client...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                prefixIcon:
                                    _isSearching
                                        ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                        : const Icon(Icons.search, size: 16),
                                suffixIcon:
                                    _searchController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _searchOrders('', setStateOverlay);
                                          },
                                        )
                                        : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: AppColors.surfaceVariant,
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
                          // List of orders
                          Expanded(
                            child:
                                _isSearching
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : _filteredItems.isEmpty
                                    ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'No orders found',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      itemCount: _filteredItems.length,
                                      itemBuilder: (context, index) {
                                        final order = _filteredItems[index];
                                        final isSelected =
                                            widget.selectedOrder?.id ==
                                            order.id;

                                        return InkWell(
                                          onTap: () {
                                            widget.onChanged(order);
                                            _closeDropdown();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
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
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        order.orderNumber,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              isSelected
                                                                  ? FontWeight
                                                                      .w600
                                                                  : FontWeight
                                                                      .w500,
                                                          color:
                                                              isSelected
                                                                  ? AppColors
                                                                      .primary
                                                                  : AppColors
                                                                      .textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Client: ${order.clientName}',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          color:
                                                              AppColors
                                                                  .textSecondary,
                                                        ),
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
          ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
              ),
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
                      widget.selectedOrder != null
                          ? '${widget.selectedOrder!.orderNumber} - ${widget.selectedOrder!.clientName}'
                          : 'Select order',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color:
                            widget.selectedOrder != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isRequired && widget.selectedOrder == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Order is required',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// Searchable Supplier Dropdown Widget with Server-Side Search
class _SearchableSupplierDropdown extends StatefulWidget {
  final String labelText;
  final SupplierModel? selectedSupplier;
  final Function(SupplierModel?) onChanged;
  final bool isRequired;

  const _SearchableSupplierDropdown({
    required this.labelText,
    required this.selectedSupplier,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  State<_SearchableSupplierDropdown> createState() =>
      _SearchableSupplierDropdownState();
}

class _SearchableSupplierDropdownState
    extends State<_SearchableSupplierDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SupplierModel> _filteredItems = [];
  bool _isSearching = false;
  Timer? _debounce;
  final _supplierService = SupplierService();

  @override
  void dispose() {
    _overlayEntry?.remove();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
    _searchController.clear();
    _filteredItems = [];
    _debounce?.cancel();
  }

  Future<void> _searchSuppliers(
    String query,
    StateSetter setStateOverlay,
  ) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      setStateOverlay(() => _isSearching = true);

      try {
        final response = await _supplierService.getSuppliers(
          page: 1,
          pageSize: 50,
          search: query,
          ordering: 'name',
        );

        _filteredItems = response['results'] as List<SupplierModel>;
        setState(() => _isSearching = false);
        setStateOverlay(() => _isSearching = false);
      } catch (e) {
        print('Error searching suppliers: $e');
        setState(() => _isSearching = false);
        setStateOverlay(() => _isSearching = false);
      }
    });
  }

  void _openDropdown() {
    if (_isOpen) return;

    // Load initial data
    _searchSuppliers('', (fn) {});

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: 600,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 50),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search field
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              onChanged: (value) {
                                _searchSuppliers(value, setStateOverlay);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by name or phone...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                prefixIcon:
                                    _isSearching
                                        ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                        : const Icon(Icons.search, size: 16),
                                suffixIcon:
                                    _searchController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _searchSuppliers(
                                              '',
                                              setStateOverlay,
                                            );
                                          },
                                        )
                                        : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: AppColors.surfaceVariant,
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
                          // List of suppliers
                          Expanded(
                            child:
                                _isSearching
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : _filteredItems.isEmpty
                                    ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'No suppliers found',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      itemCount: _filteredItems.length,
                                      itemBuilder: (context, index) {
                                        final supplier = _filteredItems[index];
                                        final isSelected =
                                            widget.selectedSupplier?.id ==
                                            supplier.id;

                                        return InkWell(
                                          onTap: () {
                                            widget.onChanged(supplier);
                                            _closeDropdown();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
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
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        supplier.name,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              isSelected
                                                                  ? FontWeight
                                                                      .w600
                                                                  : FontWeight
                                                                      .w500,
                                                          color:
                                                              isSelected
                                                                  ? AppColors
                                                                      .primary
                                                                  : AppColors
                                                                      .textPrimary,
                                                        ),
                                                      ),
                                                      if (supplier.phone !=
                                                          null) ...[
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          supplier.phone!,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 10,
                                                            color:
                                                                AppColors
                                                                    .textSecondary,
                                                          ),
                                                        ),
                                                      ],
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
          ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.selectedSupplier != null
                          ? widget.selectedSupplier!.name
                          : 'Select supplier',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color:
                            widget.selectedSupplier != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isRequired && widget.selectedSupplier == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Supplier is required',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// Searchable Product Dropdown Widget with Server-Side Search
class _SearchableProductDropdown extends StatefulWidget {
  final String labelText;
  final ProductModel? selectedProduct;
  final Function(ProductModel?) onChanged;
  final bool isRequired;

  const _SearchableProductDropdown({
    required this.labelText,
    required this.selectedProduct,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  State<_SearchableProductDropdown> createState() =>
      _SearchableProductDropdownState();
}

class _SearchableProductDropdownState
    extends State<_SearchableProductDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ProductModel> _filteredItems = [];
  bool _isSearching = false;
  Timer? _debounce;
  final _productService = ProductService();

  @override
  void dispose() {
    _overlayEntry?.remove();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
    _searchController.clear();
    _filteredItems = [];
    _debounce?.cancel();
  }

  Future<void> _searchProducts(
    String query,
    StateSetter setStateOverlay,
  ) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      setStateOverlay(() => _isSearching = true);

      try {
        final response = await _productService.getProducts(
          page: 1,
          pageSize: 50,
          search: query.isEmpty ? null : query,
          isActive: true,
          ordering: 'name',
        );

        _filteredItems = response['results'] as List<ProductModel>;
        setState(() => _isSearching = false);
        setStateOverlay(() => _isSearching = false);
      } catch (e) {
        print('Error searching products: $e');
        setState(() => _isSearching = false);
        setStateOverlay(() => _isSearching = false);
      }
    });
  }

  void _openDropdown() {
    if (_isOpen) return;

    // Load initial data
    _searchProducts('', (fn) {});

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: 600,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 50),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search field
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              onChanged: (value) {
                                _searchProducts(value, setStateOverlay);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by name or reference...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                prefixIcon:
                                    _isSearching
                                        ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                        : const Icon(Icons.search, size: 16),
                                suffixIcon:
                                    _searchController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 16,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _searchProducts(
                                              '',
                                              setStateOverlay,
                                            );
                                          },
                                        )
                                        : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: AppColors.surfaceVariant,
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
                          // List of products
                          Expanded(
                            child:
                                _isSearching
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : _filteredItems.isEmpty
                                    ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'No products found',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      itemCount: _filteredItems.length,
                                      itemBuilder: (context, index) {
                                        final product = _filteredItems[index];
                                        final isSelected =
                                            widget.selectedProduct?.id ==
                                            product.id;

                                        return InkWell(
                                          onTap: () {
                                            widget.onChanged(product);
                                            _closeDropdown();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
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
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        product.name,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              isSelected
                                                                  ? FontWeight
                                                                      .w600
                                                                  : FontWeight
                                                                      .w500,
                                                          color:
                                                              isSelected
                                                                  ? AppColors
                                                                      .primary
                                                                  : AppColors
                                                                      .textPrimary,
                                                        ),
                                                      ),
                                                      if (product.reference !=
                                                          null) ...[
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'Ref: ${product.reference}',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 10,
                                                            color:
                                                                AppColors
                                                                    .textSecondary,
                                                          ),
                                                        ),
                                                      ],
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
          ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surface,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.selectedProduct != null
                          ? widget.selectedProduct!.name
                          : 'Select product',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color:
                            widget.selectedProduct != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isRequired && widget.selectedProduct == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Product is required',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// Edit Output Dialog (simplified version)
class EditOutputDialog extends StatefulWidget {
  final OutputModel output;

  const EditOutputDialog({super.key, required this.output});

  @override
  State<EditOutputDialog> createState() => _EditOutputDialogState();
}

class _EditOutputDialogState extends State<EditOutputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.output.amount);
    _descriptionController = TextEditingController(
      text: widget.output.description,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialogWidget(
      title: 'Edit Output',
      isScrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 20, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can only edit amount and description for existing outputs',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Read-only fields
            _buildReadOnlyField('Reference', widget.output.reference),
            _buildReadOnlyField('Type', widget.output.typeDisplay),

            const SizedBox(height: 24),

            // Editable fields
            CustomInputWidget(
              controller: _amountController,
              labelText: 'Amount (DA) *',
              hintText: 'Enter amount',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Amount is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomInputWidget(
              controller: _descriptionController,
              labelText: 'Description',
              hintText: 'Enter description',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedCustomButton(
          text: 'Cancel',
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        PrimaryButton(
          text: _isSubmitting ? 'Updating...' : 'Update Output',
          onPressed: _isSubmitting ? null : _handleSubmit,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'amount': _amountController.text,
      'description': _descriptionController.text,
    };

    final provider = Provider.of<OutputProvider>(context, listen: false);
    final success = await provider.partialUpdateOutput(widget.output.id, data);

    setState(() => _isSubmitting = false);

    if (context.mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Output updated successfully',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Failed to update output',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
