import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../utils/theme.dart';
import 'main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedYear;
  String? _selectedState;
  String? _selectedCollegeId;
  String? _selectedCollegeName;
  String? _selectedCity;

  // Manual entry fields for "Other"
  final TextEditingController _manualCityController = TextEditingController();
  final TextEditingController _manualCollegeController = TextEditingController();
  bool _isOtherCity = false;
  bool _isOtherCollege = false;

  List<Map<String, dynamic>> _allColleges = [];
  List<String> _states = [];
  List<String> _cities = [];
  List<Map<String, dynamic>> _filteredColleges = [];

  bool _isLoading = false;
  bool _isLoadingColleges = true;

  final List<String> _years = [
    '2024',
    '2025',
    '2026',
    '2027',
    '2028',
    '2029',
    '2030',
    '2031',
    '2032',
    '2033',
    '2034',
    '2035'
  ];

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  @override
  void dispose() {
    _manualCityController.dispose();
    _manualCollegeController.dispose();
    super.dispose();
  }

  Future<void> _loadColleges() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('colleges')
          .orderBy('state')
          .orderBy('name')
          .get();

      final colleges = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String,
          'city': data['city'] as String,
          'state': data['state'] as String,
        };
      }).toList();

      // Extract unique states
      final statesSet = <String>{};
      for (var college in colleges) {
        statesSet.add(college['state'] as String);
      }
      final sortedStates = statesSet.toList()..sort();

      setState(() {
        _allColleges = colleges;
        _states = sortedStates;
        _isLoadingColleges = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingColleges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load colleges: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onStateSelected(String? state) {
    setState(() {
      _selectedState = state;
      _selectedCity = null;
      _selectedCollegeId = null;
      _selectedCollegeName = null;

      if (state != null) {
        // Extract unique cities for the selected state
        final citiesSet = <String>{};
        for (var college in _allColleges) {
          if (college['state'] == state) {
            citiesSet.add(college['city'] as String);
          }
        }
        _cities = citiesSet.toList()..sort();
        _filteredColleges = [];
      } else {
        _cities = [];
        _filteredColleges = [];
      }
    });
  }

  void _onCitySelected(String? city) {
    setState(() {
      _selectedCity = city;
      _selectedCollegeId = null;
      _selectedCollegeName = null;
      _isOtherCity = city == 'Other';
      _isOtherCollege = false;
      _manualCityController.clear();
      _manualCollegeController.clear();

      if (city == 'Other') {
        // Allow manual entry
        _filteredColleges = [];
      } else if (city != null && _selectedState != null) {
        _filteredColleges = _allColleges
            .where((college) =>
                college['state'] == _selectedState &&
                college['city'] == city)
            .toList();
      } else {
        _filteredColleges = [];
      }
    });
  }

  Future<void> _skipOnboarding() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) return;

      // Create minimal profile to skip onboarding
      await authService.createUserProfile(
        uid: user.uid,
        graduatingYear: 'Not specified',
        collegeName: 'Not specified',
        collegeId: 'SKIPPED',
        state: 'Not specified',
        city: 'Not specified',
      );

      // Navigate to main navigation after skipping
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
        );
      }
    } catch (e) {
      // Show error if skip fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to skip: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    // Validation
    if (_selectedYear == null || _selectedState == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate "Other" city
    if (_isOtherCity && _manualCityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your city name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate college selection or manual entry
    if (!_isOtherCity && _selectedCollegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your college'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isOtherCollege && _manualCollegeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your college name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Determine final values
      final finalCity = _isOtherCity
          ? _manualCityController.text.trim()
          : _selectedCity!;
      final finalCollegeName = _isOtherCollege
          ? _manualCollegeController.text.trim()
          : _selectedCollegeName ?? 'Other';
      final finalCollegeId = _isOtherCollege || _isOtherCity
          ? 'OTHER'
          : _selectedCollegeId!;

      await authService.createUserProfile(
        uid: user.uid,
        graduatingYear: _selectedYear!,
        collegeName: finalCollegeName,
        collegeId: finalCollegeId,
        state: _selectedState!,
        city: finalCity,
      );

      analytics.logEvent('profile_created', {
        'graduating_year': _selectedYear,
        'college': _selectedCollegeName,
      });

      // Navigate to main navigation after successful profile creation
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingColleges
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Graduating Year Dropdown
                  Text(
                    'Graduating Year',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
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

                  const SizedBox(height: 24),

                  // State Dropdown
                  Text(
                    'State',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: InputDecoration(
                      hintText: 'Select your state',
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _states.map((state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: _onStateSelected,
                  ),

                  const SizedBox(height: 24),

                  // City Dropdown
                  Text(
                    'City',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: InputDecoration(
                      hintText: _selectedState == null
                          ? 'First select a state'
                          : 'Select your city',
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      ..._cities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: 'Other',
                        child: Text('Other (Not listed)'),
                      ),
                    ],
                    onChanged: _selectedState == null ? null : _onCitySelected,
                  ),

                  // Manual City Input (shown when "Other" is selected)
                  if (_isOtherCity) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _manualCityController,
                      decoration: InputDecoration(
                        hintText: 'Enter your city name',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // College Dropdown or Text Input
                  Text(
                    'College',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // Show text field if "Other" city is selected
                  if (_isOtherCity)
                    TextFormField(
                      controller: _manualCollegeController,
                      decoration: InputDecoration(
                        hintText: 'Enter your college name',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.school),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) {
                        setState(() {
                          _isOtherCollege = true;
                        });
                      },
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCollegeId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: _selectedCity == null
                            ? 'First select a city'
                            : 'Select your college',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        ..._filteredColleges.map((college) {
                          return DropdownMenuItem<String>(
                            value: college['id'] as String,
                            child: Text(
                              college['name'] as String,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }),
                        const DropdownMenuItem<String>(
                          value: 'OTHER',
                          child: Text('Other (Not listed)'),
                        ),
                      ],
                      onChanged: _selectedCity == null
                          ? null
                          : (value) {
                              setState(() {
                                if (value == 'OTHER') {
                                  _isOtherCollege = true;
                                  _selectedCollegeId = 'OTHER';
                                  _selectedCollegeName = null;
                                } else {
                                  _isOtherCollege = false;
                                  _selectedCollegeId = value;
                                  final college = _filteredColleges.firstWhere(
                                    (college) => college['id'] == value,
                                  );
                                  _selectedCollegeName = college['name'] as String;
                                  _manualCollegeController.clear();
                                }
                              });
                            },
                    ),

                  // Manual College Input (shown when "Other" college is selected from dropdown)
                  if (_isOtherCollege && !_isOtherCity) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _manualCollegeController,
                      decoration: InputDecoration(
                        hintText: 'Enter your college name',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.school),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Let\'s Go'),
                  ),
                ],
              ),
            ),
    );
  }

}
