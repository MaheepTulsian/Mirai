import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';
import '../models/roadmap.dart';
import '../models/guide.dart';
import '../models/course.dart';
import '../models/gsoc_org.dart';
import '../models/contributor.dart';
import '../models/profile.dart';
import '../models/saved_item.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Jobs
  Stream<List<Job>> getJobs({int limit = 20}) {
    return _firestore
        .collection('jobs')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Job.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Internships
  Stream<List<Job>> getInternships({int limit = 20}) {
    return _firestore
        .collection('internships')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          print('📥 Fetched ${snapshot.docs.length} internship documents');

          final internships = <Job>[];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              print('Processing internship: ${doc.id}');
              print('Data: $data');

              final internship = Job.fromFirestore(data, doc.id);
              internships.add(internship);
            } catch (e, stackTrace) {
              print('❌ Error parsing internship ${doc.id}: $e');
              print('Stack trace: $stackTrace');
              print('Document data: ${doc.data()}');
            }
          }

          print('✅ Successfully parsed ${internships.length} internships');
          return internships;
        });
  }

  // Roadmaps
  Stream<List<Roadmap>> getRoadmaps() {
    return _firestore.collection('roadmaps').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Roadmap.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<Roadmap?> getRoadmapById(String id) async {
    try {
      final doc = await _firestore.collection('roadmaps').doc(id).get();
      if (doc.exists) {
        return Roadmap.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching roadmap: $e');
      return null;
    }
  }

  // Guides
  Stream<List<Guide>> getGuides() {
    return _firestore.collection('guides').snapshots().map((snapshot) {
      print('📚 Fetched ${snapshot.docs.length} guide documents');

      final guides = <Guide>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('Processing guide: ${doc.id}');
          print('Data: $data');

          final guide = Guide.fromFirestore(data, doc.id);
          guides.add(guide);
        } catch (e, stackTrace) {
          print('❌ Error parsing guide ${doc.id}: $e');
          print('Stack trace: $stackTrace');
          print('Document data: ${doc.data()}');
        }
      }

      print('✅ Successfully parsed ${guides.length} guides');
      return guides;
    });
  }

  // Courses
  Stream<List<Course>> getCourses({int limit = 20}) {
    return _firestore
        .collection('courses')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          print('📚 Fetched ${snapshot.docs.length} course documents');

          final courses = <Course>[];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              print('Processing course: ${doc.id}');

              final course = Course.fromFirestore(data, doc.id);
              courses.add(course);
            } catch (e, stackTrace) {
              print('❌ Error parsing course ${doc.id}: $e');
              print('Stack trace: $stackTrace');
              print('Document data: ${doc.data()}');
            }
          }

          print('✅ Successfully parsed ${courses.length} courses');
          return courses;
        });
  }

  // Colleges
  Future<List<College>> getColleges() async {
    try {
      final snapshot = await _firestore.collection('colleges').get();
      return snapshot.docs
          .map((doc) => College.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching colleges: $e');
      return [];
    }
  }

  // GSoC Organizations
  Future<List<String>> getAvailableGsocYears() async {
    try {
      final snapshot = await _firestore.collection('gsoc_documents').get();
      final years = snapshot.docs.map((doc) => doc.id).toList();
      // Sort years in descending order (latest first)
      years.sort((a, b) => b.compareTo(a));
      return years;
    } catch (e) {
      print('Error fetching GSoC years: $e');
      return [];
    }
  }

  Stream<List<GsocOrg>> getGsocOrgs({String year = '2024', int? limit}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('gsoc_documents')
        .doc(year)
        .collection('organizations');

    // Only apply limit if specified
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GsocOrg.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<List<GsocOrg>> searchGsocOrgs(String query, {String year = '2024'}) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection('gsoc_documents')
          .doc(year)
          .collection('organizations')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => GsocOrg.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error searching GSoC orgs: $e');
      return [];
    }
  }

  // GSoC Contributors
  Future<List<Contributor>> searchContributors(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection('contributors')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => Contributor.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error searching contributors: $e');
      return [];
    }
  }

  // Profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('profile').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> saveUserProfile(String userId, UserProfile profile) async {
    try {
      await _firestore.collection('profile').doc(userId).set(profile.toMap());
    } catch (e) {
      print('Error saving profile: $e');
      throw e;
    }
  }

  // Saved Items
  Stream<List<SavedItem>> getSavedItems(String userId) {
    return _firestore
        .collection('saved')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedItem.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveItem(String userId, SavedItem item) async {
    try {
      final data = item.toMap();
      data['userId'] = userId;
      await _firestore.collection('saved').add(data);
    } catch (e) {
      print('Error saving item: $e');
      throw e;
    }
  }

  Future<void> removeSavedItem(String itemId) async {
    try {
      await _firestore.collection('saved').doc(itemId).delete();
    } catch (e) {
      print('Error removing saved item: $e');
      throw e;
    }
  }

  Future<bool> isItemSaved(String userId, String itemName) async {
    try {
      final snapshot = await _firestore
          .collection('saved')
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: itemName)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking saved status: $e');
      return false;
    }
  }

  /// Get app settings from Firestore (help, about, rate, etc.)
  Future<Map<String, dynamic>?> getAppSection(String sectionId) async {
    try {
      final doc = await _firestore.collection('app').doc(sectionId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching app section $sectionId: $e');
      return null;
    }
  }

  /// Submit a report for a job or internship
  Future<void> submitReport({
    required String userId,
    required String itemId,
    required String itemType, // 'job' or 'internship'
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'userId': userId,
        'itemId': itemId,
        'itemType': itemType,
        'reason': reason,
        'additionalDetails': additionalDetails,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }

  /// Submit user feedback
  Future<void> submitFeedback({
    required String userId,
    required String feedback,
    String? userEmail,
    String? userName,
  }) async {
    try {
      await _firestore.collection('feedback').add({
        'userId': userId,
        'feedback': feedback,
        'userEmail': userEmail,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
      });
    } catch (e) {
      print('Error submitting feedback: $e');
      rethrow;
    }
  }
}
