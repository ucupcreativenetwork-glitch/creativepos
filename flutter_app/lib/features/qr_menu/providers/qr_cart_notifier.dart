import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/qr_menu_models.dart';

class QrCartItem {
  const QrCartItem({
    required this.product,
    required this.quantity,
    this.notes,
  });

  final PublicMenuProduct product;
  final double quantity;
  final String? notes;

  double get subtotal => product.basePrice * quantity;

  QrCartItem copyWith({double? quantity, String? notes}) {
    return QrCartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

class QrCartState {
  const QrCartState({
    this.items = const [],
    this.notes,
    this.tableToken,
  });

  final List<QrCartItem> items;
  final String? notes;
  final String? tableToken;

  double get subtotal => items.fold<double>(0, (sum, i) => sum + i.subtotal);

  int get itemCount =>
      items.fold<int>(0, (sum, i) => sum + i.quantity.round());

  QrCartState copyWith({
    List<QrCartItem>? items,
    String? notes,
    String? tableToken,
    bool clearTableToken = false,
  }) {
    return QrCartState(
      items: items ?? this.items,
      notes: notes ?? this.notes,
      tableToken: clearTableToken ? null : (tableToken ?? this.tableToken),
    );
  }
}

class QrCartNotifier extends StateNotifier<QrCartState> {
  QrCartNotifier() : super(const QrCartState());

  void addProduct(PublicMenuProduct product, {double quantity = 1}) {
    final index = state.items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      final updated = [...state.items];
      final item = updated[index];
      updated[index] = item.copyWith(quantity: item.quantity + quantity);
      state = state.copyWith(items: updated);
      return;
    }
    state = state.copyWith(
      items: [...state.items, QrCartItem(product: product, quantity: quantity)],
    );
  }

  void updateQuantity(int productId, double quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    state = state.copyWith(
      items: state.items
          .map((i) => i.product.id == productId
              ? i.copyWith(quantity: quantity)
              : i)
          .toList(),
    );
  }

  void removeProduct(int productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void setNotes(String? notes) => state = state.copyWith(notes: notes);

  void setTableToken(String? token) =>
      state = state.copyWith(tableToken: token, clearTableToken: token == null);

  void clear() => state = const QrCartState();
}

final qrCartProvider =
    StateNotifierProvider<QrCartNotifier, QrCartState>((ref) {
  return QrCartNotifier();
});