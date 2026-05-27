import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class SeedService {
  static Future<void> seedProducts() async {
    final CollectionReference productsCollection = FirebaseFirestore.instance.collection('products');
    
    try {
      print('Seeding products to Firestore...');
      for (var product in dummyProducts) {
        await productsCollection.doc(product.id).set(product.toMap());
      }
      print('Products seeding completed successfully!');
    } catch (e) {
      print('Error seeding products: $e');
    }
  }
}
