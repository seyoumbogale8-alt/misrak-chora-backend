import 'package:flutter/material.dart';
import 'web_chat_screen.dart';
import 'hospital_info_screen.dart';
import 'departments_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Misrak Chora AI'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const WebChatScreen(),
                  ),
                );
              },
              child: const Text(
                'Start Misrak Chora AI',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const HospitalInfoScreen(),
                  ),
                );
              },
              child: const Text(
                'Hospital Information',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DepartmentsScreen(),
                  ),
                );
              },
              child: const Text(
                'Departments',
              ),
            ),
          ],
        ),
      ),
    );
  }
}