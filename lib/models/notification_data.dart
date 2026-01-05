/// Model class for FCM notification data payload
///
/// Represents the structured data sent from the admin portal backend
/// in the "data" field of FCM messages.
class NotificationData {
  /// The target screen to navigate to
  final String screen;

  /// Optional parameters for navigation (e.g., jobId, internshipId, url)
  final Map<String, dynamic> params;

  /// Unique notification ID for tracking
  final String? notificationId;

  NotificationData({
    required this.screen,
    this.params = const {},
    this.notificationId,
  });

  /// Creates NotificationData from FCM message data payload
  factory NotificationData.fromMap(Map<String, dynamic> data) {
    final screen = data['screen'] as String? ?? 'home';
    final notificationId = data['notificationId'] as String?;

    // Extract all other fields as params (excluding screen and notificationId)
    final params = Map<String, dynamic>.from(data);
    params.remove('screen');
    params.remove('notificationId');

    return NotificationData(
      screen: screen,
      params: params,
      notificationId: notificationId,
    );
  }

  /// Converts to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'screen': screen,
      'notificationId': notificationId,
      ...params,
    };
  }

  @override
  String toString() {
    return 'NotificationData(screen: $screen, params: $params, notificationId: $notificationId)';
  }
}

/// Supported deep link screens
class NotificationScreens {
  static const String home = 'home';
  static const String jobs = 'jobs';
  static const String jobDetails = 'job_details';
  static const String internships = 'internships';
  static const String internshipDetails = 'internship_details';
  static const String gsoc = 'gsoc';
  static const String gsocOrg = 'gsoc_org';
  static const String roadmaps = 'roadmaps';
  static const String roadmapDetails = 'roadmap_details';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String webview = 'webview';

  /// Returns true if the screen value is supported
  static bool isSupported(String screen) {
    return [
      home,
      jobs,
      jobDetails,
      internships,
      internshipDetails,
      gsoc,
      gsocOrg,
      roadmaps,
      roadmapDetails,
      profile,
      settings,
      webview,
    ].contains(screen);
  }
}
