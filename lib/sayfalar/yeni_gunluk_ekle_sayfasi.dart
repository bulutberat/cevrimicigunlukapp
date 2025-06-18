import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart'; // Görüntü düzenleyici paketi
import 'dart:typed_data'; // Uint8List için eklendi
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart'; // Ses oynatıcı için eklendi
import 'package:gunlukapp/sayfalar/auth_sayfasi.dart'; // AuthSayfasi için import
import 'package:gunlukapp/main.dart';
import 'package:gunlukapp/constants.dart'; // Constants dosyasını import et
import 'package:http/http.dart' as http; // http paketini import et
import 'dart:convert'; // JSON işlemleri için import et

class YeniGunlukEkleSayfasi extends StatefulWidget {
  final Map<String, dynamic>? gunlukVerisi; // Düzenlenecek günlük verisi

  const YeniGunlukEkleSayfasi({super.key, this.gunlukVerisi});

  @override
  State<YeniGunlukEkleSayfasi> createState() => _YeniGunlukEkleSayfasiDurumu();
}

class _YeniGunlukEkleSayfasiDurumu extends State<YeniGunlukEkleSayfasi> {
  File? _secilenDosya;
  final TextEditingController _metinKontrolcusu = TextEditingController();
  final AudioRecorder _sesKaydedici = AudioRecorder();
  bool _sesKayitDevamEdiyor = false;
  String? _sesDosyaYolu;
  String? _mevcutFotografUrl; // Mevcut fotoğrafın URL'si
  String? _mevcutSesKaydiUrl; // Mevcut ses kaydının URL'si
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _sesOynatiliyor = false;
  String? _secilenGunlukTuru; // Yeni: Seçilen günlük türü

  @override
  void initState() {
    super.initState();
    if (widget.gunlukVerisi != null) {
      _metinKontrolcusu.text = widget.gunlukVerisi!['metin'] ?? '';
      _mevcutFotografUrl = widget.gunlukVerisi!['fotograf_url'];
      _mevcutSesKaydiUrl = widget.gunlukVerisi!['ses_kaydi_url'];
      _secilenGunlukTuru = widget.gunlukVerisi!['type'];
    } else {
      _secilenGunlukTuru = Constants.journalTypes.keys.first;
    }
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _sesOynatiliyor = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _sesKaydedici.dispose();
    _metinKontrolcusu.dispose();
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

  Future<void> _fotografSec() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _secilenDosya = File(image.path);
        _mevcutFotografUrl = null;
      });
    }
  }

  Future<void> _fotografDuzenle() async {
    if (_secilenDosya == null && _mevcutFotografUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Düzenlemek için bir fotoğraf seçin veya mevcut fotoğrafı indirin.')),
      );
      return;
    }

    Uint8List? resimBytes;
    if (_secilenDosya != null) {
      resimBytes = await _secilenDosya!.readAsBytes();
    } else if (_mevcutFotografUrl != null) {
      try {
        resimBytes = await _supabase.storage.from('gunluk-fotograflari').download(_mevcutFotografUrl!.split('/').last);
      } on StorageException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotoğraf indirilirken hata oluştu: ${e.message}')),
          );
        }
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Beklenmeyen hata: $e')),
          );
        }
        return;
      }
    }

    if (resimBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Düzenlenecek bir fotoğraf bulunamadı veya indirilemedi.')),
        );
      }
      return;
    }

    final sonuc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          resimBytes!,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              final tempDir = await getTemporaryDirectory();
              final dosya = File('${tempDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.png');
              await dosya.writeAsBytes(bytes);
              if (mounted) Navigator.pop(context, dosya);
            },
          ),
        ),
      ),
    );

    if (sonuc != null && sonuc is File) {
      setState(() {
        _secilenDosya = sonuc;
        _mevcutFotografUrl = null;
      });
    }
  }

  Future<void> _sesKaydet() async {
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      try {
        final dizin = await getApplicationDocumentsDirectory();
        final dosyaYolu = '${dizin.path}/ses_kaydi_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _sesKaydedici.start(
          const RecordConfig(),
          path: dosyaYolu,
        );
        setState(() {
          _sesKayitDevamEdiyor = true;
          _sesDosyaYolu = null;
          _mevcutSesKaydiUrl = null;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ses kaydı başlatılırken hata: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni gerekli.')),
        );
      }
    }
  }

  Future<void> _sesKaydiDurdur() async {
    final path = await _sesKaydedici.stop();
    setState(() {
      _sesKayitDevamEdiyor = false;
      _sesDosyaYolu = path;
      if (path != null) {
        _mevcutSesKaydiUrl = null;
      }
    });
    print('Kaydedilen ses yolu: $_sesDosyaYolu');
  }

  Future<void> _sesOynat(String url) async {
    try {
      if (_sesOynatiliyor) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ses kaydı oynatılırken hata oluştu: $e')),
        );
      }
    }
  }

  Future<String?> _generateAiResponse(String diaryText) async {
    if (diaryText.isEmpty) return null;
    print('Cohere AI yanıtı oluşturma fonksiyonu çağrıldı. Giriş metni: $diaryText');

    final url = Uri.parse('https://api.cohere.com/v1/chat');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Constants.cohereApiKey}',
    };
    final body = jsonEncode({
      'model': 'c4ai-aya-expanse-8b',
      'message': '''Sen deneyimli, anlayışlı ve destekleyici bir psikolog gibi davranan bir yapay zeka asistanısın. **Her zaman ve kesinlikle Türkçe yanıt ver.** Kullanıcının günlük metnini dikkatlice oku ve ona 2-3 cümlelik, tamamıyla Türkçe, empatik ve umut verici bir yanıt oluştur. Yanıtta kesinlikle başlık veya giriş cümlesi kullanma, sadece doğrudan yanıt metnini sun. İşte bir örnek:

Günlük Metni: Bugün çok kötüydü, hiçbir şey yolunda gitmedi.
Yanıt: Hayatta inişler ve çıkışlar olur, bu zorlu zamanlar da geçecektir. Unutma ki her yeni gün, yeni umutlar getirir.

Günlük metni: "$diaryText" ve Yanıt:''',
      'temperature': 0.7,
      'max_tokens': 100,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['text'] != null && data['text'].isNotEmpty) {
          return data['text'];
        } else {
          print('Cohere API yanıtında metin bulunamadı: ${response.body}');
          return null;
        }
      } else {
        print('Cohere API hatası: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Cohere API bağlantı hatası: $e');
      return null;
    }
  }

  Future<String?> _fotografYukleSupabase(File dosya) async {
    try {
      final dosyaAdi = '${DateTime.now().millisecondsSinceEpoch}.png';
      final yuklenecekYol = 'gunluk-fotograflari/$dosyaAdi';
      await _supabase.storage.from('gunluk-fotograflari').upload(
            yuklenecekYol,
            dosya,
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from('gunluk-fotograflari').getPublicUrl(yuklenecekYol);
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf yüklenirken hata oluştu: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beklenmeyen hata: $e')),
        );
      }
      return null;
    }
  }

  Future<String?> _sesKaydiYukleSupabase(File dosya) async {
    try {
      final dosyaAdi = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final yuklenecekYol = 'gunluk-ses-kayitlari/$dosyaAdi';
      await _supabase.storage.from('gunluk-ses-kayitlari').upload(
            yuklenecekYol,
            dosya,
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from('gunluk-ses-kayitlari').getPublicUrl(yuklenecekYol);
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ses kaydı yüklenirken hata oluştu: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beklenmeyen hata: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _gunlukKaydet() async {
    String? finalFotografUrl = _mevcutFotografUrl;
    String? finalSesKaydiUrl = _mevcutSesKaydiUrl;
    final metin = _metinKontrolcusu.text;
    String? aiResponse; // AI yanıtı için değişken

    // Check if it's an existing entry and retrieve original AI response
    if (widget.gunlukVerisi != null) {
      aiResponse = widget.gunlukVerisi!['ai_response'];
      // If the text has changed, or there was no AI response previously for this entry, generate a new one
      if (metin != (widget.gunlukVerisi!['metin'] ?? '') || aiResponse == null) {
        aiResponse = await _generateAiResponse(_metinKontrolcusu.text);
      }
    } else { // New entry
      aiResponse = await _generateAiResponse(_metinKontrolcusu.text);
    }

    if (_secilenDosya != null) {
      finalFotografUrl = await _fotografYukleSupabase(_secilenDosya!);
    }

    if (_sesDosyaYolu != null) {
      finalSesKaydiUrl = await _sesKaydiYukleSupabase(File(_sesDosyaYolu!));
    }

    if (metin.isEmpty && finalFotografUrl == null && finalSesKaydiUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen en az bir giriş yapın (metin, fotoğraf veya ses).')),
        );
      }
      return;
    }

    try {
      final data = {
        'metin': metin.isEmpty ? null : metin,
        'fotograf_url': finalFotografUrl,
        'ses_kaydi_url': finalSesKaydiUrl,
        'user_id': _supabase.auth.currentUser!.id,
        'ai_response': aiResponse, // AI yanıtını ekle
        'type': _secilenGunlukTuru,
      };

      if (widget.gunlukVerisi != null) {
        await _supabase.from('gunluk_girisleri').update(data).eq('id', widget.gunlukVerisi!['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Günlük başarıyla güncellendi!')),
          );
        }
      } else {
        await _supabase.from('gunluk_girisleri').insert(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Günlük başarıyla kaydedildi!')),
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Günlük kaydedilirken/güncellenirken hata: ${e.message}')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.gunlukVerisi == null ? 'Yeni Günlük Ekle' : 'Günlüğü Düzenle',
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _secilenGunlukTuru,
              decoration: InputDecoration(
                labelText: 'Günlük Türü Seçin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              items: Constants.journalTypes.keys.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _secilenGunlukTuru = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _metinKontrolcusu,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Bugünün notları...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              minLines: 5,
            ),
            const SizedBox(height: 30),
            // Görsel Ekleme Bölümü
            Text(
              'Görsel Ekle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _secilenDosya != null
                ? Image.file(_secilenDosya!, height: 200, fit: BoxFit.cover)
                : (_mevcutFotografUrl != null
                    ? Image.network(_mevcutFotografUrl!, height: 200, fit: BoxFit.cover)
                    : const SizedBox.shrink()),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10.0, // Yatay boşluk
              runSpacing: 10.0, // Dikey boşluk
              alignment: WrapAlignment.center, // Butonları ortala
              children: [
                ElevatedButton.icon(
                  onPressed: _fotografSec,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Görsel Ekle'), // Metin güncellendi
                ),
                ElevatedButton.icon(
                  onPressed: _fotografDuzenle,
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                ),
                if (_secilenDosya != null || _mevcutFotografUrl != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _secilenDosya = null;
                        _mevcutFotografUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Kaldır'), // Metin güncellendi
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700), // Daha koyu kırmızı
                  ),
              ],
            ),
            const SizedBox(height: 30),
            // Ses Kaydı Bölümü
            Text(
              'Ses Kaydı Ekle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10.0, // Yatay boşluk
              runSpacing: 10.0, // Dikey boşluk
              alignment: WrapAlignment.center, // Butonları ortala
              children: [
                ElevatedButton.icon(
                  onPressed: _sesKayitDevamEdiyor ? _sesKaydiDurdur : _sesKaydet,
                  icon: Icon(_sesKayitDevamEdiyor ? Icons.stop : Icons.mic),
                  label: Text(_sesKayitDevamEdiyor ? 'Kaydı Durdur' : 'Kaydı Başlat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sesKayitDevamEdiyor ? Colors.red.shade700 : Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
                  ),
                ),
                if (_sesDosyaYolu != null || _mevcutSesKaydiUrl != null) ...[
                  ElevatedButton.icon(
                    onPressed: () => _sesOynat(_sesDosyaYolu ?? _mevcutSesKaydiUrl!),
                    icon: Icon(_sesOynatiliyor ? Icons.pause : Icons.play_arrow),
                    label: Text(_sesOynatiliyor ? 'Durdur' : 'Oynat'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _sesDosyaYolu = null;
                        _mevcutSesKaydiUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Kaldır'), // Metin güncellendi
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700), // Daha koyu kırmızı
                  ),
                ],
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _gunlukKaydet,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                    widget.gunlukVerisi == null ? 'Günlüğü Kaydet' : 'Günlüğü Güncelle',
                    style: const TextStyle(fontSize: 18)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}