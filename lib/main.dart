import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth untuk cek status login
import 'firebase_options.dart';

// Import Halaman
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  // 1. Pastikan binding flutter terinisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  // 2. Inisialisasi Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization failed: $e\n$stackTrace');
  }

  // 3. Jalankan App (Tanpa DevicePreview)
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  const MyApp({super.key, this.firebaseInitialized = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Literasi Digital',
      
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),

      // LOGIKA AUTO-LOGIN (PENTING)
      home: !firebaseInitialized
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Inisialisasi Firebase Gagal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pastikan perangkat terhubung ke internet dan coba buka aplikasi kembali.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // A. Jika sedang memuat status login
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // B. Jika User ditemukan (Sudah Login) -> Ke HomePage
                if (snapshot.hasData) {
                  return const HomePage();
                }

                // C. Jika User tidak ditemukan (Belum Login) -> Ke LoginPage
                return const LoginPage();
              },
            ),

      // Routes tetap ada untuk navigasi manual jika diperlukan
      routes: {
        "/login": (context) => const LoginPage(),
        "/home": (context) => const HomePage(),
      },
    );
  }
}