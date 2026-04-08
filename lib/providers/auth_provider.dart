import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../models/user_model.dart';

part 'auth_provider.g.dart';

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

@riverpod
FirestoreService firestoreService(FirestoreServiceRef ref) {
  return FirestoreService();
}

@riverpod
class OnboardingState extends _$OnboardingState {
  @override
  bool build() => false;

  void start() => state = true;
  void complete() => state = false;
}

@riverpod
Stream<UserModel?> currentUserStream(CurrentUserStreamRef ref) {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authService.authStateChanges.asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;
    return await firestoreService.getUser(firebaseUser.uid);
  });
}
