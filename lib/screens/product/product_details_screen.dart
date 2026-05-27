import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/clotex_theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../search/search_screen.dart';
import '../cart/cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String selectedSize = '';
  String selectedColor = '';
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    selectedSize = widget.product.availableSizes.first;
    selectedColor = widget.product.availableColors.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('CLOTEX'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    if (cart.items.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.items.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery (Mock)
            SizedBox(
              height: 500,
              child: PageView(
                children: [
                  _buildProductImage(widget.product.imageUrl),
                  Image.asset('assets/cover.png', fit: BoxFit.cover),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name.toUpperCase(),
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () {
                          setState(() {
                            isFavorite = !isFavorite;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFavorite ? 'Added to wishlist' : 'Removed from wishlist'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs ${widget.product.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFFD4AF37),
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  
                  // Color Selection
                  Text('SELECT COLOR — ${_getColorName(selectedColor)}', 
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: widget.product.availableColors.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? ClotexColors.primary : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(int.parse(color.replaceAll('#', '0xFF'))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Size Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SELECT SIZE', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: _showSizeGuide,
                        child: Text('SIZE GUIDE', style: Theme.of(context).textTheme.labelSmall?.copyWith(decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: widget.product.availableSizes.map((size) {
                      final isSelected = selectedSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => selectedSize = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? ClotexColors.primary : Colors.white,
                            border: Border.all(color: ClotexColors.divider),
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              color: isSelected ? Colors.white : ClotexColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<CartProvider>().addItem(widget.product, selectedSize, selectedColor);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart'), duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                      label: const Text('ADD TO CART'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClotexColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Product Features (Mock)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeatureIcon(Icons.eco_outlined, 'SUSTAINABLE'),
                      _buildFeatureIcon(Icons.verified_outlined, 'ETHICALLY MADE'),
                      _buildFeatureIcon(Icons.history_outlined, 'TIMELESS'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  const Divider(),
                  _buildExpandableTile('DETAILS & CARE', 'Dry clean only. Do not bleach. Iron on low heat if necessary. Store on a wide hanger to maintain shape.'),
                  const Divider(),
                  _buildExpandableTile('SUSTAINABILITY', 'This product was crafted using ethically sourced materials and sustainable manufacturing processes to reduce environmental impact.'),
                  const Divider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.grey)),
      ],
    );
  }

  Widget _buildExpandableTile(String title, String content) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(content, style: const TextStyle(height: 1.5, color: Colors.grey)),
        )
      ],
    );
  }

  String _getColorName(String hex) {
    switch (hex.toUpperCase()) {
      case '#3E424B': return 'CHARCOAL';
      case '#1A1A1A': return 'BLACK';
      case '#000000': return 'BLACK';
      case '#FFFFFF': return 'WHITE';
      case '#C0A080': return 'CAMEL';
      case '#1A237E': return 'NAVY';
      case '#0D47A1': return 'BLUE';
      default: return 'COLOR';
    }
  }

  void _showSizeGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SIZE GUIDE'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IT 46 - S (Chest 36")'),
            SizedBox(height: 8),
            Text('IT 48 - M (Chest 38")'),
            SizedBox(height: 8),
            Text('IT 50 - L (Chest 40")'),
            SizedBox(height: 8),
            Text('IT 52 - XL (Chest 42")'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }
  }
}
