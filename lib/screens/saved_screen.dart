import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../models/saved_item.dart';
import '../utils/url_launcher_helper.dart';
import '../utils/theme.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('saved');
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved / Bookmarks'),
        ),
        body: const Center(
          child: Text('Please log in to view saved items'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved / Bookmarks'),
      ),
      body: StreamBuilder(
        stream: firebaseService.getSavedItems(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved items yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark jobs, internships, guides, and roadmaps\nto find them easily later',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Group items by type
          final allItems = snapshot.data!;
          final jobs = allItems.where((item) => item.type == 'job').toList();
          final internships = allItems.where((item) => item.type == 'internship').toList();
          final roadmaps = allItems.where((item) => item.type == 'roadmap').toList();
          final guides = allItems.where((item) => item.type == 'guide').toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (jobs.isNotEmpty) _buildGroupSection('Saved Jobs', jobs, Icons.work),
                if (internships.isNotEmpty) _buildGroupSection('Saved Internships', internships, Icons.school),
                if (roadmaps.isNotEmpty) _buildGroupSection('Saved Roadmaps', roadmaps, Icons.route),
                if (guides.isNotEmpty) _buildGroupSection('Saved Guides', guides, Icons.book),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupSection(String title, List<SavedItem> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildSavedItemCard(item)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSavedItemCard(SavedItem item) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    IconData typeIcon;
    Color typeColor;

    switch (item.type) {
      case 'job':
        typeIcon = Icons.work;
        typeColor = AppTheme.primaryColor;
        break;
      case 'internship':
        typeIcon = Icons.school;
        typeColor = AppTheme.successColor;
        break;
      case 'guide':
        typeIcon = Icons.book;
        typeColor = AppTheme.warningColor;
        break;
      case 'roadmap':
        typeIcon = Icons.route;
        typeColor = const Color(0xFFBB86FC);
        break;
      default:
        typeIcon = Icons.bookmark;
        typeColor = AppTheme.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (item.logo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.logo!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 48,
                    height: 48,
                    color: AppTheme.surfaceColor,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, size: 24, color: typeColor),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, size: 24, color: typeColor),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(item.type.toUpperCase()),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                        backgroundColor: typeColor.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(item.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (item.link != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_browser),
                    onPressed: () async {
                      await UrlLauncherHelper.launchURL(item.link!);
                    },
                    color: AppTheme.primaryColor,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await _showDeleteConfirmation();
                    if (confirmed) {
                      await firebaseService.removeSavedItem(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Item removed from saved')),
                      );
                    }
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: const Text(
                'Are you sure you want to remove this item from saved?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
