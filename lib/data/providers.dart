import 'package:flutter/foundation.dart';
import '../models/coffee_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addItem(CoffeeItem coffee, String size) {
    final existingIndex = _items.indexWhere(
      (item) => item.coffee.id == coffee.id && item.selectedSize == size,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(coffee: coffee, selectedSize: size));
    }
    notifyListeners();
  }

  void removeItem(String coffeeId, String size) {
    _items.removeWhere(
      (item) => item.coffee.id == coffeeId && item.selectedSize == size,
    );
    notifyListeners();
  }

  void decreaseQuantity(String coffeeId, String size) {
    final index = _items.indexWhere(
      (item) => item.coffee.id == coffeeId && item.selectedSize == size,
    );
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String coffeeId, String size) {
    return _items.any(
      (item) => item.coffee.id == coffeeId && item.selectedSize == size,
    );
  }
}

class FavoritesProvider extends ChangeNotifier {
  final List<CoffeeItem> _favorites = [];

  List<CoffeeItem> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String id) => _favorites.any((item) => item.id == id);

  void toggleFavorite(CoffeeItem coffee) {
    final index = _favorites.indexWhere((item) => item.id == coffee.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(coffee);
    }
    notifyListeners();
  }
}
