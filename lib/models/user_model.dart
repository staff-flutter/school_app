class ProfileImage {
  final String? type;
  final String? key;
  final String? url;
  final String? originalName;
  final String? uploadedAt;
  final String? id;

  ProfileImage({
    this.type,
    this.key,
    this.url,
    this.originalName,
    this.uploadedAt,
    this.id,
  });

  factory ProfileImage.fromJson(dynamic json) {
    if (json is! Map) return ProfileImage();
    final m = Map<String, dynamic>.from(json);
    return ProfileImage(
      type: m['type']?.toString(),
      key: m['key']?.toString(),
      url: m['url']?.toString(),
      originalName: m['originalName']?.toString(),
      uploadedAt: m['uploadedAt']?.toString(),
      id: m['_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'key': key,
    'url': url,
    'originalName': originalName,
    'uploadedAt': uploadedAt,
    '_id': id,
  };
}

class User {
  final String id;
  final String email;
  final String userName;
  final String phoneNo;
  final String role;
  final String? schoolCode;
  final dynamic schoolId; // Can be String or Map<String, dynamic>
  final String? schoolName;
  final bool isPlatformAdmin;
  final List<String> studentId;
  final List<Map<String, dynamic>> assignments;
  final ProfileImage? profileImage;

  User({
    required this.id,
    required this.email,
    required this.userName,
    required this.phoneNo,
    required this.role,
    this.schoolCode,
    this.schoolId,
    this.schoolName,
    this.isPlatformAdmin = false,
    List<String>? studentId,
    List<Map<String, dynamic>>? assignments,
    this.profileImage,
  })  : studentId = studentId ?? [],
        assignments = assignments ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      userName: json['userName'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      role: json['role'] ?? '',
      schoolCode: json['schoolCode'],
      schoolId: json['schoolId'], // Keep as dynamic
      schoolName: json['schoolName'],
      isPlatformAdmin: json['isPlatformAdmin'] ?? false,
      studentId: List<String>.from(json['studentId'] ?? []),
      assignments:
      List<Map<String, dynamic>>.from(json['assignments'] ?? []),
      profileImage: json['profileImage'] != null
          ? ProfileImage.fromJson(json['profileImage'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'userName': userName,
      'phoneNo': phoneNo,
      'role': role,
      'schoolCode': schoolCode,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'isPlatformAdmin': isPlatformAdmin,
      'studentId': studentId,
      'assignments': assignments,
      'profileImage': profileImage?.toJson(),
    };
  }
}