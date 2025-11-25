import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/client_model.dart';
import '../../providers/client_provider.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dropdown_widget.dart';
import '../widgets/custom_dialog_widget.dart';
import '../widgets/responsive_table_widget.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final clientProvider = Provider.of<ClientProvider>(
        context,
        listen: false,
      );
      clientProvider.fetchClients();
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
      height: screenHeight * 1.2,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error State - Display at TOP
              Consumer<ClientProvider>(
                builder: (context, clientProvider, _) {
                  if (clientProvider.error != null) {
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
                            'Error: ${clientProvider.error}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedCustomButton(
                            text: 'Retry',
                            onPressed: () => clientProvider.fetchClients(),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Page Header with New Client Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clients Management',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your clients and track their credit balance',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  PrimaryButton(
                    size: ButtonSize.medium,
                    text: 'New Client',
                    onPressed: () {
                      _showCreateClientDialog(context);
                    },
                    icon: const Icon(
                      Icons.person_add,
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
                      context.read<ClientProvider>().searchClients(value);
                    }
                  });
                },
              ),

              const SizedBox(height: 32),

              // Clients Table with Pagination
              Consumer<ClientProvider>(
                builder: (context, clientProvider, _) {
                  if (clientProvider.isLoading) {
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

                  if (clientProvider.clients.isEmpty) {
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
                            Icons.people_outline,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Clients Found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            clientProvider.searchQuery.isNotEmpty
                                ? 'No clients match your search criteria'
                                : 'Create your first client to get started',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Separate active and inactive clients
                  final activeClients =
                      clientProvider.clients.where((c) => c.isActive).toList();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Clients Section
                      if (activeClients.isNotEmpty) ...[
                        Text(
                          'Active Clients (${activeClients.length})',
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
                            'Type',
                            'Initial Balance',
                            'Created',
                            'Actions',
                          ],
                          minColumnWidth: 100,
                          rows:
                              activeClients
                                  .map(
                                    (client) => _buildClientRow(
                                      context,
                                      client,
                                      clientProvider,
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Pagination Controls
                      _PaginationControls(clientProvider: clientProvider),
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

  List<Widget> _buildClientRow(
    BuildContext context,
    ClientModel client,
    ClientProvider clientProvider,
  ) {
    return [
      // Name
      Text(
        client.name,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Phone
      Text(
        client.phone.isEmpty ? '-' : client.phone,
        style: GoogleFonts.inter(fontSize: 12),
      ),
      // Address
      Text(
        client.address.isEmpty ? '-' : client.address,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Type Badge
      _ClientTypeBadge(type: client.clientType),

      // Credit Balance
      Text(
        client.formattedCreditBalance,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color:
              double.tryParse(client.creditBalance) != null &&
                      double.parse(client.creditBalance) < 0
                  ? AppColors.primary
                  : AppColors.success,
        ),
      ),
      // Created Date
      Text(client.formattedCreatedAt, style: GoogleFonts.inter(fontSize: 12)),
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
              _showClientDetailDialog(context, client);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: AppColors.info,
            tooltip: 'Edit',
            onPressed: () {
              _showEditClientDialog(context, client, clientProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.block, size: 16),
            color: AppColors.warning,
            tooltip: 'Deactivate',
            onPressed: () {
              _showDeactivateConfirm(context, client, clientProvider);
            },
          ),
        ],
      ),
    ];
  }

  void _showCreateClientDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final creditBalanceController = TextEditingController(text: '0.00');
    final notesController = TextEditingController();
    String selectedType = 'new';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'New Client',
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomInputWidget(
                        controller: nameController,
                        labelText: 'Client Name',
                        hintText: 'Enter client name',
                        prefixIcon: const Icon(Icons.person),
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
                        hintText: 'Enter address',
                        prefixIcon: const Icon(Icons.location_on),
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdownWidget<String>(
                        labelText: 'Client Type',
                        value: selectedType,
                        required: true,
                        hintText: 'Select client type',
                        prefixIcon: Icons.category,
                        items: [
                          const DropdownMenuItem(
                            value: 'new',
                            child: Text('New'),
                          ),
                          const DropdownMenuItem(
                            value: 'old',
                            child: Text('Old'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AmountInputWidget(
                        controller: creditBalanceController,
                        labelText: 'Initial Credit Balance',
                        hintText: '0.00',
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
                          final clientProvider = Provider.of<ClientProvider>(
                            context,
                            listen: false,
                          );
                          await clientProvider.createClient(
                            name: nameController.text,
                            phone: phoneController.text,
                            address: addressController.text,
                            creditBalance: creditBalanceController.text,
                            clientType: selectedType,
                            notes: notesController.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Client created successfully',
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
          ),
    );
  }

  void _showEditClientDialog(
    BuildContext context,
    ClientModel client,
    ClientProvider clientProvider,
  ) {
    final nameController = TextEditingController(text: client.name);
    final phoneController = TextEditingController(text: client.phone);
    final addressController = TextEditingController(text: client.address);
    final creditBalanceController = TextEditingController(
      text: client.creditBalance,
    );
    final notesController = TextEditingController(text: client.notes);
    String selectedType = client.clientType;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'Edit Client',
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomInputWidget(
                        controller: nameController,
                        labelText: 'Client Name',
                        hintText: 'Enter client name',
                        prefixIcon: const Icon(Icons.person),
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
                        hintText: 'Enter address',
                        prefixIcon: const Icon(Icons.location_on),
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdownWidget<String>(
                        labelText: 'Client Type',
                        value: selectedType,
                        required: true,
                        hintText: 'Select client type',
                        prefixIcon: Icons.category,
                        items: [
                          const DropdownMenuItem(
                            value: 'new',
                            child: Text('New'),
                          ),
                          const DropdownMenuItem(
                            value: 'old',
                            child: Text('Old'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AmountInputWidget(
                        controller: creditBalanceController,
                        labelText: 'Credit Balance',
                        hintText: '0.00',
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
                          await clientProvider.updateClient(
                            client.id,
                            name: nameController.text,
                            phone: phoneController.text,
                            address: addressController.text,
                            creditBalance: creditBalanceController.text,
                            clientType: selectedType,
                            notes: notesController.text,
                            isActive: client.isActive,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Client updated successfully',
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
          ),
    );
  }

  void _showDeactivateConfirm(
    BuildContext context,
    ClientModel client,
    ClientProvider clientProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Deactivate Client',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to deactivate ${client.name}?',
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
                    await clientProvider.deactivateClient(client.id);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Client deactivated successfully',
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

// Client Type Badge Widget
class _ClientTypeBadge extends StatelessWidget {
  final String type;

  const _ClientTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String displayText;

    switch (type.toLowerCase()) {
      case 'old':
        backgroundColor = AppColors.info.withOpacity(0.1);
        borderColor = AppColors.info.withOpacity(0.3);
        textColor = AppColors.info;
        displayText = 'Old';
        break;
      case 'new':
        backgroundColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success.withOpacity(0.3);
        textColor = AppColors.success;
        displayText = 'New';
        break;
      default:
        backgroundColor = AppColors.info.withOpacity(0.1);
        borderColor = AppColors.info.withOpacity(0.3);
        textColor = AppColors.info;
        displayText = type;
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

// Pagination Controls Widget
class _PaginationControls extends StatelessWidget {
  final ClientProvider clientProvider;

  const _PaginationControls({required this.clientProvider});

  @override
  Widget build(BuildContext context) {
    if (clientProvider.totalPages <= 1) return Container();

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
            'Page ${clientProvider.currentPage} of ${clientProvider.totalPages} '
            '(${clientProvider.totalCount} total clients)',
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
                    clientProvider.currentPage > 1
                        ? () => clientProvider.goToPage(1)
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    clientProvider.hasPreviousPage
                        ? () => clientProvider.previousPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              const SizedBox(width: 8),
              ...List.generate(
                clientProvider.totalPages > 5 ? 5 : clientProvider.totalPages,
                (index) {
                  int pageNum;
                  if (clientProvider.totalPages <= 5) {
                    pageNum = index + 1;
                  } else {
                    if (clientProvider.currentPage <= 3) {
                      pageNum = index + 1;
                    } else if (clientProvider.currentPage >=
                        clientProvider.totalPages - 2) {
                      pageNum = clientProvider.totalPages - 4 + index;
                    } else {
                      pageNum = clientProvider.currentPage - 2 + index;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: () => clientProvider.goToPage(pageNum),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            pageNum == clientProvider.currentPage
                                ? AppColors.primary
                                : Colors.transparent,
                        foregroundColor:
                            pageNum == clientProvider.currentPage
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
                    clientProvider.hasNextPage
                        ? () => clientProvider.nextPage()
                        : null,
                color: AppColors.primary,
                iconSize: 18,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed:
                    clientProvider.currentPage < clientProvider.totalPages
                        ? () =>
                            clientProvider.goToPage(clientProvider.totalPages)
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

void _showClientDetailDialog(
  BuildContext context,
  ClientModel client, {
  bool isOwnerView = false,
}) async {
  final clientProvider = context.read<ClientProvider>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final completeData = await clientProvider.getClientComplete(client.id);
    Navigator.pop(context);

    final clientData = completeData['client'];
    final financial = completeData['financial_summary'];
    final orders = completeData['orders'] as List<dynamic>;

    showDialog(
      context: context,
      builder:
          (context) => ClientDetailsDialog(
            clientData: clientData,
            financial: financial,
            orders: orders,
            initialOwnerView: isOwnerView,
          ),
    );
  } catch (e) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fetch client details:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

class ClientDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> clientData;
  final Map<String, dynamic> financial;
  final List<dynamic> orders;
  final bool initialOwnerView;

  const ClientDetailsDialog({
    Key? key,
    required this.clientData,
    required this.financial,
    required this.orders,
    this.initialOwnerView = false,
  }) : super(key: key);

  @override
  State<ClientDetailsDialog> createState() => _ClientDetailsDialogState();
}

class _ClientDetailsDialogState extends State<ClientDetailsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool isOwnerView;
  Set<int> expandedOrders = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    isOwnerView = widget.initialOwnerView;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildTimeline() {
    List<Map<String, dynamic>> timeline = [];
    double initialBalance = widget.financial['initial_credit_balance'] ?? 0.0;
    double runningBalance = initialBalance;

    if (initialBalance != 0) {
      timeline.add({
        'date': widget.clientData['created_at'],
        'type': 'initial',
        'description': 'Opening Balance',
        'amount': initialBalance,
        'balance': initialBalance,
      });
    }

    for (var order in widget.orders) {
      timeline.add({
        'date': order['order_date'],
        'type': 'order',
        'description': 'Order ${order['order_number']}',
        'order_details': order['description'],
        'status': order['status'],
        'amount': order['total_amount'],
        'balance': runningBalance - order['total_amount'],
        'order_id': order['id'],
        'order_benefit': order['benefit'],
        'order_expenses': order['total_expenses'],
        'outputs': order['outputs'],
      });
      runningBalance -= order['total_amount'];

      final inputs = order['inputs'] as List<dynamic>? ?? [];
      for (var payment in inputs) {
        timeline.add({
          'date': payment['date'],
          'type': 'payment',
          'description': 'Payment ${payment['reference']}',
          'order_details': payment['description'],
          'amount': payment['amount'],
          'balance': runningBalance + payment['amount'],
          'order_id': order['id'],
        });
        runningBalance += payment['amount'];
      }
    }

    timeline.sort((a, b) => a['date'].compareTo(b['date']));

    runningBalance = initialBalance;
    for (var item in timeline) {
      if (item['type'] == 'initial') {
        item['balance'] = runningBalance;
      } else if (item['type'] == 'order') {
        runningBalance -= item['amount'];
        item['balance'] = runningBalance;
      } else if (item['type'] == 'payment') {
        runningBalance += item['amount'];
        item['balance'] = runningBalance;
      }
    }

    return timeline;
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _buildTimeline();

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
            _buildInfoCards(),
            const SizedBox(height: 16),
            _buildClientInfoSection(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildTransactionsTab(timeline), _buildOrdersTab()],
              ),
            ),
            const SizedBox(height: 12),
            _buildFooter(),
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
                widget.clientData['name'],
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'ID: ${widget.clientData['id']} • ${widget.clientData['client_type'].toString().toUpperCase()}',
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
        _buildViewToggle(),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:
                widget.clientData['is_active']
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  widget.clientData['is_active']
                      ? AppColors.success
                      : AppColors.textSecondary,
            ),
          ),
          child: Text(
            widget.clientData['is_active'] ? 'ACTIVE' : 'INACTIVE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color:
                  widget.clientData['is_active']
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

  Widget _buildViewToggle() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            icon: Icons.visibility,
            label: 'Client View',
            value: false,
          ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.surfaceVariant.withOpacity(0.5),
          ),
          _buildToggleOption(
            icon: Icons.admin_panel_settings,
            label: 'Owner View',
            value: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool value,
  }) {
    final isSelected = isOwnerView == value;
    return InkWell(
      onTap: () => setState(() => isOwnerView = value),
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.surface : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.surface : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total ${isOwnerView ? "Revenue" : "Charges"}',
            '${widget.financial['total_orders_amount']} DA',
            AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            '${isOwnerView ? "Collected" : "Paid"}',
            '${widget.financial['total_paid']} DA',
            AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Outstanding',
            '${widget.financial['total_unpaid']} DA',
            AppColors.warning,
          ),
        ),
        if (isOwnerView) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              'Expenses',
              '${widget.financial['total_expenses'] ?? 0} DA',
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              'Net Profit',
              '${widget.financial['total_benefit']} DA',
              AppColors.success,
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Balance',
            '${widget.financial['final_balance']} DA',
            AppColors.secondary,
          ),
        ),
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

  Widget _buildClientInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          if (isOwnerView && widget.clientData['phone'] != null) ...[
            _buildInfoItem(Icons.phone, 'Phone', widget.clientData['phone']),
            const SizedBox(width: 20),
          ],
          if (isOwnerView && widget.clientData['address'] != null) ...[
            Expanded(
              child: _buildInfoItem(
                Icons.location_on,
                'Address',
                widget.clientData['address'],
              ),
            ),
            const SizedBox(width: 20),
          ],
          _buildInfoItem(
            Icons.shopping_bag,
            'Orders',
            widget.orders.length.toString(),
          ),
          if (isOwnerView &&
              widget.clientData['notes'] != null &&
              widget.clientData['notes'].toString().isNotEmpty) ...[
            const SizedBox(width: 20),
            Expanded(
              child: _buildInfoItem(
                Icons.notes,
                'Notes',
                widget.clientData['notes'],
              ),
            ),
          ],
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
        tabs: const [Tab(text: 'Transactions'), Tab(text: 'Orders')],
      ),
    );
  }

  Widget _buildTransactionsTab(List<Map<String, dynamic>> timeline) {
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
                _buildTableHeader('Date', flex: 2),
                _buildTableHeader('Type', flex: 1),
                _buildTableHeader('Description', flex: 3),
                if (isOwnerView) _buildTableHeader('Status', flex: 1),
                _buildTableHeader('Amount', flex: 2),
                _buildTableHeader('Balance', flex: 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: timeline.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: AppColors.surfaceVariant),
              itemBuilder: (context, index) {
                final item = timeline[index];
                return _buildTransactionRow(item);
              },
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

  Widget _buildTransactionRow(Map<String, dynamic> item) {
    Color typeColor;
    String typeText;
    String amountText;

    switch (item['type']) {
      case 'initial':
        typeColor = AppColors.secondary;
        typeText = 'Opening';
        amountText = '${item['amount']}';
        break;
      case 'order':
        typeColor = AppColors.info;
        typeText = 'Order';
        amountText = '-${item['amount']}';
        break;
      case 'payment':
        typeColor = AppColors.success;
        typeText = 'Payment';
        amountText = '+${item['amount']}';
        break;
      default:
        typeColor = AppColors.textSecondary;
        typeText = item['type'];
        amountText = '${item['amount']}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                _formatDateTime(item['date']),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: typeColor.withOpacity(0.3)),
                ),
                child: Text(
                  typeText,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item['description'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (item['order_details'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item['order_details'],
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isOwnerView)
            Expanded(
              flex: 1,
              child: Center(
                child:
                    item['status'] != null
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              item['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            item['status'].toString().toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(item['status']),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                        : const SizedBox(),
              ),
            ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '$amountText DA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      item['type'] == 'order'
                          ? AppColors.primary
                          : item['type'] == 'payment'
                          ? AppColors.success
                          : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '${item['balance']} DA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
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
                _buildTableHeader('Order #', flex: 2),
                const SizedBox(width: 16),
                _buildTableHeader('Description', flex: 4),
                _buildTableHeader('Status', flex: 1),
                _buildTableHeader('Amount', flex: 2),
                if (isOwnerView) ...[
                  _buildTableHeader('Expenses', flex: 2),
                  _buildTableHeader('Profit', flex: 2),
                ],
                _buildTableHeader('Paid', flex: 2),
                _buildTableHeader('Balance', flex: 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.orders.length,
              itemBuilder: (context, index) {
                final order = widget.orders[index];
                final isExpanded = expandedOrders.contains(index);
                return Column(
                  children: [
                    if (index > 0)
                      Divider(height: 1, color: AppColors.surfaceVariant),
                    _buildOrderRow(order, index, isExpanded),
                    if (isExpanded && isOwnerView) _buildExpenseDetails(order),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(
    Map<String, dynamic> order,
    int index,
    bool isExpanded,
  ) {
    final inputs = order['inputs'] as List<dynamic>? ?? [];
    final totalPaid = inputs.fold<double>(
      0,
      (sum, payment) => sum + (payment['amount'] ?? 0),
    );
    final balance = (order['total_amount'] ?? 0) - totalPaid;
    final outputs = order['outputs'] as List<dynamic>? ?? [];
    final hasExpenses = outputs.isNotEmpty && isOwnerView;

    return InkWell(
      onTap:
          hasExpenses
              ? () {
                setState(() {
                  if (isExpanded) {
                    expandedOrders.remove(index);
                  } else {
                    expandedOrders.add(index);
                  }
                });
              }
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: isExpanded ? AppColors.primary.withOpacity(0.02) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasExpenses)
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    if (hasExpenses) const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        order['order_number'].toString(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Center(
                child: Text(
                  order['description'] ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order['status'].toString().toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(order['status']),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '${order['total_amount']} DA',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isOwnerView) ...[
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '${order['total_expenses'] ?? 0} DA',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '${order['benefit'] ?? 0} DA',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '$totalPaid DA',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '$balance DA',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: balance > 0 ? AppColors.warning : AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseDetails(Map<String, dynamic> order) {
    final outputs = order['outputs'] as List<dynamic>? ?? [];

    if (outputs.isEmpty) return const SizedBox();

    // Calculate total expenses
    double totalExpenses = 0;
    for (var output in outputs) {
      totalExpenses += (output['amount'] ?? 0);
    }

    return Container(
      margin: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          // Header Row
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
                Expanded(
                  flex: 3,
                  child: Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Amount',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Expense Rows
          ...outputs.asMap().entries.map((entry) {
            int idx = entry.key;
            var output = entry.value;
            return Column(
              children: [
                if (idx > 0)
                  Divider(height: 1, color: AppColors.surfaceVariant),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          output['description'] ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${output['amount']} DA',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
          // Total Row
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.surfaceVariant, width: 2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total Expenses',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '$totalExpenses DA',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return AppColors.success;
      case 'pending':
      case 'processing':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }
}
