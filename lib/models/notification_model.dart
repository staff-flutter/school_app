class AppNotification {
  final String id;
  final String schoolId;
  final String type;
  final String title;
  final String message;
  final String? referenceId;
  final String? referenceModel;
  final String? path;
  final List<String> targetAudience;
  final List<String> targetClasses;
  final List<String> targetSections;
  final List<String> targetStudents;
  final String? academicYear;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.schoolId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceModel,
    this.path,
    this.targetAudience = const [],
    this.targetClasses = const [],
    this.targetSections = const [],
    this.targetStudents = const [],
    this.academicYear,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    List<String> _stringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    return AppNotification(
      id: json['_id']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      referenceId: json['referenceId']?.toString(),
      referenceModel: json['referenceModel']?.toString(),
      path: json['path']?.toString(),
      targetAudience: _stringList(json['targetAudience']),
      targetClasses: _stringList(json['targetClasses']),
      targetSections: _stringList(json['targetSections']),
      targetStudents: _stringList(json['targetStudents']),
      academicYear: json['academicYear']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
      isRead: json['isRead'] == true,
    );
  }
}