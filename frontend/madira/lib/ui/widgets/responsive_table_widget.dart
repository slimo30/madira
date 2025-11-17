import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class ResponsiveTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final double? minColumnWidth;

  const ResponsiveTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minColumnWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic column width based on available space
        final totalAvailableWidth = constraints.maxWidth;
        final columnCount = columns.length;

        // Reserve space for margins and padding
        final usableWidth = totalAvailableWidth - 48; // 24 margin on each side

        // Distribute width proportionally, but ensure minimum width per column
        final minTotalWidth = (minColumnWidth ?? 100) * columnCount;

        double columnWidth;
        if (usableWidth >= minTotalWidth) {
          // Plenty of space - divide equally
          columnWidth = usableWidth / columnCount;
        } else {
          // Limited space - use minimum width
          columnWidth = minColumnWidth ?? 100;
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  AppColors.surfaceVariant,
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.hovered)) {
                    return AppColors.primary.withOpacity(0.03);
                  }
                  return AppColors.surface;
                }),
                headingRowHeight: 48,
                dataRowHeight: 64,
                columnSpacing: 0,
                horizontalMargin: 20,
                dividerThickness: 1,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: AppColors.surfaceVariant,
                    width: 1,
                  ),
                ),
                columns:
                    columns
                        .map(
                          (column) => DataColumn(
                            label: SizedBox(
                              width: columnWidth,
                              child: Center(
                                child: Text(
                                  column,
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
                          ),
                        )
                        .toList(),
                rows:
                    rows
                        .map(
                          (row) => DataRow(
                            cells:
                                row
                                    .map(
                                      (cell) => DataCell(
                                        SizedBox(
                                          width: columnWidth,
                                          child: Center(child: cell),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
