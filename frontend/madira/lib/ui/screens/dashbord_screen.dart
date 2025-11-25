import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );
      dashboardProvider.fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<DashboardProvider>(
            builder: (context, dashboardProvider, _) {
              if (dashboardProvider.error != null) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dashboardProvider.error!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => dashboardProvider.fetchDashboardData(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(
                          'Retry',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
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
            children: [
              Consumer<DashboardProvider>(
                builder: (context, dashboardProvider, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Overview',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dashboardProvider.periodLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Real-time business analytics',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              _buildPeriodSelector(),
            ],
          ),

          const SizedBox(height: 24),

          Consumer<DashboardProvider>(
            builder: (context, dashboardProvider, _) {
              if (dashboardProvider.isLoading) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(80),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading dashboard data...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (dashboardProvider.dashboardData == null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.dashboard_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Dashboard Data',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to load dashboard analytics',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dashboardProvider.alerts.isNotEmpty) ...[
                    _buildAlertsSection(dashboardProvider),
                    const SizedBox(height: 24),
                  ],
                  _buildFinancialOverview(dashboardProvider),
                  const SizedBox(height: 24),
                  _buildTrendsSection(dashboardProvider),
                  const SizedBox(height: 24),
                  _buildExpenseBreakdown(dashboardProvider),
                  const SizedBox(height: 24),
                  _buildBottomStats(dashboardProvider),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodOption(
                dashboardProvider,
                'Today',
                'today',
                Icons.today,
              ),
              const SizedBox(width: 4),
              _buildPeriodOption(
                dashboardProvider,
                'Month',
                'month',
                Icons.calendar_month,
              ),
              const SizedBox(width: 4),
              _buildPeriodOption(
                dashboardProvider,
                'Year',
                'year',
                Icons.calendar_view_month,
              ),
              const SizedBox(width: 4),
              _buildPeriodOption(
                dashboardProvider,
                'All Time',
                'all_time',
                Icons.all_inclusive,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(
    DashboardProvider provider,
    String label,
    String period,
    IconData icon,
  ) {
    final isSelected = provider.selectedPeriod == period;
    return InkWell(
      onTap: () => provider.changePeriod(period),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(DashboardProvider provider) {
    final alerts = provider.alerts;
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_active,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Alerts & Notifications',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${alerts.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: alerts.length > 5 ? 200 : double.infinity,
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    alerts.map((alert) {
                      final isCritical = alert['type'] == 'critical';
                      final color =
                          isCritical ? AppColors.primary : AppColors.warning;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCritical ? Icons.error : Icons.warning_amber,
                              color: color,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                alert['message']?.toString() ?? 'No message',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, size: 18, color: AppColors.success),
              const SizedBox(width: 10),
              Text(
                'Financial Performance',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Total Revenue',
                  provider.totalRevenue,
                  Icons.attach_money,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetric(
                  'Cash Collected',
                  provider.totalCollected,
                  Icons.account_balance_wallet,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetric(
                  'Outstanding',
                  provider.totalOutstanding,
                  Icons.pending_actions,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetric(
                  'Cash in Hand',
                  provider.cashInHand,
                  Icons.account_balance,
                  AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Actual Profit',
                  provider.actualProfit,
                  Icons.trending_up,
                  AppColors.success,
                  subtitle:
                      '${(provider.actualProfitMargin).toStringAsFixed(1)}% margin',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetric(
                  'Expected Profit',
                  provider.expectedProfit,
                  Icons.insights,
                  AppColors.secondary,
                  subtitle:
                      '${(provider.expectedProfitMargin).toStringAsFixed(1)}% margin',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetric(
                  'Total Expenses',
                  provider.totalExpenses,
                  Icons.receipt_long,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetric(
                  'Collection Rate',
                  provider.collectionRate,
                  Icons.percent,
                  AppColors.success,
                  isPercentage: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    String title,
    double value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool isPercentage = false,
  }) {
    final safeValue = value;
    String formattedValue =
        isPercentage
            ? '${safeValue.toStringAsFixed(1)}%'
            : '${NumberFormat('#,##0', 'en_US').format(safeValue)} DA';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedValue,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendsSection(DashboardProvider provider) {
    final trends = provider.trends;

    if (trends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant, width: 1),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No Trend Data Available',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (trends.length == 1) return _buildSingleTrendCard(trends[0]);
    return _buildTrendsChart(trends);
  }

  Widget _buildSingleTrendCard(Map trend) {
    final period = trend['period']?.toString() ?? 'N/A';
    final revenue = (trend['revenue'] ?? 0.0).toDouble();
    final collected = (trend['collected'] ?? 0.0).toDouble();
    final expenses = (trend['expenses'] ?? 0.0).toDouble();
    final profit = (trend['profit'] ?? 0.0).toDouble();
    final orders = trend['orders'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.info),
              const SizedBox(width: 10),
              Text(
                'Financial Snapshot',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  period,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildTrendStatCard(
                  'Revenue',
                  revenue,
                  AppColors.info,
                  Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendStatCard(
                  'Collected',
                  collected,
                  AppColors.success,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendStatCard(
                  'Expenses',
                  expenses,
                  AppColors.warning,
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendStatCard(
                  'Profit',
                  profit,
                  profit >= 0 ? AppColors.success : AppColors.primary,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendStatCard(
                  'Orders',
                  orders.toDouble(),
                  AppColors.info,
                  Icons.shopping_cart,
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStatCard(
    String label,
    double value,
    Color color,
    IconData icon, {
    bool isCount = false,
  }) {
    final safeValue = value;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            isCount
                ? safeValue.toInt().toString()
                : NumberFormat('#,##0', 'en_US').format(safeValue),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart(List trends) {
    double maxValue = 100;
    double minValue = 0;

    for (var trend in trends) {
      final revenue = (trend['revenue'] ?? 0.0).toDouble();
      final collected = (trend['collected'] ?? 0.0).toDouble();
      final expenses = (trend['expenses'] ?? 0.0).toDouble();
      final profit = (trend['profit'] ?? 0.0).toDouble();
      if (revenue > maxValue) maxValue = revenue;
      if (collected > maxValue) maxValue = collected;
      if (expenses > maxValue) maxValue = expenses;
      if (profit > maxValue) maxValue = profit;
      if (profit < minValue) minValue = profit;
    }

    maxValue = maxValue * 1.1;
    minValue = minValue * 1.1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, size: 18, color: AppColors.info),
                  const SizedBox(width: 10),
                  Text(
                    'Financial Trends',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${trends.length} periods)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                children: [
                  _buildChartLegend('Revenue', AppColors.info),
                  _buildChartLegend('Collected', AppColors.success),
                  _buildChartLegend('Expenses', AppColors.warning),
                  _buildChartLegend('Profit', AppColors.secondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color:
                            value == 0
                                ? AppColors.textPrimary.withOpacity(0.3)
                                : AppColors.surfaceVariant,
                        strokeWidth: value == 0 ? 1.5 : 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval:
                          trends.length > 30
                              ? 5
                              : (trends.length > 20
                                  ? 4
                                  : (trends.length > 15
                                      ? 3
                                      : (trends.length > 10 ? 2 : 1))),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= trends.length) {
                          return const SizedBox.shrink();
                        }
                        final period =
                            trends[index]['period']?.toString() ?? '';
                        final day =
                            period.split('-').length == 3
                                ? period.split('-')[2]
                                : period;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            day,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 70,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            NumberFormat('#,##0', 'en_US').format(value),
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.surfaceVariant,
                    width: 1.5,
                  ),
                ),
                minX: 0,
                maxX: (trends.length - 1).toDouble(),
                minY: minValue,
                maxY: maxValue,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor:
                        (touchedSpot) =>
                            AppColors.textPrimary.withOpacity(0.95),
                    tooltipPadding: const EdgeInsets.all(10),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= trends.length) return null;
                        final date = trends[index]['period'] ?? '';
                        final labels = ['Rev', 'Col', 'Exp', 'Pro'];
                        return LineTooltipItem(
                          '$date\n${labels[touchedSpots.indexOf(spot)]}: ${NumberFormat('#,##0', 'en_US').format(spot.y)} DA',
                          GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        trends
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                entry.key.toDouble(),
                                (entry.value['revenue'] ?? 0.0).toDouble(),
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: AppColors.info,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots:
                        trends
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                entry.key.toDouble(),
                                (entry.value['collected'] ?? 0.0).toDouble(),
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots:
                        trends
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                entry.key.toDouble(),
                                (entry.value['expenses'] ?? 0.0).toDouble(),
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots:
                        trends
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                entry.key.toDouble(),
                                (entry.value['profit'] ?? 0.0).toDouble(),
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: trends.length <= 10,
                      getDotPainter:
                          (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 4,
                            color:
                                spot.y >= 0
                                    ? AppColors.success
                                    : AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withOpacity(0.12),
                          AppColors.secondary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChartSummary(
                  'Total Rev',
                  trends.fold<double>(
                    0,
                    (sum, trend) =>
                        sum + ((trend['revenue'] ?? 0.0).toDouble()),
                  ),
                  AppColors.info,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.surfaceVariant,
                ),
                _buildChartSummary(
                  'Total Col',
                  trends.fold<double>(
                    0,
                    (sum, trend) =>
                        sum + ((trend['collected'] ?? 0.0).toDouble()),
                  ),
                  AppColors.success,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.surfaceVariant,
                ),
                _buildChartSummary(
                  'Total Exp',
                  trends.fold<double>(
                    0,
                    (sum, trend) =>
                        sum + ((trend['expenses'] ?? 0.0).toDouble()),
                  ),
                  AppColors.warning,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.surfaceVariant,
                ),
                _buildChartSummary(
                  'Net Profit',
                  trends.fold<double>(
                    0,
                    (sum, trend) => sum + ((trend['profit'] ?? 0.0).toDouble()),
                  ),
                  AppColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSummary(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat('#,##0', 'en_US').format(value),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseBreakdown(DashboardProvider provider) {
    final breakdown = provider.expenseBreakdown;
    if (breakdown == null) return const SizedBox.shrink();

    final expenses = [
      {'label': 'Withdrawals', 'data': breakdown['withdrawals']},
      {'label': 'Supplier Payments', 'data': breakdown['supplier_payments']},
      {'label': 'Consumables', 'data': breakdown['consumables']},
      {'label': 'Stock Purchases', 'data': breakdown['stock_purchases']},
      {'label': 'Client Stock Usage', 'data': breakdown['client_stock_usage']},
      {'label': 'Other Expenses', 'data': breakdown['other_expenses']},
    ];

    double totalExpenses = 0;
    for (var expense in expenses) {
      final data = expense['data'] as Map?;
      totalExpenses += (data?['amount'] ?? 0.0).toDouble();
    }

    if (totalExpenses == 0) return const SizedBox.shrink();

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.textSecondary,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, size: 18, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(
                'Expense Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${NumberFormat('#,##0', 'en_US').format(totalExpenses)} DA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: PieChart(
                        PieChartData(
                          sections:
                              expenses.asMap().entries.map((entry) {
                                final index = entry.key;
                                final expense = entry.value;
                                final data = expense['data'] as Map?;
                                final amount =
                                    (data?['amount'] ?? 0.0).toDouble();
                                if (amount == 0) {
                                  return PieChartSectionData(
                                    value: 0.001,
                                    title: '',
                                    color: Colors.transparent,
                                    radius: 0,
                                  );
                                }
                                final percentage =
                                    (amount / totalExpenses * 100);
                                final color = colors[index % colors.length];
                                return PieChartSectionData(
                                  value: amount,
                                  title:
                                      percentage >= 5
                                          ? '${percentage.toStringAsFixed(0)}%'
                                          : '',
                                  color: color,
                                  radius: 80,
                                  titleStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          expenses.asMap().entries.map((entry) {
                            final index = entry.key;
                            final expense = entry.value;
                            final data = expense['data'] as Map?;
                            final amount = (data?['amount'] ?? 0.0).toDouble();
                            final count = data?['count'] ?? 0;
                            if (amount == 0) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors[index % colors.length]
                                    .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colors[index % colors.length]
                                      .withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense['label'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$count transactions',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat('#,##0', 'en_US').format(amount)} DA',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors[index % colors.length],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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

  Widget _buildBottomStats(DashboardProvider provider) {
    final clients = provider.topClients;
    final debtors = provider.topDebtors;
    final lowStockItems = provider.lowStockItems;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 18, color: AppColors.info),
              const SizedBox(width: 10),
              Text(
                'Business Analytics',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Orders',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildStatRow(
                        'Total Orders',
                        (provider.totalOrders).toString(),
                        AppColors.info,
                      ),
                      _buildStatRow(
                        'Completed',
                        (provider.completedOrders).toString(),
                        AppColors.success,
                      ),
                      _buildStatRow(
                        'In Progress',
                        (provider.inProgressOrders).toString(),
                        AppColors.warning,
                      ),
                      _buildStatRow(
                        'Pending',
                        (provider.pendingOrders).toString(),
                        AppColors.textSecondary,
                      ),
                      _buildStatRow(
                        'Fully Paid',
                        (provider.fullyPaidOrders).toString(),
                        AppColors.success,
                      ),
                      _buildStatRow(
                        'Partially Paid',
                        (provider.partiallyPaidOrders).toString(),
                        AppColors.warning,
                      ),
                      _buildStatRow(
                        'Unpaid',
                        (provider.unpaidOrders).toString(),
                        AppColors.primary,
                      ),
                      if (provider.averageOrderValue > 0)
                        _buildStatRow(
                          'Avg Order',
                          '${NumberFormat('#,##0', 'en_US').format(provider.averageOrderValue)} DA',
                          AppColors.info,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Inventory',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildStatRow(
                        'Total Products',
                        (provider.totalProducts ).toString(),
                        AppColors.info,
                      ),
                      _buildStatRow(
                        'Out of Stock',
                        (provider.outOfStockCount ).toString(),
                        AppColors.primary,
                      ),
                      _buildStatRow(
                        'Low Stock',
                        (provider.lowStockCount ).toString(),
                        AppColors.warning,
                      ),
                      _buildStatRow(
                        'Stock Value',
                        '${NumberFormat('#,##0', 'en_US').format(provider.totalStockValue )} DA',
                        AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: AppColors.surfaceVariant),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (clients.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Top Clients (${provider.totalClients } total)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...clients.map((client) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    client['name']?.toString() ?? 'Unknown',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${NumberFormat('#,##0', 'en_US').format((client['revenue'] ).toDouble())} DA',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      '${client['orders_count'] } orders',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              if (clients.isNotEmpty && debtors.isNotEmpty)
                const SizedBox(width: 20),
              if (debtors.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Top Debtors',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...debtors.map((debtor) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    debtor['name']?.toString() ?? 'Unknown',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${NumberFormat('#,##0', 'en_US').format((debtor['outstanding'] ).toDouble())} DA',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (lowStockItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Low Stock Items',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  lowStockItems.map((item) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item['name']?.toString() ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${item['current_quantity'] } ${item['unit'] ?? ''}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
