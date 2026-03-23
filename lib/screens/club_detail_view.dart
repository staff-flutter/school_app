import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:school_app/models/club_model.dart';
import 'package:school_app/controllers/club_detail_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';

class ClubDetailView extends StatefulWidget {
  const ClubDetailView({super.key});

  @override
  State<ClubDetailView> createState() => _ClubDetailViewState();
}

class _ClubDetailViewState extends State<ClubDetailView> {
  final controller = Get.put(ClubDetailController());

  @override
  void initState() {
    super.initState();
    final clubId = Get.arguments as String;
    controller.fetchClubDetails(clubId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.club.value == null) {
            return const Center(child: Text('Club not found'));
          }

          final club = controller.club.value!;
          final authController = Get.find<AuthController>();
          final isParent = authController.user.value?.role?.toLowerCase() == 'parent';

          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              
              return CustomScrollView(
                slivers: [
                  _buildSliverAppBar(club, constraints),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(club, context),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildDescription(club, context),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildInfoCards(club, context, isTablet),
                          SizedBox(height: isTablet ? 32 : 24),
                          if (!isParent) _buildMembershipSection(club, context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildSliverAppBar(Club club, BoxConstraints constraints) {
    final isTablet = constraints.maxWidth > 600;
    
    return SliverAppBar(
      expandedHeight: isTablet ? 300 : 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: club.thumbnailUrl != null
            ? GestureDetector(
                onTap: () => _showFullScreenImage(club.thumbnailUrl!),
                child: Hero(
                  tag: 'club_image_${club.id}',
                  child: CachedNetworkImage(
                    imageUrl: club.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => _buildDefaultImage(),
                  ),
                ),
              )
            : _buildDefaultImage(),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
      ),
      child: const Center(
        child: Icon(Icons.groups, size: 80, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(Club club, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                club.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: club.isActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                club.isActive ? 'Active' : 'Inactive',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          club.category,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Club club, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 12),
            Text(
              club.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(Club club, BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Club Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 24 : 20,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Tablet/Desktop: 2x2 grid
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.person,
                          title: 'Coordinator',
                          value: club.coordinator,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.schedule,
                          title: 'Meeting',
                          value: '${club.meetingDay}\n${club.meetingTime}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.location_on,
                          title: 'Location',
                          value: club.location,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.class_,
                          title: 'Class',
                          value: club.className ?? 'Not assigned',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Created',
                          value: _formatDate(club.createdAt),
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Mobile: 2x2 grid with smaller spacing
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.person,
                          title: 'Coordinator',
                          value: club.coordinator,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.schedule,
                          title: 'Meeting',
                          value: '${club.meetingDay}\n${club.meetingTime}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.location_on,
                          title: 'Location',
                          value: club.location,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.class_,
                          title: 'Class',
                          value: club.className ?? 'Not assigned',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Created',
                          value: _formatDate(club.createdAt),
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipSection(Club club, BuildContext context) {
    final authController = Get.find<AuthController>();
    final isParent = authController.user.value?.role?.toLowerCase() == 'parent';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Membership',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!isParent) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members: ${club.memberCount}/${club.maxMembers}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '${(club.occupancyRate * 100).toInt()}% Full',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: club.occupancyRate,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  club.occupancyRate > 0.8 ? Colors.red : Colors.blue,
                ),
              ),
            ] else ...[
              // For parents, show a message instead of member count
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contact the club coordinator for membership information',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: club.isFull ? null : () => _joinClub(club),
                icon: const Icon(Icons.add),
                label: Text(club.isFull ? 'Club Full' : 'Join Club'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Hero(
            tag: 'club_image_${controller.club.value!.id}',
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
      transition: Transition.fade,
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _joinClub(Club club) {
    Get.snackbar(
      'Join Club',
      'Feature coming soon!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
