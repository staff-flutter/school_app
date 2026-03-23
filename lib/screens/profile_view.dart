// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../controllers/school_controller.dart';
// import '../modules/auth/controllers/auth_controller.dart';
// import '../core/widgets/responsive_wrapper.dart';
// import '../data/services/api_service.dart';
//
// /// =================================================
// /// GLASS CARD
// /// =================================================
//
// class GlassCard extends StatelessWidget {
//   final Widget child;
//   final EdgeInsets padding;
//
//   const GlassCard({
//     super.key,
//     required this.child,
//     this.padding = const EdgeInsets.all(18),
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(26),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.05),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//           BoxShadow(
//             color: Colors.white.withOpacity(.9),
//             blurRadius: 10,
//             offset: const Offset(-4, -4),
//           )
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(26),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Container(
//             padding: padding,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(26),
//               color: Colors.white.withOpacity(.75),
//               border: Border.all(color: Colors.white.withOpacity(.7)),
//             ),
//             child: child,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// =================================================
// /// PROFILE VIEW
// /// =================================================
//
// class ProfileView extends GetView<AuthController> {
//   const ProfileView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       controller.refreshUserData();
//       controller.fetchUserSchoolInfo();
//     });
//
//     return Container(
//       color: const Color(0xffF9FAFB),
//       child: ResponsiveWrapper(
//         child: Obx(() {
//           final user = controller.user.value;
//           if (user == null) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           return CustomScrollView(
//             slivers: [
//               _buildTopBar(user),
//
//               SliverPadding(
//                 padding: const EdgeInsets.all(16),
//                 sliver: SliverList(
//                   delegate: SliverChildListDelegate([
//                     _buildProfileHeader(user),
//                     const SizedBox(height: 20),
//
//                     _buildPersonalInfoCard(user),
//                     const SizedBox(height: 20),
//
//                     _buildSchoolInfoCard(user),
//                     const SizedBox(height: 20),
//
//                     if (user.role.toLowerCase() == 'parent' &&
//                         user.studentId != null &&
//                         user.studentId!.isNotEmpty)
//                       _buildChildrenCard(user),
//
//                     const SizedBox(height: 20),
//
//                     _buildSettingsCard(),
//                     const SizedBox(height: 20),
//
//                     _buildLogoutButton(),
//                     const SizedBox(height: 40),
//                   ]),
//                 ),
//               )
//             ],
//           );
//         }),
//       ),
//     );
//   }
//
//   /// =================================================
//   /// TOP BAR
//   /// =================================================
//
//   Widget _buildTopBar(dynamic user) {
//     return SliverAppBar(
//       pinned: true,
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       flexibleSpace: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: GlassCard(
//             child: Row(
//               children: [
//                 const Icon(Icons.person, size: 20),
//                 const SizedBox(width: 10),
//                 const Expanded(
//                   child: Text(
//                     "My Profile",
//                     style:
//                     TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                   ),
//                 ),
//                 _roleChip(user.role),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// =================================================
//   /// PROFILE HEADER
//   /// =================================================
//
//   Widget _buildProfileHeader(dynamic user) {
//     return GlassCard(
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.purple.shade200,
//                   Colors.blue.shade200,
//                 ],
//               ),
//             ),
//             child: CircleAvatar(
//               radius: 42,
//               backgroundColor: Colors.white,
//               child: Text(
//                 user.userName[0].toUpperCase(),
//                 style: const TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.deepPurple),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(user.userName,
//               style:
//               const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
//           const SizedBox(height: 6),
//           _roleChip(user.role),
//         ],
//       ),
//     );
//   }
//
//   /// =================================================
//   /// PERSONAL INFO
//   /// =================================================
//
//   Widget _buildPersonalInfoCard(dynamic user) {
//     return GlassCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _title(Icons.person, "Personal Information"),
//           const SizedBox(height: 12),
//           _infoTile(Icons.email, "Email", user.email),
//           const SizedBox(height: 12),
//           _infoTile(Icons.phone, "Phone", user.phoneNo),
//         ],
//       ),
//     );
//   }
//
//   /// =================================================
//   /// SCHOOL INFO
//   /// =================================================
//
//   Widget _buildSchoolInfoCard(dynamic user) {
//     return Obx(() {
//       final school = controller.userSchool.value;
//       if (school == null) return const SizedBox();
//
//       return GlassCard(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _title(Icons.school, "School Information"),
//             const SizedBox(height: 12),
//             _infoTile(Icons.business, "School", school['name'] ?? "N/A"),
//             if (school['address'] != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 12),
//                 child:
//                 _infoTile(Icons.location_on, "Address", school['address']),
//               ),
//             const SizedBox(height: 12),
//             _buildSocialMediaSection(school),
//           ],
//         ),
//       );
//     });
//   }
//
//   /// =================================================
//   /// CHILDREN
//   /// =================================================
//
//   Widget _buildChildrenCard(dynamic user) {
//     return GlassCard(
//       child: InkWell(
//         onTap: () => Get.toNamed('/my-children'),
//         child: Row(
//           children: [
//             const Icon(Icons.child_care, size: 20),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 "${user.studentId.length} Children Linked",
//                 style: const TextStyle(fontWeight: FontWeight.w600),
//               ),
//             ),
//             const Icon(Icons.arrow_forward_ios, size: 14),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// =================================================
//   /// SETTINGS
//   /// =================================================
//
//   Widget _buildSettingsCard() {
//     return GlassCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _title(Icons.settings, "Settings"),
//           const SizedBox(height: 12),
//           _settingsTile(Icons.privacy_tip, "Privacy Policy",
//                   () => Get.toNamed('/privacy-policy')),
//           _settingsTile(Icons.delete, "Delete Account",
//                   () => Get.toNamed('/delete-account')),
//         ],
//       ),
//     );
//   }
//
//   /// =================================================
//   /// LOGOUT
//   /// =================================================
//
//   Widget _buildLogoutButton() {
//     return GestureDetector(
//       onTap: controller.logout,
//       child: const GlassCard(
//         child: Center(
//           child: Text(
//             "Logout",
//             style: TextStyle(
//                 color: Colors.red,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// =================================================
//   /// SOCIAL MEDIA
//   /// =================================================
//
//   Widget _buildSocialMediaSection(Map school) {
//     final id = school['_id'] ?? school['id'];
//     if (id == null) return const SizedBox();
//
//     return FutureBuilder<Map<String, String?>>(
//       future: _getSocialLinks(id),
//       builder: (_, snap) {
//         if (!snap.hasData) return const SizedBox();
//
//         final links = snap.data!;
//         return Row(
//           children: links.entries
//               .where((e) => e.value != null && e.value!.isNotEmpty)
//               .map((e) => Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: InkWell(
//               onTap: () => _openUrl(e.value!),
//               child: GlassCard(
//                 padding: const EdgeInsets.all(10),
//                 child: Text(e.key[0].toUpperCase()),
//               ),
//             ),
//           ))
//               .toList(),
//         );
//       },
//     );
//   }
//
//   /// =================================================
//   /// COMPONENTS
//   /// =================================================
//
//   Widget _title(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 20),
//         const SizedBox(width: 10),
//         Text(text,
//             style:
//             const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
//       ],
//     );
//   }
//
//   Widget _roleChip(String role) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.7),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(role.toUpperCase(),
//           style: const TextStyle(fontSize: 12)),
//     );
//   }
//
//   Widget _infoTile(IconData icon, String label, String value) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(18),
//         color: Colors.white.withOpacity(.65),
//         border: Border.all(color: Colors.white.withOpacity(.7)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: Colors.deepPurple),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label,
//                   style: const TextStyle(
//                       fontSize: 12, color: Colors.black54)),
//               Text(value,
//                   style: const TextStyle(
//                       fontSize: 14, fontWeight: FontWeight.w600)),
//             ],
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _settingsTile(
//       IconData icon, String title, VoidCallback onTap) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(18),
//         child: Container(
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(18),
//             color: Colors.white.withOpacity(.7),
//             border: Border.all(color: Colors.white.withOpacity(.7)),
//           ),
//           child: Row(
//             children: [
//               Icon(icon, size: 20, color: Colors.deepPurple),
//               const SizedBox(width: 12),
//               Expanded(child: Text(title)),
//               const Icon(Icons.arrow_forward_ios, size: 14)
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// =================================================
//   /// API
//   /// =================================================
//
//   Future<Map<String, String?>> _getSocialLinks(String id) async {
//     try {
//       final api = Get.find<ApiService>();
//       final res =
//       await api.get('/api/school/getschool/socialplatform/$id');
//
//       if (res.data['ok'] == true) {
//         final data = res.data['data']['socialPlatform'];
//         return {
//           'instagram': data['instagram'],
//           'facebook': data['facebook'],
//           'linkedin': data['linkedin'],
//           'youtube': data['youtube'],
//         };
//       }
//       return {};
//     } catch (_) {
//       return {};
//     }
//   }
//
//   void _openUrl(String url) async {
//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:school_app/core/icons/custom_icons.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/constants/api_constants.dart';

class ProfileView extends GetView<AuthController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto-refresh data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshUserData();
      controller.fetchUserSchoolInfo();
    });
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Obx(() {
            final user = controller.user.value;
            if (user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryBlue),
                    const SizedBox(height: 16),
                    Text('Loading profile...', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                _buildModernAppBar(context, isTablet, user),
                SliverPadding(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildProfileHeader(context, isTablet, user),
                      const SizedBox(height: 24),
                      _buildPersonalInfoCard(context, isTablet, user),
                      const SizedBox(height: 20),
                      _buildSchoolInfoCard(context, isTablet, user),
                      if (user.role.toLowerCase() == 'parent' && user.studentId != null && user.studentId!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildChildrenCard(context, isTablet, user),
                      ],
                      const SizedBox(height: 20),
                      _buildSettingsCard(context, isTablet),
                      const SizedBox(height: 24),
                      _buildLogoutButton(context, isTablet),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, bool isTablet, dynamic user) {
    return SliverAppBar(
      expandedHeight: isTablet ? 200 : 160,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.appBarGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD8D5E8).withOpacity(0.6),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.geographySoftGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppTheme.primaryBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Profile',
                              style: TextStyle(
                                color: AppTheme.primaryText,
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Manage your account settings',
                              style: TextStyle(
                                color: AppTheme.subtitleOnWhite,
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.geographySoftGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        collapseMode: CollapseMode.pin,
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isTablet, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: AppTheme.geographySoftGradient,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: isTablet ? 60 : 50,
                backgroundColor: Colors.white,
                child: Text(
                  (user.userName.isNotEmpty ? user.userName[0] : 'U').toUpperCase(),
                  style: TextStyle(
                    fontSize: isTablet ? 48 : 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user.userName,
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.titleOnWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.geographySoftGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, bool isTablet, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.biologySoftGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_outline, color: AppTheme.biologyGreen, size: 24),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleOnWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoTile(Icons.email_outlined, 'Email Address', user.email, isTablet),
            const SizedBox(height: 16),
            _buildModernInfoTile(Icons.phone_outlined, 'Phone Number', user.phoneNo, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolInfoCard(BuildContext context, bool isTablet, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.mathSoftGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.school_outlined, color: AppTheme.mathOrange, size: 24),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  'School Information',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleOnWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              final school = controller.userSchool.value;

              if (school != null) {
                return Column(
                  children: [
                    if (school['logo'] != null && school['logo']['url'] != null)
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _showFullScreenLogo(context, school['logo']['url']),
                              child: Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withOpacity(0.3),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: NetworkImage(school['logo']['url']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 15,
                              right: 0,
                              child: controller.user.value?.role.toLowerCase() == 'correspondent'
                                  ? GestureDetector(
                                onTap: () => _showImagePicker(context, school['_id'] ?? school['id']),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    _buildModernInfoTile(Icons.business_outlined, 'School Name', school['name'] ?? 'N/A', isTablet),
                    if (school['address'] != null && school['address'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildModernInfoTile(Icons.location_on_outlined, 'Address', school['address'], isTablet),
                    ],
                    if (school['email'] != null && school['email'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildModernInfoTile(Icons.email_outlined, 'Contact Email', school['email'], isTablet),
                    ],
                    const SizedBox(height: 16),
                    _buildSocialMediaSection(school, isTablet),
                  ],
                );
              }

              return _buildModernInfoTile(Icons.school_outlined, 'School ID', user.schoolId ?? 'N/A', isTablet);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenCard(BuildContext context, bool isTablet, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => Get.toNamed('/my-children'),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.chemistrySoftGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.child_care, color: AppTheme.chemistryYellow, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Children',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.titleOnWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.studentId!.length} Children Linked',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.subtitleOnWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.chemistryYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.chemistryYellow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.geographySoftGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.settings_outlined, color: AppTheme.geographyBlue, size: 24),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleOnWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettingsTile(Icons.privacy_tip_outlined, 'Privacy Policy', 'View our privacy policy', isTablet, () => Get.toNamed('/privacy-policy')),
            const SizedBox(height: 12),
            _buildSettingsTile(Icons.delete_forever_outlined, 'Delete Account', 'Request account deletion', isTablet, () => Get.toNamed('/delete-account')),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.logout(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoTile(IconData icon, String label, String value, bool isTablet) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.appBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.5 + (value * 0.5),
                        child: Transform.rotate(
                          angle: value * 6.28,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.geographySoftGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: AppTheme.geographyBlue, size: 20),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value.isEmpty ? 'N/A' : value,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.titleOnWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, bool isTablet, [VoidCallback? onTap]) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.appBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap ?? () {},
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 0.1,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.geographySoftGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: AppTheme.geographyBlue, size: 20),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.titleOnWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.subtitleOnWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(value * 2, 0),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppTheme.mutedText,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialMediaSection(Map<String, dynamic> school, bool isTablet) {
    final schoolId = school['_id'] ?? school['id'];
    if (schoolId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, String?>>(
      future: _getSocialMediaLinks(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 6.28,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.share, color: AppTheme.primaryBlue, size: 20),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Social Media',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading social media links...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final socialLinks = snapshot.data!;
        final hasAnyLinks = socialLinks.values.any((link) => link != null && link.isNotEmpty);

        if (!hasAnyLinks) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.share, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Social Media',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (socialLinks['instagram'] != null && socialLinks['instagram']!.isNotEmpty)
                    _buildCustomSocialIcon(CustomIcons.instagramIcon(), () => _openUrl(socialLinks['instagram']!)),
                  if (socialLinks['facebook'] != null && socialLinks['facebook']!.isNotEmpty)
                    _buildCustomSocialIcon(CustomIcons.facebookIcon(), () => _openUrl(socialLinks['facebook']!)),
                  if (socialLinks['linkedin'] != null && socialLinks['linkedin']!.isNotEmpty)
                    _buildCustomSocialIcon(CustomIcons.linkedinIcon(), () => _openUrl(socialLinks['linkedin']!)),
                  if (socialLinks['youtube'] != null && socialLinks['youtube']!.isNotEmpty)
                    _buildCustomSocialIcon(CustomIcons.youtubeIcon(), () => _openUrl(socialLinks['youtube']!)),
                  // Add edit button for correspondent
                  if (controller.user.value?.role.toLowerCase() == 'correspondent')
                    _buildEditSocialMediaButton(schoolId),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildCustomSocialIcon(Widget icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon,
        ),
      ),
    );
  }

  Future<Map<String, String?>> _getSocialMediaLinks(String schoolId) async {
    try {
      final apiService = Get.find<ApiService>();
      final response = await apiService.get('/api/school/getschool/socialplatform/$schoolId');

      if (response.data['ok'] == true) {
        final socialPlatform = response.data['data']['socialPlatform'] as Map<String, dynamic>;
        return {
          'instagram': socialPlatform['instagram'],
          'facebook': socialPlatform['facebook'],
          'linkedin': socialPlatform['linkedin'],
          'youtube': socialPlatform['youtube'],
        };
      }
      return {'instagram': null, 'facebook': null, 'linkedin': null, 'youtube': null};
    } catch (e) {

      return {'instagram': null, 'facebook': null, 'linkedin': null, 'youtube': null};
    }
  }

  void _openUrl(String url) async {
    try {
      // Actually open the URL using url_launcher
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not open link',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open link',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showFullScreenLogo(BuildContext context, String logoUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.9),
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          Navigator.of(context).pop();
                          Get.snackbar(
                            'Error',
                            'Failed to load logo',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePicker(BuildContext context, String schoolId) {
    var schlcontroller = Get.put(SchoolController());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Update School Logo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildImageSourceOption(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          onTap: () {
                            Navigator.pop(context);
                            schlcontroller.pickAndUploadLogo(schoolId);
                          },
                        ),
                        _buildImageSourceOption(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onTap: () {
                            Navigator.pop(context);
                            schlcontroller.pickAndUploadLogo(schoolId);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditSocialMediaButton(String schoolId) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: InkWell(
        onTap: () => _showSocialMediaEditDialog(schoolId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade600],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.edit, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _showSocialMediaEditDialog(String schoolId) {
    final instagramController = TextEditingController();
    final facebookController = TextEditingController();
    final linkedinController = TextEditingController();
    final youtubeController = TextEditingController();
    final isLoading = false.obs;
    final schoolController = Get.put(SchoolController());

    // Load current values
    _getSocialMediaLinks(schoolId).then((links) {
      instagramController.text = links['instagram'] ?? '';
      facebookController.text = links['facebook'] ?? '';
      linkedinController.text = links['linkedin'] ?? '';
      youtubeController.text = links['youtube'] ?? '';
    });

    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.share, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Edit Social Media Links',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildColorfulTextField(
                  controller: instagramController,
                  label: 'Instagram URL',
                  icon: Icons.camera_alt,
                  color: Colors.pink,
                ),
                const SizedBox(height: 16),
                _buildColorfulTextField(
                  controller: facebookController,
                  label: 'Facebook URL',
                  icon: Icons.facebook,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildColorfulTextField(
                  controller: linkedinController,
                  label: 'LinkedIn URL',
                  icon: Icons.business,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 16),
                _buildColorfulTextField(
                  controller: youtubeController,
                  label: 'YouTube URL',
                  icon: Icons.play_circle,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Obx(() => Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade300, Colors.grey.shade400],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Get.back(),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade400, Colors.green.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: isLoading.value ? null : () async {
                              isLoading.value = true;
                              try {
                                // Update each platform individually using SchoolController's updateSocialMedia method
                                final platforms = {
                                  'instagram': instagramController.text.trim(),
                                  'facebook': facebookController.text.trim(),
                                  'linkedin': linkedinController.text.trim(),
                                  'youtube': youtubeController.text.trim(),
                                };

                                for (final entry in platforms.entries) {
                                  await schoolController.updateSocialMedia(schoolId, entry.key, entry.value);
                                }

                                Get.back();
                                Get.snackbar(
                                  'Success',
                                  'Social media links updated successfully',
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  icon: const Icon(Icons.check_circle, color: Colors.white),
                                );
                                // Refresh the profile view
                                controller.fetchUserSchoolInfo();
                              } catch (e) {
                                String errorMessage = 'Failed to update social media links';

                                if (e is DioException && e.response?.data != null) {
                                  // Show exact error message from API
                                  errorMessage = e.response!.data['message'] ?? errorMessage;
                                }

                                Get.snackbar(
                                  'Error',
                                  errorMessage,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                  icon: const Icon(Icons.error, color: Colors.white),
                                );
                              } finally {
                                isLoading.value = false;
                              }
                            },
                            child: Center(
                              child: isLoading.value
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorfulTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Enter $label (leave blank to remove)',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ),
    );
  }


}