import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class LocationService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Konum izin kontrolü
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Konum servisi aktif mi kontrol et
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Kullanıcıya konum servisini aktifleştirmesi için bildirim gösterilebilir
      return false;
    }

    // Konum izni kontrolü
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // İzin reddedildi
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // İzin kalıcı olarak reddedildi
      return false;
    }

    // Tüm kontrollerden geçildi, konum alınabilir
    return true;
  }

  // Kullanıcının konumunu al
  Future<Position?> getCurrentLocation() async {
    try {
      bool permissionGranted = await checkLocationPermission();
      if (!permissionGranted) {
        print('Konum izni alınamadı');
        return null;
      }

      // Kullanıcının konumunu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Konum alınırken hata: $e');
      return null;
    }
  }

  // Kullanıcının konumunu Firestore'a kaydet
  Future<bool> saveUserLocation() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Giriş yapmış kullanıcı bulunamadı');
        return false;
      }

      // Kullanıcının konumunu al
      Position? position = await getCurrentLocation();
      if (position == null) {
        print('Kullanıcı konumu alınamadı');
        return false;
      }

      // GeoPoint olarak kaydet
      GeoPoint geoPoint = GeoPoint(position.latitude, position.longitude);

      // Kullanıcı dökümanına konum bilgisini ekle
      await _firestore.collection('users').doc(currentUser.uid).update({
        'location': geoPoint,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('Kullanıcı konumu başarıyla kaydedildi');
      return true;
    } catch (e) {
      print('Konum kaydedilirken hata: $e');
      return false;
    }
  }

  // İki kullanıcı arasındaki mesafeyi hesapla (km)
  double calculateDistance(GeoPoint? location1, GeoPoint? location2) {
    if (location1 == null || location2 == null) return double.infinity;

    return Geolocator.distanceBetween(
          location1.latitude,
          location1.longitude,
          location2.latitude,
          location2.longitude,
        ) /
        1000; // Metreyi kilometreye çevir
  }

  // Kullanıcının belirli bir yarıçap içerisindeki kullanıcıları getir
  Future<List<String>> getNearbyUserIds(double radiusKm) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Giriş yapmış kullanıcı bulunamadı');
        return [];
      }

      // Mevcut kullanıcının konumunu al
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        print('Kullanıcı bulunamadı');
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final GeoPoint? userLocation = userData['location'];

      if (userLocation == null) {
        print('Kullanıcı konumu bulunamadı');
        return [];
      }

      // Tüm kullanıcıları getir
      final querySnapshot = await _firestore.collection('users').get();
      final List<String> nearbyUserIds = [];

      // Her kullanıcının mesafesini hesapla
      for (var doc in querySnapshot.docs) {
        // Kendisi hariç
        if (doc.id == currentUser.uid) continue;

        final data = doc.data();
        final GeoPoint? otherLocation = data['location'];

        if (otherLocation != null) {
          // Mesafeyi hesapla
          double distance = calculateDistance(userLocation, otherLocation);

          // Belirtilen yarıçap içindeyse listeye ekle
          if (distance <= radiusKm) {
            nearbyUserIds.add(doc.id);
          }
        }
      }

      return nearbyUserIds;
    } catch (e) {
      print('Yakındaki kullanıcılar alınırken hata: $e');
      return [];
    }
  }
}
