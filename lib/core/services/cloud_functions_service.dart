import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String?> generateToken({
    required String destinationStopId,
    required int companionCount,
    required String passengerId,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateToken');
      final result = await callable.call({
        'destinationStopId': destinationStopId,
        'companionCount': companionCount,
        'passengerId': passengerId,
      });
      return result.data['tokenId'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> processBoarding({
    required String tokenId,
    required String conductorId,
    required String busId,
  }) async {
    try {
      final callable = _functions.httpsCallable('processBoarding');
      final result = await callable.call({
        'tokenId': tokenId,
        'conductorId': conductorId,
        'busId': busId,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> signalDrop({required String tripId}) async {
    try {
      final callable = _functions.httpsCallable('signalDrop');
      await callable.call({'tripId': tripId});
    } catch (e) {
      // Ignore
    }
  }
}
