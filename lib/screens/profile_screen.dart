import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../models/profile.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedYear;
  String? _selectedCollege;
  String? _selectedCollegeId;
  List<College> _colleges = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showSuccessAnimation = false;
  late AnimationController _successAnimationController;
  late Animation<double> _successScaleAnimation;

  final List<String> _years = [
    '2025',
    '2026',
    '2027',
    '2028',
    '2029',
    '2030',
  ];

  @override
  void initState() {
    super.initState();
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('profile');

    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successScaleAnimation = CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    );

    _loadData();
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    super.dispose();
  }

  /// Show success animation after save
  void _triggerSuccessAnimation() {
    setState(() => _showSuccessAnimation = true);
    _successAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _successAnimationController.reverse().then((_) {
            if (mounted) {
              setState(() => _showSuccessAnimation = false);
            }
          });
        }
      });
    });
  }

  Future<void> _loadData() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      // User not logged in, shouldn't happen
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Load colleges from Firestore
    final colleges = await firebaseService.getColleges();

    // Load existing profile using actual user ID
    final profile = await firebaseService.getUserProfile(currentUser.uid);

    setState(() {
      _colleges = colleges;
      if (profile != null) {
        _selectedYear = profile.graduatingYear;
        _selectedCollege = profile.collegeName;
        _selectedCollegeId = profile.collegeId;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_selectedYear == null || _selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both graduating year and college')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final profile = UserProfile(
      graduatingYear: _selectedYear!,
      collegeName: _selectedCollege!,
      collegeId: _selectedCollegeId,
    );

    try {
      await firebaseService.saveUserProfile(currentUser.uid, profile);
      analytics.logProfileUpdated(_selectedYear!, _selectedCollege!);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // Trigger success animation
        _triggerSuccessAnimation();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information Card
                        _buildPersonalCard(currentUser),

                        const SizedBox(height: 16),

                        // Academic Information Card
                        _buildAcademicCard(),

                        const SizedBox(height: 24),

                        // Save Button with success animation
                        _buildSaveButton(),

                        const SizedBox(height: 16),

                        // Info Card
                        _buildInfoCard(),
                      ],
                    ),
                  ),
                ),
          // Success Animation Overlay
          if (_showSuccessAnimation)
            Center(
              child: ScaleTransition(
                scale: _successScaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build Personal Information Card
  Widget _buildPersonalCard(currentUser) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: currentUser?.photoURL != null
                        ? CachedNetworkImageProvider(currentUser!.photoURL!)
                        : null,
                    child: currentUser?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser?.displayName ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Academic Information Card
  Widget _buildAcademicCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Academic Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Graduating Year
            Text(
              'Graduating Year',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedYear,
              decoration: InputDecoration(
                hintText: 'Select your graduating year',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: _years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedYear = value;
                });
              },
            ),
            const SizedBox(height: 20),
            // College Name
            Text(
              'College Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCollege,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select your college',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: _colleges.map((college) {
                return DropdownMenuItem<String>(
                  value: college.name,
                  child: Text(
                    college.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCollege = value;
                  // Find the college ID
                  final college = _colleges.firstWhere(
                    (c) => c.name == value,
                    orElse: () => College(collegeId: '', name: ''),
                  );
                  _selectedCollegeId =
                      college.collegeId.isNotEmpty ? college.collegeId : null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build Save Button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProfile,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Build Info Card
  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'About Your Profile',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your profile information helps us provide personalized job and internship recommendations. We do not share your personal information with third parties.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
