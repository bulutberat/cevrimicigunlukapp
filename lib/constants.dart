// Bu dosya, uygulama genelinde kullanılan sabit değerleri (değişmeyen bilgileri) içerir.
// Amacı, API anahtarı gibi önemli bilgileri tek bir yerde toplamak ve kolayca erişilebilir kılmaktır.
class Constants {
  // Cohere AI servisi için kullanılan API anahtarı.
  // Bu anahtar, yapay zeka ile iletişim kurarken kimlik doğrulaması için kullanılır.
  static const String cohereApiKey = 'GplAIb8SJlFsYPIjHtTi6PfRK3XVAHNve3YCgrpK';

  static const Map<String, String> journalTypes = {
    'Klasik Günlük': 'Günlük yaşam, duygular, olaylar ve düşünceler yazılır.',
    'Seyahat Günlüğü': 'Yolculuk sırasında yaşananlar, gezilen yerler ve gözlemler yazılır. Genellikle tarih ve konum bilgileri içerir.',
    'Şükran Günlüğü': 'Gün içinde minnet duyulan şeyler yazılır. Ruh sağlığını desteklemek, olumlu düşünceyi artırmak amacıyla tutulur.',
    'Rüya Günlüğü': 'Görülen rüyalar kaydedilir. Rüyaların anlamlarını analiz etmek isteyenler veya yaratıcı projelerde ilham arayanlar kullanır.',
    'Sanat Günlüğü / Görsel Günlük': 'Yazıların yanı sıra çizimler, kolajlar, boyamalar da bulunur. Duygular hem yazı hem görsel olarak ifade edilir.',
    'Yansıtıcı Günlük': 'Eğitim, terapi, iş gibi süreçlerde bireyin kendi gelişimini değerlendirdiği yazılardır. Öğrenciler, öğretmenler veya profesyoneller tarafından kullanılır.',
    'Gelişim Günlüğü': 'Bir hedefe (diyet, spor, okuma vb.) yönelik ilerleme kaydedilir. Planlama ve motivasyon amaçlıdır.',
    'Duygu Günlüğü / Duygusal Günlük': 'Sadece duygulara odaklanır. Anksiyete, stres, mutluluk gibi duygular detaylandırılır. Özellikle terapötik kullanımda yaygındır.',
    'Hayal Günlüğü / Manifestasyon Günlüğü': 'Olmasını istediğin şeyler, hayaller, hedefler yazılır. Pozitif düşünce ve niyet ile hayatı şekillendirme amacı taşır.'
  };
} 