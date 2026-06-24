import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/timetable_controller.dart';
import 'package:school_app/controllers/teacher_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/models/school_models.dart';

// ─── Design System: Light Blue Professional Theme ─────────────────────────────
class _DS {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF0284C7);
  static const primaryLight = Color(0xFF7DD3FC);
  static const primarySoft = Color(0xFFE0F2FE);
  static const primaryMuted = Color(0xFFBAE6FD);

  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEE2E2);

  static const border = Color(0xFFE2E8F0);
  static const borderFocus = Color(0xFF7DD3FC);
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const radius = 16.0;
  static const radiusSm = 10.0;
  static const radiusLg = 24.0;
  static const radiusXl = 32.0;

  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
  static const spacingXxl = 32.0;

  // Day-based color palette for timetable columns
  static const dayColors = [
    Color(0xFFEDE9FE), // Mon - lavender
    Color(0xFFFCE7F3), // Tue - pink
    Color(0xFFD1FAE5), // Wed - green
    Color(0xFFFEF3C7), // Thu - amber
    Color(0xFFDBEAFE), // Fri - blue
    Color(0xFFFFEDD5), // Sat - orange
  ];
  static const dayTextColors = [
    Color(0xFF6D28D9),
    Color(0xFFBE185D),
    Color(0xFF065F46),
    Color(0xFF92400E),
    Color(0xFF1D4ED8),
    Color(0xFFC2410C),
  ];

  static double get mobile => 600;
  static double get tablet => 900;
}

// ─── Responsive Helpers ───────────────────────────────────────────────────────
class _Responsive {
  static double padding(BuildContext context) =>
      MediaQuery.of(context).size.width < _DS.tablet ? _DS.spacingLg : _DS.spacingXl;

  static double fontSize(BuildContext context, {double mobile = 14, double tablet = 16}) =>
      MediaQuery.of(context).size.width < _DS.tablet ? mobile : tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _DS.tablet;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: padding(context), vertical: _DS.spacingLg);

  static double cardRadius(BuildContext context) =>
      isTablet(context) ? _DS.radiusLg : _DS.radius;

  // FIX: Timetable cell sizes - removed fixed maxHeight usage
  static double timetableCellWidth(BuildContext context) =>
      isTablet(context) ? 140 : 108;

  static double timetableCellHeight(BuildContext context) =>
      isTablet(context) ? 72 : 62;

  static double periodColWidth(BuildContext context) =>
      isTablet(context) ? 80 : 68;
}

// ─── Reusable Components ──────────────────────────────────────────────────────
Widget _card({required Widget child, EdgeInsets? padding, Color? color, BuildContext? context}) {
  return Container(
    margin: EdgeInsets.only(bottom: _DS.spacingMd),
    padding: padding ?? EdgeInsets.all(_DS.spacingLg),
    decoration: BoxDecoration(
      color: color ?? _DS.surface,
      borderRadius: BorderRadius.circular(context != null ? _Responsive.cardRadius(context) : _DS.radius),
      border: Border.all(color: _DS.border),
      boxShadow: _DS.shadow,
    ),
    child: child,
  );
}

Widget _badge(String label, {Color? bg, Color? fg, double fontSize = 11}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg ?? _DS.primarySoft,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: fg ?? _DS.primary, letterSpacing: 0.3),
    ),
  );
}

Widget _iconBox(IconData icon, {Color? bg, Color? fg, double size = 20}) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: bg ?? _DS.primarySoft, borderRadius: BorderRadius.circular(_DS.radiusSm)),
    child: Icon(icon, color: fg ?? _DS.primary, size: size),
  );
}

Widget _sectionHeader(BuildContext context, String title, {Widget? action, IconData? icon}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(0, _DS.spacingSm, 0, _DS.spacingMd),
    child: Row(
      children: [
        if (icon != null) _iconBox(icon, size: 16),
        if (icon != null) const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: _Responsive.fontSize(context, mobile: 15, tablet: 16),
            fontWeight: FontWeight.w700,
            color: _DS.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (action != null) ...[const Spacer(), action],
      ],
    ),
  );
}

Widget _primaryBtn({
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  IconData? icon,
  bool loading = false,
  Color? color,
  bool fullWidth = true,
  double? height,
}) {
  return SizedBox(
    width: fullWidth ? double.infinity : null,
    height: height,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? _DS.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _DS.primaryMuted,
        padding: EdgeInsets.symmetric(vertical: _DS.spacingLg),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(
            label,
            style: TextStyle(
              fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 15),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _secondaryBtn({
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  IconData? icon,
  Color? color,
  bool fullWidth = false,
}) {
  return SizedBox(
    width: fullWidth ? double.infinity : null,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? _DS.primary,
        side: BorderSide(color: color ?? _DS.primary),
        padding: EdgeInsets.symmetric(vertical: _DS.spacingLg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(
            label,
            style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 14, tablet: 15), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

Widget _field(TextEditingController ctrl, String label, BuildContext context,
    {TextInputType? keyboardType, bool obscure = false, String? prefix, Widget? suffixIcon}) {
  return TextField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: TextStyle(fontSize: _Responsive.fontSize(context), color: _DS.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: _DS.textSecondary, fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14)),
      filled: true,
      fillColor: _DS.surfaceAlt,
      contentPadding: EdgeInsets.symmetric(horizontal: _DS.spacingLg, vertical: _DS.spacingMd),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_DS.radiusSm), borderSide: const BorderSide(color: _DS.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_DS.radiusSm), borderSide: const BorderSide(color: _DS.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_DS.radiusSm), borderSide: const BorderSide(color: _DS.primary, width: 1.5)),
    ),
  );
}

Widget _dropdown<T>({
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?) onChanged,
  required String hint,
  required IconData icon,
  required BuildContext context,
  List<Widget>? selectedItemBuilder,
  bool isExpanded = true,
}) {
  return Container(
    decoration: BoxDecoration(
      color: _DS.surfaceAlt,
      borderRadius: BorderRadius.circular(_DS.radiusSm),
      border: Border.all(color: _DS.border),
    ),
    child: DropdownButtonFormField<T>(
      isExpanded: isExpanded,
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _DS.textMuted, fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14)),
        prefixIcon: Icon(icon, color: _DS.primary, size: 20),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: _DS.spacingMd, vertical: _DS.spacingMd),
      ),
      dropdownColor: _DS.surface,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(_DS.radius),
      icon: const Icon(Icons.unfold_more_rounded, color: _DS.textMuted, size: 20),
      style: TextStyle(color: _DS.textPrimary, fontSize: _Responsive.fontSize(context)),
      selectedItemBuilder: selectedItemBuilder != null ? (_) => selectedItemBuilder : null,
      items: items,
      onChanged: onChanged,
    ),
  );
}

Widget _emptyState(BuildContext context,
    {required IconData icon, required String title, required String subtitle, Widget? action}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(_DS.spacingXxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: _DS.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: _DS.primary),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: TextStyle(
                  fontSize: _Responsive.fontSize(context, mobile: 17, tablet: 18),
                  fontWeight: FontWeight.w700,
                  color: _DS.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13), color: _DS.textMuted)),
          if (action != null) ...[const SizedBox(height: 20), action],
        ],
      ),
    ),
  );
}

// ─── IMPROVED Timetable Cell Widget ──────────────────────────────────────────
// FIX: Uses intrinsic sizing instead of fixed heights to avoid BoxConstraints conflicts
Widget _timetableCell({
  required String subject,
  required String teacher,
  required BuildContext context,
  bool isInteractive = false,
  VoidCallback? onTap,
  bool isBreak = false,
  bool isAssigned = false,
  bool isHighlight = false,
  int dayIndex = 0,
}) {
  final cellWidth = _Responsive.timetableCellWidth(context);

  Color bgColor;
  Color textColor;
  Color borderColor;
  IconData cellIcon;

  if (isBreak) {
    bgColor = _DS.warningSoft;
    textColor = _DS.warning;
    borderColor = _DS.warning;
    cellIcon = Icons.free_breakfast_rounded;
  } else if (isHighlight) {
    bgColor = _DS.successSoft;
    textColor = _DS.success;
    borderColor = _DS.success;
    cellIcon = Icons.star_rounded;
  } else if (isAssigned) {
    bgColor = _DS.dayColors[dayIndex % _DS.dayColors.length];
    textColor = _DS.dayTextColors[dayIndex % _DS.dayTextColors.length];
    borderColor = textColor.withOpacity(0.3);
    cellIcon = Icons.menu_book_rounded;
  } else {
    bgColor = _DS.surfaceAlt;
    textColor = _DS.textMuted;
    borderColor = _DS.border;
    cellIcon = Icons.add_rounded;
  }

  return InkWell(
    onTap: isInteractive ? onTap : null,
    borderRadius: BorderRadius.circular(_DS.radiusSm),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: cellWidth,
      // FIX: Use constraints instead of fixed height to avoid non-normalized BoxConstraints
      constraints: BoxConstraints(
        minHeight: _Responsive.timetableCellHeight(context),
        minWidth: cellWidth,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: borderColor, width: isAssigned || isHighlight ? 1.5 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // FIX: min size prevents unbounded expansion
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cellIcon, size: 10, color: textColor.withOpacity(0.7)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12),
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (!isBreak) ...[
            const SizedBox(height: 3),
            Text(
              teacher,
              style: TextStyle(
                fontSize: _Responsive.fontSize(context, mobile: 9, tablet: 10),
                color: textColor.withOpacity(0.65),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
          if (isInteractive && !isAssigned && !isBreak) ...[
            const SizedBox(height: 2),
            Text(
              'Tap to add',
              style: TextStyle(
                fontSize: 8,
                color: _DS.textMuted.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// ─── Class & Section Bottom Sheet ─────────────────────────────────────────────
// A modal bottom sheet that lets the user pick class then section.
// Returns a record (SchoolClass?, Section?) when dismissed via "Apply".
class _ClassSectionSheet extends StatefulWidget {
  final List<SchoolClass> classes;
  final List<Section> sections;
  final SchoolClass? initialClass;
  final Section? initialSection;
  final bool hasSectionAccess;
  final Future<void> Function(SchoolClass cls) onClassChanged;
  final int Function(String, String) compareClassNames;
  final IconData Function(String) getClassIcon;

  const _ClassSectionSheet({
    required this.classes,
    required this.sections,
    required this.initialClass,
    required this.initialSection,
    required this.hasSectionAccess,
    required this.onClassChanged,
    required this.compareClassNames,
    required this.getClassIcon,
  });

  @override
  State<_ClassSectionSheet> createState() => _ClassSectionSheetState();
}

class _ClassSectionSheetState extends State<_ClassSectionSheet> {
  SchoolClass? _selectedClass;
  Section? _selectedSection;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.initialClass;
    _selectedSection = widget.initialSection;
  }

  List<SchoolClass> get _sortedClasses {
    return List<SchoolClass>.from(widget.classes)
      ..sort((a, b) => widget.compareClassNames(a.name, b.name));
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_DS.radiusXl)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: _DS.border, borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _DS.primarySoft, borderRadius: BorderRadius.circular(_DS.radiusSm)),
                    child: const Icon(Icons.class_rounded, color: _DS.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Select Class & Section',
                          style: TextStyle(
                            fontSize: _Responsive.fontSize(context, mobile: 16, tablet: 17),
                            fontWeight: FontWeight.w800, color: _DS.textPrimary,
                          )),
                      Text(
                        _selectedClass != null
                            ? (_selectedSection != null
                            ? '${_selectedClass!.name} · ${_selectedSection!.name}'
                            : _selectedClass!.name)
                            : 'No selection',
                        style: TextStyle(
                          fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13),
                          color: _selectedClass != null ? _DS.primary : _DS.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _DS.surfaceAlt, borderRadius: BorderRadius.circular(100)),
                      child: const Icon(Icons.close_rounded, size: 16, color: _DS.textMuted),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CLASS label
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
                      child: const Text('CLASS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              color: _DS.textMuted, letterSpacing: 1.2)),
                    ),
                    const SizedBox(height: 10),

                    // Class chips
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
                      child: widget.classes.isEmpty
                          ? Text('No classes available',
                          style: TextStyle(fontSize: 13, color: _DS.textMuted))
                          : Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _sortedClasses.map((cls) {
                          final isSelected = _selectedClass?.id == cls.id;
                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                _selectedClass = cls;
                                _selectedSection = null;
                              });
                              await widget.onClassChanged(cls);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected ? _DS.primary : _DS.surfaceAlt,
                                borderRadius: BorderRadius.circular(_DS.radiusSm),
                                border: Border.all(
                                  color: isSelected ? _DS.primary : _DS.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(cls.name,
                                  style: TextStyle(
                                    fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14),
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : _DS.textPrimary,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Section chips (only when class selected)
                    if (widget.hasSectionAccess && _selectedClass != null) ...[
                      const SizedBox(height: 20),
                      Divider(height: 1, color: _DS.border),
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
                        child: const Text('SECTION',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                                color: _DS.textMuted, letterSpacing: 1.2)),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
                        child: sections.isEmpty
                            ? Row(children: [
                          const Icon(Icons.info_outline_rounded, color: _DS.textMuted, size: 15),
                          const SizedBox(width: 8),
                          Text('No sections — class-level timetable',
                              style: TextStyle(
                                  fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13),
                                  color: _DS.textMuted)),
                        ])
                            : Wrap(
                          spacing: 10, runSpacing: 10,
                          children: [
                            // "All" chip
                            GestureDetector(
                              onTap: () => setState(() => _selectedSection = null),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  color: _selectedSection == null ? _DS.primary : _DS.surfaceAlt,
                                  borderRadius: BorderRadius.circular(_DS.radiusSm),
                                  border: Border.all(
                                    color: _selectedSection == null ? _DS.primary : _DS.border,
                                    width: _selectedSection == null ? 1.5 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text('All',
                                    style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: _selectedSection == null ? Colors.white : _DS.textPrimary,
                                    )),
                              ),
                            ),
                            ...sections.map((sec) {
                              final isSelected = _selectedSection?.id == sec.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSection = sec),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected ? _DS.primary : _DS.surfaceAlt,
                                    borderRadius: BorderRadius.circular(_DS.radiusSm),
                                    border: Border.all(
                                      color: isSelected ? _DS.primary : _DS.border,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(sec.name,
                                      style: TextStyle(
                                        fontSize: 17, fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : _DS.textPrimary,
                                      )),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: _DS.border),

            // Footer
            Padding(
              padding: EdgeInsets.fromLTRB(
                _Responsive.padding(context), 16,
                _Responsive.padding(context),
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                children: [
                  if (_selectedClass != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _selectedClass = null;
                          _selectedSection = null;
                        }),
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _DS.textSecondary,
                          side: const BorderSide(color: _DS.border),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedClass == null
                          ? null
                          : () => Navigator.of(context).pop((_selectedClass, _selectedSection)),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _selectedClass == null
                            ? 'Select a class first'
                            : _selectedSection != null
                            ? 'Apply · ${_selectedClass!.name}, ${_selectedSection!.name}'
                            : 'Apply · ${_selectedClass!.name}',
                        style: TextStyle(
                          fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedClass != null ? _DS.primary : _DS.surfaceAlt,
                        foregroundColor: _selectedClass != null ? Colors.white : _DS.textMuted,
                        disabledBackgroundColor: _DS.surfaceAlt,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── IMPROVED Timetable Grid Widget ──────────────────────────────────────────
// Replaces DataTable with a custom scrollable grid to avoid BoxConstraints issues
class _TimetableGrid extends StatelessWidget {
  final List<dynamic> weeklySchedule;
  final List<String> addedDays;
  final bool isTablet;
  final bool isInteractive;
  final void Function(String day, int period)? onCellTap;
  final bool showTeacher;
  final bool isTeacherView;

  const _TimetableGrid({
    required this.weeklySchedule,
    required this.addedDays,
    required this.isTablet,
    required this.isInteractive,
    this.onCellTap,
    this.showTeacher = true,
    this.isTeacherView = false,
  });

  @override
  Widget build(BuildContext context) {
    final cellWidth = _Responsive.timetableCellWidth(context);
    final cellHeight = _Responsive.timetableCellHeight(context);
    final periodColWidth = _Responsive.periodColWidth(context);
    final totalPeriods = 8;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min, // FIX: prevents unbounded height
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────────
          Row(
            children: [
              // Period label header
              Container(
                width: periodColWidth,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _DS.primarySoft,
                  borderRadius: BorderRadius.circular(_DS.radiusSm),
                  border: Border.all(color: _DS.border),
                ),
                child: Text(
                  'Period',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: _Responsive.fontSize(context, mobile: 10, tablet: 11),
                    color: _DS.primaryDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Day headers
              ...List.generate(addedDays.length, (i) {
                final dayColor = _DS.dayColors[i % _DS.dayColors.length];
                final dayTextColor = _DS.dayTextColors[i % _DS.dayTextColors.length];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: cellWidth,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dayColor,
                      borderRadius: BorderRadius.circular(_DS.radiusSm),
                      border: Border.all(color: dayTextColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      addedDays[i].substring(0, addedDays[i].length > 3 ? 3 : addedDays[i].length).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12),
                        color: dayTextColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),
          // ── Period Rows ─────────────────────────────────────────────────
          ...List.generate(totalPeriods, (periodIndex) {
            final periodNumber = periodIndex + 1;
            final isEven = periodIndex.isEven;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Period label cell
                  Container(
                    width: periodColWidth,
                    height: cellHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isEven ? _DS.primarySoft : _DS.surface,
                      borderRadius: BorderRadius.circular(_DS.radiusSm),
                      border: Border.all(color: isEven ? _DS.primaryMuted : _DS.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'P$periodNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13),
                            color: _DS.primaryDark,
                          ),
                        ),
                        Text(
                          _periodTime(periodNumber),
                          style: TextStyle(
                            fontSize: 8,
                            color: _DS.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Day cells
                  ...List.generate(addedDays.length, (dayIndex) {
                    final day = addedDays[dayIndex];
                    final daySchedule = weeklySchedule.firstWhereOrNull((ws) => ws['day'] == day);

                    String subject = '-';
                    String teacher = '-';
                    bool isBreak = false;
                    bool isYourPeriod = false;

                    if (daySchedule != null) {
                      final periods = daySchedule['periods'] as List? ?? [];
                      final periodData = periods.firstWhereOrNull((p) => p['periodNumber'] == periodNumber);
                      if (periodData != null) {
                        isBreak = periodData['isBreak'] ?? false;
                        if (isTeacherView) {
                          subject = periodData['subjectName'] ?? '-';
                          isYourPeriod = periodData['isYourPeriod'] ?? false;
                        } else {
                          subject = isBreak ? 'Break' : (periodData['subjectName'] ?? '-');
                          final teacherData = periodData['teacherId'];
                          if (teacherData is Map) teacher = teacherData['userName'] ?? '-';
                        }
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: isTeacherView
                          ? _teacherViewCell(context, subject, isYourPeriod, cellWidth, cellHeight, dayIndex)
                          : _timetableCell(
                        subject: subject,
                        teacher: teacher,
                        context: context,
                        isInteractive: isInteractive,
                        onTap: isInteractive && onCellTap != null ? () => onCellTap!(day, periodNumber) : null,
                        isBreak: isBreak,
                        isAssigned: !isBreak && subject != '-',
                        dayIndex: dayIndex,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Simple time label per period
  String _periodTime(int period) {
    const times = ['8:00', '8:45', '9:30', '10:30', '11:15', '12:00', '1:30', '2:15'];
    return period <= times.length ? times[period - 1] : '';
  }

  Widget _teacherViewCell(
      BuildContext context, String subject, bool isYourPeriod, double cellWidth, double cellHeight, int dayIndex) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: cellWidth,
      constraints: BoxConstraints(minHeight: cellHeight),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isYourPeriod ? _DS.successSoft : _DS.surfaceAlt,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(
          color: isYourPeriod ? _DS.success : _DS.border,
          width: isYourPeriod ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isYourPeriod)
            Icon(Icons.person_pin_rounded, size: 12, color: _DS.success.withOpacity(0.8)),
          const SizedBox(height: 2),
          Text(
            subject == '-' ? '—' : subject,
            style: TextStyle(
              fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12),
              fontWeight: isYourPeriod ? FontWeight.w800 : FontWeight.w500,
              color: isYourPeriod ? _DS.success : _DS.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class TimetableManagementView extends StatefulWidget {
  @override
  State<TimetableManagementView> createState() => _TimetableManagementViewState();
}

class _TimetableManagementViewState extends State<TimetableManagementView> with TickerProviderStateMixin {
  final schoolController = Get.find<SchoolController>();
  final timetableController = Get.put(TimetableController());
  final teacherController = Get.put(TeacherController());
  final authController = Get.find<AuthController>();

  late TabController _tabController;
  SchoolClass? selectedClass;
  Section? selectedSection;
  String? selectedTeacherId;

  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getAvailableTabsCount(), vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ApiPermissions.isSchoolReadOnly(currentUserRole)) {
        final userSchoolId = authController.user.value?.schoolId;
        if (userSchoolId != null) {
          final userSchool = schoolController.schools.firstWhereOrNull((s) => s.id == userSchoolId);
          if (userSchool != null) {
            schoolController.selectedSchool.value = userSchool;
            schoolController.getAllClasses(userSchool.id);
            schoolController.loadTeachers();
          }
        }
      }
    });
  }

  int _getAvailableTabsCount() {
    int count = 0;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) count++;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) count++;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) count++;
    return count > 0 ? count : 1;
  }

  List<Widget> _buildTabs(BuildContext context) {
    final List<Widget> tabs = [];
    final isTablet = _Responsive.isTablet(context);

    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) {
      tabs.add(Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_calendar_rounded, size: isTablet ? 14 : 12),
            const SizedBox(width: 4),
            Text('Manage', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13))),
          ],
        ),
      ));
    }

    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) {
      tabs.add(Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_list_rounded, size: isTablet ? 14 : 12),
            const SizedBox(width: 4),
            Text('View', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13))),
          ],
        ),
      ));
    }

    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) {
      tabs.add(Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, size: isTablet ? 14 : 12),
            const SizedBox(width: 4),
            Text('Teacher', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13))),
          ],
        ),
      ));
    }

    return tabs.isNotEmpty ? tabs : [const Tab(text: 'No Access')];
  }

  List<Widget> _buildTabViews(BuildContext context) {
    final List<Widget> views = [];
    final isTablet = _Responsive.isTablet(context);
    final isLandscape = _Responsive.isLandscape(context);

    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) {
      views.add(_buildManageTab(context, isTablet, isLandscape));
    }

    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) {
      views.add(_buildViewTab(context, isTablet, isLandscape));
    }

    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) {
      views.add(_buildTeacherTab(context, isTablet, isLandscape));
    }

    return views.isNotEmpty ? views : [_buildNoAccessView(context)];
  }

  Widget _buildNoAccessView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: _Responsive.isTablet(context) ? 80 : 64, color: _DS.textMuted),
          const SizedBox(height: 24),
          Text('No Access',
              style: TextStyle(
                  fontSize: _Responsive.fontSize(context, mobile: 20, tablet: 24),
                  fontWeight: FontWeight.bold,
                  color: _DS.textSecondary)),
          const SizedBox(height: 16),
          Text(
            'You don\'t have permission to access timetable management',
            style: TextStyle(
                fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14), color: _DS.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _compareClassNames(String a, String b) {
    final aLower = a.toLowerCase().trim();
    final bLower = b.toLowerCase().trim();

    int getClassPriority(String className) {
      if (className == 'lkg') return 1;
      if (className == 'ukg') return 2;
      if (className.startsWith('grade ')) {
        final match = RegExp(r'grade (\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) return 2 + num;
        }
      }
      if (className.startsWith('class ')) {
        final match = RegExp(r'class (\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) return 20 + num;
        }
      }
      return 999;
    }

    return getClassPriority(aLower).compareTo(getClassPriority(bLower));
  }

  IconData _getClassIcon(String className) {
    final lower = className.toLowerCase();
    if (lower == 'lkg' || lower == 'ukg') return Icons.child_care_rounded;
    if (lower.contains('grade 1') || lower.contains('grade 2') || lower.contains('grade 3')) return Icons.looks_one_rounded;
    if (lower.contains('grade 4') || lower.contains('grade 5') || lower.contains('grade 6')) return Icons.looks_two_rounded;
    if (lower.contains('grade 7') || lower.contains('grade 8') || lower.contains('grade 9')) return Icons.looks_3_rounded;
    return Icons.looks_4_rounded;
  }

  String get currentUserRole => authController.user.value?.role?.toLowerCase() ?? '';

  @override
  Widget build(BuildContext context) {
    final isTablet = _Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: _DS.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_DS.primary, _DS.primaryDark]),
                boxShadow: _DS.shadowMd,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        _Responsive.padding(context),
                        isTablet ? 24 : 16,
                        _Responsive.padding(context),
                        isTablet ? 16 : 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(_DS.radiusSm),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Icon(Icons.grid_view_rounded, color: Colors.white, size: isTablet ? 18 : 14),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Academic Schedule',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 22 : 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3)),
                              const SizedBox(height: 2),
                              Text('Management Portal',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: isTablet ? 13 : 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.more_vert_rounded, color: Colors.white, size: isTablet ? 22 : 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // ── Pill TabBar ───────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: _Responsive.padding(context), vertical: _DS.spacingSm),
                    child: Container(
                      height: isTablet ? 36 : 32,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                      child: TabBar(
                        controller: _tabController,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                            color: _DS.surface,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: _DS.shadow),
                        labelColor: _DS.primary,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        labelStyle: TextStyle(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w700),
                        unselectedLabelStyle:
                        TextStyle(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w500),
                        tabs: _buildTabs(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: Container(
                color: _DS.bg,
                child: TabBarView(controller: _tabController, children: _buildTabViews(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Manage Tab ───────────────────────────────────────────────────────────
  Widget _buildManageTab(BuildContext context, bool isTablet, bool isLandscape) {
    return RefreshIndicator(
      onRefresh: () async {
        if (schoolController.selectedSchool.value != null && selectedClass != null) {
          await timetableController.getAllTimetables(
            schoolId: schoolController.selectedSchool.value!.id,
            classId: selectedClass!.id,
            sectionId: selectedSection?.id,
          );
        }
      },
      color: _DS.primary,
      child: SingleChildScrollView(
        padding: _Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCollapsibleSelectors(context, isLandscape, isTablet),
            const SizedBox(height: 16),
            _buildTimetableGrid(context, isTablet),
          ],
        ),
      ),
    );
  }

  // ─── View Tab ─────────────────────────────────────────────────────────────
  Widget _buildViewTab(BuildContext context, bool isTablet, bool isLandscape) {
    return RefreshIndicator(
      onRefresh: () async {
        if (schoolController.selectedSchool.value != null && selectedClass != null) {
          await timetableController.getAllTimetables(
            schoolId: schoolController.selectedSchool.value!.id,
            classId: selectedClass!.id,
            sectionId: selectedSection?.id,
          );
        }
      },
      color: _DS.primary,
      child: SingleChildScrollView(
        padding: _Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCollapsibleSelectors(context, isLandscape, isTablet),
            const SizedBox(height: 16),
            _buildViewOnlyTimetable(context, isTablet),
          ],
        ),
      ),
    );
  }

  // ─── Teacher Tab ──────────────────────────────────────────────────────────
  Widget _buildTeacherTab(BuildContext context, bool isTablet, bool isLandscape) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (schoolController.selectedSchool.value != null) schoolController.loadTeachers();
    });
    return SingleChildScrollView(
      padding: _Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeacherSelector(context, isTablet),
          const SizedBox(height: 20),
          _buildTeacherSchedule(context, isTablet),
        ],
      ),
    );
  }

  // ─── Class & Section Bottom Sheet Trigger ────────────────────────────────
  Widget _buildCollapsibleSelectors(BuildContext context, bool isLandscape, bool isTablet) {
    final hasClass = selectedClass != null;
    final hasSection = selectedSection != null;

    return GestureDetector(
      onTap: () => _openClassSectionSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(_DS.radius),
          border: Border.all(
            color: hasClass ? _DS.primary : _DS.border,
            width: hasClass ? 1.5 : 1,
          ),
          boxShadow: _DS.shadow,
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasClass ? _DS.primarySoft : _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(_DS.radiusSm),
              ),
              child: Icon(
                Icons.class_rounded,
                color: hasClass ? _DS.primary : _DS.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasClass ? selectedClass!.name : 'Select Class & Section',
                    style: TextStyle(
                      fontSize: _Responsive.fontSize(context, mobile: 14, tablet: 15),
                      fontWeight: FontWeight.w700,
                      color: hasClass ? _DS.textPrimary : _DS.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasClass
                        ? (hasSection
                        ? 'Section: ${selectedSection!.name}'
                        : 'All Sections · tap to change')
                        : 'Tap to choose a class and section',
                    style: TextStyle(
                      fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12),
                      color: hasClass ? _DS.textSecondary : _DS.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Badges
            if (hasClass) ...[
              _badge(
                selectedClass!.name.length > 10
                    ? '${selectedClass!.name.substring(0, 9)}…'
                    : selectedClass!.name,
                bg: _DS.primarySoft,
                fg: _DS.primary,
                fontSize: 10,
              ),
              if (hasSection) ...[
                const SizedBox(width: 4),
                _badge(selectedSection!.name,
                    bg: _DS.successSoft, fg: _DS.success, fontSize: 10),
              ],
              const SizedBox(width: 8),
            ],
            // Edit/arrow icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasClass ? _DS.primarySoft : _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                hasClass ? Icons.edit_rounded : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: hasClass ? _DS.primary : _DS.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openClassSectionSheet(BuildContext context) async {
    if (schoolController.selectedSchool.value != null &&
        schoolController.classes.isEmpty &&
        !schoolController.isLoading.value) {
      schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
    }

    final result = await showModalBottomSheet<(SchoolClass?, Section?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, __) => Obx(
              () => _ClassSectionSheet(
            classes: schoolController.classes,
            sections: schoolController.sections,
            initialClass: selectedClass,
            initialSection: selectedSection,
            hasSectionAccess: ApiPermissions.hasSectionAccess(currentUserRole),
            compareClassNames: _compareClassNames,
            getClassIcon: _getClassIcon,
            onClassChanged: (cls) async {
              if (schoolController.selectedSchool.value != null) {
                schoolController.getAllSections(
                  classId: cls.id,
                  schoolId: schoolController.selectedSchool.value!.id,
                );
              }
            },
          ),
        ),
      ),
    );

    if (result != null) {
      final (newClass, newSection) = result;
      setState(() {
        selectedClass = newClass;
        selectedSection = newSection;
      });
      if (newClass != null && schoolController.selectedSchool.value != null) {
        await timetableController.getAllTimetables(
          schoolId: schoolController.selectedSchool.value!.id,
          classId: newClass.id,
          sectionId: newSection?.id,
        );
      }
    }
  }

  // ─── Teacher Selector ─────────────────────────────────────────────────────
  Widget _buildTeacherSelector(BuildContext context, bool isTablet) {
    final searchController = TextEditingController();
    final filteredTeachers = <Map<String, dynamic>>[].obs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Teacher Directory', icon: Icons.person_search_rounded),
        Container(
          decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.radius),
              boxShadow: _DS.shadow),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              filteredTeachers.value = schoolController.teachers
                  .where((t) =>
                  (t['userName'] as String).toLowerCase().contains(value.toLowerCase()))
                  .toList();
            },
            style:
            TextStyle(fontSize: _Responsive.fontSize(context), color: _DS.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name...',
              hintStyle: TextStyle(color: _DS.textMuted, fontSize: _Responsive.fontSize(context)),
              prefixIcon: const Icon(Icons.search_rounded, color: _DS.primary),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(vertical: _DS.spacingMd, horizontal: _DS.spacingLg),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final list =
          searchController.text.isEmpty ? schoolController.teachers : filteredTeachers;
          if (schoolController.isLoading.value) {
            return Center(
                child: Padding(
                    padding: EdgeInsets.all(_DS.spacingXl),
                    child: CircularProgressIndicator(color: _DS.primary, strokeWidth: 2)));
          }
          if (list.isEmpty) {
            return _emptyState(context,
                icon: Icons.person_off_rounded,
                title: 'No teachers found',
                subtitle: 'Try adjusting your search');
          }
          return Container(
            constraints: BoxConstraints(maxHeight: isTablet ? 500 : 350),
            child: ListView.builder(
              itemCount: list.length,
              padding: EdgeInsets.only(bottom: _DS.spacingLg),
              itemBuilder: (context, index) {
                final teacher = list[index];
                final isSelected = selectedTeacherId == teacher['_id'];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _DS.primarySoft : _DS.surface,
                    borderRadius: BorderRadius.circular(_DS.radiusSm),
                    border: Border.all(
                        color: isSelected ? _DS.primary : _DS.border,
                        width: isSelected ? 1.5 : 1),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: _DS.spacingMd, vertical: _DS.spacingSm),
                    leading: Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isSelected ? _DS.primary : _DS.border, width: 2)),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected ? _DS.primary : _DS.surfaceAlt,
                        child: Text(
                          (teacher['userName'] as String).substring(0, 1).toUpperCase(),
                          style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : _DS.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    title: Text(
                      teacher['userName'] ?? 'Unknown',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: _Responsive.fontSize(context),
                          color: isSelected ? _DS.primaryDark : _DS.textPrimary),
                    ),
                    subtitle: Text(
                        "ID: ${teacher['_id'].toString().substring(0, 8)}...",
                        style: TextStyle(
                            fontSize: _Responsive.fontSize(context, mobile: 10, tablet: 11),
                            color: _DS.textMuted)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: _DS.primary, size: 20)
                        : const Icon(Icons.chevron_right_rounded, color: _DS.textMuted, size: 20),
                    onTap: () {
                      setState(() => selectedTeacherId = teacher['_id']);
                      timetableController.getTeacherSchedule(
                          schoolId: schoolController.selectedSchool.value!.id,
                          teacherId: teacher['_id']);
                    },
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  // ─── Timetable Grid (Manage) ──────────────────────────────────────────────
  Widget _buildTimetableGrid(BuildContext context, bool isTablet) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _emptyState(
        context,
        icon: Icons.calendar_today_outlined,
        title: 'Select class to manage',
        subtitle: 'Choose a class from the selectors above to view and edit the timetable',
        // action: _secondaryBtn(
        //   context: context,
        //   label: 'Refresh Classes',
        //   onPressed: () {
        //     if (schoolController.selectedSchool.value != null) {
        //       schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
        //     }
        //   },
        // ),
      );
    }

    return _card(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min, // FIX: prevent unbounded growth
        children: [
          // ── Grid header with actions ─────────────────────────────────────
          Container(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            decoration: const BoxDecoration(
              color: _DS.primarySoft,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_DS.radiusLg),
                  topRight: Radius.circular(_DS.radiusLg)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: _DS.primary, size: isTablet ? 22 : 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Weekly Timetable',
                        style: TextStyle(
                            fontSize: isTablet ? 15 : 13,
                            fontWeight: FontWeight.bold,
                            color: _DS.primaryDark),
                      ),
                    ),
                    // ── Legend ─────────────────────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendDot(_DS.dayColors[0], _DS.dayTextColors[0], 'Assigned'),
                        const SizedBox(width: 8),
                        _legendDot(_DS.warningSoft, _DS.warning, 'Break'),
                      ],
                    ),
                  ],
                ),
                if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday'))
                  Padding(
                    padding: EdgeInsets.only(top: _DS.spacingMd),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddDayDialog,
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('Add Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _DS.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm)),
                          ),
                        ),
                        if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _showDeleteTimetableDialog,
                            icon: const Icon(Icons.delete_rounded, size: 15),
                            label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _DS.danger,
                              side: const BorderSide(color: _DS.danger),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // ── Timetable grid ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            child: _buildTimetableContent(context, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color bg, Color fg, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: fg.withOpacity(0.5))),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, color: _DS.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTimetableContent(BuildContext context, bool isTablet) {
    return Obx(() {
      if (timetableController.isLoading.value) {
        return Center(
            child: Padding(
                padding: EdgeInsets.all(_DS.spacingXl),
                child: CircularProgressIndicator(color: _DS.primary, strokeWidth: 2)));
      }

      if (timetableController.timetables.isEmpty) {
        return _emptyState(
          context,
          icon: Icons.calendar_today_outlined,
          title: 'No Timetable Days Added',
          subtitle: 'Click "Add Day" to create your first timetable day',
          action: ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday')
              ? _primaryBtn(
              context: context,
              label: 'Add First Day',
              icon: Icons.add_rounded,
              onPressed: _showAddDayDialog,
              fullWidth: false)
              : null,
        );
      }

      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

      // FIX: Use custom _TimetableGrid instead of DataTable to avoid BoxConstraints issues
      return _TimetableGrid(
        weeklySchedule: weeklySchedule,
        addedDays: addedDays,
        isTablet: isTablet,
        isInteractive: ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod'),
        onCellTap: _showEditPeriodDialog,
      );
    });
  }

  // ─── View-Only Timetable ──────────────────────────────────────────────────
  Widget _buildViewOnlyTimetable(BuildContext context, bool isTablet) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _emptyState(context,
          icon: Icons.visibility_outlined,
          title: 'Select class to view',
          subtitle: 'Choose a class from the selectors above to view the timetable');
    }

    return _card(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            decoration: const BoxDecoration(
              color: _DS.primarySoft,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_DS.radiusLg),
                  topRight: Radius.circular(_DS.radiusLg)),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_rounded, color: _DS.primary, size: isTablet ? 22 : 18),
                const SizedBox(width: 12),
                Text('Timetable View',
                    style: TextStyle(
                        fontSize: isTablet ? 20 : 17,
                        fontWeight: FontWeight.bold,
                        color: _DS.primaryDark)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            child: _buildReadOnlyTimetable(context, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTimetable(BuildContext context, bool isTablet) {
    return Obx(() {
      if (timetableController.isLoading.value) {
        return Center(
            child: Padding(
                padding: EdgeInsets.all(_DS.spacingXl),
                child: CircularProgressIndicator(color: _DS.primary, strokeWidth: 2)));
      }

      if (timetableController.timetables.isEmpty) {
        return _emptyState(context,
            icon: Icons.schedule_rounded,
            title: 'No timetable data',
            subtitle: 'Timetable has not been created yet');
      }

      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

      // FIX: Use _TimetableGrid — no ConstrainedBox(minHeight), no dataRowMaxHeight
      return _TimetableGrid(
        weeklySchedule: weeklySchedule,
        addedDays: addedDays,
        isTablet: isTablet,
        isInteractive: ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher'),
        onCellTap: _showAssignTeacherDialog,
      );
    });
  }

  // ─── Teacher Schedule ─────────────────────────────────────────────────────
  Widget _buildTeacherSchedule(BuildContext context, bool isTablet) {
    return Obx(() {
      if (timetableController.teacherSchedule.isEmpty) {
        return _card(
          context: context,
          child: _emptyState(context,
              icon: Icons.person_outline_rounded,
              title: 'Select a teacher',
              subtitle: 'Choose a teacher from the list above to view their schedule'),
        );
      }

      final schedule = timetableController.teacherSchedule.first;
      final weeklySchedule = schedule['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

      return _card(
        context: context,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
              decoration: const BoxDecoration(
                color: _DS.successSoft,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_DS.radiusLg),
                    topRight: Radius.circular(_DS.radiusLg)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      color: _DS.success, size: isTablet ? 22 : 18),
                  const SizedBox(width: 12),
                  Text('Teacher Schedule',
                      style: TextStyle(
                          fontSize: isTablet ? 17 : 15,
                          fontWeight: FontWeight.bold,
                          color: _DS.success)),
                  //const Spacer(),
                  // _badge('Your periods highlighted',
                  //     bg: _DS.successSoft, fg: _DS.success, fontSize: 7,),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
              child: _TimetableGrid(
                weeklySchedule: weeklySchedule,
                addedDays: addedDays,
                isTablet: isTablet,
                isInteractive: false,
                isTeacherView: true,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  void _showAddDayDialog() {
    String selectedDay = days.first;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
        title: Row(
          children: [
            _iconBox(Icons.calendar_today_rounded, size: 16),
            const SizedBox(width: 10),
            const Text('Add Day '),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return _dropdown<String>(
              value: selectedDay,
              hint: 'Select Day',
              icon: Icons.calendar_today_rounded,
              context: context,
              selectedItemBuilder: days.map((day) => Text(day)).toList(),
              items: days.map((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: _DS.primary),
                      const SizedBox(width: 8),
                      Text(day),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (day) {
                if (day != null) setState(() => selectedDay = day);
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (schoolController.selectedSchool.value != null && selectedClass != null) {
                await timetableController.addDay(
                  schoolId: schoolController.selectedSchool.value!.id,
                  classId: selectedClass!.id,
                  sectionId: selectedSection?.id,
                  day: selectedDay,
                );
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _DS.primary, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTimetableDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
        title: Row(
          children: [
            _iconBox(Icons.delete_rounded, bg: _DS.dangerSoft, fg: _DS.danger, size: 16),
            const SizedBox(width: 10),
            const Text('Delete Timetable'),
          ],
        ),
        content: Text(
            'Are you sure you want to delete the entire timetable for ${selectedClass?.name}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (timetableController.timetables.isNotEmpty) {
                final timetableId = timetableController.timetables.first['_id'];
                Get.back();
                final success = await timetableController.deleteTimetable(timetableId);
                if (success &&
                    schoolController.selectedSchool.value != null &&
                    selectedClass != null) {
                  await timetableController.getAllTimetables(
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _DS.danger, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignTeacherDialog(String day, int period) {
    if (schoolController.selectedSchool.value != null) schoolController.loadTeachers();
    final searchCtrl = TextEditingController();
    String? localTeacherId;

    // Initialize and filter teachers reactively
    final filteredTeachers = <Map<String, dynamic>>[].obs;
    filteredTeachers.value = schoolController.teachers;

    // Add search listener ONCE out here to prevent duplicate bindings on dialog setState
    searchCtrl.addListener(() {
      final query = searchCtrl.text.toLowerCase();
      filteredTeachers.value = schoolController.teachers
          .where((t) => (t['userName'] as String).toLowerCase().contains(query))
          .toList();
    });

    Get.dialog(
      StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
            title: Text('Assign Teacher\n$day — Period $period',
                style: const TextStyle(fontSize: 15)),
            content: SizedBox(
              width: 300,
              // 1. SingleChildScrollView prevents content layout overflows when the keyboard pops up
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(searchCtrl, 'Search Teacher', context),
                    const SizedBox(height: 12),

                    // 2. Bound the interior list using keyboard-aware dynamic constraints
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        // Shrinks the teacher list area dynamically when the keyboard takes up screen space
                        maxHeight: MediaQuery.of(context).viewInsets.bottom > 0 ? 140 : 260,
                      ),
                      child: Obx(() => ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        itemCount: filteredTeachers.length,
                        itemBuilder: (context, index) {
                          final teacher = filteredTeachers[index];
                          final isSelected = localTeacherId == teacher['_id'];
                          return InkWell(
                            onTap: () => dialogSetState(() => localTeacherId = teacher['_id']),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? _DS.primarySoft : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: isSelected ? _DS.primary : Colors.transparent),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected ? _DS.primary : _DS.primarySoft,
                                    child: Icon(Icons.person,
                                        color: isSelected ? Colors.white : _DS.primary,
                                        size: 14),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(teacher['userName'] ?? 'Unknown',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: isSelected ? _DS.primaryDark : _DS.textPrimary,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal),
                                          overflow: TextOverflow.ellipsis)),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: _DS.primary, size: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (localTeacherId == null) {
                    Get.snackbar('Error', 'Please select a teacher',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  if (timetableController.timetables.isEmpty) {
                    Get.snackbar('Error', 'No timetable found',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  final timetable = timetableController.timetables.first;
                  final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
                  final daySchedule = weeklySchedule.firstWhereOrNull((ws) => ws['day'] == day);
                  if (daySchedule == null) {
                    Get.snackbar('Error', 'Day not found',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  final dayId = daySchedule['_id'] as String?;
                  if (dayId == null) {
                    Get.snackbar('Error', 'Invalid timetable data',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }

                  Get.back();
                  final success = await timetableController.assignTeacher(
                    mode: 'add',
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                    weeklyScheduleId: dayId,
                    periodNumber: period,
                    teacherId: localTeacherId!,
                  );

                  if (success &&
                      schoolController.selectedSchool.value != null &&
                      selectedClass != null) {
                    await timetableController.getAllTimetables(
                      schoolId: schoolController.selectedSchool.value!.id,
                      classId: selectedClass!.id,
                      sectionId: selectedSection?.id,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.primary, foregroundColor: Colors.white),
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // 3. Clean up the controller instance to prevent memory leak issues when dialog exits
      //searchCtrl.dispose();
    });
  }

  void _showEditPeriodDialog(String day, int period) {
    if (schoolController.selectedSchool.value != null) schoolController.loadTeachers();
    String existingSubject = '';
    String? existingTeacherId;
    String? existingStartTime;
    String? existingEndTime;
    if (timetableController.timetables.isNotEmpty) {
      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final daySchedule = weeklySchedule.firstWhereOrNull((ws) => ws['day'] == day);
      if (daySchedule != null) {
        final periods = daySchedule['periods'] as List? ?? [];
        final periodData = periods.firstWhereOrNull((p) => p['periodNumber'] == period);
        if (periodData != null) {
          existingSubject = periodData['subjectName'] ?? '';
          existingStartTime=periodData['startTime']??'';
          existingEndTime=periodData['endTime']??'';
          final teacherData = periodData['teacherId'];
          if (teacherData is Map) existingTeacherId = teacherData['_id'];
        }
      }
    }
    final startTimeController = TextEditingController(text: existingStartTime);
    final endTimeController = TextEditingController(text: existingEndTime);
    final subjectController = TextEditingController(text: existingSubject);
    final searchCtrl = TextEditingController();
    String? localTeacherId = existingTeacherId;

    // Initialize and filter teachers reactively
    final filteredTeachers = <Map<String, dynamic>>[].obs;
    filteredTeachers.value = schoolController.teachers;

    // Add the listener ONCE out here, so it does not re-register on every StatefulBuilder setState
    searchCtrl.addListener(() {
      final query = searchCtrl.text.toLowerCase();
      filteredTeachers.value = schoolController.teachers
          .where((t) => (t['userName'] as String).toLowerCase().contains(query))
          .toList();
    });

    Get.dialog(
      StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
            title: Text('Edit Period\n$day — Period $period', style: const TextStyle(fontSize: 15)),
            content: SizedBox(
              width: 300,
              // 1. SingleChildScrollView shields the column from shrinking or breaking when the keyboard rises
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(subjectController, 'Subject Name', context),
                    const SizedBox(height: 12),

// ✅ Time range row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Start Time',
                              prefixIcon: const Icon(Icons.access_time, color: _DS.primary, size: 18),
                              filled: true,
                              fillColor: _DS.surfaceAlt,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(_DS.radiusSm)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                startTimeController.text =
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'End Time',
                              prefixIcon: const Icon(Icons.access_time_filled, color: _DS.primary, size: 18),
                              filled: true,
                              fillColor: _DS.surfaceAlt,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(_DS.radiusSm)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                endTimeController.text =
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    _field(searchCtrl, 'Search Teacher', context),
                    const SizedBox(height: 8),

                    // 2. Bound the inner scrolling list explicitly so it stays compact
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        // Uses slightly tighter box constraints on small devices when keyboard pops up
                        maxHeight: MediaQuery.of(context).viewInsets.bottom > 0 ? 140 : 220,
                      ),
                      child: Obx(() => ListView.builder(
                        shrinkWrap: true,
                        // Allow list view to scroll inside if it overflows its constraint bar
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        itemCount: filteredTeachers.length,
                        itemBuilder: (context, index) {
                          final teacher = filteredTeachers[index];
                          final isSelected = localTeacherId == teacher['_id'];
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: _DS.primarySoft,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: isSelected ? _DS.primary : _DS.primarySoft,
                                child: Icon(Icons.person,
                                    color: isSelected ? Colors.white : _DS.primary,
                                    size: 14)),
                            title: Text(teacher['userName'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 13)),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: _DS.primary, size: 16)
                                : null,
                            onTap: () => dialogSetState(() => localTeacherId = teacher['_id']),
                          );
                        },
                      )),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
              if (ApiPermissions.hasApiAccess(
                  currentUserRole, 'DELETE /api/timetable/deleteperiod'))
                TextButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar('Success', 'Period deleted',
                        backgroundColor: _DS.success, colorText: Colors.white);
                  },
                  child: const Text('Delete', style: TextStyle(color: _DS.danger)),
                ),
              ElevatedButton(
                onPressed: () async {
                  if (subjectController.text.trim().isEmpty) {
                    Get.snackbar('Error', 'Please enter a subject',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  if (localTeacherId == null) {
                    Get.snackbar('Error', 'Please select a teacher',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  if (schoolController.selectedSchool.value == null || selectedClass == null) {
                    Get.snackbar('Error', 'School and class must be selected',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  if (timetableController.timetables.isEmpty) {
                    Get.snackbar('Error', 'No timetable found',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }

                  final timetable = timetableController.timetables.first;
                  final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
                  final daySchedule = weeklySchedule.firstWhereOrNull((ws) => ws['day'] == day);

                  if (daySchedule == null) {
                    Get.snackbar('Error', 'Day not found',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  final dayId = daySchedule['_id'] as String?;
                  if (dayId == null) {
                    Get.snackbar('Error', 'Invalid timetable data',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }

                  Get.back();
                  final success = await timetableController.updatePeriod(
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                    weeklyScheduleId: dayId,
                    day: day,
                    periodData: {
                      'periodNumber': period,
                      'subjectName': subjectController.text.trim(),
                      'teacherId': localTeacherId,
                       'startTime': startTimeController.text,
                       'endTime': endTimeController.text,
                    },
                  );
                  if (success) {
                    await timetableController.getAllTimetables(
                      schoolId: schoolController.selectedSchool.value!.id,
                      classId: selectedClass!.id,
                      sectionId: selectedSection?.id,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.primary, foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // Clean up controllers when dialog is completely dismissed to prevent memory leaks
      //subjectController.dispose();
      //searchCtrl.dispose();
    });
  }
}