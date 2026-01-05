import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../widgets/guide_card.dart';
import '../widgets/filter_chips.dart';
import 'guide_detail_sheet.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
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
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('guides');
  }

  @override
  Widget build(BuildContext context) {
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

        Expanded(
          child: StreamBuilder(
            stream: firebaseService.getGuides(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 80,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No guides available',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later for learning resources',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              var guides = snapshot.data!;

              // Filter by category
              if (_selectedCategory != null) {
                guides = guides
                    .where((guide) =>
                        guide.category.toLowerCase() ==
                        _selectedCategory!.toLowerCase())
                    .toList();
              }

              // Filter by type
              if (_selectedType != null) {
                guides = guides
                    .where((guide) =>
                        guide.type.toLowerCase() ==
                        _selectedType!.toLowerCase())
                    .toList();
              }

              if (guides.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No guides found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting your filters',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
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
              );
            },
          ),
        ),
      ],
    );
  }
}
