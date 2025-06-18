import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gunlukapp/sayfalar/yeni_gunluk_ekle_sayfasi.dart';
import 'package:gunlukapp/sayfalar/gunluk_listesi_sayfasi.dart';
import 'package:gunlukapp/sayfalar/auth_sayfasi.dart';
import 'package:gunlukapp/sayfalar/gunluk_turleri_bilgi_sayfasi.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://eqtqjjedzwmqclqyropc.supabase.co",
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxdHFqamVkendtcWNscXlyb3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwMzkyNzQsImV4cCI6MjA2NDYxNTI3NH0.MhX82DIalZRT04nvsPG8VqxPmYSnWeNgAcfmDgUc8KI',
  );

  runApp(const GunlukUygulamasi());
}

class GunlukUygulamasi extends StatefulWidget {
  const GunlukUygulamasi({super.key});

  @override
  State<GunlukUygulamasi> createState() => _GunlukUygulamasiState();
}

class _GunlukUygulamasiState extends State<GunlukUygulamasi> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // uygulama ilk açldığında vya oturm durumu değiştiinde yönlndirme
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        // otrum açma veya kapama durumnda navigatrü güncellyrek doğru syfaya yönlendrme
        if (Supabase.instance.client.auth.currentUser == null) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthSayfasi()),
            (Route<dynamic> route) => false,
          );
        } else {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const GunlukAnaSayfa(baslik: 'Günlük Ana Sayfa')),
            (Route<dynamic> route) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Günlük Uygulaması',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.grey,
          background: Colors.white,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black87,
          onSurface: Colors.black87,
          error: Colors.red,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black54,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      home: Supabase.instance.client.auth.currentUser == null
          ? const AuthSayfasi()
          : const GunlukAnaSayfa(baslik: 'Günlük Ana Sayfa'),
    );
  }
}

class GunlukAnaSayfa extends StatefulWidget {
  const GunlukAnaSayfa({super.key, required this.baslik});

  final String baslik;

  @override
  State<GunlukAnaSayfa> createState() => _GunlukAnaSayfaDurumu();
}

class _GunlukAnaSayfaDurumu extends State<GunlukAnaSayfa> {

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Başarıyla çıkış yapıldı!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['adi'] ?? 'Misafir';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        title: Text(widget.baslik, style: Theme.of(context).textTheme.headlineMedium),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/app_icon.png',
              height: 100,
            ),
            const SizedBox(height: 30),
            Text(
              'Hoş Geldin $userName!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const YeniGunlukEkleSayfasi(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_box, size: 28),
                label: const Text('Yeni Günlük Ekle'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GunlukListesiSayfasi(),
                    ),
                  );
                },
                icon: const Icon(Icons.book, size: 28),
                label: const Text('Günlüklerim'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GunlukTurleriBilgiSayfasi(),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline, size: 28),
                label: const Text('Günlük Türleri Bilgisi'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, size: 28),
                label: const Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }
}
