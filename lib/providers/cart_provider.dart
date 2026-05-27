import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  final String selectedSize;
  final String selectedColor;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'productId': product.id,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, String docId) {
    return CartItem(
      product: Product.fromFirestore(Map<String, dynamic>.from(map['product'] ?? {}), map['productId'] ?? docId),
      selectedSize: map['selectedSize'] ?? '',
      selectedColor: map['selectedColor'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CartItem> get items => [..._items];

  int get itemCount => _items.length;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get shipping => subtotal > 15000 ? 0 : 250;

  double get tax => subtotal * 0.05;

  double get total => subtotal + shipping + tax;

  // Load cart from Firestore
  Future<void> loadCartFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('carts').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic> itemsList = doc.data()!['items'] ?? [];
        _items.clear();
        for (var itemMap in itemsList) {
          _items.add(CartItem.fromMap(Map<String, dynamic>.from(itemMap), itemMap['productId'] ?? ''));
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart from Firestore: $e');
    }
  }

  // Sync cart to Firestore
  Future<void> syncCartToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('carts').doc(user.uid).set({
        'items': _items.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error syncing cart to Firestore: $e');
    }
  }

  void addItem(Product product, String size, String color) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.selectedSize == size && item.selectedColor == color,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(CartItem(
        product: product,
        selectedSize: size,
        selectedColor: color,
      ));
    }
    notifyListeners();
    syncCartToFirestore();
  }

  void removeItem(String productId, String size, String color) {
    _items.removeWhere(
      (item) => item.product.id == productId && item.selectedSize == size && item.selectedColor == color,
    );
    notifyListeners();
    syncCartToFirestore();
  }

  void updateQuantity(String productId, String size, String color, int delta) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId && item.selectedSize == size && item.selectedColor == color,
    );
    if (index >= 0) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
      syncCartToFirestore();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    syncCartToFirestore();
  }
}
