#services
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Handles all Firebase Storage uploads for PayRoute.
///
/// Storage path conventions:
///   users/{userId}/profile.jpg
///   drivers/{driverId}/profile.jpg
///   drivers/{driverId}/selfie.jpg
///   drivers/{driverId}/license_front.jpg
///   drivers/{driverId}/license_back.jpg
///   conductors/{conductorId}/profile.jpg
///   conductors/{conductorId}/selfie.jpg
///   owners/{ownerId}/profile.jpg
///   owners/{ownerId}/selfie.jpg
///   buses/{busId}/photo.jpg
///   buses/{busId}/rmv_book.jpg
///   buses/{busId}/insurance.jpg
///   complaints/{complaintId}/photo.jpg
class StorageService {
  StorageService._();

  /// Uploads [file] to [storagePath] in Firebase Storage.
  /// Returns the public download URL.
  /// Throws on failure — callers should handle errors.
  static Future<String> uploadFile({
    required File file,
    required String storagePath,
    void Function(double progress)? onProgress,
  }) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    final task = ref.putFile(file);

    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });
    }
#servicesend
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }
}
