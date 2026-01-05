import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<void> launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        // Try external browser first, fallback to platform default
        bool launched = false;

        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          print('External browser failed, trying platform default: $e');
        }

        // Fallback to platform default if external failed
        if (!launched) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        }

        if (!launched) {
          throw 'Could not launch $url';
        }
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      // Don't throw, just show error - prevents app crash
      rethrow;
    }
  }
}
