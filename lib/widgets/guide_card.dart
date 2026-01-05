import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

import '../models/guide.dart';
import '../utils/theme.dart';

/// Guide card widget with color-coded vertical bar and bookmark progress ring
///
/// Features:
/// - Color-coded 4px vertical bar on left edge (red for YouTube, green for Article, blue for Link)
/// - Circular progress ring showing completion percentage
/// - Type badge with icon
/// - Preview tap opens bottom sheet
class GuideCard extends StatelessWidget {
  final Guide guide;
  final VoidCallback onTap;
  final double progress; // 0.0 to 1.0

  const GuideCard({
    super.key,
    required this.guide,
    required this.onTap,
    this.progress = 0.0,
  });

  /// Get type badge color based on guide type
  Color _getTypeBadgeColor() {
    switch (guide.type.toLowerCase()) {
      case 'youtube':
        return Colors.red.shade700;
      case 'article':
        return Colors.green.shade700;
      case 'link':
        return Colors.blue.shade700;
      default:
        return AppTheme.textSecondary;
    }
  }

  /// Get type icon based on guide type
  IconData _getTypeIcon() {
    switch (guide.type.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_outline;
      case 'article':
        return Icons.article_outlined;
      case 'link':
        return Icons.link;
      default:
        return Icons.book_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeBadgeColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Color-coded vertical bar indicator (4px width)
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    typeColor,
                    typeColor.withOpacity(0.6),
                  ],
                ),
              ),
            ),

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Logo + Title + Progress Ring
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        if (guide.logo != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: guide.logo!,
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
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.book,
                                  size: 28,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.book,
                              size: 28,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        const SizedBox(width: 12),

                        // Title and Category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guide.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Category Chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  guide.category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Bookmark Progress Ring
                        if (progress > 0)
                          _buildProgressRing(progress)
                        else
                          // Type Badge (shown when no progress)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTypeIcon(),
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  guide.type,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      guide.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Stats Row
                    Row(
                      children: [
                        // Steps Count
                        if (guide.steps.isNotEmpty) ...[
                          Icon(
                            Icons.format_list_numbered,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${guide.steps.length} steps',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Topics Count
                        if (guide.topics.isNotEmpty) ...[
                          Icon(
                            Icons.local_offer_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${guide.topics.length} topics',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Views
                        Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          guide.viewsDisplay,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),

                    // Topics Preview (first 3)
                    if (guide.topics.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: guide.topics
                            .take(3)
                            .map((topic) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          AppTheme.textSecondary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    topic,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ))
                            .toList(),
                      ),
                      if (guide.topics.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '+${guide.topics.length - 3} more',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build circular progress ring showing bookmark completion
  Widget _buildProgressRing(double progress) {
    final percentage = (progress * 100).toInt();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: progress,
              color: AppTheme.successColor,
              backgroundColor: AppTheme.surfaceColor,
            ),
          ),
        ),
        // Percentage text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            Icon(
              Icons.bookmark,
              size: 14,
              color: AppTheme.successColor,
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom painter for circular progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius - 2, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
