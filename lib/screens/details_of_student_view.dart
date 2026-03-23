import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/services/api_service.dart';

class DetailsOfStudentView extends StatefulWidget {
  const DetailsOfStudentView({super.key});

  @override
  State<DetailsOfStudentView> createState() => _DetailsOfStudentViewState();
}

class _DetailsOfStudentViewState extends State<DetailsOfStudentView> {
  final isLoading = true.obs;
  final studentData = <String, dynamic>{}.obs;
  final expandedSections = <String, bool>{
    'mandatory': true,
    'nonMandatory': false,
    'clubs': false,
  }.obs;

  final clubsData = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final args = Get.arguments as Map<String, dynamic>? ?? {};
      final studentId = args['_id'];
      
      if (studentId == null) {
        studentData.value = args;
        isLoading.value = false;
        return;
      }

      final apiService = Get.find<ApiService>();
      final response = await apiService.get('/api/student/get/$studentId');
      
      if (response.data['ok'] == true) {
        final data = response.data['data'];
        studentData.value = {
          ...args,
          'studentImage': data['studentImage'],
          'mandatory': data['mandatory'] ?? {},
          'nonMandatory': data['nonMandatory'] ?? {},
          'clubs': data['clubs'] ?? [],
        };
        
        // Fetch club details
        await _loadClubDetails(data['clubs'] ?? []);
      } else {
        studentData.value = args;
      }
    } catch (e) {
      
      studentData.value = Get.arguments as Map<String, dynamic>? ?? {};
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadClubDetails(List<dynamic> clubIds) async {
    if (clubIds.isEmpty) return;
    
    try {
      final apiService = Get.find<ApiService>();
      final clubs = <Map<String, dynamic>>[];
      
      for (var clubId in clubIds) {
        if (clubId is String) {
          try {
            final response = await apiService.get('/api/club/get/$clubId');
            if (response.data['ok'] == true) {
              clubs.add(response.data['data']);
            }
          } catch (e) {
            
          }
        }
      }
      
      clubsData.value = clubs;
    } catch (e) {
      
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Obx(() => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${studentData['studentName'] ?? 'Student'} Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )),
          ),
        ),
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade50, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              children: [
                _buildProfileCard(isTablet),
                const SizedBox(height: 16),
                _buildCollapsibleSection(
                  'Mandatory Information',
                  Icons.info,
                  LinearGradient(colors: [Colors.purple.shade600, Colors.purple.shade400]),
                  'mandatory',
                  _buildMandatoryInfo(),
                  isTablet,
                ),
                const SizedBox(height: 16),
                _buildCollapsibleSection(
                  'UDISE',
                  Icons.description,
                  LinearGradient(colors: [Colors.orange.shade600, Colors.orange.shade400]),
                  'nonMandatory',
                  _buildNonMandatoryInfo(),
                  isTablet,
                ),
                const SizedBox(height: 16),
                _buildCollapsibleSection(
                  'Club Memberships',
                  Icons.groups,
                  LinearGradient(colors: [Colors.pink.shade600, Colors.pink.shade400]),
                  'clubs',
                  _buildClubsInfo(),
                  isTablet,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileCard(bool isTablet) {
    return Obx(() {
      final studentImage = studentData['studentImage'];
      final imageUrl = studentImage is Map ? studentImage['url'] : null;
      
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade600, Colors.teal.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: imageUrl != null ? () => _showFullImage(imageUrl) : null,
                child: Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  (studentData['studentName'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.teal.shade600,
                                    fontSize: isTablet ? 40 : 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              (studentData['studentName'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.teal.shade600,
                                fontSize: isTablet ? 40 : 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentData['studentName'] ?? 'Unknown Student',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // const SizedBox(height: 8),
                  // _buildInfoChip('ID: ${studentData['srId'] ?? 'N/A'}', Icons.badge),
                  const SizedBox(height: 4),
                  _buildInfoChip('Class: ${studentData['className'] ?? 'N/A'}', Icons.class_),
                  const SizedBox(height: 4),
                  _buildInfoChip('Section: ${studentData['sectionName'] ?? 'N/A'}', Icons.group),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    });
  }

  void _showFullImage(String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection(
    String title,
    IconData icon,
    Gradient gradient,
    String key,
    Widget content,
    bool isTablet,
  ) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => expandedSections[key] = !expandedSections[key]!,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: expandedSections[key]! ? Radius.zero : const Radius.circular(16),
                  bottomRight: expandedSections[key]! ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    expandedSections[key]! ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (expandedSections[key]!)
            Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: content,
            ),
        ],
      ),
    ));
  }

  Widget _buildMandatoryInfo() {
    return Obx(() {
      final mandatory = studentData['mandatory'] ?? {};
      return Column(
        children: [
          _buildInfoRow('Gender', mandatory['gender']),
          _buildInfoRow('Father Name', mandatory['fatherName']),
          _buildInfoRow('Mother Name', mandatory['motherName']),
          _buildInfoRow('Guardian Name', mandatory['guardianName']),
          _buildInfoRow('Mobile Number', mandatory['mobileNumber']),
          _buildInfoRow('Alternate Mobile', mandatory['alternateMobile']),
          _buildInfoRow('Email', mandatory['email']),
          _buildInfoRow('Date of Birth', mandatory['dob']),
          _buildInfoRow('Aadhaar Number', mandatory['aadhaarNumber']),
          _buildInfoRow('Aadhaar Name', mandatory['aadhaarName']),
          _buildInfoRow('Education Number', mandatory['educationNumber']),
          _buildInfoRow('Address', mandatory['address']),
          _buildInfoRow('Pincode', mandatory['pincode']),
          _buildInfoRow('Mother Tongue', mandatory['motherTongue']),
          _buildInfoRow('Social Category', mandatory['socialCategory']),
          _buildInfoRow('Minority Group', mandatory['minorityGroup']),
          _buildInfoRow('BPL', mandatory['bpl']),
          _buildInfoRow('AAY', mandatory['aay']),
          _buildInfoRow('EWS', mandatory['ews']),
          _buildInfoRow('CWSN', mandatory['cwsn']),
          _buildInfoRow('Impairments', mandatory['impairments']),
          _buildInfoRow('Indian', mandatory['indian']),
          _buildInfoRow('Out of School', mandatory['outOfSchool']),
          _buildInfoRow('Mainstreamed Date', mandatory['mainstreamedDate']),
          _buildInfoRow('Disability Certificate', mandatory['disabilityCert']),
          _buildInfoRow('Disability Percent', mandatory['disabilityPercent']),
          _buildInfoRow('Blood Group', mandatory['bloodGroup']),
        ],
      );
    });
  }

  Widget _buildNonMandatoryInfo() {
    return Obx(() {
      final nonMandatory = studentData['nonMandatory'] ?? {};
      return Column(
        children: [
          _buildInfoRow('Facilities Provided', nonMandatory['facilitiesProvided']),
          _buildInfoRow('Facilities for CWSN', nonMandatory['facilitiesForCWSN']),
          _buildInfoRow('Screened for SLD', nonMandatory['screenedForSLD']),
          _buildInfoRow('SLD Type', nonMandatory['sldType']),
          _buildInfoRow('Screened for ASD', nonMandatory['screenedForASD']),
          _buildInfoRow('Screened for ADHD', nonMandatory['screenedForADHD']),
          _buildInfoRow('Gifted/Talented', nonMandatory['isGiftedOrTalented']),
          _buildInfoRow('Participated in Competitions', nonMandatory['participatedInCompetitions']),
          _buildInfoRow('Participated in Activities', nonMandatory['participatedInActivities']),
          _buildInfoRow('Can Handle Digital Devices', nonMandatory['canHandleDigitalDevices']),
          _buildInfoRow('Height (cm)', nonMandatory['heightInCm']),
          _buildInfoRow('Weight (kg)', nonMandatory['weightInKg']),
          _buildInfoRow('Distance to School', nonMandatory['distanceToSchool']),
          _buildInfoRow('Parent Education Level', nonMandatory['parentEducationLevel']),
          _buildInfoRow('Admission Number', nonMandatory['admissionNumber']),
          _buildInfoRow('Admission Date', nonMandatory['admissionDate']),
          _buildInfoRow('Roll Number', nonMandatory['rollNumber']),
          _buildInfoRow('Medium of Instruction', nonMandatory['mediumOfInstruction']),
          _buildInfoRow('Languages Studied', nonMandatory['languagesStudied']),
          _buildInfoRow('Academic Stream', nonMandatory['academicStream']),
          _buildInfoRow('Subjects Studied', nonMandatory['subjectsStudied']),
          _buildInfoRow('Status in Previous Year', nonMandatory['statusInPreviousYear']),
          _buildInfoRow('Grade Studied Last Year', nonMandatory['gradeStudiedLastYear']),
          _buildInfoRow('Enrolled Under', nonMandatory['enrolledUnder']),
          _buildInfoRow('Previous Result', nonMandatory['previousResult']),
          _buildInfoRow('Marks Obtained %', nonMandatory['marksObtainedPercentage']),
          _buildInfoRow('Days Attended Last Year', nonMandatory['daysAttendedLastYear']),
        ],
      );
    });
  }

  Widget _buildClubsInfo() {
    return Obx(() {
      if (clubsData.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.groups_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Not a member of any clubs',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: clubsData.map<Widget>((club) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade50, Colors.pink.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club['name'] ?? 'Unknown Club',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (club['description'] != null)
                        Text(
                          club['description'],
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final displayValue = value?.toString() ?? 'N/A';
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.blue.shade50.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade100.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.label,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade200.withOpacity(0.3),
                ),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
