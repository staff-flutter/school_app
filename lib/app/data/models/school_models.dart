class School {
  final String id;
  final String name;
  final String? email;
  final String? phoneNo;
  final String? address;
  final String? currentAcademicYear;
  final Map<String, dynamic>? logo;
  final String? schoolCode;

  School({
    required this.id,
    required this.name,
    this.email,
    this.phoneNo,
    this.address,
    this.currentAcademicYear,
    this.logo,
    this.schoolCode,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phoneNo: json['phoneNo'],
      address: json['address'],
      currentAcademicYear: json['currentAcademicYear'],
      logo: json['logo'],
      schoolCode: json['schoolCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phoneNo': phoneNo,
      'address': address,
      'currentAcademicYear': currentAcademicYear,
      'logoUrl': logo,
      'schoolCode': schoolCode
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is School && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SchoolClass {
  final String id;
  final String name;
  final int order;
  final bool hasSections;
  final String? classTeacherId;
  final String schoolId;

  SchoolClass({
    required this.id,
    required this.name,
    required this.order,
    required this.hasSections,
    this.classTeacherId,
    required this.schoolId,
  });

  int get studentCount => 0; // Placeholder - should be calculated from actual student data

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    try {
      return SchoolClass(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        order: json['order'] ?? 0,
        hasSections: json['hasSections'] ?? false,
        classTeacherId: _getTeacherId(json['classTeacherId']),
        schoolId: _getId(json['schoolId']),
      );
    } catch (e) {

      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'order': order,
      'hasSections': hasSections,
      'classTeacherId': classTeacherId,
      'schoolId': schoolId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolClass && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Section {
  final String id;
  final String name;
  final String classId;
  final String schoolId;
  final String? classTeacherId;
  final String? roomNumber;
  final int? capacity;
  final String? className;
  final List<Map<String, dynamic>>? classTeachers;

  Section({
    required this.id,
    required this.name,
    required this.classId,
    required this.schoolId,
    this.classTeacherId,
    this.roomNumber,
    this.capacity,
    this.className,
    this.classTeachers,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      classId: _getId(json['classId']),
      schoolId: _getId(json['schoolId']),
      classTeacherId: _getTeacherId(json['classTeacherId']),
      roomNumber: json['roomNumber']?.toString(),
      capacity: json['capacity'],
      className: json['classId'] is Map<String, dynamic> ? json['classId']['name']?.toString() : null,
      classTeachers: _getClassTeachers(json['classTeacherId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'classId': classId,
      'schoolId': schoolId,
      'classTeacherId': classTeacherId,
      'roomNumber': roomNumber,
      'capacity': capacity,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Section && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

String _getId(dynamic data) {
  if (data == null) return '';
  if (data is String) {
    return data;
  } else if (data is Map<String, dynamic>) {
    return data['_id']?.toString() ?? '';
  } else if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is String) return first;
    if (first is Map<String, dynamic>) return first['_id']?.toString() ?? '';
  }
  return data.toString();
}

String? _getTeacherId(dynamic data) {
  if (data == null) return null;
  if (data is String && data.isNotEmpty) {
    return data;
  } else if (data is List) {
    if (data.isEmpty) return null;
    final first = data.first;
    if (first is String) return first;
    if (first is Map<String, dynamic>) return first['_id']?.toString();
    return first?.toString();
  } else if (data is Map<String, dynamic>) {
    return data['_id']?.toString();
  }
  return data.toString();
}

String? _getClassName(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) {
    return data['name']?.toString();
  }
  return null;
}

List<Map<String, dynamic>>? _getClassTeachers(dynamic data) {
  if (data == null) return null;
  if (data is List) {
    return data.cast<Map<String, dynamic>>();
  }
  return null;
}

class StudentRecord {
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;
  final String? rollNumber;

  StudentRecord({
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.rollNumber,
  });

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    final classData = json['classId'];
    final sectionData = json['sectionId'];
    
    return StudentRecord(
      classId: _getId(classData),
      className: _getClassName(classData),
      sectionId: _getId(sectionData),
      sectionName: _getClassName(sectionData),
      rollNumber: json['rollNumber']?.toString(),
    );
  }
}

