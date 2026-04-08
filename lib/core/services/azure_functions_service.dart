import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

const String azureBaseUrl = 'https://payroute-functions.azurewebsites.net/api';
// Set false when Azure deployed
const bool kUseMockFunctions = false; 

class AzureFunctionsService {
  
  Future<String?> generateToken({
    required String destinationStopId,
    required int companionCount,
    required String passengerId,
  }) async {
    if (kUseMockFunctions) {
      await Future.delayed(const Duration(seconds: 1));
      return 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return null;

      final response = await http.post(
        Uri.parse('$azureBaseUrl/generateToken'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'destinationStopId': destinationStopId,
          'companionCount': companionCount,
          'passengerId': passengerId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['tokenId'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> processBoarding({
    required String tokenId,
    required String conductorId,
    required String busId,
  }) async {
    if (kUseMockFunctions) {
      await Future.delayed(const Duration(seconds: 2));
      return {
        'success': true, 
        'seatNumber': 14, 
        'fareCents': 4500,
        'boardingStopName': 'Gampaha Station',
        'tripId': 'mock_trip_id'
      };
    }

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return null;

      final response = await http.post(
        Uri.parse('$azureBaseUrl/processBoarding'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'tokenId': tokenId,
          'conductorId': conductorId,
          'busId': busId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Unknown error');
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> signalDrop({required String tripId}) async {
    if (kUseMockFunctions) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
       final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return false;

      final response = await http.post(
        Uri.parse('$azureBaseUrl/signalDrop'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'tripId': tripId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
