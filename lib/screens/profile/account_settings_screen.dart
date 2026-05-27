import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  // Personal Info
  String _name = '';
  String _email = '';
  String _phone = '';
  String _dob = 'Not Set';

  // Security
  bool _twoFactorEnabled = false;

  // Preferences
  String _currency = 'LKR (Rs)';
  String _language = 'English';

  bool _isLoading = true;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    _email = user.email ?? '';
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ?? '';
          _phone = data['phone'] ?? '';
          _dob = data['dob'] ?? 'Not Set';
          _twoFactorEnabled = data['twoFactor'] ?? false;
          _currency = data['currency'] ?? 'LKR (Rs)';
          _language = data['language'] ?? 'English';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveField(String field, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({field: value}, SetOptions(merge: true));
  }

  // ── Edit text field dialog ──────────────────────────────────────────────
  Future<void> _editTextField({
    required String title,
    required String currentValue,
    required void Function(String) onSave,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final ctrl = TextEditingController(text: obscure ? '' : currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSave(result);
    }
  }

  // ── Date picker for DOB ────────────────────────────────────────────────
  Future<void> _pickDOB() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 10),
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() => _dob = formatted);
      await _saveField('dob', formatted);
    }
  }

  // ── Change password ────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Current Password', currentCtrl, obscure: true),
            const SizedBox(height: 12),
            _dialogField('New Password', newCtrl, obscure: true),
            const SizedBox(height: 12),
            _dialogField('Confirm New Password', confirmCtrl, obscure: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match.')));
                return;
              }
              if (newCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Password must be at least 6 characters.')));
                return;
              }
              Navigator.pop(ctx);
              try {
                final user = _auth.currentUser!;
                final cred = EmailAuthProvider.credential(
                    email: user.email!, password: currentCtrl.text);
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newCtrl.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Password updated successfully.')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')));
                }
              }
            },
            child: const Text('Update',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black26)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black)),
      ),
    );
  }

  // ── Picker bottom sheet ────────────────────────────────────────────────
  Future<void> _showPicker({
    required String title,
    required List<String> options,
    required String current,
    required void Function(String) onSelect,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 13)),
            const SizedBox(height: 16),
            ...options.map((opt) => ListTile(
                  title: Text(opt),
                  trailing: opt == current
                      ? const Icon(Icons.check, color: Colors.black)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect(opt);
                  },
                )),
          ],
        ),
      ),
    );
  }

  // ── Delete Account ─────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final passwordCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent and cannot be undone. Enter your password to confirm.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _dialogField('Password', passwordCtrl, obscure: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: passwordCtrl.text);
      await user.reauthenticateWithCredential(cred);

      // Delete Firestore data
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete the auth account
      await user.delete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACCOUNT SETTINGS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── PERSONAL INFORMATION ──────────────────────────────
                  const Text('PERSONAL INFORMATION',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 12)),
                  const SizedBox(height: 24),

                  _buildSettingItem(
                    label: 'NAME',
                    value: _name.isEmpty ? 'Not Set' : _name,
                    onTap: () => _editTextField(
                      title: 'Edit Name',
                      currentValue: _name,
                      onSave: (v) async {
                        setState(() => _name = v.toUpperCase());
                        await _saveField('name', v.toUpperCase());
                      },
                    ),
                  ),

                  _buildSettingItem(
                    label: 'EMAIL',
                    value: _email,
                    onTap: () => _editTextField(
                      title: 'Edit Email',
                      currentValue: _email,
                      keyboardType: TextInputType.emailAddress,
                      onSave: (v) async {
                        try {
                          await _auth.currentUser!.verifyBeforeUpdateEmail(v);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Verification email sent. Please verify to update.')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                  ),

                  _buildSettingItem(
                    label: 'PHONE',
                    value: _phone.isEmpty ? 'Not Set' : _phone,
                    onTap: () => _editTextField(
                      title: 'Edit Phone',
                      currentValue: _phone,
                      keyboardType: TextInputType.phone,
                      onSave: (v) async {
                        setState(() => _phone = v);
                        await _saveField('phone', v);
                      },
                    ),
                  ),

                  _buildSettingItem(
                    label: 'DATE OF BIRTH',
                    value: _dob,
                    onTap: _pickDOB,
                  ),

                  const SizedBox(height: 40),

                  // ── SECURITY ──────────────────────────────────────────
                  const Text('SECURITY',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 12)),
                  const SizedBox(height: 24),

                  _buildSettingItem(
                    label: 'PASSWORD',
                    value: '••••••••••••',
                    onTap: _changePassword,
                  ),

                  _buildToggleItem(
                    label: 'TWO-FACTOR AUTH',
                    subtitle: _twoFactorEnabled ? 'Enabled' : 'Disabled',
                    value: _twoFactorEnabled,
                    onChanged: (v) async {
                      setState(() => _twoFactorEnabled = v);
                      await _saveField('twoFactor', v);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Two-Factor Auth ${v ? 'enabled' : 'disabled'}.'),
                        ));
                      }
                    },
                  ),

                  const SizedBox(height: 40),

                  // ── PREFERENCES ───────────────────────────────────────
                  const Text('PREFERENCES',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 12)),
                  const SizedBox(height: 24),

                  _buildSettingItem(
                    label: 'CURRENCY',
                    value: _currency,
                    onTap: () => _showPicker(
                      title: 'SELECT CURRENCY',
                      options: ['LKR (Rs)', 'USD (\$)', 'EUR (€)', 'GBP (£)', 'INR (₹)'],
                      current: _currency,
                      onSelect: (v) async {
                        setState(() => _currency = v);
                        await _saveField('currency', v);
                      },
                    ),
                  ),

                  _buildSettingItem(
                    label: 'LANGUAGE',
                    value: _language,
                    onTap: () => _showPicker(
                      title: 'SELECT LANGUAGE',
                      options: ['English', 'Sinhala', 'Tamil', 'Arabic', 'French'],
                      current: _language,
                      onSelect: (v) async {
                        setState(() => _language = v);
                        await _saveField('language', v);
                      },
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── DELETE ACCOUNT ────────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: _deleteAccount,
                      child: const Text(
                        'DELETE ACCOUNT',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }
}
