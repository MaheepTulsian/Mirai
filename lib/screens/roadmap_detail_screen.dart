import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/roadmap.dart';
import '../models/saved_item.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../utils/url_launcher_helper.dart';
import '../utils/theme.dart';

class RoadmapDetailScreen extends StatelessWidget {
  final Roadmap roadmap;

  const RoadmapDetailScreen({super.key, required this.roadmap});

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(roadmap.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => _saveRoadmap(context),
          ),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roadmap.name,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            roadmap.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(label: Text(roadmap.level)),
                              Chip(label: Text(roadmap.category)),
                            ],
                          ),
                          if (roadmap.externalReferenceLink != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await UrlLauncherHelper.launchURL(
                                      roadmap.externalReferenceLink!);
                                },
                                icon: const Icon(Icons.link),
                                label: const Text('External Reference'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Milestones
                  Text(
                    'Milestones',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roadmap.milestones.length,
                    itemBuilder: (context, index) {
                      final milestone = roadmap.milestones[index];
                      return _buildMilestoneCard(
                          context, milestone, index + 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildMilestoneCard(
      BuildContext context, Milestone milestone, int number) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    milestone.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              milestone.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),

            // Topics
            if (milestone.topics.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.topic_outlined, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Topics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: milestone.topics
                    .map((topic) => Chip(
                          label: Text(topic),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ))
                    .toList(),
              ),
            ],

            // Course Link
            if (milestone.courseLink != null && milestone.courseLink!.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => UrlLauncherHelper.launchURL(milestone.courseLink!),
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: const Text('Recommended Course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
              ),
            ],

            // Read Links
            if (milestone.readLinks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.article_outlined, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Read',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...milestone.readLinks.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => UrlLauncherHelper.launchURL(entry.value),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Article ${entry.key + 1}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Icon(Icons.open_in_new, size: 14, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],

            // Watch Links
            if (milestone.watchLinks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.play_circle_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    'Watch',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...milestone.watchLinks.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => UrlLauncherHelper.launchURL(entry.value),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.video_library, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Video ${entry.key + 1}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Icon(Icons.open_in_new, size: 14, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],

            // Build Projects
            if (milestone.buildProjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.construction, size: 18, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Build Projects',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: milestone.buildProjects.map((project) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              project,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveRoadmap(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    final userId = authService.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save items')),
      );
      return;
    }

    final savedItem = SavedItem(
      id: '',
      type: 'roadmap',
      name: roadmap.name,
      link: roadmap.externalReferenceLink,
      logo: roadmap.logo,
      timestamp: DateTime.now(),
    );

    firebaseService.saveItem(userId, savedItem).then((_) {
      analytics.logItemSaved('roadmap', roadmap.name);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roadmap saved successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $error')),
      );
    });
  }
}
