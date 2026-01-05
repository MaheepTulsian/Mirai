class SavedItem {
  final String id;
  final String type; // job, roadmap, course, guide
  final String name;
  final String? link;
  final String? logo;
  final DateTime timestamp;

  SavedItem({
    required this.id,
    required this.type,
    required this.name,
    this.link,
    this.logo,
    required this.timestamp,
  });

  factory SavedItem.fromFirestore(Map<String, dynamic> data, String id) {
    return SavedItem(
      id: id,
      type: data['type'] ?? '',
      name: data['name'] ?? '',
      link: data['link'],
      logo: data['logo'],
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'link': link,
      'logo': logo,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
