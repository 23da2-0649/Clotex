import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/clotex_theme.dart';

class _Address {
  String id;
  String label;
  String name;
  String address;
  String phone;
  bool isDefault;

  _Address({
    required this.id,
    required this.label,
    required this.name,
    required this.address,
    required this.phone,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'name': name,
        'address': address,
        'phone': phone,
        'isDefault': isDefault,
      };

  factory _Address.fromMap(String id, Map<String, dynamic> map) => _Address(
        id: id,
        label: map['label'] ?? '',
        name: map['name'] ?? '',
        address: map['address'] ?? '',
        phone: map['phone'] ?? '',
        isDefault: map['isDefault'] ?? false,
      );
}

class ShippingAddressesScreen extends StatefulWidget {
  const ShippingAddressesScreen({super.key});

  @override
  State<ShippingAddressesScreen> createState() =>
      _ShippingAddressesScreenState();
}

class _ShippingAddressesScreenState extends State<ShippingAddressesScreen> {
  List<_Address> _addresses = [];
  bool _isLoading = true;

  CollectionReference<Map<String, dynamic>>? _addressCollection;

  @override
  void initState() {
    super.initState();
    _initFirestore();
  }

  void _initFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _addressCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses');
      _loadAddresses();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final snapshot = await _addressCollection!.get();
      final loaded = snapshot.docs
          .map((doc) => _Address.fromMap(doc.id, doc.data()))
          .toList();
      loaded.sort((a, b) => b.isDefault ? 1 : -1);
      if (mounted) {
        setState(() {
          _addresses = loaded;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddress(_Address addr) async {
    if (_addressCollection == null) return;
    if (addr.id.isEmpty) {
      // New address
      final doc = await _addressCollection!.add(addr.toMap());
      addr.id = doc.id;
    } else {
      await _addressCollection!.doc(addr.id).set(addr.toMap());
    }
  }

  Future<void> _deleteAddress(String id) async {
    if (_addressCollection == null) return;
    await _addressCollection!.doc(id).delete();
  }

  Future<void> _setDefault(String id) async {
    if (_addressCollection == null) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final a in _addresses) {
      batch.update(_addressCollection!.doc(a.id), {'isDefault': a.id == id});
    }
    await batch.commit();
    await _loadAddresses();
  }

  void _showAddressForm({_Address? existing}) {
    final isEdit = existing != null;

    final labelCtrl =
        TextEditingController(text: isEdit ? existing.label : '');
    final nameCtrl = TextEditingController(text: isEdit ? existing.name : '');
    final addrCtrl =
        TextEditingController(text: isEdit ? existing.address : '');
    final phoneCtrl =
        TextEditingController(text: isEdit ? existing.phone : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 28,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'EDIT ADDRESS' : 'NEW ADDRESS',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                _formField('LABEL (e.g. HOME, OFFICE)', labelCtrl),
                const SizedBox(height: 16),
                _formField('FULL NAME', nameCtrl),
                const SizedBox(height: 16),
                _formField('ADDRESS', addrCtrl),
                const SizedBox(height: 16),
                _formField('PHONE NUMBER', phoneCtrl),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClotexColors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () async {
                      final label = labelCtrl.text.trim().toUpperCase();
                      final name = nameCtrl.text.trim();
                      final address = addrCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();

                      if (label.isEmpty ||
                          name.isEmpty ||
                          address.isEmpty ||
                          phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill in all fields.')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      final addr = isEdit
                          ? (existing
                            ..label = label
                            ..name = name
                            ..address = address
                            ..phone = phone)
                          : _Address(
                              id: '',
                              label: label,
                              name: name,
                              address: address,
                              phone: phone,
                              isDefault: _addresses.isEmpty,
                            );

                      await _saveAddress(addr);
                      await _loadAddresses();
                    },
                    child: Text(isEdit ? 'SAVE CHANGES' : 'ADD ADDRESS'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _formField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ClotexColors.divider)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(_Address addr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content:
            Text('Remove "${addr.label}" address?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteAddress(addr.id);
      await _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHIPPING ADDRESSES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: _addresses.isEmpty
                        ? const Center(
                            child: Text(
                              'No saved addresses.\nTap below to add one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _addresses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (_, i) =>
                                _buildAddressCard(_addresses[i]),
                          ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => _showAddressForm(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                      child: const Text('ADD NEW ADDRESS',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressCard(_Address addr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
            color: addr.isDefault ? Colors.black : ClotexColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(addr.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 12)),
              if (addr.isDefault)
                const Text('DEFAULT',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Text(addr.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(addr.address,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(addr.phone,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAddressForm(existing: addr),
                child: const Text('Edit',
                    style: TextStyle(
                        decoration: TextDecoration.underline, fontSize: 12)),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _confirmDelete(addr),
                child: const Text('Delete',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                        color: Colors.red)),
              ),
              if (!addr.isDefault) ...[
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _setDefault(addr.id),
                  child: const Text('Set Default',
                      style: TextStyle(
                          decoration: TextDecoration.underline, fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
