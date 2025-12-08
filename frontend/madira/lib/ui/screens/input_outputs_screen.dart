//  Input Outputs Screen - View outputs for a specific input with complete details
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/input_model.dart';
import '../../models/output_model.dart';
import '../../providers/output_proviider.dart';
import '../widgets/custom_button_widget.dart';

class InputOutputsScreen extends StatefulWidget {
  final InputModel input;

  const InputOutputsScreen({super.key, required this.input});

  @override
  State<InputOutputsScreen> createState() => _InputOutputsScreenState();
}

class _InputOutputsScreenState extends State<InputOutputsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final outputProvider = Provider.of<OutputProvider>(
        context,
        listen: false,
      );
      // Fetch ALL outputs without pagination
      outputProvider.fetchOutputsByInput(widget.input.id, pageSize: 10000000);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction History',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.input.reference,
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
          ],
        ),
        actions: [
          Consumer<OutputProvider>(
            builder: (context, provider, _) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.info),
                ),
                child: Text(
                  '${provider.inputOutputs.length} Transactions',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Input Complete Details Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceVariant),
              ),
            ),
            child: _buildInputDetailsSection(),
          ),

          // Financial Summary Cards
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceVariant),
              ),
            ),
            child: _buildFinancialSummaryCards(),
          ),

          // Scrollable Transactions Table
          Expanded(
            child: Consumer<OutputProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  );
                }

                if (provider.errorMessage != null) {
                  return Center(
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
                          provider.errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'Retry',
                          onPressed:
                              () =>
                                  provider.fetchOutputsByInput(widget.input.id),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.inputOutputs.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildTransactionsTable(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Input Information',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Details Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildInfoItem(Icons.tag, 'Reference', widget.input.reference),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.category,
                  'Type',
                  _getTypeDisplay(widget.input.type),
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.account_balance_wallet,
                  'Amount',
                  '${widget.input.formattedAmount} DA',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.savings,
                  'Remaining',
                  '${widget.input.formattedRemainingAmount} DA',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.person_outline,
                  'Client',
                  widget.input.clientName ?? 'N/A',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.shopping_cart_outlined,
                  'Order',
                  widget.input.orderNumber ?? 'N/A',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.calendar_today,
                  'Date',
                  widget.input.formattedDate,
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  Icons.person,
                  'Created By',
                  widget.input.createdByName,
                ),
              ],
            ),
          ),
          if (widget.input.description.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, size: 14, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.input.description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
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

  Widget _buildFinancialSummaryCards() {
    return Consumer<OutputProvider>(
      builder: (context, provider, _) {
        double totalSpent = 0;
        for (var output in provider.inputOutputs) {
          totalSpent += double.tryParse(output.amount) ?? 0;
        }

        final inputAmount = double.tryParse(widget.input.amount) ?? 0;
        final remainingAmount = inputAmount - totalSpent;
        final usagePercentage =
            inputAmount > 0 ? (totalSpent / inputAmount) * 100 : 0;

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Initial Amount',
                '${inputAmount.toStringAsFixed(2)} DA',
                AppColors.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Total Spent',
                '${totalSpent.toStringAsFixed(2)} DA',
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Remaining',
                '${remainingAmount.toStringAsFixed(2)} DA',
                remainingAmount >= 0 ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Usage %',
                '${usagePercentage.toStringAsFixed(1)}%',
                usagePercentage > 90 ? AppColors.primary : AppColors.secondary,
              ),
            ),
          ],
        );
      },
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

  Widget _buildTransactionsTable(OutputProvider provider) {
    double totalSpent = 0;
    for (var output in provider.inputOutputs) {
      totalSpent += double.tryParse(output.amount) ?? 0;
    }

    final inputAmount = double.tryParse(widget.input.amount) ?? 0;
    final remainingAmount = inputAmount - totalSpent;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surfaceVariant),
            child: Row(
              children: [
                _buildTableHeader('Date', flex: 2),
                _buildTableHeader('Reference', flex: 2),
                _buildTableHeader('Type', flex: 2),
                _buildTableHeader('Product', flex: 2),
                _buildTableHeader('Order', flex: 2),
                _buildTableHeader('Supplier', flex: 2),
                _buildTableHeader('Client', flex: 2),
                _buildTableHeader('Description', flex: 5),
                _buildTableHeader('Created By', flex: 2),
                _buildTableHeader('Amount', flex: 2),
              ],
            ),
          ),

          // Transactions List
          ...provider.inputOutputs.map((output) {
            return Column(
              children: [
                _buildTransactionRow(output),
                Divider(height: 1, color: AppColors.surfaceVariant),
              ],
            );
          }),

          // Total Row - Right after the last transaction with no space
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border(
                top: BorderSide(color: AppColors.primary, width: 2),
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
                    'Initial: ${inputAmount.toStringAsFixed(2)} DA',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Text(
                    '${provider.inputOutputs.length} transaction(s)',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Remaining: ${remainingAmount.toStringAsFixed(2)} DA',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          remainingAmount >= 0
                              ? AppColors.success
                              : AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${totalSpent.toStringAsFixed(2)} DA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTransactionRow(OutputModel output) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Text(
              output.formattedDate,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Reference
          Expanded(
            flex: 2,
            child: Text(
              output.reference,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Type Badge
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(output.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getTypeColor(output.type)),
                ),
                child: Text(
                  _getTypeShort(output.type),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _getTypeColor(output.type),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // Product
          Expanded(
            flex: 2,
            child: Text(
              output.productName ?? '-',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Order
          Expanded(
            flex: 2,
            child: Text(
              output.orderNumber ?? '-',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Supplier
          Expanded(
            flex: 2,
            child: Text(
              output.supplierName ?? '-',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Client
          Expanded(
            flex: 2,
            child: Text(
              output.clientName ?? '-',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Description
          Expanded(
            flex: 5,
            child: Text(
              output.description.isEmpty ? '-' : output.description,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Created By
          Expanded(
            flex: 2,
            child: Text(
              output.createdByUsername ?? '-',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              '${output.formattedAmount} DA',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'withdrawal':
        return AppColors.primary;
      case 'supplier_payment':
        return AppColors.warning;
      case 'consumable':
        return AppColors.info;
      case 'global_stock_purchase':
        return AppColors.success;
      case 'client_stock_usage':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.textSecondary;
    }
  }

  String _getTypeShort(String type) {
    switch (type) {
      case 'withdrawal':
        return 'WITHDRAWAL';
      case 'supplier_payment':
        return 'PAYMENT';
      case 'consumable':
        return 'CONSUMABLE';
      case 'global_stock_purchase':
        return 'STOCK';
      case 'client_stock_usage':
        return 'CLIENT';
      case 'other_expense':
        return 'EXPENSE';
      default:
        return type.toUpperCase();
    }
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
            'This input has no associated outputs yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
