import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Restaurant Admin'),
              subtitle: const Text('admin@maasharda.com'),
              trailing: TextButton(onPressed: () {}, child: const Text('Edit')),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings'), onTap: () {}),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help & Support'), onTap: () {}),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
