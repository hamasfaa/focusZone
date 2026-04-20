import 'package:cloud_firestore/cloud_firestore.dart';

class FireStoreService {
  static const activityStatusRunning = 'running';
  static const activityStatusCompleted = 'completed';

  final CollectionReference _activitiesCollection = FirebaseFirestore.instance
      .collection('activities');

  Future<void> addActivity({
    required String name,
    required String description,
    required int durationInSeconds,
    required String userId,
    String status = activityStatusCompleted,
  }) async {
    try {
      await _activitiesCollection.add({
        'name': name,
        'description': description,
        'durationInSeconds': durationInSeconds,
        'durationInMinutes': (durationInSeconds / 60).ceil(),
        'status': status,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add activity: $e');
    }
  }
}
