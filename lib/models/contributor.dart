class Contributor {
  final String id;
  final String name;
  final String github;
  final List<String> expertise;
  final List<String>? contributions;
  final List<String>? topRepos;

  Contributor({
    required this.id,
    required this.name,
    required this.github,
    required this.expertise,
    this.contributions,
    this.topRepos,
  });

  factory Contributor.fromFirestore(Map<String, dynamic> data, String id) {
    return Contributor(
      id: id,
      name: data['name'] ?? '',
      github: data['github'] ?? '',
      expertise: List<String>.from(data['expertise'] ?? []),
      contributions: data['contributions'] != null
          ? List<String>.from(data['contributions'])
          : null,
      topRepos:
          data['topRepos'] != null ? List<String>.from(data['topRepos']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'github': github,
      'expertise': expertise,
      'contributions': contributions,
      'topRepos': topRepos,
    };
  }
}
