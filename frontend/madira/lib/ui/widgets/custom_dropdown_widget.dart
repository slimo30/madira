import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class CustomDropdownWidget<T> extends StatefulWidget {
  final String labelText;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String? hintText;
  final bool required;
  final IconData prefixIcon;
  final String? errorText;
  final bool enabled;

  const CustomDropdownWidget({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.required = false,
    this.prefixIcon = Icons.security,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<CustomDropdownWidget<T>> createState() =>
      _CustomDropdownWidgetState<T>();
}

class _CustomDropdownWidgetState<T> extends State<CustomDropdownWidget<T>> {
  late T _currentValue;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  late GlobalKey _containerKey;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _containerKey = GlobalKey();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
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
    if (!widget.enabled) return;

    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isOpen = false);
      return;
    }

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
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.surfaceVariant, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: BoxConstraints(
                  maxHeight: (widget.items.length * 44.0).clamp(0, 220),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isSelected = item.value == _currentValue;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _currentValue = item.value as T;
                          _isOpen = false;
                        });
                        _overlayEntry?.remove();
                        _overlayEntry = null;
                        widget.onChanged(item.value);
                      },
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary.withOpacity(0.08)
                                  : Colors.transparent,
                          border:
                              isSelected
                                  ? Border(
                                    left: BorderSide(
                                      color: AppColors.primary,
                                      width: 3,
                                    ),
                                  )
                                  : null,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            (item.child as Text).data ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        if (widget.labelText.isNotEmpty)
          RichText(
            text: TextSpan(
              text: widget.labelText,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              children: [
                if (widget.required)
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
        // Dropdown Container
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _showDropdownMenu,
            child: Container(
              key: _containerKey,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      widget.errorText != null
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                  width: widget.errorText != null ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color:
                    widget.enabled
                        ? AppColors.surface
                        : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          widget.prefixIcon,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _currentValue == null
                                ? (widget.hintText ?? 'Select an option')
                                : (widget.items
                                                .firstWhere(
                                                  (item) =>
                                                      item.value ==
                                                      _currentValue,
                                                )
                                                .child
                                            as Text)
                                        .data ??
                                    '',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color:
                                  _currentValue == null
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
                    color:
                        widget.enabled
                            ? AppColors.textSecondary
                            : AppColors.textSecondary.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Error text
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                widget.errorText!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
 