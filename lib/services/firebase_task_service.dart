import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:studio_track/data/dummy_data.dart';
import 'package:studio_track/screens/studio_workboard_screen.dart';

class FirebaseTaskService {
  static final FirebaseTaskService _instance = FirebaseTaskService._internal();
  factory FirebaseTaskService() => _instance;
  FirebaseTaskService._internal();

  static const String _collectionName = 'tasks';

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get _firestore {
    if (!_isFirebaseAvailable) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance error: $e');
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _tasksCollection =>
      _firestore?.collection(_collectionName);

  /// Converts a StudioTask to a Firestore Map
  Map<String, dynamic> taskToMap(StudioTask task) {
    return {
      'id': task.id,
      'date': task.date,
      'designerName': task.designerName,
      'designerRole': task.designerRole,
      'avatarUrl': task.avatarUrl,
      'workName': task.workName,
      'clientName': task.clientName,
      'typeTag': task.typeTag,
      'workBrief': task.workBrief,
      'status': task.status.name,
      'timeWindow': task.timeWindow,
      'timeLogged': task.timeLogged,
      'isPriority': task.isPriority,
      'attachments': task.attachments.map((att) => {
        'id': att.id,
        'name': att.name,
        'imageUrl': att.imageUrl,
        'fileSize': att.fileSize,
        'uploadedAt': att.uploadedAt,
        'localPath': att.localPath ?? '',
      }).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts a Firestore Map to a StudioTask
  StudioTask taskFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final id = doc.id;
    
    // Parse TaskStatus
    final statusStr = data['status'] as String? ?? 'inProgress';
    TaskStatus status = TaskStatus.inProgress;
    for (final s in TaskStatus.values) {
      if (s.name == statusStr || s.label.toLowerCase() == statusStr.toLowerCase()) {
        status = s;
        break;
      }
    }

    // Parse Attachments
    final rawAttachments = data['attachments'] as List<dynamic>? ?? [];
    final attachments = rawAttachments.map((item) {
      final m = item as Map<String, dynamic>;
      return TaskAttachment(
        id: m['id'] as String? ?? UniqueKey().toString(),
        name: m['name'] as String? ?? 'Attachment',
        imageUrl: m['imageUrl'] as String? ?? '',
        fileSize: m['fileSize'] as String? ?? '',
        uploadedAt: m['uploadedAt'] as String? ?? '',
        localPath: m['localPath'] as String?,
      );
    }).toList();

    return StudioTask(
      id: id,
      date: data['date'] as String? ?? 'Oct 24, 2024',
      designerName: data['designerName'] as String? ?? '',
      designerRole: data['designerRole'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      workName: data['workName'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      typeTag: data['typeTag'] as String? ?? '',
      workBrief: data['workBrief'] as String? ?? '',
      status: status,
      timeWindow: data['timeWindow'] as String? ?? '09:00 AM - ---',
      timeLogged: data['timeLogged'] as String? ?? '0h 00m logged',
      isPriority: data['isPriority'] as bool? ?? false,
      attachments: attachments,
    );
  }

  /// Real-time stream of all tasks from Firestore
  Stream<List<StudioTask>> streamTasks() {
    final col = _tasksCollection;
    if (col == null) {
      return const Stream.empty();
    }
    return col.snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        await seedInitialTasksIfEmpty();
        final reloaded = await col.get();
        return reloaded.docs.map((doc) => taskFromDoc(doc)).toList();
      }
      return snapshot.docs.map((doc) => taskFromDoc(doc)).toList();
    });
  }

  /// Fetches tasks once
  Future<List<StudioTask>> fetchTasks() async {
    final col = _tasksCollection;
    if (col == null) {
      return [];
    }
    try {
      final snapshot = await col.get();
      if (snapshot.docs.isEmpty) {
        await seedInitialTasksIfEmpty();
        final reloaded = await col.get();
        return reloaded.docs.map((doc) => taskFromDoc(doc)).toList();
      }
      return snapshot.docs.map((doc) => taskFromDoc(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching tasks from Firestore: $e');
      return [];
    }
  }

  /// Seeds initial tasks into Firestore if the collection is empty
  Future<void> seedInitialTasksIfEmpty() async {
    final store = _firestore;
    final col = _tasksCollection;
    if (store == null || col == null) return;

    try {
      final snapshot = await col.limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Seeding ${tasks.length} initial tasks into Firebase Firestore...');
        final batch = store.batch();
        for (final task in tasks) {
          final docRef = col.doc(task.id);
          batch.set(docRef, taskToMap(task));
        }
        await batch.commit();
        debugPrint('Successfully seeded initial tasks into Firebase Firestore.');
      }
    } catch (e) {
      debugPrint('Error seeding initial tasks to Firestore: $e');
    }
  }

  /// Adds a new task to Firestore
  Future<void> addTask(StudioTask task) async {
    final col = _tasksCollection;
    if (col == null) return;

    try {
      final docRef = col.doc(task.id);
      await docRef.set(taskToMap(task));
      debugPrint('Task ${task.id} ("${task.workName}") saved to Firestore.');
    } catch (e) {
      debugPrint('Error saving task to Firestore: $e');
    }
  }

  /// Updates an existing task in Firestore
  Future<void> updateTask(StudioTask task) async {
    final col = _tasksCollection;
    if (col == null) return;

    try {
      final docRef = col.doc(task.id);
      await docRef.set(taskToMap(task), SetOptions(merge: true));
      debugPrint('Task ${task.id} updated in Firestore.');
    } catch (e) {
      debugPrint('Error updating task in Firestore: $e');
    }
  }

  /// Updates task status and optional time/logged hours in Firestore
  Future<void> updateTaskStatus(
    String taskId,
    TaskStatus newStatus, {
    String? timeWindow,
    String? timeLogged,
  }) async {
    final col = _tasksCollection;
    if (col == null) return;

    try {
      final Map<String, dynamic> updateData = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (timeWindow != null) updateData['timeWindow'] = timeWindow;
      if (timeLogged != null) updateData['timeLogged'] = timeLogged;

      await col.doc(taskId).update(updateData);
      debugPrint('Task $taskId status updated to ${newStatus.name} in Firestore.');
    } catch (e) {
      debugPrint('Error updating task status in Firestore: $e');
    }
  }

  /// Automatically progresses previous pending tasks with the same workName when completed
  Future<void> cascadeProgressForWork(String workName, String completedTaskId) async {
    final store = _firestore;
    final col = _tasksCollection;
    if (store == null || col == null) return;

    try {
      final snapshot = await col.get();
      final batch = store.batch();
      bool hasUpdates = false;

      for (final doc in snapshot.docs) {
        if (doc.id == completedTaskId) continue;
        final data = doc.data();
        final itemWorkName = data['workName'] as String? ?? '';
        final itemStatus = data['status'] as String? ?? '';

        if (itemWorkName.trim().toLowerCase() == workName.trim().toLowerCase() &&
            (itemStatus == TaskStatus.pending.name || itemStatus.toLowerCase() == 'pending')) {
          batch.update(doc.reference, {
            'status': TaskStatus.progressed.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
        debugPrint('Cascaded progressed status for work "$workName" in Firestore.');
      }
    } catch (e) {
      debugPrint('Error cascading progressed status in Firestore: $e');
    }
  }

  /// Deletes a task from Firestore
  Future<void> deleteTask(String taskId) async {
    final col = _tasksCollection;
    if (col == null) return;

    try {
      await col.doc(taskId).delete();
      debugPrint('Task $taskId deleted from Firestore.');
    } catch (e) {
      debugPrint('Error deleting task from Firestore: $e');
    }
  }
}
