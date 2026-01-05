/// Course model for online learning courses
///
/// Supports courses from multiple platforms:
/// - Coursera, Udemy, edX, Udacity, LinkedIn Learning, etc.
/// - Includes pricing, ratings, levels, and enrollment tracking
class Course {
  final String id;
  final String title;
  final String description;
  final String platform;
  final String instructor;
  final String duration;
  final String level; // 'beginner', 'intermediate', 'advanced'
  final double price;
  final double? originalPrice;
  final String enrollLink;
  final String? logo;
  final double? rating;
  final bool isActive;
  final List<String> tags;
  final int views;
  final int enrollments;
  final int? createdAt;
  final int? updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.platform,
    required this.instructor,
    required this.duration,
    required this.level,
    required this.price,
    this.originalPrice,
    required this.enrollLink,
    this.logo,
    this.rating,
    this.isActive = true,
    required this.tags,
    this.views = 0,
    this.enrollments = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Course.fromFirestore(Map<String, dynamic> data, String id) {
    return Course(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      platform: data['platform'] ?? '',
      instructor: data['instructor'] ?? '',
      duration: data['duration'] ?? '',
      level: data['level'] ?? 'beginner',
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: data['originalPrice']?.toDouble(),
      enrollLink: data['enrollLink'] ?? '',
      logo: data['logo'],
      rating: data['rating']?.toDouble(),
      isActive: data['isActive'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      views: data['views'] ?? 0,
      enrollments: data['enrollments'] ?? 0,
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'platform': platform,
      'instructor': instructor,
      'duration': duration,
      'level': level,
      'price': price,
      'enrollLink': enrollLink,
      'isActive': isActive,
      'tags': tags,
      'views': views,
      'enrollments': enrollments,
    };

    if (originalPrice != null) map['originalPrice'] = originalPrice;
    if (logo != null) map['logo'] = logo;
    if (rating != null) map['rating'] = rating;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;

    return map;
  }

  /// Check if course is on discount
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// Calculate discount percentage
  double get discountPercentage {
    if (!hasDiscount || originalPrice == 0) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  /// Check if course is free
  bool get isFree => price == 0;

  /// Get formatted price with currency
  String get priceDisplay {
    if (isFree) return 'FREE';
    return '₹${price.toStringAsFixed(0)}';
  }

  /// Get formatted original price
  String? get originalPriceDisplay {
    if (originalPrice == null) return null;
    return '₹${originalPrice!.toStringAsFixed(0)}';
  }

  /// Get rating display with stars
  String get ratingDisplay {
    if (rating == null) return 'No rating';
    return '⭐ ${rating!.toStringAsFixed(1)}';
  }

  /// Get views display
  String get viewsDisplay {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$views views';
    }
  }

  /// Get enrollments display
  String get enrollmentsDisplay {
    if (enrollments >= 1000000) {
      return '${(enrollments / 1000000).toStringAsFixed(1)}M enrolled';
    } else if (enrollments >= 1000) {
      return '${(enrollments / 1000).toStringAsFixed(1)}K enrolled';
    } else {
      return '$enrollments enrolled';
    }
  }

  /// Get created date
  DateTime? get createdDate {
    return createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(createdAt!)
        : null;
  }

  /// Get updated date
  DateTime? get updatedDate {
    return updatedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(updatedAt!)
        : null;
  }

  /// Get level color
  String get levelColor {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'green';
      case 'intermediate':
        return 'orange';
      case 'advanced':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get level display name
  String get levelDisplay {
    return level[0].toUpperCase() + level.substring(1);
  }
}
