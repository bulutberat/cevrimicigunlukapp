import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gunlukapp/main.dart';

class AuthSayfasi extends StatefulWidget {
  const AuthSayfasi({super.key});

  @override
  State<AuthSayfasi> createState() => _AuthSayfasiState();
}

class _AuthSayfasiState extends State<AuthSayfasi> {
  bool _girisYapiliyor = true;
  final TextEditingController _emailKontrolcusu = TextEditingController();
  final TextEditingController _sifreKontrolcusu = TextEditingController();
  final TextEditingController _sifreTekrarKontrolcusu = TextEditingController();
  final TextEditingController _adKontrolcusu = TextEditingController();
  final TextEditingController _soyadKontrolcusu = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  String _translateErrorMessage(String englishMessage) {
    switch (englishMessage) {
      case 'Invalid login credentials':
        return 'Geçersiz e-posta veya şifre.';
      case 'Email already registered':
        return 'Bu e-posta adresi zaten kayıtlı.';
      case 'User already registered':
        return 'Bu kullanıcı zaten kayıtlı.';
      case 'Email rate limit exceeded':
        return 'E-posta gönderme limiti aşıldı, lütfen daha sonra tekrar deneyin.';
      case 'For security purposes, you can only request this once every 60 seconds':
        return 'Güvenlik nedeniyle, bu isteği yalnızca 60 saniyede bir yapabilirsiniz.';
      case 'Password should be at least 6 characters':
        return 'Şifre en az 6 karakter olmalıdır.';
      default:
        return englishMessage;
    }
  }

  Future<void> _girisYap() async {
    try {
      await _supabase.auth.signInWithPassword(
        email: _emailKontrolcusu.text,
        password: _sifreKontrolcusu.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı!')),
        );
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GunlukAnaSayfa(baslik: 'Günlük Ana Sayfa')),
          (Route<dynamic> route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş hatası: ${_translateErrorMessage(e.message)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beklenmeyen bir hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _kayitOl() async {
    final email = _emailKontrolcusu.text.trim();
    final password = _sifreKontrolcusu.text.trim();
    final confirmPassword = _sifreTekrarKontrolcusu.text.trim();
    final ad = _adKontrolcusu.text.trim();
    final soyad = _soyadKontrolcusu.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || ad.isEmpty || soyad.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
        );
      }
      return;
    }

    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz e-posta formatı.')),
        );
      }
      return;
    }

    if (password != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifreler eşleşmiyor.')),
        );
      }
      return;
    }

    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'adi': ad, 'soyadi': soyad},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı!')),
        );
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GunlukAnaSayfa(baslik: 'Günlük Ana Sayfa')),
          (Route<dynamic> route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: ${_translateErrorMessage(e.message)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beklenmeyen bir hata oluştu: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailKontrolcusu.dispose();
    _sifreKontrolcusu.dispose();
    _sifreTekrarKontrolcusu.dispose();
    _adKontrolcusu.dispose();
    _soyadKontrolcusu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset(
                'assets/app_icon.png',
                height: 120,
              ),
              const SizedBox(height: 40),
              Text(
                _girisYapiliyor ? 'Hoş Geldiniz!' : 'Yeni Hesap Oluşturun',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailKontrolcusu,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email, color: Colors.black54),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (!_girisYapiliyor) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _adKontrolcusu,
                  decoration: const InputDecoration(
                    labelText: 'Adınız',
                    prefixIcon: Icon(Icons.person, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _soyadKontrolcusu,
                  decoration: const InputDecoration(
                    labelText: 'Soyadınız',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.black54),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _sifreKontrolcusu,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock, color: Colors.black54),
                ),
                obscureText: true,
              ),
              if (!_girisYapiliyor) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _sifreTekrarKontrolcusu,
                  decoration: const InputDecoration(
                    labelText: 'Şifreyi Tekrar Girin',
                    prefixIcon: Icon(Icons.lock, color: Colors.black54),
                  ),
                  obscureText: true,
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _girisYapiliyor ? _girisYap : _kayitOl,
                child: Text(_girisYapiliyor ? 'Giriş Yap' : 'Kayıt Ol'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _girisYapiliyor = !_girisYapiliyor;
                    _emailKontrolcusu.clear();
                    _sifreKontrolcusu.clear();
                    _sifreTekrarKontrolcusu.clear();
                    _adKontrolcusu.clear();
                    _soyadKontrolcusu.clear();
                  });
                },
                child: Text(
                  _girisYapiliyor
                      ? 'Hesabınız yok mu? Kayıt Olun'
                      : 'Zaten hesabınız var mı? Giriş Yapın',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}