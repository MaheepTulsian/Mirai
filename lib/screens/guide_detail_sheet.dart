import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import '../models/guide.dart';
import '../models/saved_item.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../utils/url_launcher_helper.dart';
import '../utils/theme.dart';

void showGuideDetailSheet(BuildContext context, Guide guide) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GuideDetailSheet(guide: guide),
  );
}

/// Detailed view of a learning guide shown as a modal bottom sheet
class GuideDetailSheet extends StatefulWidget {
  final Guide guide;

  const GuideDetailSheet({super.key, required this.guide});

  @override
  State<GuideDetailSheet> createState() => _GuideDetailSheetState();
}

class _GuideDetailSheetState extends State<GuideDetailSheet>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  final Set<int> _completedSteps = {}; // Local state for completed steps
  bool _showConfetti = false;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Calculate completion progress (0.0 to 1.0)
  double get _progress {
    if (widget.guide.steps.isEmpty) return 0.0;
    return _completedSteps.length / widget.guide.steps.length;
  }

  /// Check if all steps are completed
  bool get _isFullyCompleted {
    return widget.guide.steps.isNotEmpty &&
        _completedSteps.length == widget.guide.steps.length;
  }

  /// Trigger confetti animation when guide is fully completed
  void _checkAndShowConfetti() {
    if (_isFullyCompleted && !_showConfetti) {
      setState(() => _showConfetti = true);
      _confettiController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _showConfetti = false);
            _confettiController.reset();
          }
        });
      });
    }
  }

  /// Get type badge color
  Color _getTypeBadgeColor() {
    switch (widget.guide.type.toLowerCase()) {
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

  /// Get type icon
  IconData _getTypeIcon() {
    switch (widget.guide.type.toLowerCase()) {
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
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    return Stack(
      children: [
        DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo and Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.guide.logo != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: widget.guide.logo!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 72,
                                    height: 72,
                                    color: AppTheme.surfaceColor,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.book, size: 36),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.book, size: 36),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Type Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTypeBadgeColor(),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getTypeIcon(),
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.guide.type,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Category
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
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
                                      widget.guide.category,
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          widget.guide.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Stats Row
                        Row(
                          children: [
                            if (widget.guide.steps.isNotEmpty) ...[
                              _buildStatChip(
                                Icons.format_list_numbered,
                                '${widget.guide.steps.length} steps',
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (widget.guide.topics.isNotEmpty) ...[
                              _buildStatChip(
                                Icons.local_offer_outlined,
                                '${widget.guide.topics.length} topics',
                              ),
                              const SizedBox(width: 12),
                            ],
                            _buildStatChip(
                              Icons.visibility_outlined,
                              widget.guide.viewsDisplay,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Step Completion Progress Bar
                        if (widget.guide.steps.isNotEmpty) ...[
                          _buildProgressBar(),
                          const SizedBox(height: 20),
                        ],

                        // Description
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.guide.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                              ),
                        ),

                        // Topics
                        if (widget.guide.topics.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Topics Covered',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.guide.topics
                                .map((topic) => Chip(
                                      label: Text(topic),
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                                      labelStyle: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      side: BorderSide(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],

                        // Steps
                        if (widget.guide.steps.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Step-by-Step Guide',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.guide.steps.asMap().entries.map((entry) {
                            final index = entry.key;
                            final step = entry.value;
                            final isCompleted = _completedSteps.contains(index);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isCompleted) {
                                      _completedSteps.remove(index);
                                    } else {
                                      _completedSteps.add(index);
                                    }
                                  });
                                  _checkAndShowConfetti();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppTheme.successColor.withOpacity(0.1)
                                        : AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCompleted
                                          ? AppTheme.successColor
                                          : AppTheme.textSecondary.withOpacity(0.3),
                                      width: isCompleted ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppTheme.successColor
                                              : AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: isCompleted
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 18,
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            step,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  decoration: isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  color: isCompleted
                                                      ? AppTheme.textSecondary
                                                      : AppTheme.textPrimary,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  analytics.logGuideOpen(
                                    widget.guide.title,
                                    widget.guide.category,
                                  );
                                  await UrlLauncherHelper.launchURL(
                                    widget.guide.resourceLink,
                                  );
                                },
                                icon: Icon(_getTypeIcon()),
                                label: Text(_getActionButtonText()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getTypeBadgeColor(),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _isSaving ? null : () => _saveGuide(context),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : const Icon(Icons.bookmark_border),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.surfaceColor,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
                ],
              ),
            );
          },
        ),
        // Confetti overlay when guide is fully completed
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(_confettiController),
              ),
            ),
          ),
      ],
    );
  }

  /// Build progress bar showing step completion
  Widget _buildProgressBar() {
    final percentage = (_progress * 100).toInt();
    final completedCount = _completedSteps.length;
    final totalCount = widget.guide.steps.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isFullyCompleted
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFullyCompleted
              ? AppTheme.successColor
              : AppTheme.textSecondary.withValues(alpha: 0.2),
          width: _isFullyCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Learning Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isFullyCompleted
                          ? AppTheme.successColor
                          : AppTheme.textPrimary,
                    ),
              ),
              Row(
                children: [
                  if (_isFullyCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.play_circle_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    '$completedCount/$totalCount steps',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isFullyCompleted
                              ? AppTheme.successColor
                              : AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isFullyCompleted
                          ? [AppTheme.successColor, AppTheme.successColor]
                          : [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: (_isFullyCompleted
                                ? AppTheme.successColor
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Percentage text
          Text(
            _isFullyCompleted
                ? '🎉 Completed! Great job!'
                : '$percentage% completed',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isFullyCompleted
                      ? AppTheme.successColor
                      : AppTheme.textSecondary,
                  fontWeight: _isFullyCompleted ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }

  /// Build stat chip widget
  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get action button text based on guide type
  String _getActionButtonText() {
    switch (widget.guide.type.toLowerCase()) {
      case 'youtube':
        return 'Watch on YouTube';
      case 'article':
        return 'Read Article';
      case 'link':
        return 'Open Link';
      default:
        return 'Open Resource';
    }
  }

  /// Save guide to bookmarks
  Future<void> _saveGuide(BuildContext context) async {
    setState(() => _isSaving = true);

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to save items')),
          );
        }
        return;
      }

      final savedItem = SavedItem(
        id: '',
        type: 'guide',
        name: widget.guide.title,
        link: widget.guide.resourceLink,
        logo: widget.guide.logo,
        timestamp: DateTime.now(),
      );

      await firebaseService.saveItem(currentUser.uid, savedItem);
      analytics.logItemSaved('guide', widget.guide.title);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guide saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Custom painter for confetti animation when guide is fully completed
class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final math.Random _random = math.Random();

  _ConfettiPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;

    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      final randomX = _random.nextDouble() * size.width;
      final randomColor = _getRandomColor(i);
      final randomSize = 4.0 + _random.nextDouble() * 4.0;

      // Confetti falls from top to bottom
      final startY = -50.0;
      final endY = size.height + 50.0;
      final currentY = startY + (endY - startY) * progress;

      // Add slight horizontal drift
      final drift = math.sin(progress * math.pi * 2 + i) * 30;

      final paint = Paint()
        ..color = randomColor.withValues(alpha: 1.0 - progress * 0.3)
        ..style = PaintingStyle.fill;

      // Draw confetti as small rectangles with rotation
      canvas.save();
      canvas.translate(randomX + drift, currentY);
      canvas.rotate(progress * math.pi * 4 + i);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: randomSize,
        height: randomSize * 1.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );

      canvas.restore();
    }
  }

  Color _getRandomColor(int seed) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      AppTheme.primaryColor,
      AppTheme.successColor,
    ];
    return colors[seed % colors.length];
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
