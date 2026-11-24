import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getHospitalInfo() async {
    final doc = await _firestore
        .collection('hospital_info')
        .doc('general')
        .get();

    return doc.data();
  }
}