/// App-wide constants and configuration values
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ===== Data Fetch Limits =====

  /// Maximum number of internships to fetch on main screen
  static const int internshipsLimit = 50;

  /// Maximum number of jobs to fetch on main screen
  static const int jobsLimit = 50;

  /// Maximum number of courses to fetch
  static const int coursesLimit = 50;

  /// Maximum number of roadmaps to fetch
  static const int roadmapsLimit = 50;

  /// Number of items to show on home screen preview
  static const int homePreviewLimit = 2;

  /// Number of recommendations to fetch for similarity matching
  static const int recommendationsFetchLimit = 15;

  /// Maximum number of recommendations to display
  static const int recommendationsDisplayLimit = 3;

  // ===== UI Configuration =====

  /// Maximum number of tech tags to display on cards
  static const int maxTagsOnCard = 3;

  /// ListView cache extent for better scrolling performance (in pixels)
  static const double listViewCacheExtent = 500.0;

  /// Standard card height estimate for ListView optimization
  static const double estimatedCardHeight = 220.0;

  /// Debounce duration for search/filter operations
  static const Duration searchDebounce = Duration(milliseconds: 300);

  // ===== Image Configuration =====

  /// Company logo size on cards (width & height)
  static const double logoSizeCard = 56.0;

  /// Company logo size on detail sheets
  static const double logoSizeDetail = 64.0;

  /// Company logo size on recommendations
  static const double logoSizeRecommendation = 48.0;

  /// Maximum image cache age
  static const Duration imageCacheAge = Duration(days: 7);

  // ===== Tag Filtering =====

  /// Tags to exclude from display (meta tags)
  static const List<String> excludedTags = [
    'paid',
    'remote',
    'internship',
    'job',
    'full-time',
    'part-time',
  ];

  // ===== Animation Durations =====

  /// Standard animation duration for UI transitions
  static const Duration standardAnimation = Duration(milliseconds: 300);

  /// Quick animation for small UI changes
  static const Duration quickAnimation = Duration(milliseconds: 150);

  /// Slow animation for large transitions
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // ===== Error Messages =====

  static const String errorNoInternet = 'No internet connection. Please check your network.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorLoadingData = 'Failed to load data. Pull to refresh.';
  static const String errorSavingItem = 'Failed to save item. Please try again.';

  // ===== Empty State Messages =====

  static const String emptyInternships = 'No internships available yet';
  static const String emptyJobs = 'No jobs available yet';
  static const String emptyCourses = 'No courses available yet';
  static const String emptyRoadmaps = 'No roadmaps available yet';
  static const String emptyFilteredResults = 'No results found for selected filter';

  // ===== Success Messages =====

  static const String successItemSaved = 'Item saved successfully!';
  static const String successItemRemoved = 'Item removed successfully!';
  static const String successReportSubmitted = 'Report submitted successfully!';

  // ===== API Configuration =====

  /// Base API URL for admin portal (update with your actual URL)
  static const String apiBaseUrl = 'YOUR_ADMIN_PORTAL_API_URL'; // TODO: Update with actual URL

  /// API Endpoints
  static const String apiJobsEndpoint = '/api/jobs';
  static const String apiReportsEndpoint = '/api/reports';

  // ===== Report Reasons =====

  /// Available reasons for reporting content
  static const List<ReportReason> reportReasons = [
    ReportReason(
      value: 'expired',
      label: 'Expired',
      description: 'Job posting has expired',
    ),
    ReportReason(
      value: 'broken_link',
      label: 'Broken Link',
      description: 'Application link is not working',
    ),
    ReportReason(
      value: 'incorrect_info',
      label: 'Incorrect Info',
      description: 'Information is incorrect or misleading',
    ),
    ReportReason(
      value: 'duplicate',
      label: 'Duplicate',
      description: 'Duplicate posting',
    ),
    ReportReason(
      value: 'spam',
      label: 'Spam',
      description: 'Spam or fraudulent posting',
    ),
    ReportReason(
      value: 'other',
      label: 'Other',
      description: 'Other issue',
    ),
  ];
}

/// Model for report reasons
class ReportReason {
  final String value;
  final String label;
  final String description;

  const ReportReason({
    required this.value,
    required this.label,
    required this.description,
  });
}
