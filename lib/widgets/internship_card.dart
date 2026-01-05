import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/job.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../screens/internship_detail_sheet.dart';

/// Card widget for displaying internship information in a list
///
/// Features:
/// - Company logo with optimized caching
/// - Paid/Remote badges for quick identification
/// - Tech tags (max 3) to show required skills
/// - Location display
/// - Performance optimized with ValueKey and const constructors
class InternshipCard extends StatelessWidget {
  final Job internship;
  final VoidCallback? onTap;

  const InternshipCard({
    super.key,
    required this.internship,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap ?? () => showInternshipDetailSheet(context, internship),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildLocation(context),
              const SizedBox(height: 8),
              _buildBadges(context),
              _buildTechTags(context),
              const SizedBox(height: 8),
              _buildViewDetailsButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build company logo and title section
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildLogo(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                internship.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                internship.company,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build company logo with caching and fallback
  Widget _buildLogo() {
    if (internship.logo == null) {
      return _buildLogoPlaceholder();
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: internship.logo!,
        width: AppConstants.logoSizeCard,
        height: AppConstants.logoSizeCard,
        fit: BoxFit.cover,
        maxHeightDiskCache: 150, // Optimize memory usage
        maxWidthDiskCache: 150,
        memCacheWidth: 150,
        memCacheHeight: 150,
        placeholder: (context, url) => _buildLogoPlaceholder(),
        errorWidget: (context, url, error) => _buildLogoPlaceholder(),
      ),
    );
  }

  /// Build logo placeholder when image is null or fails to load
  Widget _buildLogoPlaceholder() {
    return Container(
      width: AppConstants.logoSizeCard,
      height: AppConstants.logoSizeCard,
      color: AppTheme.surfaceColor,
      child: const Icon(Icons.business, size: 28),
    );
  }

  /// Build location row with icon
  Widget _buildLocation(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            internship.locationDisplay, // Use helper method for location display
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build Paid/Remote badges section
  Widget _buildBadges(BuildContext context) {
    // Cache these lookups for performance
    final isPaid = _hasPaidTag();
    final isRemote = _hasRemoteTag();

    if (!isPaid && !isRemote) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (isPaid) _buildPaidBadge(context),
        if (isPaid && isRemote) const SizedBox(width: 8),
        if (isRemote) _buildRemoteBadge(context),
      ],
    );
  }

  /// Check if internship has paid tag
  bool _hasPaidTag() {
    return internship.tags
        .any((tag) => tag.toLowerCase().contains('paid'));
  }

  /// Check if internship has remote tag
  bool _hasRemoteTag() {
    return internship.tags
        .any((tag) => tag.toLowerCase().contains('remote'));
  }

  /// Build "Paid" badge with green styling
  Widget _buildPaidBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.attach_money,
            size: 14,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Paid',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.successColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Build "Remote" badge with blue styling
  Widget _buildRemoteBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Remote',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Build tech tags section (displays max 3 tags, excludes meta tags)
  Widget _buildTechTags(BuildContext context) {
    final displayTags = _getDisplayTags();

    if (displayTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: displayTags
            .map((tag) => _buildTag(context, tag))
            .toList(growable: false), // Optimize list creation
      ),
    );
  }

  /// Get filtered and limited tags for display
  /// Excludes meta tags like 'paid', 'remote', 'internship'
  /// Returns max 3 tags
  List<String> _getDisplayTags() {
    return internship.tags
        .where((tag) {
          final lowerTag = tag.toLowerCase();
          return !AppConstants.excludedTags.any(
            (excluded) => lowerTag.contains(excluded),
          );
        })
        .take(AppConstants.maxTagsOnCard)
        .toList();
  }

  /// Build individual tag chip
  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 11,
            ),
      ),
    );
  }

  /// Build "View Details" button at bottom of card
  Widget _buildViewDetailsButton(BuildContext context) {
    return Row(
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
        const Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }
}
