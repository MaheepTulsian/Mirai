import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../services/notification_navigator.dart';
import '../models/notification_data.dart';
import '../utils/theme.dart';

/// FCM Testing Screen (Development Only)
///
/// Provides tools for testing Firebase Cloud Messaging:
/// - View and copy FCM token
/// - Test deep link navigation
/// - Simulate notification taps
class FCMTestScreen extends StatefulWidget {
  const FCMTestScreen({super.key});

  @override
  State<FCMTestScreen> createState() => _FCMTestScreenState();
}

class _FCMTestScreenState extends State<FCMTestScreen> {
  String? _fcmToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    setState(() => _isLoading = true);
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    final token = await notificationService.getToken();
    setState(() {
      _fcmToken = token;
      _isLoading = false;
    });
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ FCM Token copied to clipboard!')),
      );
    }
  }

  Future<void> _testDeepLink(String screen,
      [Map<String, dynamic>? params]) async {
    final data = NotificationData(
      screen: screen,
      params: params ?? {},
      notificationId: 'test_${DateTime.now().millisecondsSinceEpoch}',
    );

    await NotificationNavigator.navigate(context, data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigated to: $screen')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('FCM Testing'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FCM Token Section
                  Card(
                    color: AppTheme.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FCM Token',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _fcmToken ?? 'No token available',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _copyToken,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Token'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Deep Link Tests Section
                  const Text(
                    'Test Deep Links',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap buttons to simulate notification deep links:',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Test Buttons
                  _buildTestButton('🏠 Home', () => _testDeepLink('home')),
                  _buildTestButton('💼 Jobs', () => _testDeepLink('jobs')),
                  _buildTestButton(
                    '📄 Job Details',
                    () => _testDeepLink(
                        'job_details', {'jobId': 'test_job_123'}),
                  ),
                  _buildTestButton(
                      '🎓 Internships', () => _testDeepLink('internships')),
                  _buildTestButton(
                    '📝 Internship Details',
                    () => _testDeepLink('internship_details',
                        {'internshipId': 'test_intern_456'}),
                  ),
                  _buildTestButton(
                      '🏆 GSoC', () => _testDeepLink('gsoc')),
                  _buildTestButton(
                    '🏢 GSoC Org',
                    () => _testDeepLink('gsoc_org', {'orgId': 'test_org_789'}),
                  ),
                  _buildTestButton(
                      '🗺️ Roadmaps', () => _testDeepLink('roadmaps')),
                  _buildTestButton(
                    '📚 Roadmap Details',
                    () => _testDeepLink(
                        'roadmap_details', {'roadmapId': 'test_roadmap_123'}),
                  ),
                  _buildTestButton('👤 Profile', () => _testDeepLink('profile')),
                  _buildTestButton(
                    '🌐 Webview',
                    () => _testDeepLink(
                        'webview', {'url': 'https://flutter.dev'}),
                  ),

                  const SizedBox(height: 24),

                  // Instructions
                  Card(
                    color: AppTheme.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📋 Testing Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Copy your FCM token\n'
                            '2. Go to Firebase Console → Cloud Messaging\n'
                            '3. Create new notification\n'
                            '4. Add custom data with "screen" key\n'
                            '5. Send to your device using the token\n\n'
                            'Test in different states:\n'
                            '• Foreground (app open)\n'
                            '• Background (app minimized)\n'
                            '• Terminated (app closed)',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Link to full guide
                  Card(
                    color: Colors.blue.shade900,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade100),
                              const SizedBox(width: 8),
                              const Text(
                                'Full Testing Guide',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'For comprehensive testing instructions, see:\n'
                            'FCM_TESTING_GUIDE.md in project root',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.textPrimary,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
