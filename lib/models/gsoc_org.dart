class GsocOrg {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String imageBackgroundColor;
  final String url;
  final String category;
  final String? blogUrl;
  final String? contactEmail;
  final String? ircChannel;
  final String? mailingList;
  final String? twitterUrl;
  final String? projectsUrl;
  final int numProjects;
  final List<String> technologies;
  final List<String> topics;
  final List<GsocProject> projects;

  GsocOrg({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.imageBackgroundColor,
    required this.url,
    required this.category,
    this.blogUrl,
    this.contactEmail,
    this.ircChannel,
    this.mailingList,
    this.twitterUrl,
    this.projectsUrl,
    required this.numProjects,
    required this.technologies,
    required this.topics,
    required this.projects,
  });

  factory GsocOrg.fromFirestore(Map<String, dynamic> data, String id) {
    return GsocOrg(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',
      imageBackgroundColor: data['image_background_color'] ?? '#ffffff',
      url: data['url'] ?? '',
      category: data['category'] ?? '',
      blogUrl: data['blog_url'],
      contactEmail: data['contact_email'],
      ircChannel: data['irc_channel'],
      mailingList: data['mailing_list'],
      twitterUrl: data['twitter_url'],
      projectsUrl: data['projects_url'],
      numProjects: data['num_projects'] ?? 0,
      technologies: List<String>.from(data['technologies'] ?? []),
      topics: List<String>.from(data['topics'] ?? []),
      projects: (data['projects'] as List<dynamic>?)
              ?.map((p) => GsocProject.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'image_background_color': imageBackgroundColor,
      'url': url,
      'category': category,
      'blog_url': blogUrl,
      'contact_email': contactEmail,
      'irc_channel': ircChannel,
      'mailing_list': mailingList,
      'twitter_url': twitterUrl,
      'projects_url': projectsUrl,
      'num_projects': numProjects,
      'technologies': technologies,
      'topics': topics,
      'projects': projects.map((p) => p.toMap()).toList(),
    };
  }
}

class GsocProject {
  final String title;
  final String description;
  final String shortDescription;
  final String studentName;
  final String projectUrl;
  final String? codeUrl;

  GsocProject({
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.studentName,
    required this.projectUrl,
    this.codeUrl,
  });

  factory GsocProject.fromMap(Map<String, dynamic> data) {
    return GsocProject(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      shortDescription: data['short_description'] ?? '',
      studentName: data['student_name'] ?? '',
      projectUrl: data['project_url'] ?? '',
      codeUrl: data['code_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'short_description': shortDescription,
      'student_name': studentName,
      'project_url': projectUrl,
      'code_url': codeUrl,
    };
  }
}
