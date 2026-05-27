import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/clotex_theme.dart';
import '../home/home_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'order_history_screen.dart';
import 'wishlist_screen.dart';
import 'shipping_addresses_screen.dart';
import 'account_settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _userEmail = '';
  Uint8List? _profileImageBytes;
  static const String _prefKey = 'profile_picture_base64';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final base64Str = prefs.getString(_prefKey);
      if (base64Str != null && mounted) {
        setState(() => _profileImageBytes = base64Decode(base64Str));
      }
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
      });
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _userName = (doc.data()?['name'] ?? 'USER').toString().toUpperCase();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _userName = 'USER';
          });
        }
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final updatedName = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: _userName,
          currentEmail: _userEmail,
        ),
      ),
    );
    if (updatedName != null && mounted) {
      setState(() => _userName = updatedName);
    }
    // Reload profile image in case it changed
    _loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('CLOTEX'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Switch to search tab via parent bottom nav
              final homeState = context.findAncestorStateOfType<HomeScreenState>();
              if (homeState != null) {
                homeState.setState(() {
                  homeState.currentIndex = 1;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : null,
                        child: _profileImageBytes == null
                            ? Icon(Icons.person, size: 40, color: Colors.grey.shade500)
                            : null,
                      ),
                      GestureDetector(
                        onTap: _navigateToEditProfile,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: const Icon(Icons.edit, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  Text(
                    _userEmail,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _navigateToEditProfile,
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Stats Row
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'ORDERS', value: '12'),
                _StatItem(label: 'POINTS', value: '08'),
              ],
            ),
            const SizedBox(height: 40),

            // Menu Items
            _buildEditProfileItem(context),
            _buildMenuItem(context, Icons.shopping_bag_outlined, 'Order History', const OrderHistoryScreen()),
            _buildMenuItem(context, Icons.favorite_outline, 'Wishlist', const WishlistScreen()),
            _buildMenuItem(context, Icons.local_shipping_outlined, 'Shipping Addresses', const ShippingAddressesScreen()),
            _buildMenuItem(context, Icons.settings_outlined, 'Account Settings', const AccountSettingsScreen()),
            
            const SizedBox(height: 40),

            
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      // Success - reactive StreamBuilder in main.dart handles transition to LoginScreen.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClotexColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                  child: const Text('LOGOUT'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'CLOTEX MEMBERSHIP • SINCE 2024',
              style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileItem(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline, size: 20, color: Colors.black),
          title: const Text('Edit Profile', style: TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          onTap: _navigateToEditProfile,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        const Divider(indent: 24, endIndent: 24),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, Widget destination) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, size: 20, color: Colors.black),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        const Divider(indent: 24, endIndent: 24),
      ],
    );
  }
}


class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
