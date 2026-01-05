import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import 'jobs_screen.dart';
import 'internships_screen.dart';
import 'learning_resources_screen.dart';
import 'gsoc_screen.dart';
import 'home_screen.dart';
import 'saved_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  /// Switches to a specific tab by index
  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Returns the list of screens with necessary callbacks
  List<Widget> _getScreens() {
    return [
      HomeScreen(onSwitchTab: _switchTab),
      const JobsScreen(),
      const InternshipsScreen(),
      const LearningResourcesScreen(),
      const GsocScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with hamburger and logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Hamburger menu
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),

                  // Centered Logo
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Bookmark and Profile buttons
                  IconButton(
                    icon: const Icon(
                      Icons.bookmark,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Screen content
            Expanded(
              child: _getScreens()[_currentIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        showUnselectedLabels: true,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Internships',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories_outlined),
            activeIcon: Icon(Icons.auto_stories),
            label: 'Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'GSoC',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Main Menu Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'ACCOUNT',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bookmark_outline,
                    title: 'Saved Items',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonDialog(context, 'Notifications');
                    },
                  ),

                  const Divider(color: AppTheme.textSecondary, height: 24),

                  // App Settings Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'APP',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonDialog(context, 'Settings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: true, // Always dark mode for now
                      onChanged: null, // Disabled - will enable in future
                      activeColor: AppTheme.primaryColor,
                    ),
                    onTap: null, // Disabled
                  ),

                  const Divider(color: AppTheme.textSecondary, height: 24),

                  // Support Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'SUPPORT',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    onTap: () {
                      Navigator.pop(context);
                      _showFeedbackDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.star_outline,
                    title: 'Rate App',
                    onTap: () {
                      Navigator.pop(context);
                      _showRateAppDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.share_outlined,
                    title: 'Share App',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonDialog(context, 'Share App');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoonDialog(context, 'Privacy Policy');
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontSize: 16,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      enabled: onTap != null,
      hoverColor: AppTheme.primaryColor.withOpacity(0.1),
    );
  }

  void _showAboutDialog(BuildContext context) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final aboutData = await firebaseService.getAppSection('about');

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show actual content
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(aboutData?['title'] ?? 'About Mirai'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aboutData?['appName'] ?? 'Mirai - CS Career & Learning Hub',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  aboutData?['version'] ?? 'Version 1.0.0',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  aboutData?['description'] ??
                      'Your comprehensive platform for CS jobs, internships, courses, roadmaps, and opportunities.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  aboutData?['tagline'] ??
                      'Built with ❤️ for CS students and professionals',
                  style: const TextStyle(fontSize: 14),
                ),
                if (aboutData?['contact'] != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Contact: ${aboutData!['contact']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('Error'),
          content: Text('Failed to load about information: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Row(
          children: [
            Icon(Icons.rocket_launch_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Coming Soon'),
          ],
        ),
        content: Text(
          '$feature is coming soon! Stay tuned for updates.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final helpData = await firebaseService.getAppSection('help');

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Parse FAQs from Firestore
      final faqs = (helpData?['faqs'] as List<dynamic>?) ?? [];

      // Show actual content
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Row(
            children: [
              Icon(Icons.help_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(helpData?['title'] ?? 'Help & Support'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                // Display FAQs from Firestore
                if (faqs.isNotEmpty)
                  ...faqs.map((faq) => Column(
                        children: [
                          _buildFAQItem(
                            question: faq['question'] ?? '',
                            answer: faq['answer'] ?? '',
                          ),
                          const SizedBox(height: 12),
                        ],
                      ))
                else
                  ...[
                    _buildFAQItem(
                      question: 'How do I save jobs or internships?',
                      answer:
                          'Click the bookmark icon on any job or internship card to save it for later.',
                    ),
                    const SizedBox(height: 12),
                    _buildFAQItem(
                      question: 'How do I apply for opportunities?',
                      answer:
                          'Open the job/internship details and click the "Apply Now" button to visit the company\'s application page.',
                    ),
                    const SizedBox(height: 12),
                    _buildFAQItem(
                      question: 'How do I update my profile?',
                      answer:
                          'Go to Profile from the sidebar menu and update your graduating year and college information.',
                    ),
                    const SizedBox(height: 12),
                  ],
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  helpData?['helpText'] ?? 'Need more help?',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  helpData?['contact'] ?? 'Contact us at: support@mirai.app',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('Error'),
          content: Text('Failed to load help information: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Q: $question',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A: $answer',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Row(
          children: [
            Icon(Icons.feedback_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Send Feedback'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We\'d love to hear from you! Share your thoughts, suggestions, or report issues.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                hintText: 'Type your feedback here...',
                border: const OutlineInputBorder(),
                hintStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              maxLines: 5,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              feedbackController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final feedback = feedbackController.text.trim();
              if (feedback.isNotEmpty) {
                try {
                  final user = authService.currentUser;
                  await firebaseService.submitFeedback(
                    userId: user?.uid ?? 'anonymous',
                    feedback: feedback,
                    userEmail: user?.email,
                    userName: user?.displayName,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your feedback!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit feedback: $e'),
                      ),
                    );
                  }
                } finally {
                  feedbackController.dispose();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your feedback'),
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRateAppDialog(BuildContext context) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rateData = await firebaseService.getAppSection('rate');

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show rating dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Row(
            children: [
              Icon(Icons.star_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(rateData?['title'] ?? 'Rate Our App'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rateData?['message'] ??
                    'Enjoying Mirai? Please take a moment to rate us!',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                rateData?['subtitle'] ??
                    'Your feedback helps us improve and reach more students.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Open app store/play store link
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your support!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: const Text('Rate Now'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('Error'),
          content: Text('Failed to load rating information: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
