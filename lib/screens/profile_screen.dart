import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (user != null) ...[
              if (user.photoURL != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user.photoURL!),
                )
              else
                CircleAvatar(
                  radius: 50,
                  child: Icon(LucideIcons.user, size: 50),
                ),
              const SizedBox(height: 16),
              Text(
                user.displayName ?? 'Felhasználó',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (user.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.email!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Kijelentkezés'),
                      content: const Text('Biztosan ki szeretnél jelentkezni?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Mégse'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Kijelentkezés'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    // Sign out from Google
                    await googleSignIn.signOut();
                    // Sign out from Firebase
                    await FirebaseAuth.instance.signOut();
                    // The AuthWrapper will automatically redirect to login screen
                  }
                },
                icon: const Icon(LucideIcons.logOut),
                label: const Text(
                  'Kijelentkezés',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

