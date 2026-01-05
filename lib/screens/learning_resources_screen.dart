import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../widgets/guide_card.dart';
import '../widgets/roadmap_card.dart';
import '../widgets/filter_chips.dart';
import '../utils/theme.dart';
import 'guide_detail_sheet.dart';
import 'roadmap_detail_screen.dart';

/// Merged Learning Resources screen with Guides and Roadmaps tabs
class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({super.key});

  @override
  State<LearningResourcesScreen> createState() =>
      _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  String? _selectedType;

  final List<String> _categoryFilters = [
    'All',
    'DSA',
    'Development',
    'Design',
    'Data Science',
    'DevOps',
    'Mobile',
    'Security',
    'AI/ML',
    'Web3',
    'Interview Prep',
    'System Design',
  ];

  final List<String> _typeFilters = [
    'All Types',
    'Youtube',
    'Article',
    'Link',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('learning_resources');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: '📚 Guides'),
              Tab(text: '🗺️ Roadmaps'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGuidesTab(),
              _buildRoadmapsTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Guides tab content with filters
  Widget _buildGuidesTab() {
    final firebaseService = Provider.of<FirebaseService>(context);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    return Column(
      children: [
        // Category Filters
        FilterChips(
          filters: _categoryFilters,
          selectedFilter: _selectedCategory,
          onFilterSelected: (filter) {
            setState(() {
              _selectedCategory = filter == 'All' ? null : filter;
            });
            if (filter != null && filter != 'All') {
              analytics.logEvent('guide_filter_category', {'category': filter});
            }
          },
        ),

        // Type Filters
        FilterChips(
          filters: _typeFilters,
          selectedFilter: _selectedType,
          onFilterSelected: (filter) {
            setState(() {
              _selectedType = filter == 'All Types' ? null : filter;
            });
            if (filter != null && filter != 'All Types') {
              analytics.logEvent('guide_filter_type', {'type': filter});
            }
          },
        ),

        // Guides List
        Expanded(
          child: StreamBuilder(
            stream: firebaseService.getGuides(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 80,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No guides available',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              var guides = snapshot.data!;

              // Apply category filter
              if (_selectedCategory != null) {
                guides = guides
                    .where((guide) => guide.category
                        .toLowerCase()
                        .contains(_selectedCategory!.toLowerCase()))
                    .toList();
              }

              // Apply type filter
              if (_selectedType != null) {
                guides = guides
                    .where((guide) => guide.type
                        .toLowerCase()
                        .contains(_selectedType!.toLowerCase()))
                    .toList();
              }

              if (guides.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_alt_off,
                        size: 60,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No guides match the selected filters',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: guides.length,
                  itemBuilder: (context, index) {
                    final guide = guides[index];
                    return GuideCard(
                      guide: guide,
                      onTap: () {
                        analytics.logGuideOpen(guide.title, guide.category);
                        showGuideDetailSheet(context, guide);
                      },
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

  /// Build Roadmaps tab content
  Widget _buildRoadmapsTab() {
    final firebaseService = Provider.of<FirebaseService>(context);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);

    return StreamBuilder(
      stream: firebaseService.getRoadmaps(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 80,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No roadmaps available',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryColor,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final roadmap = snapshot.data![index];
              return RoadmapCard(
                roadmap: roadmap,
                onTap: () {
                  analytics.logRoadmapOpen(roadmap.name);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoadmapDetailScreen(roadmap: roadmap),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
