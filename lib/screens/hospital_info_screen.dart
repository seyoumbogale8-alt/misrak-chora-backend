import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class HospitalInfoScreen extends StatefulWidget {
  const HospitalInfoScreen({super.key});

  @override
  State<HospitalInfoScreen> createState() => _HospitalInfoScreenState();
}

class _HospitalInfoScreenState extends State<HospitalInfoScreen> {
  final FirestoreService service = FirestoreService();

  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final result = await service.getHospitalInfo();

    if (!mounted) return;
    setState(() {
      data = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Information'),
      ),
      body: data == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(
                    data!['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data!['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}