import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentsService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> getDepartments() async {
    final snapshot =
        await _firestore.collection('departments').get();

    return snapshot.docs;
  }

  Future<Map<String, dynamic>?> findDepartment(
      String query) async {
    final snapshot =
        await _firestore.collection('departments').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final nameAm =
          (data['name_am'] ?? '')
              .toString()
              .toLowerCase();

      final nameEn =
          (data['name_en'] ?? '')
              .toString()
              .toLowerCase();

      if (query.toLowerCase().contains(nameAm) ||
          query.toLowerCase().contains(nameEn)) {
        return data;
      }
    }

    return null;
  }
}