import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/edit-user-profile'),
            tooltip: 'Edit user profile',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ਸਾਡਾ ਉਦੇਸ਼',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('ਗੁਰਬਾਣੀ ਕੰਠ ਕਰਨੀ ਅਤੇ ਆਪਣੇ ਇਤਿਹਾਸ ਤੇ ਵਿਰਸੇ ਨਾਲ ਜੁੜਨਾ।',
                        style: TextStyle(fontSize: 14)),
                    SizedBox(height: 12),
                    Text('Our Mission',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                        'Come, let us learn Gurbani by heart and stay connected to our rich history and values.',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/gurbani-list'),
              child: const Text('Select Gurbani / ਚੁਣੋ'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/prize-list'),
              child: const Text('Select Prize / ਇਨਾਮ ਚੁਣੋ'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/status'),
              child: const Text('Current Status / ਮੌਜੂਦਾ ਸਥਿਤੀ'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              child: const Text('Participation Record / ਭਾਗੀਦਾਰੀ ਦਾ ਵੇਰਵਾ'),
            ),
            const Spacer(),
            const Text('Welcome to the app. Select a flow to continue.'),
          ],
        ),
      ),
    );
  }
}
