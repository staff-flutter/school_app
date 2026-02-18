# Communications Module Implementation

## Overview
This module implements a role-based communications system for the school management app with announcements, messages, and notifications.

## Role-Based Access Control

### Permissions
- **NOTICES_CREATE**: Can create, edit, and delete announcements
- **NOTICES_VIEW**: Can view announcements

### Role Access Matrix
| Role | Create Announcements | View Announcements | Send Messages | View Messages |
|------|---------------------|-------------------|---------------|---------------|
| correspondent | ✅ | ✅ | ✅ | ✅ |
| administrator | ✅ | ✅ | ✅ | ✅ |
| principal | ✅ | ✅ | ✅ | ✅ |
| viceprincipal | ❌ | ✅ | ❌ | ✅ |
| teacher | ❌ | ✅ | ❌ | ✅ |
| accountant | ❌ | ✅ | ❌ | ✅ |
| parent | ❌ | ✅ | ❌ | ✅ |

## API Endpoints Used

### Announcements
- `POST /api/announcement/create` - Create announcement (API-49)
- `GET /api/announcement/getall` - Get all announcements (API-50)
- `PUT /api/announcement/update/:id` - Update announcement (API-52)
- `DELETE /api/announcement/delete/:id` - Delete announcement (API-55)

## Files Structure

```
lib/app/modules/communications/
├── controllers/
│   └── communications_controller.dart    # Main controller with role-based logic
├── views/
│   ├── communications_view.dart          # Complex view with AnnouncementController
│   └── simple_communications_view.dart   # Simplified view using CommunicationsController
├── bindings/
│   └── communications_binding.dart       # Dependency injection
└── README.md                            # This file
```

## Key Features

### CommunicationsController
- Role-based permission checking
- API integration for announcements
- Dummy data for messages and notifications (for demo)
- Proper error handling and loading states
- Permission-based UI controls

### SimpleCommunicationsView
- Clean, tabbed interface
- Role-based action buttons
- Permission wrapper for create functionality
- Responsive design with proper loading states

## Usage

1. **Import the controller**:
```dart
import '../controllers/communications_controller.dart';
```

2. **Use permission wrapper for restricted actions**:
```dart
PermissionWrapper(
  permission: Permission.NOTICES_CREATE,
  child: FloatingActionButton(
    onPressed: () => _showCreateAnnouncementDialog(context),
    child: const Icon(Icons.add),
  ),
)
```

3. **Check permissions in controller**:
```dart
bool get canCreateAnnouncements => ApiGuard.checkPermission(Permission.NOTICES_CREATE);
```

## Target Audience Mapping

The system automatically maps user roles to appropriate target audiences:
- **parent** → "Parents"
- **student** → "Students" 
- **teacher** → "Teachers"
- **principal/viceprincipal/administrator** → "Staff"
- **correspondent/accountant** → "All"

## Error Handling

- Permission denied errors are caught and displayed as snackbars
- API errors are logged and fallback to dummy data for demo purposes
- Loading states are properly managed

## Future Enhancements

1. Real-time notifications using WebSocket
2. Message threading and replies
3. File attachments for messages
4. Push notifications
5. Message search and filtering
6. Read receipts and delivery status