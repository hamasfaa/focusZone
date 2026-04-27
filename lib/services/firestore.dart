import 'package:cloud_firestore/cloud_firestore.dart';

class FireStoreService {
  static const activityStatusRunning = 'running';
  static const activityStatusCompleted = 'completed';

  final CollectionReference<Map<String, dynamic>> _activitiesCollection =
      FirebaseFirestore.instance.collection('activities');
  final CollectionReference<Map<String, dynamic>> _categoriesCollection =
      FirebaseFirestore.instance.collection('categories');
  final CollectionReference<Map<String, dynamic>> _remindersCollection =
      FirebaseFirestore.instance.collection('reminders');

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamActivitiesForUser(String userId) {
    return _activitiesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.docs,
          );

          docs.sort((a, b) {
            final aDate = _resolveSortDate(a.data());
            final bDate = _resolveSortDate(b.data());
            return bDate.compareTo(aDate);
          });

          return docs;
        });
  }

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

  DateTime _resolveSortDate(Map<String, dynamic> data) {
    final completedAt = data['completedAt'];
    if (completedAt is Timestamp) {
      return completedAt.toDate();
    }

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<bool> hasRunningActivity(String userId) async {
    final runningActivity = await getRunningActivityForUser(userId);
    return runningActivity != null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCompletedActivitiesForUser(
    String userId,
  ) {
    return _activitiesCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: activityStatusCompleted)
        .snapshots();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamCategoriesForUser(String userId) {
    return _categoriesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.docs,
          );
          docs.sort((a, b) {
            final aCreatedAt = a.data()['createdAt'];
            final bCreatedAt = b.data()['createdAt'];
            if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
              return bCreatedAt.compareTo(aCreatedAt);
            }
            return 0;
          });
          return docs;
        });
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamRemindersForUser(String userId) {
    return _remindersCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.docs,
          );
          docs.sort((a, b) {
            final aCreatedAt = a.data()['createdAt'];
            final bCreatedAt = b.data()['createdAt'];
            if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
              return bCreatedAt.compareTo(aCreatedAt);
            }
            return 0;
          });
          return docs;
        });
  }

  Future<String> addCategory({
    required String name,
    required int colorValue,
    required String userId,
  }) async {
    try {
      final doc = await _categoriesCollection.add({
        'name': name,
        'colorValue': colorValue,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesCollection.doc(categoryId).delete();
  }

  Future<String> addActivity({
    required String name,
    required String description,
    required int durationInSeconds,
    required String userId,
    String status = activityStatusCompleted,
    String? categoryId,
  }) async {
    try {
      if (status == activityStatusRunning && await hasRunningActivity(userId)) {
        throw Exception(
          'Masih ada aktivitas yang running. Selesaikan dulu sebelum membuat aktivitas baru.',
        );
      }

      final doc = await _activitiesCollection.add({
        'name': name,
        'description': description,
        'durationInSeconds': durationInSeconds,
        'durationInMinutes': (durationInSeconds / 60).ceil(),
        'status': status,
        'userId': userId,
        if (categoryId != null) 'categoryId': categoryId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      throw Exception('Failed to add activity: $e');
    }
  }

  Future<String> addReminder({
    required String title,
    required String userId,
    required int hour,
    required int minute,
    required List<int> weekdays,
    required List<int> notificationIds,
    bool isEnabled = true,
  }) async {
    try {
      final doc = await _remindersCollection.add({
        'title': title,
        'userId': userId,
        'hour': hour,
        'minute': minute,
        'weekdays': weekdays,
        'notificationIds': notificationIds,
        'isEnabled': isEnabled,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      throw Exception('Failed to add reminder: $e');
    }
  }

  Future<void> updateReminder({
    required String reminderId,
    String? title,
    int? hour,
    int? minute,
    List<int>? weekdays,
    List<int>? notificationIds,
    bool? isEnabled,
  }) async {
    final updateData = <String, dynamic>{};
    if (title != null) updateData['title'] = title;
    if (hour != null) updateData['hour'] = hour;
    if (minute != null) updateData['minute'] = minute;
    if (weekdays != null) updateData['weekdays'] = weekdays;
    if (notificationIds != null) {
      updateData['notificationIds'] = notificationIds;
    }
    if (isEnabled != null) updateData['isEnabled'] = isEnabled;

    if (updateData.isEmpty) return;

    await _remindersCollection.doc(reminderId).update(updateData);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _remindersCollection.doc(reminderId).delete();
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

  Future<void> addNoteToActivity({
    required String activityId,
    required String noteText,
    required List<String> imageUrls,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (noteText.isNotEmpty) {
      updateData['noteText'] = noteText;
    }
    if (imageUrls.isNotEmpty) {
      updateData['noteImageUrls'] = imageUrls;
    }

    if (updateData.isNotEmpty) {
      await _activitiesCollection.doc(activityId).update(updateData);
    }
  }

  Future<void> deleteActivity(String activityId) async {
    await _activitiesCollection.doc(activityId).delete();
  }
}
