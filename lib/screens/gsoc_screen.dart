import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../models/gsoc_org.dart';
import '../utils/url_launcher_helper.dart';
import '../utils/theme.dart';

class GsocScreen extends StatefulWidget {
  const GsocScreen({super.key});

  @override
  State<GsocScreen> createState() => _GsocScreenState();
}

class _GsocScreenState extends State<GsocScreen> {
  String _selectedYear = '';
  final List<String> _selectedTechnologies = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _availableYears = [];
  bool _isLoadingYears = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('gsoc');
    _fetchAvailableYears();
  }

  Future<void> _fetchAvailableYears() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final years = await firebaseService.getAvailableGsocYears();

    setState(() {
      _availableYears = years;
      // Set the latest year (first in sorted list) as default
      _selectedYear = years.isNotEmpty ? years.first : '2024';
      _isLoadingYears = false;
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showTechnologyFilter(List<String> allTechnologies) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Technologies',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTechnologies.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: allTechnologies.length,
                  itemBuilder: (context, index) {
                    final tech = allTechnologies[index];
                    final isSelected = _selectedTechnologies.contains(tech);
                    return CheckboxListTile(
                      title: Text(tech),
                      value: isSelected,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedTechnologies.add(tech);
                          } else {
                            _selectedTechnologies.remove(tech);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Apply Filters (${_selectedTechnologies.length})',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<GsocOrg> _filterOrganizations(List<GsocOrg> orgs) {
    List<GsocOrg> filtered = orgs;

    // Filter by search query (name, description, or technologies)
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered.where((org) {
        return org.name.toLowerCase().contains(searchLower) ||
            org.description.toLowerCase().contains(searchLower) ||
            org.category.toLowerCase().contains(searchLower) ||
            org.technologies.any((tech) => tech.toLowerCase().contains(searchLower)) ||
            org.topics.any((topic) => topic.toLowerCase().contains(searchLower));
      }).toList();
    }

    // Filter by technologies
    if (_selectedTechnologies.isNotEmpty) {
      filtered = filtered.where((org) {
        return org.technologies
            .any((tech) => _selectedTechnologies.contains(tech));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    // Show loading while fetching years
    if (_isLoadingYears) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading GSoC years...'),
          ],
        ),
      );
    }

    // Show error if no years found
    if (_availableYears.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No GSoC data available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchAvailableYears,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar - Modern & Full Width
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.textSecondary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search organizations...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.6),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),

        // Year Filter Chips - Horizontal Scroll
        Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _availableYears.length,
            itemBuilder: (context, index) {
              final year = _availableYears[index];
              final isSelected = _selectedYear == year;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedYear = year;
                        _selectedTechnologies.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary.withOpacity(0.3),
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        year,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Organizations Grid
        Expanded(
          child: StreamBuilder<List<GsocOrg>>(
            stream: firebaseService.getGsocOrgs(year: _selectedYear),
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
                        Icons.search_off,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No organizations found for $_selectedYear',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                );
              }

              // Get all unique technologies for filter
              final allTechnologies = <String>{};
              for (var org in snapshot.data!) {
                allTechnologies.addAll(org.technologies);
              }
              final sortedTechnologies = allTechnologies.toList()..sort();

              // Apply filters
              final filteredOrgs = _filterOrganizations(snapshot.data!);

              return Column(
                children: [
                  // Filter Row & Results Count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Technology Dropdown Filter
                        Expanded(
                          child: InkWell(
                            onTap: () => _showTechnologyFilter(sortedTechnologies),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTechnologies.isEmpty
                                    ? AppTheme.surfaceColor
                                    : AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedTechnologies.isEmpty
                                      ? AppTheme.textSecondary.withOpacity(0.3)
                                      : AppTheme.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 18,
                                    color: _selectedTechnologies.isEmpty
                                        ? AppTheme.textSecondary
                                        : AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedTechnologies.isEmpty
                                          ? 'Filter by Technology'
                                          : '${_selectedTechnologies.length} selected',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTechnologies.isEmpty
                                            ? AppTheme.textSecondary
                                            : AppTheme.primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: _selectedTechnologies.isEmpty
                                        ? AppTheme.textSecondary
                                        : AppTheme.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_selectedTechnologies.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedTechnologies.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.surfaceColor,
                              foregroundColor: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Results Count
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.textSecondary.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filteredOrgs.length} ${filteredOrgs.length == 1 ? 'organization' : 'organizations'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_searchQuery.isNotEmpty || _selectedTechnologies.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                                _selectedTechnologies.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Grid View
                  Expanded(
                    child: filteredOrgs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.filter_alt_off,
                                  size: 64,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No organizations match your filters',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedTechnologies.clear();
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                  child: const Text('Clear all filters'),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filteredOrgs.length,
                            itemBuilder: (context, index) {
                              final org = filteredOrgs[index];
                              return _buildOrgGridCard(org, _selectedYear);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrgGridCard(GsocOrg org, String year) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: AppTheme.textSecondary.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showOrgDetails(org, year),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organization Logo with Year Badge
                Stack(
                  children: [
                    Container(
                      height: 110,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor.withOpacity(0.5),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: org.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.business_rounded,
                          size: 48,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ),
                    // Year Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          year,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Organization Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Organization Name
                        Text(
                          org.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Category Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            org.category,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const Spacer(),

                        // Project Count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.textSecondary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.code_rounded,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${org.numProjects} ${org.numProjects == 1 ? 'project' : 'projects'}',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrgDetails(GsocOrg org, String year) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildOrgCard(org, year),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrgCard(GsocOrg org, String year) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Organization Header
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Year Badge at Top
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Google Summer of Code $year',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: org.imageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 64,
                          height: 64,
                          color: AppTheme.surfaceColor,
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 64,
                          height: 64,
                          color: AppTheme.surfaceColor,
                          child: const Icon(Icons.business, size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              org.category,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  org.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Technologies
                if (org.technologies.isNotEmpty) ...[
                  Text(
                    'Technologies',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: org.technologies
                        .map((tech) => Chip(
                              label: Text(tech),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              labelStyle: Theme.of(context).textTheme.bodySmall,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Topics
                if (org.topics.isNotEmpty) ...[
                  Text(
                    'Topics',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: org.topics
                        .map((topic) => Chip(
                              label: Text(topic),
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Visit Website Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => UrlLauncherHelper.launchURL(org.url),
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: const Text('Visit Organization Website'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Projects Section
        if (org.projects.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.code_rounded,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'GSoC $year Projects (${org.numProjects})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...org.projects.map((project) => _buildProjectCard(project, year)),
        ],
      ],
    );
  }

  Widget _buildProjectCard(GsocProject project, String year) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Title with Year Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    year,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Student Name
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'By ${project.studentName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              project.shortDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                // Code Button
                if (project.codeUrl != null && project.codeUrl!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => UrlLauncherHelper.launchURL(project.codeUrl!),
                      icon: const Icon(Icons.code, size: 16),
                      label: const Text('Code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),

                if (project.codeUrl != null && project.codeUrl!.isNotEmpty)
                  const SizedBox(width: 8),

                // Project Details Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => UrlLauncherHelper.launchURL(project.projectUrl),
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
