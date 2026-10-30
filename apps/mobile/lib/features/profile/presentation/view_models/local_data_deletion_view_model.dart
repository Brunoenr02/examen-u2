import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../pets/providers/pet_providers.dart';

final localDataDeletionViewModelProvider =
    NotifierProvider.autoDispose<LocalDataDeletionViewModel, AsyncValue<bool>>(
      LocalDataDeletionViewModel.new,
    );

class LocalDataDeletionViewModel extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  Future<void> delete() async {
    if (state.isLoading) return;
    final offline = ref.read(offlinePetsProvider);
    final session = ref.read(petSessionProvider).asData?.value;
    final notify = ref.read(notifyPetChangedProvider);
    state = const AsyncLoading();
    try {
      await offline.deleteAll();
      if (session != null) notify(session.userId, '');
      if (ref.mounted) state = const AsyncData(true);
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }
}
