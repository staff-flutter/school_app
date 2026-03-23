import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/controllers/auth_controller.dart';

/// UI RBAC Helper for controlling frontend visibility and behavior based on roles
class UiRbacHelper {
  static String get currentUserRole {
    try {
      final authController = Get.find<AuthController>();
      return authController.user.value?.role?.toLowerCase() ?? '';
    } catch (e) {
      return '';
    }
  }

  static String? get currentUserSchoolId {
    try {
      final authController = Get.find<AuthController>();
      return authController.user.value?.schoolId;
    } catch (e) {
      return null;
    }
  }

  /// School Dropdown Control
  static bool get canSelectSchool => ApiPermissions.canSelectSchool(currentUserRole);
  static bool get isSchoolReadOnly => ApiPermissions.isSchoolReadOnly(currentUserRole);

  /// Section Access Control
  static bool get hasSectionAccess => ApiPermissions.hasSectionAccess(currentUserRole);

  /// Build school dropdown or read-only field based on role
  static Widget buildSchoolField({
    required String? selectedSchoolId,
    required List<Map<String, dynamic>> schools,
    required Function(String?) onChanged,
    String label = 'School',
    bool isRequired = true,
  }) {
    if (isSchoolReadOnly) {
      // Read-only field for non-correspondent roles
      final schoolName = schools.firstWhereOrNull(
        (s) => s['_id'] == (selectedSchoolId ?? currentUserSchoolId),
      )?['name'] ?? 'N/A';
      
      return TextFormField(
        initialValue: schoolName,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        enabled: false,
        style: TextStyle(color: Colors.black87),
      );
    }

    // Dropdown for correspondent
    return DropdownButtonFormField<String>(
      value: selectedSchoolId,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: schools.map((school) {
        return DropdownMenuItem<String>(
          value: school['_id'],
          child: Text(school['name'] ?? ''),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired ? (value) => value == null ? 'Please select a school' : null : null,
    );
  }

  /// Build class dropdown (filtered by user's assigned classes if applicable)
  static Widget buildClassDropdown({
    required String? selectedClassId,
    required List<Map<String, dynamic>> classes,
    required Function(String?) onChanged,
    String label = 'Class',
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedClassId,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: classes.map((cls) {
        return DropdownMenuItem<String>(
          value: cls['_id'],
          child: Text(cls['name'] ?? ''),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired ? (value) => value == null ? 'Please select a class' : null : null,
    );
  }

  /// Build section dropdown (only if role has section access)
  static Widget? buildSectionDropdown({
    required String? selectedSectionId,
    required List<Map<String, dynamic>> sections,
    required Function(String?) onChanged,
    String label = 'Section',
    bool isRequired = false,
  }) {
    if (!hasSectionAccess) return null;

    return DropdownButtonFormField<String>(
      value: selectedSectionId,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: sections.map((section) {
        return DropdownMenuItem<String>(
          value: section['_id'],
          child: Text(section['name'] ?? ''),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired ? (value) => value == null ? 'Please select a section' : null : null,
    );
  }

  /// Conditionally show widget based on API access
  static Widget? showIfHasAccess(String apiKey, Widget child) {
    return ApiPermissions.hasApiAccess(currentUserRole, apiKey) ? child : null;
  }

  /// Conditionally show button based on API access
  static Widget? showButtonIfHasAccess({
    required String apiKey,
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
    bool isPrimary = true,
  }) {
    if (!ApiPermissions.hasApiAccess(currentUserRole, apiKey)) return null;

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: isPrimary ? null : ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[600],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: isPrimary ? null : ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[600],
      ),
    );
  }

  /// Get default school ID for non-correspondent roles
  static String? getDefaultSchoolId() {
    return isSchoolReadOnly ? currentUserSchoolId : null;
  }

  /// Check if user can perform action on specific API
  static bool canPerformAction(String apiKey) {
    return ApiPermissions.hasApiAccess(currentUserRole, apiKey);
  }

  /// Show action buttons based on role permissions
  static List<Widget> buildActionButtons({
    String? createApi,
    String? updateApi,
    String? deleteApi,
    VoidCallback? onCreate,
    VoidCallback? onUpdate,
    VoidCallback? onDelete,
  }) {
    final buttons = <Widget>[];

    if (createApi != null && onCreate != null && canPerformAction(createApi)) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: Icon(Icons.add),
          label: Text('Create'),
        ),
      );
    }

    if (updateApi != null && onUpdate != null && canPerformAction(updateApi)) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onUpdate,
          icon: Icon(Icons.edit),
          label: Text('Update'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
      );
    }

    if (deleteApi != null && onDelete != null && canPerformAction(deleteApi)) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onDelete,
          icon: Icon(Icons.delete),
          label: Text('Delete'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      );
    }

    return buttons;
  }
}
