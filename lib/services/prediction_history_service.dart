import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/prediction_history_record.dart';

class PredictionHistoryService {
  CollectionReference<Map<String, dynamic>>? get _records {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('predictions');
  }

  Future<String?> save(PredictionHistoryRecord record) async {
    final records = _records;
    if (records == null) return null;
    final document = await records.add(record.toFirestore());
    return document.id;
  }

  Stream<List<PredictionHistoryRecord>> watchHistory() {
    final records = _records;
    if (records == null) return Stream.value(const []);

    return records
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => PredictionHistoryRecord.fromFirestore(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .toList(),
        );
  }

  Future<void> clearHistory() async {
    final records = _records;
    if (records == null) return;

    while (true) {
      final snapshot = await records.limit(400).get();
      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}
