import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../models/transfer_service.dart';
import '../repository/transfer_repository.dart';

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(client: ref.read(supabaseClientProvider));
});

/// Transfers del aeropuerto de Balmaceda (HU-18).
final airportTransfersProvider =
    FutureProvider.autoDispose<TransferListResult>((ref) async {
  return ref.read(transferRepositoryProvider).getAirportTransfers();
});

/// Una ficha por id, desde la misma lista (sirve también sin conexión).
final airportTransferByIdProvider =
    FutureProvider.autoDispose.family<TransferService?, String>(
  (ref, id) async {
    final result = await ref.watch(airportTransfersProvider.future);
    for (final service in result.services) {
      if (service.id == id) return service;
    }
    return null;
  },
);
