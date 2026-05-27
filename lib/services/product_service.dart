import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');

  // Fetch all products — falls back to local dummyProducts if Firestore is empty or unavailable
  Future<List<Product>> getAllProducts() async {
    try {
      final querySnapshot = await _productsCollection.get();
      final products = querySnapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // If Firestore is empty (rules not set or first run), use local data
      if (products.isEmpty) {
        return dummyProducts;
      }
      return products;
    } catch (e) {
      print('Error fetching products: $e — using local data.');
      return dummyProducts;
    }
  }

  // Fetch products by category — falls back to local dummyProducts filtered by category
  Future<List<Product>> getProductsByCategory(String categoryName) async {
    try {
      final querySnapshot = await _productsCollection
          .where('category', isEqualTo: categoryName.toLowerCase())
          .get();
      final products = querySnapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // If Firestore is empty, fall back to local data filtered by category
      if (products.isEmpty) {
        return dummyProducts.where((p) => p.category.name.toLowerCase() == categoryName.toLowerCase()).toList();
      }
      return products;
    } catch (e) {
      print('Error fetching products by category: $e — using local data.');
      return dummyProducts.where((p) => p.category.name.toLowerCase() == categoryName.toLowerCase()).toList();
    }
  }
}
