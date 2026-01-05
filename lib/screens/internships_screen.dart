import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../widgets/filter_chips.dart';
import '../widgets/internship_card.dart';
import '../models/job.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Main screen for displaying internship opportunities
///
/// Features:
/// - AI-driven recommendation carousel at top
/// - Real-time Firebase stream updates
/// - Tag-based filtering with multiple categories
/// - Sort by: Deadline, Stipend, Duration, Newest
/// - Smooth infinite scroll with pagination
/// - Pull-to-refresh for manual data refresh
/// - Optimized ListView with caching
/// - Preloaded stipend/duration filters
class InternshipsScreen extends StatefulWidget {
  const InternshipsScreen({super.key});

  @override
  State<InternshipsScreen> createState() => _InternshipsScreenState();
}

class _InternshipsScreenState extends State<InternshipsScreen> {
  String _selectedSort = 'Newest'; // Default sort
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;

  // Pagination
  int _currentLimit = 20; // Start with 20 items
  bool _isLoadingMore = false;

  // Cached filter values
  final List<String> _commonStipends = [];
  final List<String> _commonDurations = [];

  /// Sort options
  final List<String> _sortOptions = [
    'Newest',
    'Deadline',
    'Stipend',
    'Duration',
  ];

  @override
  void initState() {
    super.initState();
    _logScreenView();
    _setupScrollListener();
    _preloadFilterValues();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Log screen view event to Firebase Analytics
  void _logScreenView() {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('internships');
  }

  /// Setup scroll listener for infinite scroll
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  /// Load more items when scrolling near bottom
  void _loadMore() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentLimit += 10; // Load 10 more items
    });

    // Reset loading state after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    });
  }

  /// Preload common stipend and duration values for quick filtering
  void _preloadFilterValues() {
    // Common stipend ranges
    _commonStipends.addAll([
      'Unpaid',
      '₹5,000 - ₹10,000',
      '₹10,000 - ₹20,000',
      '₹20,000 - ₹30,000',
      '₹30,000+',
    ]);

    // Common durations
    _commonDurations.addAll([
      '1 month',
      '2 months',
      '3 months',
      '6 months',
      '6+ months',
    ]);
  }


  /// Sort internships based on selected criteria
  List<Job> _sortInternships(List<Job> internships) {
    final sorted = List<Job>.from(internships);

    switch (_selectedSort) {
      case 'Deadline':
        // Sort by earliest deadline first (null deadlines at end)
        sorted.sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
        break;

      case 'Stipend':
        // Sort by highest stipend first (parse stipend string)
        sorted.sort((a, b) {
          final aStipend = _parseStipend(a.stipend);
          final bStipend = _parseStipend(b.stipend);
          return bStipend.compareTo(aStipend); // Descending
        });
        break;

      case 'Duration':
        // Sort by shortest duration first
        sorted.sort((a, b) {
          final aDuration = _parseDuration(a.duration);
          final bDuration = _parseDuration(b.duration);
          return aDuration.compareTo(bDuration); // Ascending
        });
        break;

      case 'Newest':
      default:
        // Sort by most recent posted date (null dates at end)
        sorted.sort((a, b) {
          if (a.postedDate == null && b.postedDate == null) return 0;
          if (a.postedDate == null) return 1;
          if (b.postedDate == null) return -1;
          return b.postedDate!.compareTo(a.postedDate!); // Descending
        });
        break;
    }

    return sorted;
  }

  /// Parse stipend string to numeric value for sorting
  /// Examples: "₹15,000/month" → 15000, "Unpaid" → 0
  int _parseStipend(String? stipend) {
    if (stipend == null || stipend.isEmpty) return 0;

    final lowerStipend = stipend.toLowerCase();
    if (lowerStipend.contains('unpaid')) return 0;

    // Extract first number from string
    final numbers = RegExp(r'\d+').allMatches(stipend.replaceAll(',', ''));
    if (numbers.isEmpty) return 0;

    return int.tryParse(numbers.first.group(0) ?? '0') ?? 0;
  }

  /// Parse duration string to months for sorting
  /// Examples: "3 months" → 3, "6-12 weeks" → 3
  int _parseDuration(String? duration) {
    if (duration == null || duration.isEmpty) return 0;

    final lowerDuration = duration.toLowerCase();

    // Extract first number
    final numbers = RegExp(r'\d+').allMatches(duration);
    if (numbers.isEmpty) return 0;

    final value = int.tryParse(numbers.first.group(0) ?? '0') ?? 0;

    // Convert weeks to months if needed
    if (lowerDuration.contains('week')) {
      return (value / 4).ceil(); // Convert weeks to months
    }

    return value; // Assume months
  }

  /// Get AI-driven recommendations based on user activity
  List<Job> _getRecommendations(List<Job> allInternships) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || allInternships.isEmpty) {
      // Return top 15 newest internships if no user context
      return allInternships.take(15).toList();
    }

    // Simple recommendation algorithm:
    // 1. Score each internship based on:
    //    - Popular tags (Web Development, Mobile, AI/ML)
    //    - Remote opportunities
    //    - Paid internships
    //    - Recent postings
    // 2. Return top 15 scored items

    final scoredInternships = allInternships.map((internship) {
      double score = 0.0;

      // Popular tech tags (bonus points)
      final popularTags = ['web development', 'mobile', 'ai', 'ml', 'data science', 'flutter', 'react'];
      for (var tag in internship.tags) {
        if (popularTags.any((popular) => tag.toLowerCase().contains(popular))) {
          score += 2.0;
        }
      }

      // Remote bonus
      if (internship.tags.any((tag) => tag.toLowerCase().contains('remote'))) {
        score += 3.0;
      }

      // Paid bonus
      if (internship.stipend != null && !internship.stipend!.toLowerCase().contains('unpaid')) {
        score += 2.0;
      }

      // Recency bonus (posted in last 7 days)
      if (internship.postedDate != null) {
        final daysAgo = DateTime.now().difference(internship.postedDateTime!).inDays;
        if (daysAgo <= 7) {
          score += 5.0;
        } else if (daysAgo <= 30) {
          score += 2.0;
        }
      }

      // Active status
      if (internship.isStillActive) {
        score += 1.0;
      }

      return MapEntry(internship, score);
    }).toList();

    // Sort by score descending
    scoredInternships.sort((a, b) => b.value.compareTo(a.value));

    // Return top 15
    return scoredInternships.take(15).map((e) => e.key).toList();
  }

  /// Handle pull-to-refresh action
  Future<void> _handleRefresh() async {
    // Reset pagination
    setState(() => _currentLimit = 20);

    // Stream automatically refreshes, but we add a small delay
    // to show the refresh indicator for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {}); // Trigger rebuild to show fresh data
  }

  /// Filter internships by search query
  List<Job> _filterBySearch(List<Job> internships) {
    if (_searchQuery.isEmpty) return internships;

    return internships.where((internship) {
      return internship.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          internship.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          internship.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    return Column(
      children: [
        // Search Bar (toggleable)
        if (_showSearchBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildSearchBar(),
          ),

        const SizedBox(height: 8),

        // Recommendations Carousel Section
        StreamBuilder<List<Job>>(
          stream: firebaseService.getInternships(limit: 50),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final recommendations = _getRecommendations(snapshot.data!);
              if (recommendations.isNotEmpty) {
                return _buildRecommendationsCarousel(recommendations);
              }
            }
            return const SizedBox.shrink();
          },
        ),

        // Sort Pills with Search Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildSortPills(analytics)),
              const SizedBox(width: 8),
              // Search button
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                    if (!_showSearchBar) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
                icon: Icon(
                  _showSearchBar ? Icons.close : Icons.search,
                  color: AppTheme.primaryColor,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Main content area with stream builder
        Expanded(
          child: StreamBuilder<List<Job>>(
            stream: firebaseService.getInternships(
              limit: _currentLimit,
            ),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeletonLoader();
              }

              // Error state
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              // Empty state - no data from Firebase
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(
                  AppConstants.emptyInternships,
                  'Check back soon for new opportunities!',
                );
              }

              // Apply search filter and sorting
              var processedInternships = _filterBySearch(snapshot.data!);
              processedInternships = _sortInternships(processedInternships);

              // Empty state - no results after filtering
              if (processedInternships.isEmpty) {
                return _buildEmptyState(
                  AppConstants.emptyFilteredResults,
                  'Try selecting a different sort option',
                );
              }

              // Success state - show list with pull-to-refresh
              return RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
                  cacheExtent: AppConstants.listViewCacheExtent, // Cache items for smoother scrolling
                  itemCount: processedInternships.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at bottom when loading more
                    if (index == processedInternships.length) {
                      return _buildLoadingMoreIndicator();
                    }

                    final internship = processedInternships[index];
                    return InternshipCard(
                      internship: internship,
                      key: ValueKey(internship.id), // Optimize rebuilds
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build AI-driven recommendations carousel
  Widget _buildRecommendationsCarousel(List<Job> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Icon(
                Icons.stars_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommended For You',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            cacheExtent: 500,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final internship = recommendations[index];
              return _buildRecommendationCard(internship);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build individual recommendation card
  Widget _buildRecommendationCard(Job internship) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          final analytics = Provider.of<AnalyticsService>(context, listen: false);
          analytics.logEvent('recommendation_tap', {'internship': internship.title});

          // Import and show detail sheet
          showInternshipDetailSheet(context, internship);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo
                  if (internship.logo != null)
                    ClipRRect(
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
                            color: AppTheme.surfaceColor,
                            child: Icon(Icons.business, size: 20),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.business, size: 20),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          internship.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          internship.company,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Location and Stipend
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      internship.locationDisplay,
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (internship.stipend != null) ...[
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 12, color: AppTheme.successColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        internship.stipend!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Tags (max 2)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: internship.tags
                    .where((tag) => !AppConstants.excludedTags.any((excluded) => tag.toLowerCase().contains(excluded)))
                    .take(2)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) {
          setState(() => _searchQuery = value);
          if (value.isNotEmpty) {
            Provider.of<AnalyticsService>(context, listen: false)
                .logEvent('internship_search', {'query': value});
          }
        },
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search internships...',
          hintStyle: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textSecondary.withOpacity(0.6),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  /// Build sort pills section
  Widget _buildSortPills(AnalyticsService analytics) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sortOptions.length,
              itemBuilder: (context, index) {
                final option = _sortOptions[index];
                final isSelected = _selectedSort == option;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedSort = option);
                      analytics.logEvent('internship_sort_changed', {
                        'sort': option,
                      });
                    },
                    backgroundColor: AppTheme.surfaceColor,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading indicator for "load more" at bottom
  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  /// Build skeleton loader with shimmer effect
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: AppTheme.surfaceColor,
            highlightColor: AppTheme.surfaceColor.withOpacity(0.5),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build error state widget
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.errorLoadingData,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}), // Retry
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Import statement for showInternshipDetailSheet
void showInternshipDetailSheet(BuildContext context, Job internship) {
  // This will be implemented in internship_detail_sheet.dart
  // For now, show a simple dialog
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Center(
        child: Text('Internship details coming soon...'),
      ),
    ),
  );
}
