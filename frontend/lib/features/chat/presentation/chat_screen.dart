import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFF1B4F72)),
            SizedBox(height: 16),
            Text(
              'المحادثات قادمة قريباً',
              style: TextStyle(fontSize: 18, fontFamily: 'Cairo', color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
