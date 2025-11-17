import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

enum DialogSize { small, big }

class CustomDialogWidget extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final bool isScrollable;
  final DialogSize size; // ✅ new parameter

  const CustomDialogWidget({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.isScrollable = true,
    this.size = DialogSize.big, // ✅ default is big
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Set width/height based on size parameter
    double minWidth = screenWidth * 0.7;
    double maxWidth = screenWidth * 0.9;
    double maxHeight = screenHeight * 0.9;

    if (size == DialogSize.small && screenWidth > 800) {
      minWidth = screenWidth * 0.2;
      maxWidth = screenWidth * 0.3;
      maxHeight = screenHeight * 0.5;
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // stretch to full width
            children: [
              // --- Title ---
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center, // ✅ title centered
              ),
              const SizedBox(height: 16),

              // --- Scrollable Content ---
              Flexible(
                child:
                    isScrollable
                        ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Center(
                            child: content, // ✅ content centered
                          ),
                        )
                        : Center(child: content), // ✅ content centered
              ),

              const SizedBox(height: 16),

              // --- Actions ---
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for displaying detail rows
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (left-aligned)
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.left,
            ),
          ),

          // Value (left-aligned, no spacing between columns)
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

// class CustomDialogWidget extends StatelessWidget {
//   final String title;
//   final Widget content;
//   final List<Widget> actions;
//   final bool isScrollable;

//   const CustomDialogWidget({
//     super.key,
//     required this.title,
//     required this.content,
//     required this.actions,
//     this.isScrollable = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//       title: Text(
//         title,
//         style: GoogleFonts.inter(
//           fontSize: 20,
//           fontWeight: FontWeight.w700,
//           color: AppColors.textPrimary,
//           letterSpacing: -0.5,
//         ),
//       ),
//       content: isScrollable ? SingleChildScrollView(child: content) : content,
//       contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
//       actions: actions,
//       actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
//       backgroundColor: AppColors.surface,
//       elevation: 8,
//     );
//   }
// }

// // Helper widget for displaying detail rows
// class DetailRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool isHighlight;

//   const DetailRow({
//     super.key,
//     required this.label,
//     required this.value,
//     this.isHighlight = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               label,
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//             Text(
//               value,
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
//                 color: isHighlight ? AppColors.primary : AppColors.textPrimary,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//       ],
//     );
//   }
// }
