import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/job.dart';
import '../models/saved_item.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../utils/url_launcher_helper.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

/// Show internship detail bottom sheet with spring animation
void showInternshipDetailSheet(BuildContext context, Job internship) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => InternshipDetailSheet(internship: internship),
  );
}

/// Detailed view of an internship opportunity shown as a modal bottom sheet
///
/// Features:
/// - Spring animation on open
/// - Full internship description
/// - Requirements displayed as bullet points
/// - All skills displayed as chips
/// - Apply button with loading state
/// - Save button with animated success checkmark
/// - Similar Internships grid (3 items)
/// - Firebase Auth integration for user-specific saves
class InternshipDetailSheet extends StatefulWidget {
  final Job internship;

  const InternshipDetailSheet({super.key, required this.internship});

  @override
  State<InternshipDetailSheet> createState() => _InternshipDetailSheetState();
}

class _InternshipDetailSheetState extends State<InternshipDetailSheet>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  bool _isApplying = false;
  bool _saveSuccess = false;

  // Spring animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Spring-like curve
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.5, 0.75, 0.95],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDragHandle(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompanyHeader(context),
                          const SizedBox(height: 20),
                          _buildInternshipTitle(context),
                          const SizedBox(height: 16),
                          _buildInfoCards(context),
                          const SizedBox(height: 20),
                          _buildBadges(context),
                          const SizedBox(height: 20),
                          _buildRequirementsChecklist(context),
                          const SizedBox(height: 20),
                          _buildSkillsSection(context),
                          const SizedBox(height: 20),
                          _buildDescriptionSection(context),
                          const SizedBox(height: 24),
                          _buildActionButtons(context),
                          const SizedBox(height: 32),
                          _buildSimilarInternshipsGrid(context),
                          const SizedBox(height: 16),
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
    );
  }

  /// Build drag handle at top of sheet
  Widget _buildDragHandle() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 1000) {
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Build company logo and header information
  Widget _buildCompanyHeader(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'internship_logo_${widget.internship.id}',
          child: _buildCompanyLogo(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.internship.company,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.internship.locations.join(' • '), // Show all locations
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build company logo with optimized caching
  Widget _buildCompanyLogo() {
    if (widget.internship.logo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.internship.logo!,
          width: AppConstants.logoSizeDetail,
          height: AppConstants.logoSizeDetail,
          fit: BoxFit.cover,
          maxHeightDiskCache: 200,
          maxWidthDiskCache: 200,
          memCacheWidth: 200,
          memCacheHeight: 200,
          placeholder: (context, url) => _buildLogoPlaceholder(),
          errorWidget: (context, url, error) => _buildLogoPlaceholder(),
        ),
      );
    }
    return _buildLogoPlaceholder();
  }

  /// Build logo placeholder
  Widget _buildLogoPlaceholder() {
    return Container(
      width: AppConstants.logoSizeDetail,
      height: AppConstants.logoSizeDetail,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.business, size: 32),
    );
  }

  /// Build internship title
  Widget _buildInternshipTitle(BuildContext context) {
    return Text(
      widget.internship.title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// Build info cards (Stipend, Duration, Deadline)
  Widget _buildInfoCards(BuildContext context) {
    final hasInfo = widget.internship.stipend != null ||
        widget.internship.duration != null ||
        widget.internship.deadline != null;

    if (!hasInfo) return const SizedBox.shrink();

    return Row(
      children: [
        if (widget.internship.stipend != null)
          Expanded(child: _buildInfoCard(
            context,
            icon: Icons.payments_outlined,
            label: 'Stipend',
            value: widget.internship.stipend!,
            color: AppTheme.successColor,
          )),
        if (widget.internship.stipend != null && widget.internship.duration != null)
          const SizedBox(width: 12),
        if (widget.internship.duration != null)
          Expanded(child: _buildInfoCard(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Duration',
            value: widget.internship.duration!,
            color: AppTheme.primaryColor,
          )),
        if ((widget.internship.stipend != null || widget.internship.duration != null) &&
            widget.internship.deadline != null)
          const SizedBox(width: 12),
        if (widget.internship.deadline != null)
          Expanded(child: _buildInfoCard(
            context,
            icon: Icons.schedule_outlined,
            label: 'Deadline',
            value: _formatDeadline(widget.internship.deadlineDate),
            color: AppTheme.warningColor,
          )),
      ],
    );
  }

  /// Build individual info card
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Format deadline date
  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) return 'Not specified';
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).ceil()} months';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else {
      return 'Expired';
    }
  }

  /// Build Paid/Remote badges
  Widget _buildBadges(BuildContext context) {
    final isPaid = _hasPaidTag();
    final isRemote = _hasRemoteTag();

    if (!isPaid && !isRemote) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isPaid) _buildPaidBadge(context),
        if (isRemote) _buildRemoteBadge(context),
      ],
    );
  }

  /// Check for paid tag
  bool _hasPaidTag() {
    return widget.internship.tags
        .any((tag) => tag.toLowerCase().contains('paid'));
  }

  /// Check for remote tag
  bool _hasRemoteTag() {
    return widget.internship.tags
        .any((tag) => tag.toLowerCase().contains('remote'));
  }

  /// Build paid badge
  Widget _buildPaidBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.attach_money,
            size: 16,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Paid',
            style: const TextStyle(
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build remote badge
  Widget _buildRemoteBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Remote',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build requirements section with bullet points
  Widget _buildRequirementsChecklist(BuildContext context) {
    final requirements = widget.internship.requirements;

    if (requirements == null || requirements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, size: 22, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Requirements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(requirements.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < requirements.length - 1 ? 10 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bullet point
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        requirements[index],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Build skills section
  Widget _buildSkillsSection(BuildContext context) {
    final skills = widget.internship.skills;

    if (skills == null || skills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Skills',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Build description section
  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Internship',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.internship.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
        ),
      ],
    );
  }

  /// Build action buttons (Apply and Save with animated checkmark)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isApplying ? null : _handleApply,
            icon: _isApplying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.open_in_browser),
            label: Text(_isApplying ? 'Opening...' : 'Apply Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Save button with animated checkmark
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _saveSuccess ? AppTheme.successColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _isSaving || _saveSuccess ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: _saveSuccess
                        ? const Icon(
                            Icons.check_circle,
                            key: ValueKey('check'),
                            color: Colors.white,
                            size: 28,
                          )
                        : const Icon(
                            Icons.bookmark_border,
                            key: ValueKey('bookmark'),
                            color: AppTheme.primaryColor,
                          ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // Report button
        IconButton(
          onPressed: () => _showReportDialog(context),
          icon: const Icon(Icons.flag_outlined),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceColor,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  /// Show report dialog
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportInternshipDialog(internship: widget.internship),
    );
  }

  /// Handle apply button press
  Future<void> _handleApply() async {
    if (_isApplying) return;

    setState(() => _isApplying = true);

    try {
      // Log analytics event
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      analytics.logEvent('internship_apply', {
        'title': widget.internship.title,
        'company': widget.internship.company,
      });

      // Launch URL
      await UrlLauncherHelper.launchURL(widget.internship.applyLink);
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: $e'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  /// Handle save button press with animated checkmark
  Future<void> _handleSave() async {
    if (_isSaving || _saveSuccess) return;

    // Get current user ID from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to save internships'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final analytics = Provider.of<AnalyticsService>(context, listen: false);

      final savedItem = SavedItem(
        id: '',
        type: 'internship',
        name: widget.internship.title,
        link: widget.internship.applyLink,
        logo: widget.internship.logo,
        timestamp: DateTime.now(),
      );

      await firebaseService.saveItem(currentUser.uid, savedItem);

      analytics.logItemSaved('internship', widget.internship.title);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveSuccess = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successItemSaved),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Close sheet after 1 second to show success animation
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.errorSavingItem}: $e'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  /// Build similar internships as 3-item grid
  Widget _buildSimilarInternshipsGrid(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return StreamBuilder<List<Job>>(
      stream: firebaseService.getInternships(
        limit: AppConstants.recommendationsFetchLimit,
      ),
      builder: (context, snapshot) {
        // Don't show section if loading or error
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get exactly 3 similar internships
        final similar = _getSimilarInternships(snapshot.data!);

        if (similar.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 22, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Similar Internships You May Like',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 3-column grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75, // Slightly taller cards
              ),
              itemCount: similar.length,
              itemBuilder: (context, index) {
                return _buildSimilarCard(context, similar[index]);
              },
            ),
          ],
        );
      },
    );
  }

  /// Get list of similar internships (max 3)
  List<Job> _getSimilarInternships(List<Job> allInternships) {
    return allInternships
        .where((i) => i.id != widget.internship.id) // Exclude current
        .where((i) =>
            // Match by shared tags
            i.tags.any((tag) => widget.internship.tags.contains(tag)) ||
            // Or shared location
            i.locations.any((loc) => widget.internship.locations.contains(loc)))
        .take(3) // Exactly 3 items
        .toList();
  }

  /// Build individual similar internship card for grid
  Widget _buildSimilarCard(BuildContext context, Job internship) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close current sheet
          showInternshipDetailSheet(context, internship); // Open new one
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(
                child: internship.logo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          internship.logo!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.business, size: 20),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.business, size: 20),
                      ),
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                internship.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Company
              Text(
                internship.company,
                style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for reporting an internship with radio list + text box
class ReportInternshipDialog extends StatefulWidget {
  final Job internship;

  const ReportInternshipDialog({super.key, required this.internship});

  @override
  State<ReportInternshipDialog> createState() => _ReportInternshipDialogState();
}

class _ReportInternshipDialogState extends State<ReportInternshipDialog> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    // For "Other" reason, require additional details
    if (_selectedReason == 'other' &&
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide details for "Other" reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to submit reports')),
          );
        }
        return;
      }

      // Submit report to Firebase
      await firebaseService.submitReport(
        userId: currentUser.uid,
        itemId: widget.internship.id,
        itemType: 'internship',
        reason: _selectedReason!,
        additionalDetails: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Report submitted successfully. Thank you for your feedback!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Report Internship'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us maintain quality by reporting issues with this internship posting.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reason *',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // Radio list
            ...AppConstants.reportReasons.map((reason) => RadioListTile<String>(
                  value: reason.value,
                  groupValue: _selectedReason,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() => _selectedReason = value);
                        },
                  title: Text(reason.label),
                  subtitle: Text(
                    reason.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                )),
            const SizedBox(height: 16),
            // Text box for additional details
            if (_selectedReason != null) ...[
              Text(
                _selectedReason == 'other'
                    ? 'Details *'
                    : 'Additional Details (Optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Provide more details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                ),
                maxLines: 3,
                enabled: !_isSubmitting,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
