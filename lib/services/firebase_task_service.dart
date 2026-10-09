import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:studio_track/data/dummy_data.dart';
import 'package:studio_track/screens/studio_workboard_screen.dart';

class AttachmentBytesCache {
  static final Map<String, Uint8List> _cache = {};

  static void put(String key, Uint8List bytes) {
    if (key.isNotEmpty) {
      _cache[key] = bytes;
    }
  }

  static Uint8List? get(String key) {
    if (key.isEmpty) return null;
    return _cache[key];
  }

  static Future<Uint8List?> getOrFetch(TaskAttachment att) async {
    if (att.bytes != null && att.bytes!.isNotEmpty) {
      put(att.id, att.bytes!);
      if (att.imageUrl.isNotEmpty) put(att.imageUrl, att.bytes!);
      put(att.name, att.bytes!);
      return att.bytes;
    }

    final cached = get(att.id) ?? get(att.imageUrl) ?? get(att.name);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (att.imageUrl.startsWith('data:image')) {
      try {
        final base64Str = att.imageUrl.contains(',') ? att.imageUrl.split(',').last : att.imageUrl;
        final decoded = base64Decode(base64Str);
        put(att.id, decoded);
        put(att.imageUrl, decoded);
        return decoded;
      } catch (_) {}
    }

    if (att.imageUrl.contains('firebasestorage.googleapis.com') || att.imageUrl.startsWith('gs://')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(att.imageUrl);
        final bytes = await ref.getData(5 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) {
          put(att.id, bytes);
          put(att.imageUrl, bytes);
          put(att.name, bytes);
          return bytes;
        }
      } catch (e) {
        debugPrint('Firebase Storage ref.getData notice: $e');
      }
    }

    return null;
  }
}

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
        'thumbnailData': att.thumbnailData,
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

    // Parse Attachments with cached bytes restore
    final rawAttachments = data['attachments'] as List<dynamic>? ?? [];
    final attachments = rawAttachments.map((item) {
      final m = item as Map<String, dynamic>;
      final attId = m['id'] as String? ?? UniqueKey().toString();
      final attName = m['name'] as String? ?? 'Attachment';
      final attUrl = m['imageUrl'] as String? ?? '';
      final attThumb = m['thumbnailData'] as String? ?? '';
      final cachedBytes = AttachmentBytesCache.get(attId) ?? AttachmentBytesCache.get(attUrl) ?? AttachmentBytesCache.get(attName);
      return TaskAttachment(
        id: attId,
        name: attName,
        imageUrl: attUrl,
        thumbnailData: attThumb,
        fileSize: m['fileSize'] as String? ?? '',
        uploadedAt: m['uploadedAt'] as String? ?? '',
        localPath: m['localPath'] as String?,
        bytes: cachedBytes,
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

  /// Deletes a file from Firebase Storage
  Future<void> deleteAttachmentFile(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      if (_isFirebaseAvailable &&
          (imageUrl.contains('firebasestorage.googleapis.com') || imageUrl.startsWith('gs://'))) {
        final storage = FirebaseStorage.instance;
        final ref = storage.refFromURL(imageUrl);
        await ref.delete();
        debugPrint('Attachment file deleted from Firebase Storage: $imageUrl');
      }
    } catch (e) {
      debugPrint('Notice/Error deleting file from Firebase Storage: $e');
    }
  }

  /// Uploads an attachment file to Firebase Storage and returns its download URL (or Base64 fallback)
  Future<String> uploadAttachmentFile({
    required String taskId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    AttachmentBytesCache.put(fileName, bytes);

    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'png';
    String contentType = 'application/octet-stream';
    if (ext == 'png') {
      contentType = 'image/png';
    } else if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    } else if (ext == 'webp') {
      contentType = 'image/webp';
    } else if (ext == 'gif') {
      contentType = 'image/gif';
    } else if (ext == 'svg') {
      contentType = 'image/svg+xml';
    } else if (ext == 'pdf') {
      contentType = 'application/pdf';
    }

    try {
      if (_isFirebaseAvailable) {
        final storage = FirebaseStorage.instance;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final storageRef = storage
            .ref()
            .child('task_attachments')
            .child(taskId.isNotEmpty ? taskId : 'general')
            .child('${timestamp}_$cleanFileName');

        final metadata = SettableMetadata(
          contentType: contentType,
          customMetadata: {'originalName': fileName},
        );

        final uploadTask = await storageRef.putData(bytes, metadata);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        AttachmentBytesCache.put(downloadUrl, bytes);
        debugPrint('File $fileName successfully uploaded to Firebase Storage: $downloadUrl');
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Firebase Storage upload notice/fallback: $e');
    }

    // High-reliability Fallback (stores as base64 data URI if storage offline or rules pending)
    try {
      final b64 = base64Encode(bytes);
      final dataUri = 'data:$contentType;base64,$b64';
      AttachmentBytesCache.put(dataUri, bytes);
      return dataUri;
    } catch (e) {
      debugPrint('Base64 encoding error: $e');
      return '';
    }
  }
}
