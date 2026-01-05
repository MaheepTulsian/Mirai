import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/notification_data.dart';
import '../screens/main_navigation.dart';
import '../screens/profile_screen.dart';
import '../screens/saved_screen.dart';

/// Service responsible for handling deep link navigation from notifications
///
/// Parses notification data and navigates to the appropriate screen
/// based on the screen value and parameters.
class NotificationNavigator {
  /// Navigates to the screen specified in notification data
  ///
  /// [context] - BuildContext for navigation
  /// [data] - NotificationData containing screen and params
  static Future<void> navigate(BuildContext context, NotificationData data) async {
    debugPrint('NotificationNavigator: Navigating to ${data.screen} with params ${data.params}');

    try {
      switch (data.screen) {
        case NotificationScreens.home:
          await _navigateToHome(context);
          break;

        case NotificationScreens.jobs:
          await _navigateToJobs(context);
          break;

        case NotificationScreens.jobDetails:
          await _navigateToJobDetails(context, data.params);
          break;

        case NotificationScreens.internships:
          await _navigateToInternships(context);
          break;

        case NotificationScreens.internshipDetails:
          await _navigateToInternshipDetails(context, data.params);
          break;

        case NotificationScreens.gsoc:
          await _navigateToGsoc(context);
          break;

        case NotificationScreens.gsocOrg:
          await _navigateToGsocOrg(context, data.params);
          break;

        case NotificationScreens.roadmaps:
          await _navigateToRoadmaps(context);
          break;

        case NotificationScreens.roadmapDetails:
          await _navigateToRoadmapDetails(context, data.params);
          break;

        case NotificationScreens.profile:
          await _navigateToProfile(context);
          break;

        case NotificationScreens.settings:
          await _navigateToSettings(context);
          break;

        case NotificationScreens.webview:
          await _openWebview(context, data.params);
          break;

        default:
          debugPrint('NotificationNavigator: Unknown screen ${data.screen}, defaulting to home');
          await _navigateToHome(context);
      }
    } catch (e) {
      debugPrint('NotificationNavigator: Error navigating to ${data.screen}: $e');
      // Fallback to home on error
      await _navigateToHome(context);
    }
  }

  /// Navigate to home screen (no action needed, MainNavigation handles it)
  static Future<void> _navigateToHome(BuildContext context) async {
    // If already on MainNavigation, switch to home tab
    // Otherwise, navigate to MainNavigation
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate to Jobs screen (tab index 1)
  static Future<void> _navigateToJobs(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    // The MainNavigation will handle tab switching
    // We need a way to pass the tab index - will be handled in main.dart
  }

  /// Navigate to specific job details
  static Future<void> _navigateToJobDetails(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final jobId = params['jobId'] as String?;
    if (jobId == null) {
      debugPrint('NotificationNavigator: jobId is required for job_details');
      await _navigateToJobs(context);
      return;
    }

    // Import and navigate to JobDetailsScreen when implemented
    debugPrint('NotificationNavigator: Navigate to job details with ID: $jobId');
    // TODO: Implement when JobDetailsScreen is created
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => JobDetailsScreen(jobId: jobId),
    // ));
  }

  /// Navigate to Internships screen (tab index 2)
  static Future<void> _navigateToInternships(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    // The MainNavigation will handle tab switching
  }

  /// Navigate to specific internship details
  static Future<void> _navigateToInternshipDetails(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final internshipId = params['internshipId'] as String?;
    if (internshipId == null) {
      debugPrint('NotificationNavigator: internshipId is required for internship_details');
      await _navigateToInternships(context);
      return;
    }

    debugPrint('NotificationNavigator: Navigate to internship details with ID: $internshipId');
    // TODO: Implement when InternshipDetailsScreen is created
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => InternshipDetailsScreen(internshipId: internshipId),
    // ));
  }

  /// Navigate to GSoC screen (tab index 3)
  static Future<void> _navigateToGsoc(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate to specific GSoC organization
  static Future<void> _navigateToGsocOrg(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final orgId = params['orgId'] as String?;
    if (orgId == null) {
      debugPrint('NotificationNavigator: orgId is required for gsoc_org');
      await _navigateToGsoc(context);
      return;
    }

    debugPrint('NotificationNavigator: Navigate to GSoC org with ID: $orgId');
    // TODO: Implement when GsocOrgDetailsScreen is created
  }

  /// Navigate to Roadmaps screen (tab index 4)
  static Future<void> _navigateToRoadmaps(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate to specific roadmap details
  static Future<void> _navigateToRoadmapDetails(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final roadmapId = params['roadmapId'] as String?;
    if (roadmapId == null) {
      debugPrint('NotificationNavigator: roadmapId is required for roadmap_details');
      await _navigateToRoadmaps(context);
      return;
    }

    debugPrint('NotificationNavigator: Navigate to roadmap details with ID: $roadmapId');
    // TODO: Implement when RoadmapDetailsScreen is created
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => RoadmapDetailsScreen(roadmapId: roadmapId),
    // ));
  }

  /// Navigate to Profile screen
  static Future<void> _navigateToProfile(BuildContext context) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  /// Navigate to Settings screen
  static Future<void> _navigateToSettings(BuildContext context) async {
    debugPrint('NotificationNavigator: Settings screen not implemented yet');
    // TODO: Implement when SettingsScreen is created
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => const SettingsScreen(),
    // ));
  }

  /// Open URL in webview or external browser
  static Future<void> _openWebview(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final url = params['url'] as String?;
    if (url == null) {
      debugPrint('NotificationNavigator: url is required for webview');
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
      } else {
        debugPrint('NotificationNavigator: Cannot launch URL: $url');
      }
    } catch (e) {
      debugPrint('NotificationNavigator: Error launching URL: $e');
    }
  }
}
