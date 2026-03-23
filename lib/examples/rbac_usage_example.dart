// Example: Student Records View with RBAC
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/widgets/rbac_wrapper.dart';
import 'package:school_app/core/permissions/api_permission_system.dart';

class StudentRecordsViewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Records')),
      body: Column(
        children: [
          // Only show if user can view student records
          RBACWrapper(
            apiEndpoint: Permission.STUDENTS_VIEW,
            child: Text('Student List'),
          ),
          
          // Only show concession update button for allowed roles
          // Administrator will NOT see this button (403 error fixed)
          RBACWrapper(
            apiEndpoint: Permission.CONCESSION_APPLY_OVERRIDE,
            child: ElevatedButton(
              onPressed: () => _updateConcessionValue(),
              child: Text('Update Concession Value'),
            ),
            fallback: Text('You cannot update concession values'),
          ),
          
          // Only show fee collection for accountant/correspondent
          RBACWrapper(
            apiEndpoint: Permission.FEES_COLLECT,
            child: ElevatedButton(
              onPressed: () => _collectFee(),
              child: Text('Collect Fee'),
            ),
          ),
          
          // Module-level access check
          ModuleWrapper(
            moduleName: 'expenses',
            child: Card(
              child: ListTile(
                title: Text('Expenses Module'),
                subtitle: Text('Manage school expenses'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateConcessionValue() {
    
  }

  void _collectFee() {
    
  }
}

// RBAC Summary by Role:
/*
CORRESPONDENT: Full access to all modules and APIs
ADMINISTRATOR: 
  - VISIBLE: Users, Classes, Sections, Students, Announcements, Clubs, Attendance
  - HIDDEN: Schools, Expenses, Fee Collection, Financial operations
  - CANNOT: Update concession values (API-36 restriction)

PRINCIPAL:
  - VISIBLE: Students (read), Announcements, Clubs, Financial reports (read)
  - CAN: Update concession values, Revert receipts
  - CANNOT: Create/Delete, Fee collection

ACCOUNTANT:
  - VISIBLE: Students (finance), Fee Collection, Expenses, Financial modules
  - HIDDEN: Attendance, Announcements, Academic modules
  - CAN: Collect fees, Manage expenses, Update concessions

PARENT:
  - VISIBLE: Dashboard, Announcements (read), Clubs (read), Own children attendance
  - HIDDEN: All admin/financial modules
  - READ-ONLY: Everything

TEACHER:
  - VISIBLE: Attendance (mark/view), Students (class-scoped), Announcements (read)
  - CAN: Mark attendance for assigned classes
  - CANNOT: Financial operations, Admin functions
*/