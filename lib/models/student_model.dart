class Student {
  final String id;
  final String? srId;
  final String? name;
  final String? studentImage;
  final String? currentClassId;
  final String? currentSectionId;
  final bool isActive;
  final String? schoolId;
  final String? classId;
  final String? sectionId;
  final String? newOld;
  List<String>? clubs; // Make clubs mutable
  
  // Mandatory fields
  final String? gender;
  final String? dob;
  final String? educationNumber;
  final String? motherName;
  final String? fatherName;
  final String? guardianName;
  final String? aadhaarNumber;
  final String? aadhaarName;
  final String? address;
  final String? pincode;
  final String? mobileNumber;
  final String? alternateMobile;
  final String? email;
  final String? motherTongue;
  final String? socialCategory;
  final String? minorityGroup;
  final String? bpl;
  final String? aay;
  final String? ews;
  final String? cwsn;
  final String? impairments;
  final String? indian;
  final String? outOfSchool;
  final String? mainstreamedDate;
  final String? disabilityCert;
  final String? disabilityPercent;
  final String? bloodGroup;
  
  // Non-mandatory fields
  final String? facilitiesProvided;
  final String? facilitiesForCWSN;
  final String? screenedForSLD;
  final String? sldType;
  final String? studentType;
  final String? screenedForASD;
  final String? screenedForADHD;
  final String? isGiftedOrTalented;
  final String? participatedInCompetitions;
  final String? participatedInActivities;
  final String? canHandleDigitalDevices;
  final String? heightInCm;
  final String? weightInKg;
  final String? distanceToSchool;
  final String? parentEducationLevel;
  final String? admissionNumber;
  final String? admissionDate;
  final String? rollNumber;
  final String? mediumOfInstruction;
  final String? languagesStudied;
  final String? academicStream;
  final String? subjectsStudied;
  final String? statusInPreviousYear;
  final String? gradeStudiedLastYear;
  final String? enrolledUnder;
  final String? previousResult;
  final String? marksObtainedPercentage;
  final String? daysAttendedLastYear;

  // Computed properties for compatibility
  String get studentName => name ?? 'N/A';
  Map<String, dynamic>? get mandatory => {
    'gender': gender,
    'dob': dob,
    'educationNumber': educationNumber,
    'motherName': motherName,
    'fatherName': fatherName,
    'guardianName': guardianName,
    'aadhaarNumber': aadhaarNumber,
    'aadhaarName': aadhaarName,
    'address': address,
    'pincode': pincode,
    'mobileNumber': mobileNumber,
    'alternateMobile': alternateMobile,
    'email': email,
    'motherTongue': motherTongue,
    'socialCategory': socialCategory,
    'minorityGroup': minorityGroup,
    'bpl': bpl,
    'aay': aay,
    'ews': ews,
    'cwsn': cwsn,
    'impairments': impairments,
    'indian': indian,
    'outOfSchool': outOfSchool,
    'mainstreamedDate': mainstreamedDate,
    'disabilityCert': disabilityCert,
    'disabilityPercent': disabilityPercent,
    'bloodGroup': bloodGroup,
  };

  Student({
    required this.id,
    this.srId,
    this.name,
    this.studentImage,
    this.currentClassId,
    this.currentSectionId,
    this.isActive = true,
    this.schoolId,
    this.classId,
    this.sectionId,
    this.newOld,
    this.clubs, // Add clubs parameter
    this.gender,
    this.dob,
    this.educationNumber,
    this.motherName,
    this.fatherName,
    this.guardianName,
    this.aadhaarNumber,
    this.aadhaarName,
    this.address,
    this.pincode,
    this.mobileNumber,
    this.alternateMobile,
    this.email,
    this.motherTongue,
    this.socialCategory,
    this.minorityGroup,
    this.bpl,
    this.aay,
    this.ews,
    this.cwsn,
    this.impairments,
    this.indian,
    this.outOfSchool,
    this.mainstreamedDate,
    this.disabilityCert,
    this.disabilityPercent,
    this.bloodGroup,
    this.facilitiesProvided,
    this.facilitiesForCWSN,
    this.screenedForSLD,
    this.sldType,
    this.studentType,
    this.screenedForASD,
    this.screenedForADHD,
    this.isGiftedOrTalented,
    this.participatedInCompetitions,
    this.participatedInActivities,
    this.canHandleDigitalDevices,
    this.heightInCm,
    this.weightInKg,
    this.distanceToSchool,
    this.parentEducationLevel,
    this.admissionNumber,
    this.admissionDate,
    this.rollNumber,
    this.mediumOfInstruction,
    this.languagesStudied,
    this.academicStream,
    this.subjectsStudied,
    this.statusInPreviousYear,
    this.gradeStudiedLastYear,
    this.enrolledUnder,
    this.previousResult,
    this.marksObtainedPercentage,
    this.daysAttendedLastYear,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final mandatory = json['mandatory'] as Map<String, dynamic>? ?? {};
    final nonMandatory = json['nonMandatory'] as Map<String, dynamic>? ?? {};

    return Student(
      id: json['_id']?.toString() ?? '',
      srId: json['srId']?.toString(),
      name: json['studentName']?.toString(),
      studentImage: json['studentImage']?.toString(),
      currentClassId: _extractId(json['currentClassId']),
      currentSectionId: _extractId(json['currentSectionId']),
      isActive: json['isActive'] ?? true,
      schoolId: json['schoolId']?.toString(),
      classId: _extractId(json['currentClassId']) ?? _extractId(json['classId']),
      sectionId: _extractId(json['currentSectionId']) ?? _extractId(json['sectionId']),
      newOld: json['newOld']?.toString(),
      clubs: json['clubs'] != null ? List<String>.from(json['clubs']) : null, // Parse clubs array
      
      // Mandatory fields
      gender: mandatory['gender']?.toString(),
      dob: mandatory['dob']?.toString(),
      educationNumber: mandatory['educationNumber']?.toString(),
      motherName: mandatory['motherName']?.toString(),
      fatherName: mandatory['fatherName']?.toString(),
      guardianName: mandatory['guardianName']?.toString(),
      aadhaarNumber: mandatory['aadhaarNumber']?.toString(),
      aadhaarName: mandatory['aadhaarName']?.toString(),
      address: mandatory['address']?.toString(),
      pincode: mandatory['pincode']?.toString(),
      mobileNumber: mandatory['mobileNumber']?.toString(),
      alternateMobile: mandatory['alternateMobile']?.toString(),
      email: mandatory['email']?.toString(),
      motherTongue: mandatory['motherTongue']?.toString(),
      socialCategory: mandatory['socialCategory']?.toString(),
      minorityGroup: mandatory['minorityGroup']?.toString(),
      bpl: mandatory['bpl']?.toString(),
      aay: mandatory['aay']?.toString(),
      ews: mandatory['ews']?.toString(),
      cwsn: mandatory['cwsn']?.toString(),
      impairments: mandatory['impairments']?.toString(),
      indian: mandatory['indian']?.toString(),
      outOfSchool: mandatory['outOfSchool']?.toString(),
      mainstreamedDate: mandatory['mainstreamedDate']?.toString(),
      disabilityCert: mandatory['disabilityCert']?.toString(),
      disabilityPercent: mandatory['disabilityPercent']?.toString(),
      bloodGroup: mandatory['bloodGroup']?.toString(),
      
      // Non-mandatory fields
      facilitiesProvided: nonMandatory['facilitiesProvided']?.toString(),
      facilitiesForCWSN: nonMandatory['facilitiesForCWSN']?.toString(),
      screenedForSLD: nonMandatory['screenedForSLD']?.toString(),
      sldType: nonMandatory['sldType']?.toString(),
      studentType: nonMandatory['studentType']?.toString(),
      screenedForASD: nonMandatory['screenedForASD']?.toString(),
      screenedForADHD: nonMandatory['screenedForADHD']?.toString(),
      isGiftedOrTalented: nonMandatory['isGiftedOrTalented']?.toString(),
      participatedInCompetitions: nonMandatory['participatedInCompetitions']?.toString(),
      participatedInActivities: nonMandatory['participatedInActivities']?.toString(),
      canHandleDigitalDevices: nonMandatory['canHandleDigitalDevices']?.toString(),
      heightInCm: nonMandatory['heightInCm']?.toString(),
      weightInKg: nonMandatory['weightInKg']?.toString(),
      distanceToSchool: nonMandatory['distanceToSchool']?.toString(),
      parentEducationLevel: nonMandatory['parentEducationLevel']?.toString(),
      admissionNumber: nonMandatory['admissionNumber']?.toString(),
      admissionDate: nonMandatory['admissionDate']?.toString(),
      rollNumber: nonMandatory['rollNumber']?.toString(),
      mediumOfInstruction: nonMandatory['mediumOfInstruction']?.toString(),
      languagesStudied: nonMandatory['languagesStudied']?.toString(),
      academicStream: nonMandatory['academicStream']?.toString(),
      subjectsStudied: nonMandatory['subjectsStudied']?.toString(),
      statusInPreviousYear: nonMandatory['statusInPreviousYear']?.toString(),
      gradeStudiedLastYear: nonMandatory['gradeStudiedLastYear']?.toString(),
      enrolledUnder: nonMandatory['enrolledUnder']?.toString(),
      previousResult: nonMandatory['previousResult']?.toString(),
      marksObtainedPercentage: nonMandatory['marksObtainedPercentage']?.toString(),
      daysAttendedLastYear: nonMandatory['daysAttendedLastYear']?.toString(),
    );
  }

  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['_id']?.toString() ?? value['id']?.toString();
    }
    if (value is List) {
      // Handle case where value is a list - take first element if it exists
      if (value.isNotEmpty && value.first is String) {
        return value.first as String;
      }
      if (value.isNotEmpty && value.first is Map<String, dynamic>) {
        final firstItem = value.first as Map<String, dynamic>;
        return firstItem['_id']?.toString() ?? firstItem['id']?.toString();
      }
      return null;
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentName': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'fatherName': fatherName,
      'schoolId': schoolId,
      'classId': classId,
      'sectionId': sectionId,
      'rollNumber': rollNumber,
      'dob': dob,
      'address': address,
    };
  }

  @override
  String toString() {
    return 'Student(id: $id, name: ${name ?? 'N/A'}, rollNumber: ${rollNumber ?? 'N/A'}, schoolId: ${schoolId ?? 'N/A'})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
