class Club {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String schoolId;
  final String category;
  final String coordinator;
  final String? meetingDay;
  final String? meetingTime;
  final String location;
  final int memberCount;
  final int maxMembers;
  final String? classId;
  final String? thumbnailUrl;
  final String? className;
  final List<String>? studentIds;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.schoolId,
    required this.category,
    required this.coordinator,
    this.meetingDay,
    this.meetingTime,
    required this.location,
    required this.memberCount,
    required this.maxMembers,
    this.classId,
    this.thumbnailUrl,
    this.className,
    this.studentIds,
  });

  // Computed properties
  bool get isFull => memberCount >= maxMembers;
  double get occupancyRate => maxMembers > 0 ? memberCount / maxMembers : 0.0;

  factory Club.fromJson(Map<String, dynamic> json) {
    // Handle classId which can be either a string or an object
    String? classId;
    String? className;
    if (json['classId'] is String) {
      classId = json['classId'];
    } else if (json['classId'] is Map<String, dynamic>) {
      classId = json['classId']['_id'];
      className = json['classId']['name'];
    }
    
    // Handle studentId which can be a list of strings or objects
    List<String>? studentIds;
    if (json['studentId'] != null) {
      final studentData = json['studentId'];
      if (studentData is List) {
        studentIds = studentData.map((item) {
          if (item is String) return item;
          if (item is Map<String, dynamic>) return item['_id']?.toString() ?? '';
          return item.toString();
        }).where((id) => id.isNotEmpty).toList();
      }
    }
    
    return Club(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      schoolId: json['schoolId'] ?? '',
      category: json['category'] ?? 'Academic',
      coordinator: json['coordinator'] ?? '',
      meetingDay: json['meetingDay'],
      meetingTime: json['meetingTime'],
      location: json['location'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      maxMembers: json['maxMembers'] ?? 30,
      classId: classId,
      thumbnailUrl: json['thumbnail']?['url'],
      className: className,
      studentIds: studentIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'schoolId': schoolId,
      'category': category,
      'coordinator': coordinator,
      'meetingDay': meetingDay,
      'meetingTime': meetingTime,
      'location': location,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'classId': classId,
      'thumbnail': thumbnailUrl != null ? {'url': thumbnailUrl} : null,
      'studentId': studentIds,
    };
  }

  Club copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    String? schoolId,
    String? category,
    String? coordinator,
    String? meetingDay,
    String? meetingTime,
    String? location,
    int? memberCount,
    int? maxMembers,
    String? classId,
    String? thumbnailUrl,
    String? className,
    List<String>? studentIds,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schoolId: schoolId ?? this.schoolId,
      category: category ?? this.category,
      coordinator: coordinator ?? this.coordinator,
      meetingDay: meetingDay ?? this.meetingDay,
      meetingTime: meetingTime ?? this.meetingTime,
      location: location ?? this.location,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      classId: classId ?? this.classId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      className: className ?? this.className,
      studentIds: studentIds ?? this.studentIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Club && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}