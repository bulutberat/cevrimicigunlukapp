import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart'; // Ses oynatıcı için eklenecek
import 'package:gunlukapp/sayfalar/yeni_gunluk_ekle_sayfasi.dart'; // Yeni ekleme için import
import 'package:gunlukapp/sayfalar/auth_sayfasi.dart'; // AuthSayfasi için import
import 'package:gunlukapp/main.dart';
import 'package:gunlukapp/constants.dart'; // Constants dosyasını import et

class GunlukListesiSayfasi extends StatefulWidget {
  const GunlukListesiSayfasi({super.key});

  @override
  State<GunlukListesiSayfasi> createState() => _GunlukListesiSayfasiDurumu();
}

class _GunlukListesiSayfasiDurumu extends State<GunlukListesiSayfasi> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _gunlukGirisleri;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Ses oynatıcı nesnesi
  String? _oynatilanSesUrl; // Oynatılan sesin URL'sini tutar
  PlayerState _playerState = PlayerState.stopped;
  String? _secilenKategori; // Yeni: Seçilen kategori

  @override
  void initState() {
    super.initState();
    // Başlangıçta tüm günlükleri getir veya varsayılan bir kategori seç
    _secilenKategori = 'Tüm Günlükler'; // Varsayılan kategori
    _gunlukGirisleri = _fetchGunlukGirisleri(category: _secilenKategori); 
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthSayfasi()),
          (Route<dynamic> route) => false,
        );
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

  Future<List<Map<String, dynamic>>> _fetchGunlukGirisleri({String? category}) async {
    // Yalnızca oturum açmış kullanıcının günlüklerini getir
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return Future.value([]); // Kullanıcı yoksa boş Future liste döndür
    }
    try {
      var query = _supabase
          .from('gunluk_girisleri')
          .select()
          .eq('user_id', currentUserId); // Mevcut kullanıcının id'si ile filtrele

      if (category != null && category != 'Tüm Günlükler') {
        query = query.eq('type', category);
      }

      final List<Map<String, dynamic>> veriler = await query.order('olusturulma_tarihi', ascending: false);
      return veriler; // Verileri döndür
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Günlükler yüklenirken hata oluştu: $e')),
        );
      }
      return Future.error(e); // Hatayı FutureBuilder'a ilet
    }
  }

  Future<void> _sesOynat(String url) async {
    try {
      if (_oynatilanSesUrl == url && _playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_oynatilanSesUrl == url && _playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _oynatilanSesUrl = url;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ses kaydı oynatılırken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _gunlukSil(String id) async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Günlüğü Sil'),
          content: const Text('Bu günlüğü silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (onay == true) {
      try {
        await _supabase.from('gunluk_girisleri').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Günlük başarıyla silindi!')),
          );
        }
        _gunlukGirisleri = _fetchGunlukGirisleri();
        setState(() {});
      } on PostgrestException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Günlük silinirken hata: ${e.message}')),
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
  }

  Future<void> _gunlukDuzenle(Map<String, dynamic> gunluk) async {
    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YeniGunlukEkleSayfasi(gunlukVerisi: gunluk),
      ),
    );
    if (sonuc == true) {
      _gunlukGirisleri = _fetchGunlukGirisleri();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlüklerim'),
        toolbarHeight: 120.0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // Dropdown için yükseklik
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: DropdownButtonFormField<String>(
              value: _secilenKategori,
              decoration: InputDecoration(
                labelText: 'Kategoriye Göre Filtrele',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['Tüm Günlükler', ...Constants.journalTypes.keys].map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _secilenKategori = newValue;
                  _gunlukGirisleri = _fetchGunlukGirisleri(category: _secilenKategori);
                });
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gunlukGirisleri,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Günlükler yüklenirken hata oluştu: ${snapshot.error}\nLütfen Supabase RLS policy\'lerinizi kontrol edin.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red.shade700),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    !snapshot.hasData || snapshot.data!.isEmpty
                        ? (_secilenKategori != null && _secilenKategori != 'Tüm Günlükler'
                            ? 'Bu kategoride henüz bir günlük girişi yok.'
                            : 'Henüz bir günlük girişi yok.')
                        : '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Yeni bir günlük eklemek için geri dönün.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          } else {
            final gunlukler = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: gunlukler.length,
              itemBuilder: (context, index) {
                final gunluk = gunlukler[index];
                return Card(
                  elevation: Theme.of(context).cardTheme.elevation,
                  shape: Theme.of(context).cardTheme.shape,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori: ${gunluk['type'] ?? 'Belirtilmemiş'}' ?? 'Belirtilmemiş',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (gunluk['fotograf_url'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                gunluk['fotograf_url'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Text(
                          gunluk['metin'] ?? 'Metin yok',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 15),
                        if (gunluk['ai_response'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yapay Zeka Yanıtı:',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                gunluk['ai_response'],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        if (gunluk['ses_kaydi_url'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ses Kaydı',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _sesOynat(gunluk['ses_kaydi_url']),
                                      icon: Icon(_oynatilanSesUrl == gunluk['ses_kaydi_url'] && _playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow),
                                      label: Text(_oynatilanSesUrl == gunluk['ses_kaydi_url'] && _playerState == PlayerState.playing ? 'Durdur' : 'Oynat'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${DateTime.parse(gunluk['olusturulma_tarihi']).toLocal().day}.'
                            '${DateTime.parse(gunluk['olusturulma_tarihi']).toLocal().month}.'
                            '${DateTime.parse(gunluk['olusturulma_tarihi']).toLocal().year} ' // Yıl
                            '${DateTime.parse(gunluk['olusturulma_tarihi']).toLocal().hour}:'
                            '${DateTime.parse(gunluk['olusturulma_tarihi']).toLocal().minute}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _gunlukDuzenle(gunluk),
                              child: const Text('Düzenle'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _gunlukSil(gunluk['id']),
                              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
} 