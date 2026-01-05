/// Model for Job and Internship opportunities
///
/// Supports fields from Firestore schema:
/// - For Jobs: company, title, description, salary, locations, tags, applyLink, logo,
///   deadline, postedDate, views, reportCount, isReported, lastReportedAt, reportReasons
/// - For Internships: company, title, companyLogo, location, locationType, tags,
///   applyLink, requirements, skills, deadline, duration, startDate, stipend
class Job {
  final String id;
  final String title;
  final String company;
  final String description;
  final String? salary;
  final List<String> locations; // NEW: Array of locations (was single location)
  final List<String> tags;
  final String applyLink;
  final String? logo;

  // Job posting metadata
  final int? deadline; // timestamp in milliseconds
  final int? postedDate; // NEW: timestamp in milliseconds
  final int? views;

  // Reporting fields
  final int? reportCount; // NEW: Number of reports
  final bool? isReported; // NEW: Whether job has been reported
  final int? lastReportedAt; // NEW: Last report timestamp
  final List<String>? reportReasons; // NEW: Array of report reasons

  // Additional internship-specific fields
  final String? locationType; // 'onsite', 'remote', 'hybrid'
  final List<String>? requirements;
  final List<String>? skills;
  final String? duration;
  final int? startDate; // timestamp in milliseconds
  final String? stipend;
  final bool? isActive;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    this.salary,
    required this.locations,
    required this.tags,
    required this.applyLink,
    this.logo,
    this.deadline,
    this.postedDate,
    this.views,
    this.reportCount,
    this.isReported,
    this.lastReportedAt,
    this.reportReasons,
    this.locationType,
    this.requirements,
    this.skills,
    this.duration,
    this.startDate,
    this.stipend,
    this.isActive,
  });

  factory Job.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle backward compatibility: support both single 'location' and 'locations' array
    List<String> locationsList = [];
    if (data['locations'] != null && data['locations'] is List) {
      locationsList = List<String>.from(data['locations']);
    } else if (data['location'] != null && data['location'] is String) {
      // Backward compatibility: convert single location to array
      locationsList = [data['location']];
    }

    // Handle stipend: can be String or Map
    String? stipendString;
    if (data['stipend'] != null) {
      if (data['stipend'] is String) {
        stipendString = data['stipend'];
      } else if (data['stipend'] is Map) {
        final stipendMap = data['stipend'] as Map<String, dynamic>;
        final amount = stipendMap['amount'];
        final currency = stipendMap['currency'] ?? 'INR';
        final period = stipendMap['period'] ?? 'monthly';
        if (amount != null) {
          stipendString = '$currency $amount/$period';
        }
      }
    }

    return Job(
      id: id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      description: data['description'] ?? '',
      salary: data['salary'],
      locations: locationsList,
      tags: List<String>.from(data['tags'] ?? []),
      applyLink: data['applyLink'] ?? '',
      // Support both 'logo' (for jobs) and 'companyLogo' (for internships)
      logo: data['companyLogo'] ?? data['logo'],
      // Job posting metadata
      deadline: data['deadline'],
      postedDate: data['postedDate'],
      views: data['views'],
      // Reporting fields
      reportCount: data['reportCount'],
      isReported: data['isReported'],
      lastReportedAt: data['lastReportedAt'],
      reportReasons: data['reportReasons'] != null
          ? List<String>.from(data['reportReasons'])
          : null,
      // Internship-specific fields
      locationType: data['locationType'],
      requirements: data['requirements'] != null
          ? List<String>.from(data['requirements'])
          : null,
      skills: data['skills'] != null
          ? List<String>.from(data['skills'])
          : null,
      duration: data['duration'],
      startDate: data['startDate'],
      stipend: stipendString,
      isActive: data['isActive'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'company': company,
      'description': description,
      'locations': locations, // NEW: Array of locations
      'tags': tags,
      'applyLink': applyLink,
    };

    // Add optional fields only if they're not null
    // Using null-aware operators to fix field promotion issues
    if (salary != null) map['salary'] = salary!;
    if (logo != null) map['logo'] = logo!; // Use 'logo' for jobs
    // Job posting metadata
    if (deadline != null) map['deadline'] = deadline!;
    if (postedDate != null) map['postedDate'] = postedDate!;
    if (views != null) map['views'] = views!;
    // Reporting fields
    if (reportCount != null) map['reportCount'] = reportCount!;
    if (isReported != null) map['isReported'] = isReported!;
    if (lastReportedAt != null) map['lastReportedAt'] = lastReportedAt!;
    if (reportReasons != null) map['reportReasons'] = reportReasons!;
    // Internship-specific fields
    if (locationType != null) map['locationType'] = locationType!;
    if (requirements != null) map['requirements'] = requirements!;
    if (skills != null) map['skills'] = skills!;
    if (duration != null) map['duration'] = duration!;
    if (startDate != null) map['startDate'] = startDate!;
    if (stipend != null) map['stipend'] = stipend!;
    if (isActive != null) map['isActive'] = isActive!;

    return map;
  }

  /// Helper getter for backward compatibility (internships use companyLogo)
  String? get companyLogo => logo;

  /// Helper method to get formatted deadline date
  DateTime? get deadlineDate {
    return deadline != null
        ? DateTime.fromMillisecondsSinceEpoch(deadline!)
        : null;
  }

  /// Helper method to get formatted start date
  DateTime? get startDateTime {
    return startDate != null
        ? DateTime.fromMillisecondsSinceEpoch(startDate!)
        : null;
  }

  /// Helper method to get formatted posted date
  DateTime? get postedDateTime {
    return postedDate != null
        ? DateTime.fromMillisecondsSinceEpoch(postedDate!)
        : null;
  }

  /// Helper method to get formatted last reported date
  DateTime? get lastReportedDateTime {
    return lastReportedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(lastReportedAt!)
        : null;
  }

  /// Check if internship/job is still active and not past deadline
  bool get isStillActive {
    if (isActive == false) return false;
    if (deadline == null) return true;
    return DateTime.now().millisecondsSinceEpoch < deadline!;
  }

  /// Get primary location for display (Remote/Hybrid/On-site or first location)
  String get primaryLocation {
    if (locations.isEmpty) return 'Not specified';

    // Prefer work modes (Remote, Hybrid, On-site) if present
    final workModes = ['Remote', 'Hybrid', 'On-site'];
    for (var mode in workModes) {
      if (locations.any((loc) => loc.toLowerCase() == mode.toLowerCase())) {
        return mode;
      }
    }

    // Otherwise return first location
    return locations.first;
  }

  /// Get formatted location string for display
  String get locationDisplay {
    if (locations.isEmpty) return 'Not specified';

    if (locations.length == 1) {
      return locations.first;
    }

    // If multiple locations, show first one + count
    return '${locations.first} +${locations.length - 1} more';
  }

  /// Check if job has multiple locations
  bool get hasMultipleLocations {
    return locations.length > 1;
  }
}
