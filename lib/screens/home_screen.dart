import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/horizontal_carousel.dart';
import '../widgets/dashboard_card.dart';
import 'job_detail_sheet.dart';
import 'internship_detail_sheet.dart';
import 'guide_detail_sheet.dart';

/// Modern Home Screen with dashboard grid and horizontal carousels
class HomeScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;

  const HomeScreen({super.key, this.onSwitchTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logAppOpen();
    analytics.logEvent('homepage_view');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Get personalized greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Get user's first name from auth
  String _getFirstName() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final displayName = authService.currentUser?.displayName ?? 'Student';
    return displayName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger rebuild
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _buildSearchBar(),
            ),
          ),

          // Greeting Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildGreetingRow(),
            ),
          ),

          // Dashboard Grid (1×4 - All in one row)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDashboardGrid(),
            ),
          ),

          // Trending Jobs Grid (2x3)
          SliverToBoxAdapter(
            child: _buildSection(
              title: '🔥 Trending Jobs',
              onSeeAll: () => widget.onSwitchTab?.call(1),
              child: StreamBuilder(
                stream: firebaseService.getJobs(limit: 6),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerGrid();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final jobs = snapshot.data!.take(6).toList();
                  return _buildJobsGrid(jobs, analytics);
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Recommended Internships Grid (2x3)
          SliverToBoxAdapter(
            child: _buildSection(
              title: '⚡ Recommended Internships',
              onSeeAll: () => widget.onSwitchTab?.call(2),
              child: StreamBuilder(
                stream: firebaseService.getInternships(limit: 6),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerGrid();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final internships = snapshot.data!.take(6).toList();
                  return _buildInternshipsGrid(internships, analytics);
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Learning Resources (Guides & Roadmaps)
          SliverToBoxAdapter(
            child: _buildSection(
              title: '📚 Learning Resources',
              onSeeAll: () => widget.onSwitchTab?.call(4),
              child: StreamBuilder(
                stream: firebaseService.getGuides(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerCarousel();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final guides = snapshot.data!.take(10).toList();
                  return HorizontalCarousel(
                    items: guides,
                    itemType: CarouselItemType.guide,
                    onItemTap: (item) {
                      analytics.logGuideOpen(item.title, item.category);
                      showGuideDetailSheet(context, item);
                    },
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// Build modern search bar with glass effect
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
        onChanged: (value) {
          setState(() => _searchQuery = value);
          if (value.isNotEmpty) {
            Provider.of<AnalyticsService>(context, listen: false)
                .logEvent('search_query', {'query': value});
          }
        },
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search jobs, internships...',
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

  /// Build personalized greeting row
  Widget _buildGreetingRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreeting()}, ${_getFirstName()} 👋',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Explore opportunities tailored for you',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// Build dashboard grid with quick access cards (1 row x 4 columns - all visible)
  Widget _buildDashboardGrid() {
    return Row(
      children: [
        Expanded(
          child: DashboardCard(
            title: 'Jobs',
            icon: Icons.work_outline,
            onTap: () => widget.onSwitchTab?.call(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DashboardCard(
            title: 'Internships',
            icon: Icons.school_outlined,
            onTap: () => widget.onSwitchTab?.call(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DashboardCard(
            title: 'GSoC',
            icon: Icons.emoji_events_outlined,
            onTap: () => widget.onSwitchTab?.call(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DashboardCard(
            title: 'Learning',
            icon: Icons.auto_stories_outlined,
            onTap: () => widget.onSwitchTab?.call(4),
          ),
        ),
      ],
    );
  }

  /// Build section with header and content
  Widget _buildSection({
    required String title,
    required VoidCallback onSeeAll,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  /// Build shimmer loading carousel
  Widget _buildShimmerCarousel() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: AppTheme.surfaceColor,
              highlightColor: AppTheme.surfaceColor.withOpacity(0.5),
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build shimmer loading grid (2x3)
  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppTheme.surfaceColor,
            highlightColor: AppTheme.surfaceColor.withOpacity(0.5),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build jobs grid (2x3)
  Widget _buildJobsGrid(List jobs, AnalyticsService analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildJobGridCard(job, analytics);
        },
      ),
    );
  }

  /// Build internships grid (2x3)
  Widget _buildInternshipsGrid(
      List internships, AnalyticsService analytics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: internships.length,
        itemBuilder: (context, index) {
          final internship = internships[index];
          return _buildInternshipGridCard(internship, analytics);
        },
      ),
    );
  }

  /// Build compact job card for grid
  Widget _buildJobGridCard(dynamic job, AnalyticsService analytics) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          analytics.logEvent('job_card_tap', {'job': job.title});
          showJobDetailSheet(context, job);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.1),
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo
              if (job.logo != null && job.logo!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: job.logo!,
                    height: 36,
                    width: 36,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.work_outline,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
              const SizedBox(height: 8),
              // Job title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Company name
                    Text(
                      job.company,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      job.locations.isNotEmpty ? job.locations.first : 'Remote',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build compact internship card for grid
  Widget _buildInternshipGridCard(
      dynamic internship, AnalyticsService analytics) {
    // Safe access to logo (supports both 'logo' and 'companyLogo')
    final String? logoUrl = internship.logo ?? internship.companyLogo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          analytics.logEvent('internship_card_tap',
              {'internship': internship.title});
          showInternshipDetailSheet(context, internship);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.1),
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo
              if (logoUrl != null && logoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: logoUrl,
                    height: 36,
                    width: 36,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
              const SizedBox(height: 8),
              // Internship title and company
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      internship.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Company name
                    Text(
                      internship.company,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      internship.locations.isNotEmpty ? internship.locations.first : 'Remote',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
