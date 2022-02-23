import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_firebase_hooks/controllers/auth_controller.dart';
import 'package:riverpod_firebase_hooks/models/item_model.dart';
import 'package:riverpod_firebase_hooks/repositories/custom_exception.dart';
import 'package:riverpod_firebase_hooks/repositories/item_repo.dart';

final itemListExceptionProvider = StateProvider<CustomException?>((_) => null);

final itemListControllerProvider =
    StateNotifierProvider<ItemListController, AsyncValue<List<Item>>>((ref) {
  final user = ref.watch(authControllerProvider);

  return ItemListController(ref.read, user?.uid);
});

class ItemListController extends StateNotifier<AsyncValue<List<Item>>> {
  ItemListController(
    this._reader,
    this._userId,
  ) : super(const AsyncValue.loading()) {
    if (_userId != null) retrieveItems();
  }

  final Reader _reader;
  final String? _userId;

  Future<void> retrieveItems({bool isRefreshing = false}) async {
    if (isRefreshing) state = const AsyncValue.loading();

    try {
      final items =
          await _reader(itemRepositoryProvider).retrieveItems(userId: _userId!);
      if (mounted) state = AsyncValue.data(items);
    } on CustomException catch (err, st) {
      state = AsyncValue.error(err, stackTrace: st);
    }
  }

  Future<void> addItem({required String name, bool obtained = false}) async {
    try {
      final item = Item(name: name, obtained: obtained);
      final itemId = await _reader(itemRepositoryProvider).createItem(
        userId: _userId!,
        item: item,
      );
      state.whenData((items) =>
          state = AsyncValue.data(items..add(item.copyWith(id: itemId))));
    } on CustomException catch (er) {
      _reader(itemListExceptionProvider.notifier).state = er;
    }
  }

  Future<void> updateItem({required Item itemToUpdate}) async {
    try {
      await _reader(itemRepositoryProvider)
          .updateItem(userId: _userId!, item: itemToUpdate);

      state.whenData((items) {
        state = AsyncValue.data([
          for (final item in items)
            if (item.id == itemToUpdate.id) itemToUpdate else item
        ]);
      });
    } on CustomException catch (er) {
      _reader(itemListExceptionProvider.notifier).state = er;
    }
  }

  Future<void> deleteItem({required String itemId}) async {
    try {
      await _reader(itemRepositoryProvider)
          .deleteItem(userId: _userId!, itemId: itemId);

      state.whenData((items) => state =
          AsyncValue.data(items..removeWhere((item) => item.id == itemId)));
    } on CustomException catch (er) {
      _reader(itemListExceptionProvider.notifier).state = er;
    }
  }

// End of class
}
