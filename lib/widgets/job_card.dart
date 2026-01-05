import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/job.dart';
import '../models/saved_item.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../screens/job_detail_sheet.dart';

/// Job card widget with fade-in logo animation and location tooltip
class JobCard extends StatefulWidget {
  final Job job;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveJob(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save items')),
      );
      return;
    }

    final savedItem = SavedItem(
      id: '',
      type: 'job',
      name: '${widget.job.title} at ${widget.job.company}',
      link: widget.job.applyLink,
      logo: widget.job.logo,
      timestamp: DateTime.now(),
    );

    firebaseService.saveItem(currentUser.uid, savedItem).then((_) {
      analytics.logItemSaved('job', widget.job.title);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job saved successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: widget.onTap ?? () => showJobDetailSheet(context, widget.job),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo with Fade Animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildLogo(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.job.company,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location with Tooltip
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildLocationDisplay(),
                  ),
                ],
              ),

              // Tech Tags
              if (widget.job.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.job.tags
                      .take(3)
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                  ),
                            ),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 8),

              // View Details Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build logo with cached network image
  Widget _buildLogo() {
    if (widget.job.logo != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.job.logo!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          maxHeightDiskCache: 150,
          maxWidthDiskCache: 150,
          memCacheWidth: 150,
          memCacheHeight: 150,
          placeholder: (context, url) => Container(
            width: 56,
            height: 56,
            color: AppTheme.surfaceColor,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business, size: 28),
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.business, size: 28),
    );
  }

  /// Build location display with tooltip for multiple locations
  Widget _buildLocationDisplay() {
    if (widget.job.hasMultipleLocations) {
      return Tooltip(
        message: widget.job.locations.join(', '),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        textStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        preferBelow: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.job.locationDisplay,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 14,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ],
        ),
      );
    }

    return Text(
      widget.job.locationDisplay,
      style: Theme.of(context).textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
