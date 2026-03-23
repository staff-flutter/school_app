class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String className;
  final String section;
  final String feeStatus;
  final String parentName;
  final String phone;
  final String email;
  final String address;
  final String admissionDate;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.className,
    required this.section,
    required this.feeStatus,
    required this.parentName,
    required this.phone,
    required this.email,
    required this.address,
    required this.admissionDate,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      className: json['className'] ?? json['class'] ?? '',
      section: json['section'] ?? '',
      feeStatus: json['feeStatus'] ?? 'Unknown',
      parentName: json['parentName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      admissionDate: json['admissionDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rollNumber': rollNumber,
      'className': className,
      'section': section,
      'parentName': parentName,
      'phone': phone,
      'email': email,
      'address': address,
      'admissionDate': admissionDate,
    };
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String author;
  final String date;
  final String priority;
  final String targetAudience;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    required this.priority,
    required this.targetAudience,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? json['description'] ?? '',
      author: json['author'] ?? json['createdBy'] ?? 'System',
      date: json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      priority: json['priority'] ?? 'Medium',
      targetAudience: json['targetAudience'] ?? 'All',
    );
  }
}

