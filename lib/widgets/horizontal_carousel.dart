import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/job.dart';
import '../models/gsoc_org.dart';
import '../models/guide.dart';
import '../utils/theme.dart';

/// Enum for carousel item types
enum CarouselItemType {
  job,
  internship,
  gsocOrg,
  guide,
}

/// Horizontal carousel widget for displaying items
class HorizontalCarousel extends StatelessWidget {
  final List<dynamic> items;
  final CarouselItemType itemType;
  final Function(dynamic) onItemTap;

  const HorizontalCarousel({
    super.key,
    required this.items,
    required this.itemType,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        cacheExtent: 500,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildCarouselItem(context, item),
          );
        },
      ),
    );
  }

  Widget _buildCarouselItem(BuildContext context, dynamic item) {
    return GestureDetector(
      onTap: () => onItemTap(item),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textSecondary.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  _buildLogo(item),
                  const SizedBox(width: 12),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTitle(item),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSubtitle(item),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                _getDescription(item),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Footer
              _buildFooter(context, item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(dynamic item) {
    String? logoUrl;

    if (item is Job) {
      logoUrl = item.logo;
    } else if (item is GsocOrg) {
      logoUrl = item.imageUrl;
    } else if (item is Guide) {
      logoUrl = item.logo;
    }

    if (logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          maxHeightDiskCache: 100,
          maxWidthDiskCache: 100,
          memCacheWidth: 100,
          memCacheHeight: 100,
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
            child: Icon(
              _getIcon(),
              size: 24,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getIcon(),
        size: 24,
        color: AppTheme.textSecondary,
      ),
    );
  }

  IconData _getIcon() {
    switch (itemType) {
      case CarouselItemType.job:
      case CarouselItemType.internship:
        return Icons.work_outline;
      case CarouselItemType.gsocOrg:
        return Icons.emoji_events_outlined;
      case CarouselItemType.guide:
        return Icons.book_outlined;
    }
  }

  String _getTitle(dynamic item) {
    if (item is Job) return item.title;
    if (item is GsocOrg) return item.name;
    if (item is Guide) return item.title;
    return '';
  }

  String _getSubtitle(dynamic item) {
    if (item is Job) return item.company;
    if (item is GsocOrg) return item.category;
    if (item is Guide) return item.category;
    return '';
  }

  String _getDescription(dynamic item) {
    if (item is Job) return item.description;
    if (item is GsocOrg) return item.description;
    if (item is Guide) return item.description;
    return '';
  }

  Widget _buildFooter(BuildContext context, dynamic item) {
    if (item is Job) {
      return Row(
        children: [
          if (item.locations.isNotEmpty) ...[
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                item.locationDisplay,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (item.salary != null) ...[
            const SizedBox(width: 12),
            Text(
              item.salary!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ],
      );
    } else if (item is GsocOrg) {
      return Row(
        children: [
          Icon(
            Icons.code,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${item.numProjects} projects',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          if (item.technologies.isNotEmpty)
            Text(
              '${item.technologies.length} techs',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
        ],
      );
    } else if (item is Guide) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getGuideBadgeColor(item),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Icon(
            Icons.visibility_outlined,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            item.viewsDisplay,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Color _getGuideBadgeColor(Guide guide) {
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
}
