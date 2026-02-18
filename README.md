# School Management Application

A comprehensive Flutter-based school management system with role-based access control, supporting multiple schools and various administrative functions.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [User Roles & Permissions](#user-roles--permissions)
- [Key Modules](#key-modules)
- [State Management](#state-management)
- [API Integration](#api-integration)
- [Theme & Styling](#theme--styling)
- [Development Guidelines](#development-guidelines)

## 🎯 Overview

This is a multi-tenant school management application built with Flutter and GetX. It provides comprehensive management tools for schools including student management, attendance tracking, fee management, communications, and more.

## ✨ Features

### Core Features
- **Multi-School Support** - Manage multiple schools from a single application
- **Role-Based Access Control (RBAC)** - Fine-grained permissions for different user roles
- **Subscription Management** - Module-based subscription system
- **Responsive Design** - Optimized for mobile, tablet, and desktop
- **Offline Support** - Local data caching with Hive
- **Real-time Updates** - Live data synchronization

### Functional Modules
- Student Management
- Attendance Tracking
- Fee Management
- Timetable Management
- Homework Management
- Communications (Announcements, Notifications)
- Clubs & Activities
- Accounting & Finance
- Reports & Analytics
- Profile Management

## 🏗️ Architecture

### Design Pattern
- **MVC Pattern** with GetX
- **Repository Pattern** for data layer
- **Service Layer** for business logic
- **Dependency Injection** via GetX

### Tech Stack
- **Framework**: Flutter 3.x
- **State Management**: GetX
- **Local Storage**: Hive
- **HTTP Client**: Dio
- **Routing**: GetX Navigation
- **UI Components**: Material Design 3

## 📁 Project Structure

```
lib/
├── app/
│   ├── controllers/          # Global controllers
│   │   ├── school_controller.dart
│   │   ├── student_controller.dart
│   │   ├── attendance_controller.dart
│   │   └── ...
│   │
│   ├── core/                 # Core utilities
│   │   ├── constants/        # App constants
│   │   ├── icons/           # Custom icons
│   │   ├── rbac/            # Role-based access control
│   │   ├── theme/           # App theme & styling
│   │   └── widgets/         # Reusable widgets
│   │
│   ├── data/                # Data layer
│   │   ├── models/          # Data models
│   │   ├── providers/       # API providers
│   │   └── services/        # Services (API, Storage)
│   │
│   ├── modules/             # Feature modules
│   │   ├── auth/           # Authentication
│   │   ├── home/           # Home/Dashboard
│   │   ├── students/       # Student management
│   │   ├── attendance/     # Attendance tracking
│   │   ├── communications/ # Announcements
│   │   ├── clubs/          # Clubs & Activities
│   │   ├── accounting/     # Finance & Accounting
│   │   └── ...
│   │
│   ├── routes/             # App routing
│   │   └── app_routes.dart
│   │
│   ├── views/              # Shared views
│   │   ├── homework_management_view.dart
│   │   ├── timetable_management_view.dart
│   │   └── ...
│   │
│   └── widgets/            # Shared widgets
│       ├── gradient_card.dart
│       └── ...
│
└── main.dart              # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd school_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   - Update `lib/app/core/constants/api_constants.dart`
   - Set your backend API URL

4. **Run the app**
   ```bash
   flutter run
   ```

### Environment Setup

Create a `.env` file (if needed):
```
API_BASE_URL=https://your-api-url.com
```

## 👥 User Roles & Permissions

### Available Roles
1. **Correspondent** - Full system access, multi-school management
2. **Principal** - School-level administration
3. **Teacher** - Class and student management
4. **Accountant** - Financial operations
5. **Parent** - View child information
6. **Student** - View personal information

### Permission System
Located in `lib/app/core/rbac/api_rbac.dart`

```dart
// Example permission check
if (ApiPermissions.hasApiAccess(userRole, 'POST /api/students/create')) {
  // Show create student button
}
```

### Key Permission Methods
- `hasApiAccess(role, endpoint)` - Check API endpoint access
- `hasPermission(permission)` - Check specific permission
- `isSchoolReadOnly(role)` - Check if role can select schools
- `hasSectionAccess(role)` - Check section-level access

## 📦 Key Modules

### 1. Authentication (`modules/auth/`)
- Login/Logout
- Token management
- User session handling
- Role-based routing

**Key Files:**
- `controllers/auth_controller.dart` - Auth state management
- `views/login_view.dart` - Login UI

### 2. Student Management (`modules/students/`)
- Student CRUD operations
- Bulk student upload
- Student profiles
- Class/Section assignment

**Key Files:**
- `controllers/students_controller.dart`
- `views/students_view.dart`

### 3. Attendance (`modules/attendance/`)
- Daily attendance marking
- Attendance reports
- Leave management
- Attendance analytics

**Key Files:**
- `controllers/attendance_controller.dart`
- `views/attendance_view.dart`

### 4. Fee Management (`modules/accounting/`)
- Fee structure setup
- Fee collection
- Payment tracking
- Financial reports

**Key Files:**
- `controllers/fee_structure_controller.dart`
- `views/fee_management_view.dart`

### 5. Communications (`modules/communications/`)
- Announcements
- Notifications
- Role-based messaging
- File attachments

**Key Files:**
- `controllers/announcement_controller.dart`
- `views/announcements_view.dart`

### 6. Clubs & Activities (`modules/clubs/`)
- Club management
- Activity scheduling
- Member management
- Event organization

**Key Files:**
- `controllers/clubs_controller.dart`
- `views/clubs_activities_view.dart`

### 7. Homework Management (`views/homework_management_view.dart`)
- Assignment creation
- File attachments
- Submission tracking
- Class/Section filtering

### 8. Timetable Management (`views/timetable_management_view.dart`)
- Weekly schedule
- Period management
- Teacher assignment
- Class timetables

## 🔄 State Management

### GetX Controllers

**Global Controllers** (in `app/controllers/`)
- `SchoolController` - School data & selection
- `StudentController` - Student operations
- `AttendanceController` - Attendance tracking
- `AnnouncementController` - Communications

**Usage Example:**
```dart
// Get controller instance
final schoolController = Get.find<SchoolController>();

// Access reactive data
Obx(() => Text(schoolController.selectedSchool.value?.name ?? ''))

// Call methods
await schoolController.getAllSchools();
```

### Reactive Variables
```dart
// Observable
final selectedSchool = Rxn<School>();

// Observable list
final students = <Student>[].obs;

// Observable primitive
final isLoading = false.obs;
```

## 🌐 API Integration

### API Service (`data/services/api_service.dart`)

```dart
final apiService = Get.find<ApiService>();

// GET request
final response = await apiService.get('/api/students');

// POST request
final response = await apiService.post('/api/students', data: studentData);

// PUT request
final response = await apiService.put('/api/students/$id', data: updateData);

// DELETE request
final response = await apiService.delete('/api/students/$id');
```

### API Constants (`core/constants/api_constants.dart`)
```dart
class ApiConstants {
  static const String baseUrl = 'https://your-api.com';
  static const String studentsEndpoint = '/api/students';
  // ... other endpoints
}
```

### Error Handling
```dart
try {
  final response = await apiService.get('/api/students');
  // Handle success
} on DioException catch (e) {
  // Handle API errors
  Get.snackbar('Error', e.response?.data['message'] ?? 'Something went wrong');
}
```

## 🎨 Theme & Styling

### App Theme (`core/theme/app_theme.dart`)

**Colors:**
```dart
AppTheme.primaryBlue      // Main brand color
AppTheme.primaryText      // Text color
AppTheme.cardBackground   // Card background
AppTheme.appBackground    // App background
```

**Gradients:**
```dart
AppTheme.primaryGradient     // Main gradient
AppTheme.appBarGradient      // AppBar gradient
AppTheme.mathSoftGradient    // Subject-specific gradients
AppTheme.biologySoftGradient
AppTheme.geographySoftGradient
```

**Usage:**
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient,
    borderRadius: BorderRadius.circular(AppTheme.radius),
  ),
)
```

### Custom Widgets (`core/widgets/`)

**GradientCard:**
```dart
GradientCard(
  gradient: AppTheme.primaryGradient,
  child: Text('Content'),
)
```

**ResponsiveWrapper:**
```dart
ResponsiveWrapper(
  child: YourWidget(),
)
```

## 💻 Development Guidelines

### Code Style
- Follow Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused

### Widget Organization
```dart
class MyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
  
  Widget _buildAppBar() { /* ... */ }
  Widget _buildBody() { /* ... */ }
}
```

### Controller Pattern
```dart
class MyController extends GetxController {
  // Reactive variables
  final items = <Item>[].obs;
  final isLoading = false.obs;
  
  // Lifecycle
  @override
  void onInit() {
    super.onInit();
    loadData();
  }
  
  // Methods
  Future<void> loadData() async {
    isLoading.value = true;
    try {
      // Load data
    } finally {
      isLoading.value = false;
    }
  }
}
```

### Navigation
```dart
// Navigate to new screen
Get.to(() => DetailView());

// Navigate with arguments
Get.to(() => DetailView(), arguments: {'id': '123'});

// Named routes
Get.toNamed('/students');

// Go back
Get.back();
```

### Dependency Injection
```dart
// Register controller
Get.put(MyController());

// Lazy load controller
Get.lazyPut(() => MyController());

// Find controller
final controller = Get.find<MyController>();
```

### Error Handling
```dart
try {
  await someOperation();
} catch (e) {
  Get.snackbar(
    'Error',
    e.toString(),
    backgroundColor: Colors.red,
    colorText: Colors.white,
  );
}
```

### Loading States
```dart
Obx(() {
  if (controller.isLoading.value) {
    return CircularProgressIndicator();
  }
  return YourContent();
})
```

### Empty States
```dart
if (items.isEmpty) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.inbox, size: 64),
        Text('No items found'),
      ],
    ),
  );
}
```

## 🔧 Common Tasks

### Adding a New Module

1. Create module structure:
   ```
   lib/app/modules/my_module/
   ├── controllers/
   │   └── my_controller.dart
   ├── views/
   │   └── my_view.dart
   └── bindings/
       └── my_binding.dart
   ```

2. Create controller:
   ```dart
   class MyController extends GetxController {
     // Implementation
   }
   ```

3. Create view:
   ```dart
   class MyView extends GetView<MyController> {
     // Implementation
   }
   ```

4. Add route in `routes/app_routes.dart`

### Adding API Endpoint

1. Add endpoint constant in `api_constants.dart`
2. Add permission in `api_rbac.dart`
3. Create service method in controller
4. Handle response and errors

### Adding New Permission

1. Update `api_rbac.dart`:
   ```dart
   static const Map<String, List<String>> rolePermissions = {
     'teacher': [
       'STUDENTS:READ',
       'STUDENTS:CREATE',
       // Add new permission
     ],
   };
   ```

2. Check permission in UI:
   ```dart
   if (authController.hasPermission('MY_PERMISSION')) {
     // Show feature
   }
   ```

## 📱 Responsive Design

### Screen Size Detection
```dart
final screenSize = MediaQuery.of(context).size;
final isTablet = screenSize.width > 600;
final isLandscape = screenSize.width > screenSize.height;
```

### Adaptive Layouts
```dart
Padding(
  padding: EdgeInsets.all(isTablet ? 24 : 16),
  child: Text(
    'Title',
    style: TextStyle(fontSize: isTablet ? 24 : 20),
  ),
)
```

## 🐛 Debugging

### Enable Debug Logs
```dart
// In main.dart
void main() {
  // Enable GetX logs
  Get.log = print;
  runApp(MyApp());
}
```

### Common Issues

**Issue: Controller not found**
```dart
// Solution: Ensure controller is registered
Get.put(MyController());
```

**Issue: State not updating**
```dart
// Solution: Use .obs and Obx()
final count = 0.obs;  // Make it observable
Obx(() => Text('$count'))  // Wrap in Obx
```

## 📄 License

[Add your license information here]

## 👨‍💻 Contributors

[Add contributor information here]

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Contact: [your-email@example.com]

---

**Last Updated:** December 2024
**Version:** 1.0.0
