import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/job.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../widgets/job_card.dart';
import '../utils/theme.dart';
import 'job_detail_sheet.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Newest'; // Default sort
  bool _showSearchBar = false;

  /// Sort options
  final List<String> _sortOptions = [
    'Newest',
    'Company',
    'Location',
  ];

  @override
  void initState() {
    super.initState();
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('jobs');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Sort jobs based on selected criteria
  List<Job> _sortJobs(List<Job> jobs) {
    final sorted = List<Job>.from(jobs);

    switch (_selectedSort) {
      case 'Company':
        sorted.sort((a, b) => a.company.toLowerCase().compareTo(b.company.toLowerCase()));
        break;
      case 'Location':
        sorted.sort((a, b) => a.locationDisplay.toLowerCase().compareTo(b.locationDisplay.toLowerCase()));
        break;
      case 'Newest':
      default:
        sorted.sort((a, b) {
          if (a.postedDate == null && b.postedDate == null) return 0;
          if (a.postedDate == null) return 1;
          if (b.postedDate == null) return -1;
          return b.postedDate!.compareTo(a.postedDate!);
        });
        break;
    }

    return sorted;
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

        // Jobs List
        Expanded(
          child: StreamBuilder(
            stream: firebaseService.getJobs(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeletonLoader();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 80,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No jobs available',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later for new opportunities',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              // Filter by search query and apply sorting
              var jobs = snapshot.data!;

              if (_searchQuery.isNotEmpty) {
                jobs = jobs.where((job) {
                  return job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      job.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      job.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
                }).toList();
              }

              jobs = _sortJobs(jobs);

              if (jobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No jobs found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting your filters',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                cacheExtent: 500,
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return JobCard(
                    key: ValueKey(job.id),
                    job: job,
                    onTap: () {
                      analytics.logEvent('job_card_tap', {'job': job.title});
                      showJobDetailSheet(context, job);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
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
                .logEvent('job_search', {'query': value});
          }
        },
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search jobs...',
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
                      analytics.logEvent('job_sort_changed', {
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

  /// Build skeleton loader
  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
}
