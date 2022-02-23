import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_firebase_hooks/extensions/firebase_firestore_extension.dart';
import 'package:riverpod_firebase_hooks/general_providers.dart';

import '../models/item_model.dart';
import 'custom_exception.dart';

abstract class BaseItemRepository {
  Future<List<Item>> retrieveItems({required String userId});

  Future<String> createItem({required String userId, required Item item});

  Future<void> updateItem({required String userId, required Item item});

  Future<void> deleteItem({required String userId, required String itemId});
}

final itemRepositoryProvider =
    Provider<ItemRepository>((ref) => ItemRepository(ref.read));

class ItemRepository implements BaseItemRepository {
  const ItemRepository(this._reader);

  final Reader _reader;

  @override
  Future<String> createItem({
    required String userId,
    required Item item,
  }) async {
    try {
      final docRef = await _reader(firebaseFirestoreProvider)
          .usersListRef(userId)
          .add(item.toDocument());

      return docRef.id;
    } on FirebaseException catch (err) {
      throw CustomException(message: err.message);
    }
  }

  @override
  Future<void> deleteItem({
    required String userId,
    required String itemId,
  }) async {
    try {
      await _reader(firebaseFirestoreProvider)
          .usersListRef(userId)
          .doc(itemId)
          .delete();
    } on FirebaseException catch (err) {
      throw CustomException(message: err.message);
    }
  }

  @override
  Future<List<Item>> retrieveItems({required String userId}) async {
    try {
      final snap =
          await _reader(firebaseFirestoreProvider).usersListRef(userId).get();

      return snap.docs.map((doc) => Item.fromDocument(doc)).toList();
    } on FirebaseException catch (err) {
      throw CustomException(message: err.message);
    }
  }

  @override
  Future<void> updateItem({
    required String userId,
    required Item item,
  }) async {
    try {
      await _reader(firebaseFirestoreProvider)
          .usersListRef(userId)
          .doc(item.id)
          .update(item.toDocument());
    } on FirebaseException catch (err) {
      throw CustomException(message: err.message);
    }
  }
}
