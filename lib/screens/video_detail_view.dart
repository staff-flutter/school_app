import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/clubs_controller.dart';
import 'package:school_app/widgets/video_player_widget.dart';

class VideoDetailView extends StatefulWidget {
  const VideoDetailView({super.key});

  @override
  State<VideoDetailView> createState() => _VideoDetailViewState();
}

class _VideoDetailViewState extends State<VideoDetailView> {
  final controller = Get.find<ClubsController>();
  late String videoId;
  final selectedVideo = Rxn<RecordedClass>();
  final isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    videoId = Get.arguments as String;
    _loadVideoDetails();
  }

  Future<void> _loadVideoDetails() async {
    
    isLoading.value = true;
    
    try {
      // Find video in existing list first
      final video = controller.recordedClasses.firstWhere(
        (v) => v.id == videoId,
        orElse: () => RecordedClass(
          id: '',
          title: '',
          description: '',
          clubName: '',
          clubId: '',
          category: '',
          level: '',
          thumbnailUrl: '',
          instructor: '',
          uploadDate: '',
          viewCount: 0,
        ),
      );
      
      if (video.id.isNotEmpty) {
        selectedVideo.value = video;

      } else {
        
        Get.snackbar('Error', 'Video not found');
        Get.back();
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load video details');
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          if (isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final video = selectedVideo.value;
          if (video == null) {
            return const Center(
              child: Text(
                'Video not found',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return Column(
            children: [
              // Video Player Section
              Container(
                width: double.infinity,
                color: Colors.black,
                child: video.videoUrl != null && video.videoUrl!.isNotEmpty
                    ? VideoPlayerWidget(
                        videoUrl: video.videoUrl!,
                        title: video.title,
                        autoPlay: false,
                      )
                    : Container(
                        height: 200,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library, 
                                   color: Colors.grey, size: 60),
                              SizedBox(height: 16),
                              Text(
                                'Video not available',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              
              // Video Details Section
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Actions
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                video.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Video Info Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.school,
                                title: 'Club',
                                value: video.clubName,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.category,
                                title: 'Topic',
                                value: video.category,
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
                                icon: Icons.signal_cellular_alt,
                                title: 'Level',
                                value: video.level,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.calendar_today,
                                title: 'Uploaded',
                                value: video.uploadDate,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        
                        if (video.academicYear != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.school_outlined,
                            title: 'Academic Year',
                            value: video.academicYear!,
                            color: Colors.indigo,
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Description
                        if (video.description.isNotEmpty) ...[
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              video.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: video.videoUrl != null 
                                    ? () => _openFullScreen(video)
                                    : null,
                                icon: const Icon(Icons.fullscreen),
                                label: const Text('Full Screen'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _shareVideo(video),
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _openFullScreen(RecordedClass video) {
    if (video.videoUrl != null && video.videoUrl!.isNotEmpty) {
      Get.to(() => FullScreenVideoPlayer(
        videoUrl: video.videoUrl!,
        title: video.title,
      ));
    } else {
      Get.snackbar('Error', 'Video URL not available', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _shareVideo(RecordedClass video) {
    if (video.videoUrl != null && video.videoUrl!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: video.videoUrl!));
      Get.snackbar(
        'Video Link Copied',
        'Video URL has been copied to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Error',
        'Video URL not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}