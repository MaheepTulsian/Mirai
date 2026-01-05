import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

import '../models/roadmap.dart';
import '../utils/theme.dart';

class RoadmapCard extends StatelessWidget {
  final Roadmap roadmap;
  final VoidCallback onTap;
  final double progress; // 0.0 to 1.0 representing completion progress

  const RoadmapCard({
    super.key,
    required this.roadmap,
    required this.onTap,
    this.progress = 0.0,
  });

  /// Get difficulty color based on level
  Color _getDifficultyColor() {
    switch (roadmap.level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }

  /// Calculate estimated time based on milestones (2 weeks per milestone)
  String _getEstimatedTime() {
    final weeks = roadmap.milestones.length * 2;
    if (weeks < 4) {
      return '$weeks weeks';
    } else {
      final months = (weeks / 4).ceil();
      return '$months months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProgress = progress > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual Roadmap Mini-Graph with Progress Arc
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Arc (if started)
                      if (hasProgress)
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CustomPaint(
                            painter: _ProgressArcPainter(
                              progress: progress,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      // Mini Roadmap Graph
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomPaint(
                          painter: _RoadmapGraphPainter(
                            milestoneCount: roadmap.milestones.length,
                            completedCount: (roadmap.milestones.length * progress).floor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          roadmap.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            roadmap.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Text(
                          roadmap.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              // Badges Row: Time, Difficulty, Milestones
              Row(
                children: [
                  // Time Estimate Badge
                  _buildBadge(
                    context,
                    Icons.access_time,
                    _getEstimatedTime(),
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  // Difficulty Badge
                  _buildBadge(
                    context,
                    Icons.signal_cellular_alt,
                    roadmap.level,
                    _getDifficultyColor(),
                  ),
                  const SizedBox(width: 8),
                  // Milestones Count Badge
                  _buildBadge(
                    context,
                    Icons.location_on_outlined,
                    '${roadmap.milestones.length} milestones',
                    AppTheme.textSecondary,
                  ),
                ],
              ),
              // Progress Indicator (if started)
              if (hasProgress) ...[
                const SizedBox(height: 12),
                _buildProgressIndicator(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build badge widget
  Widget _buildBadge(
      BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressIndicator(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for circular progress arc
class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
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
  bool shouldRepaint(_ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Custom painter for roadmap mini-graph visualization
class _RoadmapGraphPainter extends CustomPainter {
  final int milestoneCount;
  final int completedCount;

  _RoadmapGraphPainter({
    required this.milestoneCount,
    required this.completedCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (milestoneCount == 0) return;

    final nodeCount = math.min(milestoneCount, 5); // Show max 5 nodes
    final spacing = size.height / (nodeCount + 1);

    // Draw connecting lines first (behind nodes)
    final linePaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodeCount - 1; i++) {
      final y1 = spacing * (i + 1);
      final y2 = spacing * (i + 2);
      final x1 = size.width * 0.3 + (i % 2 == 0 ? 0 : 10);
      final x2 = size.width * 0.3 + ((i + 1) % 2 == 0 ? 0 : 10);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }

    // Draw milestone nodes
    for (int i = 0; i < nodeCount; i++) {
      final y = spacing * (i + 1);
      final x = size.width * 0.3 + (i % 2 == 0 ? 0 : 10);
      final isCompleted = i < completedCount;

      // Node circle
      final nodePaint = Paint()
        ..color = isCompleted ? AppTheme.successColor : AppTheme.primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 6, nodePaint);

      // Checkmark for completed nodes
      if (isCompleted) {
        final checkPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final path = Path()
          ..moveTo(x - 3, y)
          ..lineTo(x - 1, y + 2)
          ..lineTo(x + 3, y - 2);

        canvas.drawPath(path, checkPaint);
      }
    }

    // Draw "+" indicator if more milestones exist
    if (milestoneCount > 5) {
      final y = spacing * (nodeCount + 0.5);
      final x = size.width * 0.3 + 5;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '+${milestoneCount - 5}',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
    }
  }

  @override
  bool shouldRepaint(_RoadmapGraphPainter oldDelegate) {
    return oldDelegate.milestoneCount != milestoneCount ||
        oldDelegate.completedCount != completedCount;
  }
}
