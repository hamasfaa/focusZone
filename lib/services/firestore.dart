import 'package:cloud_firestore/cloud_firestore.dart';

class FireStoreService {
  static const activityStatusRunning = 'running';
  static const activityStatusCompleted = 'completed';

  final CollectionReference<Map<String, dynamic>> _activitiesCollection =
      FirebaseFirestore.instance.collection('activities');

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  getRunningActivityForUser(String userId) async {
    final snapshot = await _activitiesCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: activityStatusRunning)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  }

  Future<bool> hasRunningActivity(String userId) async {
    final runningActivity = await getRunningActivityForUser(userId);
    return runningActivity != null;
  }

  Future<void> addActivity({
    required String name,
    required String description,
    required int durationInSeconds,
    required String userId,
    String status = activityStatusCompleted,
  }) async {
    try {
      if (status == activityStatusRunning && await hasRunningActivity(userId)) {
        throw Exception(
          'Masih ada aktivitas yang running. Selesaikan dulu sebelum membuat aktivitas baru.',
        );
      }

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

  Future<void> updateActivityStatus({
    required String activityId,
    required String status,
  }) async {
    await _activitiesCollection.doc(activityId).update({
      'status': status,
      if (status == activityStatusCompleted)
        'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
