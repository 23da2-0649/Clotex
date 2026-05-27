enum Category { essentials, outerwear, denim }

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final Category category;
  final List<String> availableSizes;
  final List<String> availableColors;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.availableSizes,
    required this.availableColors,
  });

  // Convert Firestore Map to Product object
  factory Product.fromFirestore(Map<String, dynamic> data, String docId) {
    return Product(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      category: _categoryFromString(data['category'] ?? 'essentials'),
      availableSizes: List<String>.from(data['availableSizes'] ?? []),
      availableColors: List<String>.from(data['availableColors'] ?? []),
    );
  }

  // Convert Product object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category.name,
      'availableSizes': availableSizes,
      'availableColors': availableColors,
    };
  }

  // Helper to parse Category enum from String
  static Category _categoryFromString(String categoryStr) {
    return Category.values.firstWhere(
      (c) => c.name == categoryStr.toLowerCase(),
      orElse: () => Category.essentials,
    );
  }
}

// Dummy Data
final List<Product> dummyProducts = [
  Product(
    id: '1',
    name: 'Signature Leather Jacket',
    description: 'Meticulously crafted from ethically sourced premium leather. This jacket features a structured silhouette designed to drape perfectly, offering warmth and quiet luxury.',
    price: 8900,
    imageUrl: 'assets/overcoat.png',
    category: Category.outerwear,
    availableSizes: ['S', 'M', 'L', 'XL'],
    availableColors: ['#8B4513', '#1A1A1A'],
  ),
  Product(
    id: '2',
    name: 'Tailored Wool Trousers',
    description: 'Sophisticated wool trousers with a refined straight cut, crafted from the finest organic fibers for breathable comfort.',
    price: 5400,
    imageUrl: 'assets/sweater.png',
    category: Category.essentials,
    availableSizes: ['30', '32', '34', '36'],
    availableColors: ['#A0522D', '#556B2F'],
  ),
  Product(
    id: '3',
    name: 'Pure Silk Tailored Shirt',
    description: 'Luxurious silk shirt with a sharp tailored fit.',
    price: 3800,
    imageUrl: 'assets/silk.png',
    category: Category.essentials,
    availableSizes: ['S', 'M', 'L'],
    availableColors: ['#FFFFFF', '#000000'],
  ),
  Product(
    id: '4',
    name: 'Sculptural Straight Denim',
    description: 'Premium raw edge denim with a modern straight cut.',
    price: 2900,
    imageUrl: 'assets/denim.png',
    category: Category.denim,
    availableSizes: ['30', '32', '34', '36'],
    availableColors: ['#1A237E', '#0D47A1'],
  ),
];
