import 'package:flutter/material.dart';
import '../services/departments_service.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() =>
      _DepartmentsScreenState();
}

class _DepartmentsScreenState
    extends State<DepartmentsScreen> {
  final DepartmentsService service =
      DepartmentsService();

  List departments = [];

  @override
  void initState() {
    super.initState();
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    final data = await service.getDepartments();

    setState(() {
      departments = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
      ),
      body: departments.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: departments.length,
              itemBuilder: (context, index) {
                final dept = departments[index];
                final map =
                    dept.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(
                      map['name_am'] ??
                          map['name'] ??
                          'No Name',
                    ),
                    subtitle: Text(
                      map['location_am'] ??
                          map['location'] ??
                          'No Location',
                    ),
                  ),
                );
              },
            ),
    );
  }
}