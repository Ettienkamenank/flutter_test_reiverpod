import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_firebase_hooks/controllers/auth_controller.dart';
import 'package:riverpod_firebase_hooks/controllers/item_list_controller.dart';
import 'package:riverpod_firebase_hooks/models/item_model.dart';
import 'package:riverpod_firebase_hooks/repositories/custom_exception.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authControllerState = ref.watch(authControllerProvider);

    ref.listen<CustomException?>(
      itemListExceptionProvider,
      (previous, next) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(next!.message!),
        ));
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod'),
        leading: authControllerState != null
            ? IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => AddItemDialog.show(context, Item.empty()),
      ),
      body: const ItemList(),
    );
  }
}

final currentItem = Provider<Item>((_) => throw UnimplementedError());

class ItemList extends ConsumerWidget {
  const ItemList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemListState = ref.watch(itemListControllerProvider);

    return itemListState.when(
      data: (items) => items.isEmpty
          ? const Center(
              child: Text(
                'Tap + to add an item',
                style: TextStyle(fontSize: 20.0),
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];
                return ProviderScope(
                  overrides: [currentItem.overrideWithValue(item)],
                  child: const ItemTile(),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ItemListError(
        message: err is CustomException ? err.message! : 'Something wrong',
      ),
    );
  }

// END OF CLASS
}

class ItemTile extends ConsumerWidget {
  const ItemTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(currentItem);

    return ListTile(
      key: ValueKey(item.id),
      title: Text(item.name),
      trailing: Checkbox(
        value: item.obtained,
        onChanged: (val) => ref
            .read(itemListControllerProvider.notifier)
            .updateItem(
          itemToUpdate: item.copyWith(obtained: !item.obtained),
        ),
      ),
      onTap: () => AddItemDialog.show(context, item),
      onLongPress: () => ref
          .read(itemListControllerProvider.notifier)
          .deleteItem(itemId: item.id!),
    );
  }
}

class AddItemDialog extends HookConsumerWidget {
  const AddItemDialog({Key? key, required this.item}) : super(key: key);

  final Item item;

  bool get isUpdating => item.id != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController(text: item.name);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: isUpdating
                      ? Colors.orange
                      : Theme.of(context).primaryColor,
                ),
                child: Text(isUpdating ? 'Update' : 'Add'),
                onPressed: () {
                  isUpdating
                      ? ref
                          .read(itemListControllerProvider.notifier)
                          .updateItem(
                            itemToUpdate: item.copyWith(
                              name: textController.text.trim(),
                              obtained: item.obtained,
                            ),
                          )
                      : ref
                          .read(itemListControllerProvider.notifier)
                          .addItem(name: textController.text.trim());

                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(item: item),
    );
  }

// END OF CLASS
}

class ItemListError extends ConsumerWidget {
  final String message;

  const ItemListError({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(fontSize: 20.0)),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () => ref
                .read(itemListControllerProvider.notifier)
                .retrieveItems(isRefreshing: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
