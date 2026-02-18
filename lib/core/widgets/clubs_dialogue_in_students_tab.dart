// Redesigned version of _showStudentClubDialog and _showBulkClubDialog
// Modern, colorful (non-blue), responsive, reusable dialog UI

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// -------------------- GRADIENTS --------------------
const LinearGradient gradientPrimary = LinearGradient(
  colors: [Color(0xFFFF6A00), Color(0xFFEE0979)], // orange -> pink
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient gradientActive = LinearGradient(
  colors: [Color(0xFF11998E), Color(0xFF38EF7D)], // teal -> green
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient gradientInactive = LinearGradient(
  colors: [Color(0xFFF7F7F7), Color(0xFFEDEDED)],
);

// -------------------- REUSABLE DIALOG SHELL --------------------
class GradientDialog extends StatelessWidget {
  final Widget header;
  final Widget body;
  final Widget footer;

  const GradientDialog({
    super.key,
    required this.header,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 600
            ? constraints.maxWidth * 0.95
            : 520.0;

        return SafeArea(
          child: Center(
            child: Container(
              width: width,
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  Expanded(child: body),
                  footer,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// -------------------- HEADER --------------------
Widget dialogHeader({
  required String title,
  required String subtitle,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      gradient: gradientPrimary,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13)),
            ],
          ),
        ),
      ],
    ),
  );
}

// -------------------- CLUB TILE --------------------
Widget clubTile({
  required String name,
  required String description,
  required bool selected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: selected ? gradientActive : gradientInactive,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                        selected ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? Colors.white.withOpacity(0.85)
                            : Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// -------------------- FOOTER --------------------
Widget dialogFooter({
  required VoidCallback onCancel,
  required VoidCallback onSave,
  required bool loading,
}) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: loading ? null : onSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: Ink(
              decoration: const BoxDecoration(
                gradient: gradientPrimary,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: Container(
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
