import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track app open
  Future<void> logAppOpen() async {
    await _analytics.logEvent(name: 'app_open');
  }

  // Track screen views
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Track job open
  Future<void> logJobOpen(String jobTitle, String company) async {
    await _analytics.logEvent(
      name: 'job_open',
      parameters: {
        'job_title': jobTitle,
        'company': company,
      },
    );
  }

  // Track roadmap open
  Future<void> logRoadmapOpen(String roadmapName) async {
    await _analytics.logEvent(
      name: 'roadmap_open',
      parameters: {
        'roadmap_name': roadmapName,
      },
    );
  }

  // Track guide open
  Future<void> logGuideOpen(String guideTitle, String category) async {
    await _analytics.logEvent(
      name: 'guide_open',
      parameters: {
        'guide_title': guideTitle,
        'category': category,
      },
    );
  }

  // Track course open
  Future<void> logCourseOpen(String courseTitle, String platform) async {
    await _analytics.logEvent(
      name: 'course_open',
      parameters: {
        'course_title': courseTitle,
        'platform': platform,
      },
    );
  }

  // Track org search
  Future<void> logOrgSearch(String query) async {
    await _analytics.logEvent(
      name: 'org_search',
      parameters: {
        'search_query': query,
      },
    );
  }

  // Track contributor search
  Future<void> logContributorSearch(String query) async {
    await _analytics.logEvent(
      name: 'contributor_search',
      parameters: {
        'search_query': query,
      },
    );
  }

  // Track profile update
  Future<void> logProfileUpdated(String graduatingYear, String college) async {
    await _analytics.logEvent(
      name: 'profile_updated',
      parameters: {
        'graduating_year': graduatingYear,
        'college': college,
      },
    );
  }

  // Track item saved
  Future<void> logItemSaved(String itemType, String itemName) async {
    await _analytics.logEvent(
      name: 'item_saved',
      parameters: {
        'item_type': itemType,
        'item_name': itemName,
      },
    );
  }

  // Track roadmap share
  Future<void> logShareRoadmap(String roadmapName) async {
    await _analytics.logEvent(
      name: 'share_roadmap',
      parameters: {
        'roadmap_name': roadmapName,
      },
    );
  }

  // Track login (Firebase built-in event)
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // Track custom event
  Future<void> logEvent(String eventName, [Map<String, dynamic>? parameters]) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters?.cast<String, Object>(),
    );
  }

  // Track card clicks
  Future<void> logJobCardClick(String jobTitle, String company) async {
    await _analytics.logEvent(
      name: 'job_card_click',
      parameters: {
        'job_title': jobTitle,
        'company': company,
      },
    );
  }

  Future<void> logRoadmapCardClick(String roadmapName) async {
    await _analytics.logEvent(
      name: 'roadmap_card_click',
      parameters: {
        'roadmap_name': roadmapName,
      },
    );
  }

  Future<void> logGuideCardClick(String guideTitle, String category) async {
    await _analytics.logEvent(
      name: 'guide_card_click',
      parameters: {
        'guide_title': guideTitle,
        'category': category,
      },
    );
  }

  Future<void> logCourseCardClick(String courseTitle, String platform) async {
    await _analytics.logEvent(
      name: 'course_card_click',
      parameters: {
        'course_title': courseTitle,
        'platform': platform,
      },
    );
  }
}
