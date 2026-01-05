/// Guide model for learning guides and educational resources
///
/// Supports multiple content types:
/// - YouTube: Video tutorials
/// - Article: Written guides/blog posts
/// - Link: External resource links
class Guide {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type; // 'Youtube', 'Article', 'Link'
  final String resourceLink;
  final String? logo;
  final List<String> topics;
  final List<String> steps;
  final int? createdAt;
  final int? updatedAt;
  final int views;

  Guide({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.resourceLink,
    this.logo,
    required this.topics,
    required this.steps,
    this.createdAt,
    this.updatedAt,
    this.views = 0,
  });

  factory Guide.fromFirestore(Map<String, dynamic> data, String id) {
    return Guide(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      type: data['type'] ?? 'Link',
      resourceLink: data['resourceLink'] ?? '',
      logo: data['logo'],
      topics: data['topics'] != null ? List<String>.from(data['topics']) : [],
      steps: data['steps'] != null ? List<String>.from(data['steps']) : [],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      views: data['views'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'resourceLink': resourceLink,
      'topics': topics,
      'steps': steps,
      'views': views,
    };

    if (logo != null) map['logo'] = logo;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;

    return map;
  }

  /// Get guide type icon based on type
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'youtube':
        return '📺';
      case 'article':
        return '📄';
      case 'link':
        return '🔗';
      default:
        return '📚';
    }
  }

  /// Get guide type display name
  String get typeDisplay {
    return type;
  }

  /// Check if guide is a YouTube video
  bool get isYouTube => type.toLowerCase() == 'youtube';

  /// Check if guide is an article
  bool get isArticle => type.toLowerCase() == 'article';

  /// Check if guide is a link
  bool get isLink => type.toLowerCase() == 'link';

  /// Get formatted view count
  String get viewsDisplay {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$views views';
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
}
