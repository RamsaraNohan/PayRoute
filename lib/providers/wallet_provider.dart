import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'passenger_provider.dart';
import 'auth_provider.dart';
import '../core/services/firestore_service.dart';

part 'wallet_provider.g.dart';

@riverpod
class WalletBalance extends _$WalletBalance {
  @override
  int build() {
    final passengerAsyncValue = ref.watch(passengerStreamProvider);
    return passengerAsyncValue.when(
      data: (passenger) => passenger?.walletBalance ?? 0,
      loading: () => 0,
      error: (e, st) => 0,
    );
  }

  Future<void> topUp(int amountCents) async {
    final passenger = ref.read(passengerStreamProvider).value;
    if (passenger != null) {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updatePassengerBalance(passenger.passengerId, amountCents);
    }
  }
}
