import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final bool isDense;
  final Widget? suffixIcon;

  const ModernDropdown({
    Key? key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.fillColor,
    this.borderColor,
    this.borderRadius = 12.0,
    this.contentPadding,
    this.labelStyle,
    this.hintStyle,
    this.isDense = false,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        validator: validator,
        isDense: isDense,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null 
              ? Icon(
                  prefixIcon,
                  color: enabled ? AppTheme.primaryBlue : Colors.grey,
                  size: isTablet ? 24 : 20,
                )
              : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: fillColor ?? (enabled ? Colors.grey.shade50 : Colors.grey.shade100),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: borderColor ?? Colors.grey.shade200,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: AppTheme.primaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          contentPadding: contentPadding ?? EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 16 : 12,
          ),
          labelStyle: labelStyle ?? TextStyle(
            color: enabled ? Colors.grey.shade700 : Colors.grey.shade500,
            fontSize: isTablet ? 16 : 14,
          ),
          hintStyle: hintStyle ?? TextStyle(
            color: Colors.grey.shade500,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        style: TextStyle(
          color: enabled ? Colors.grey.shade800 : Colors.grey.shade500,
          fontSize: isTablet ? 16 : 14,
        ),
        dropdownColor: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: enabled ? AppTheme.primaryBlue : Colors.grey,
        ),
      ),
    );
  }
}

class ModernSearchableDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemAsString;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;
  final Color? fillColor;
  final double borderRadius;

  const ModernSearchableDropdown({
    Key? key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    required this.itemAsString,
    this.onChanged,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.fillColor,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  State<ModernSearchableDropdown<T>> createState() => _ModernSearchableDropdownState<T>();
}

class _ModernSearchableDropdownState<T> extends State<ModernSearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<T> _filteredItems = [];
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    if (widget.value != null) {
      _searchController.text = widget.itemAsString(widget.value as T);
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isOpen) {
      _showOverlay();
    } else if (!_focusNode.hasFocus && _isOpen) {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = widget.value == item;
                
                return InkWell(
                  onTap: () {
                    _searchController.text = widget.itemAsString(item);
                    widget.onChanged?.call(item);
                    _removeOverlay();
                    _focusNode.unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
                    ),
                    child: Text(
                      widget.itemAsString(item),
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade800,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => widget.itemAsString(item)
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
    
    if (_isOpen) {
      _removeOverlay();
      _showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _searchController,
        focusNode: _focusNode,
        enabled: widget.enabled,
        validator: widget.validator != null 
            ? (value) => widget.validator!(widget.value)
            : null,
        onChanged: _filterItems,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null 
              ? Icon(
                  widget.prefixIcon,
                  color: widget.enabled ? AppTheme.primaryBlue : Colors.grey,
                  size: isTablet ? 24 : 20,
                )
              : null,
          suffixIcon: Icon(
            _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: widget.enabled ? AppTheme.primaryBlue : Colors.grey,
          ),
          filled: true,
          fillColor: widget.fillColor ?? (widget.enabled ? Colors.grey.shade50 : Colors.grey.shade100),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: AppTheme.primaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 16 : 12,
          ),
        ),
        style: TextStyle(
          color: widget.enabled ? Colors.grey.shade800 : Colors.grey.shade500,
          fontSize: isTablet ? 16 : 14,
        ),
      ),
    );
  }
}

class ModernMultiSelectDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final List<T> selectedValues;
  final List<T> items;
  final String Function(T) itemAsString;
  final ValueChanged<List<T>>? onChanged;
  final IconData? prefixIcon;
  final bool enabled;
  final int? maxSelections;

  const ModernMultiSelectDropdown({
    Key? key,
    this.label,
    this.hint,
    required this.selectedValues,
    required this.items,
    required this.itemAsString,
    this.onChanged,
    this.prefixIcon,
    this.enabled = true,
    this.maxSelections,
  }) : super(key: key);

  @override
  State<ModernMultiSelectDropdown<T>> createState() => _ModernMultiSelectDropdownState<T>();
}

class _ModernMultiSelectDropdownState<T> extends State<ModernMultiSelectDropdown<T>> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
          InkWell(
            onTap: widget.enabled ? () => setState(() => _isOpen = !_isOpen) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: widget.enabled ? Colors.grey.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isOpen ? AppTheme.primaryBlue : Colors.grey.shade200,
                  width: _isOpen ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(
                      widget.prefixIcon,
                      color: widget.enabled ? AppTheme.primaryBlue : Colors.grey,
                      size: isTablet ? 24 : 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: widget.selectedValues.isEmpty
                        ? Text(
                            widget.hint ?? 'Select items',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: isTablet ? 16 : 14,
                            ),
                          )
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: widget.selectedValues.take(3).map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.itemAsString(item),
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList()
                              ..addAll(widget.selectedValues.length > 3
                                  ? [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '+${widget.selectedValues.length - 3}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : []),
                          ),
                  ),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: widget.enabled ? AppTheme.primaryBlue : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_isOpen) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = widget.selectedValues.contains(item);
                  final canSelect = widget.maxSelections == null || 
                      widget.selectedValues.length < widget.maxSelections! || 
                      isSelected;
                  
                  return InkWell(
                    onTap: canSelect ? () {
                      final newSelection = List<T>.from(widget.selectedValues);
                      if (isSelected) {
                        newSelection.remove(item);
                      } else {
                        newSelection.add(item);
                      }
                      widget.onChanged?.call(newSelection);
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: canSelect 
                                ? (isSelected ? AppTheme.primaryBlue : Colors.grey.shade600)
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.itemAsString(item),
                              style: TextStyle(
                                color: canSelect 
                                    ? (isSelected ? AppTheme.primaryBlue : Colors.grey.shade800)
                                    : Colors.grey.shade400,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}