import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/clotex_theme.dart';
import '../../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _fullNameController = TextEditingController(text: 'NASHMAN');
  final TextEditingController _phoneController = TextEditingController(text: '+94 1234567');
  final TextEditingController _addressController = TextEditingController(text: '42/17, Muslim Colony');
  final TextEditingController _cityController = TextEditingController(text: 'Kaduwela, Sri Lanka');

  final TextEditingController _cardNumberController = TextEditingController(text: '4000 1234 5678 8829');
  final TextEditingController _expiryController = TextEditingController(text: '11/28');
  final TextEditingController _cvvController = TextEditingController(text: '829');

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (_fullNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all shipping details.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to place an order.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderData = {
        'userId': user.uid,
        'shippingAddress': {
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'addressLine1': _addressController.text.trim(),
          'cityState': _cityController.text.trim(),
        },
        'paymentDetails': {
          'cardNumber': '•••• •••• •••• ${_cardNumberController.text.substring(_cardNumberController.text.length - 4)}',
          'cardHolder': _fullNameController.text.trim(),
        },
        'items': cart.items.map((item) => {
          'productId': item.product.id,
          'name': item.product.name,
          'price': item.product.price,
          'imageUrl': item.product.imageUrl,
          'quantity': item.quantity,
          'selectedSize': item.selectedSize,
          'selectedColor': item.selectedColor,
        }).toList(),
        'subtotal': cart.subtotal,
        'shippingCost': cart.shipping,
        'tax': cart.tax,
        'total': cart.total,
        'status': 'Processing',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        cart.clear();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('CLOTEX'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Checkout', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('Complete your order with secure payment.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                
                _buildSectionHeader(context, 'SHIPPING ADDRESS', null),
                const SizedBox(height: 16),
                _buildTextField(context, 'FULL NAME', _fullNameController),
                const SizedBox(height: 16),
                _buildTextField(context, 'PHONE NUMBER', _phoneController),
                const SizedBox(height: 16),
                _buildTextField(context, 'ADDRESS LINE 1', _addressController),
                const SizedBox(height: 16),
                _buildTextField(context, 'CITY & STATE', _cityController),
                const SizedBox(height: 32),

                _buildSectionHeader(context, 'DELIVERY METHOD', null),
                const SizedBox(height: 16),
                _buildDeliveryOption('Priority Courier', 'Next Day Delivery', 'Rs 250', true),
                const SizedBox(height: 12),
                _buildDeliveryOption('Standard Shipping', '3-5 Business Days', 'Free', false),
                const SizedBox(height: 32),

                _buildSectionHeader(context, 'PAYMENT INFORMATION', null),
                const SizedBox(height: 16),
                _buildCreditCardUI(),
                const SizedBox(height: 16),
                _buildTextField(context, 'CARD NUMBER', _cardNumberController, icon: Icons.lock_outline),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(context, 'EXPIRY DATE', _expiryController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(context, 'CVV', _cvvController)),
                  ],
                ),
                const SizedBox(height: 40),

                _buildOrderSummary(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: ClotexColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        if (action != null)
          Text(action, style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
      ],
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            suffixIcon: icon != null ? Icon(icon, size: 16, color: Colors.grey) : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: ClotexColors.divider)),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryOption(String title, String subtitle, String price, bool selected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: selected ? Colors.black : ClotexColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCreditCardUI() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.credit_card, color: Colors.white, size: 32),
              Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('•••• •••• •••• 8829', style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CARD HOLDER', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 8)),
                  const Text('NASHMAN', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPIRES', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 8)),
                  const Text('11 / 28', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...cart.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              _buildProductImage(item.product.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('Size: ${item.selectedSize}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              Text('Rs ${item.product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        )),
        const Divider(height: 32),
        _summaryRow('Subtotal', 'Rs ${cart.subtotal.toStringAsFixed(0)}'),
        _summaryRow('Shipping', cart.shipping == 0 ? 'Free' : 'Rs ${cart.shipping.toStringAsFixed(0)}'),
        _summaryRow('Estimated Tax', 'Rs ${cart.tax.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Rs ${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _placeOrder(cart),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClotexColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            ),
            child: const Text('PLACE ORDER'),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: 40,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          width: 40,
          height: 50,
          child: Icon(Icons.broken_image, size: 16, color: Colors.grey),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: 40,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          width: 40,
          height: 50,
          child: Icon(Icons.broken_image, size: 16, color: Colors.grey),
        ),
      );
    }
  }
}
