class Milestone {
  final String title;
  final String description;
  final List<String> topics;
  final String? resourceLink;
  final List<String> readLinks;
  final List<String> watchLinks;
  final List<String> buildProjects;
  final String? courseLink;

  Milestone({
    required this.title,
    required this.description,
    required this.topics,
    this.resourceLink,
    this.readLinks = const [],
    this.watchLinks = const [],
    this.buildProjects = const [],
    this.courseLink,
  });

  factory Milestone.fromMap(Map<String, dynamic> data) {
    return Milestone(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      topics: List<String>.from(data['topics'] ?? []),
      resourceLink: data['resourceLink'],
      readLinks: List<String>.from(data['readLinks'] ?? []),
      watchLinks: List<String>.from(data['watchLinks'] ?? []),
      buildProjects: List<String>.from(data['buildProjects'] ?? []),
      courseLink: data['courseLink'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'topics': topics,
      'resourceLink': resourceLink,
      'readLinks': readLinks,
      'watchLinks': watchLinks,
      'buildProjects': buildProjects,
      'courseLink': courseLink,
    };
  }
}

class Roadmap {
  final String id;
  final String name;
  final String description;
  final String level;
  final String? logo;
  final String category;
  final String? externalReferenceLink;
  final List<Milestone> milestones;

  Roadmap({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    this.logo,
    required this.category,
    this.externalReferenceLink,
    required this.milestones,
  });

  factory Roadmap.fromFirestore(Map<String, dynamic> data, String id) {
    List<Milestone> milestones = [];
    if (data['milestones'] != null) {
      milestones = (data['milestones'] as List)
          .map((m) => Milestone.fromMap(m as Map<String, dynamic>))
          .toList();
    }

    return Roadmap(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      level: data['level'] ?? '',
      logo: data['logo'],
      category: data['category'] ?? '',
      externalReferenceLink: data['externalReferenceLink'],
      milestones: milestones,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'level': level,
      'logo': logo,
      'category': category,
      'externalReferenceLink': externalReferenceLink,
      'milestones': milestones.map((m) => m.toMap()).toList(),
    };
  }
}
