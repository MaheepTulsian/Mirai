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

void showJobDetailSheet(BuildContext context, Job job) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    builder: (context) => JobDetailSheet(job: job),
  );
}

/// Job Detail Sheet with spring animation and loading states
class JobDetailSheet extends StatefulWidget {
  final Job job;

  const JobDetailSheet({super.key, required this.job});

  @override
  State<JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<JobDetailSheet>
    with SingleTickerProviderStateMixin {
  bool _isApplying = false;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Spring animation setup
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
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                // Handle bar with haptic feedback
                GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! > 1000) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company Logo and Header
                          Row(
                            children: [
                              if (widget.job.logo != null)
                                Hero(
                                  tag: 'job_logo_${widget.job.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.job.logo!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      maxHeightDiskCache: 150,
                                      maxWidthDiskCache: 150,
                                      placeholder: (context, url) => Container(
                                        width: 64,
                                        height: 64,
                                        color: AppTheme.surfaceColor,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: 64,
                                        height: 64,
                                        color: AppTheme.surfaceColor,
                                        child: const Icon(Icons.business,
                                            size: 32),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.business, size: 32),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.job.company,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Location chips
                                    _buildLocationChips(),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Job Title
                          Text(
                            widget.job.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),

                          const SizedBox(height: 16),

                          // Salary
                          if (widget.job.salary != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.successColor.withOpacity(0.15),
                                    AppTheme.successColor.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.successColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    color: AppTheme.successColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Salary',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.job.salary!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: AppTheme.successColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Tags
                          if (widget.job.tags.isNotEmpty) ...[
                            Text(
                              'Skills Required',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.job.tags
                                  .map((tag) => Chip(
                                        label: Text(tag),
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.15),
                                        labelStyle: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        side: BorderSide(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.3),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Job Description
                          Text(
                            'Job Description',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.job.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.6),
                          ),

                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isApplying ? null : () => _applyNow(),
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
                                  label: Text(_isApplying
                                      ? 'Opening...'
                                      : 'Apply Now'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        AppTheme.primaryColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _isSaving ? null : () => _saveJob(),
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
                                  disabledBackgroundColor:
                                      AppTheme.surfaceColor.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _showReportDialog(context),
                                icon: const Icon(Icons.flag_outlined),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceColor,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // More Recommended Jobs
                          _buildRecommendedJobs(context),
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

  /// Build location chips with Wrap
  Widget _buildLocationChips() {
    if (widget.job.locations.isEmpty) {
      return const SizedBox.shrink();
    }

    // If only 1-2 locations, show inline
    if (widget.job.locations.length <= 2) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: widget.job.locations
            .map((location) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    }

    // If many locations, show in wrap with max 3 visible
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...widget.job.locations.take(3).map((location) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
        if (widget.job.locations.length > 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${widget.job.locations.length - 3} more',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Apply to job with loading state
  Future<void> _applyNow() async {
    setState(() => _isApplying = true);

    try {
      final analytics =
          Provider.of<AnalyticsService>(context, listen: false);
      analytics.logJobOpen(widget.job.title, widget.job.company);

      await UrlLauncherHelper.launchURL(widget.job.applyLink);

      // Add slight delay for UX
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  /// Save job with loading state
  Future<void> _saveJob() async {
    setState(() => _isSaving = true);

    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final analytics =
          Provider.of<AnalyticsService>(context, listen: false);
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
        type: 'job',
        name: widget.job.title,
        link: widget.job.applyLink,
        logo: widget.job.logo,
        timestamp: DateTime.now(),
      );

      await firebaseService.saveItem(currentUser.uid, savedItem);
      analytics.logItemSaved('job', widget.job.title);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job saved successfully'),
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

  /// Build recommended jobs section
  Widget _buildRecommendedJobs(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return StreamBuilder<List<Job>>(
      stream: firebaseService.getJobs(limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recommendedJobs = snapshot.data!
            .where((j) => j.title != widget.job.title)
            .where((j) =>
                j.tags.any((tag) => widget.job.tags.contains(tag)) ||
                j.locations.any((loc) => widget.job.locations.contains(loc)))
            .take(3)
            .toList();

        if (recommendedJobs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'More Recommended Jobs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...recommendedJobs.map((recommendedJob) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      showJobDetailSheet(context, recommendedJob);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (recommendedJob.logo != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: recommendedJob.logo!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                maxHeightDiskCache: 100,
                                maxWidthDiskCache: 100,
                                errorWidget: (context, url, error) =>
                                    Container(
                                  width: 48,
                                  height: 48,
                                  color: AppTheme.surfaceColor,
                                  child: const Icon(Icons.business, size: 24),
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
                              child: const Icon(Icons.business, size: 24),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendedJob.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recommendedJob.company,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recommendedJob.locationDisplay,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportJobDialog(job: widget.job),
    );
  }
}

/// Dialog for reporting a job with radio list + text box
class ReportJobDialog extends StatefulWidget {
  final Job job;

  const ReportJobDialog({super.key, required this.job});

  @override
  State<ReportJobDialog> createState() => _ReportJobDialogState();
}

class _ReportJobDialogState extends State<ReportJobDialog> {
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
        itemId: widget.job.id,
        itemType: 'job',
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
      title: const Text('Report Job'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us maintain quality by reporting issues with this job posting.',
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
            // Text box for additional details (shown only if "Other" selected)
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
