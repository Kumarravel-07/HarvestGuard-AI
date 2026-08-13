import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A large, UI-only account creation form for HarvestGuard AI.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _green = Color(0xFF1B5E20);

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = MediaQuery.sizeOf(context).width > 560
        ? 480.0
        : double.infinity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _green,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back to sign in',
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.agriculture, color: _green, size: 76),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _green,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join HarvestGuard AI',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 20),
                    decoration: _fieldDecoration(
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 20),
                    decoration: _fieldDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 20),
                    decoration: _fieldDecoration(
                      label: 'Mobile Number',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 20),
                    decoration: _passwordDecoration(
                      label: 'Password',
                      hidden: _hidePassword,
                      onToggle: () => setState(
                        () => _hidePassword = !_hidePassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _hideConfirmPassword,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 20),
                    decoration: _passwordDecoration(
                      label: 'Confirm Password',
                      hidden: _hideConfirmPassword,
                      onToggle: () => setState(
                        () => _hideConfirmPassword = !_hideConfirmPassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('SIGN UP'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _green,
                      minimumSize: const Size.fromHeight(55),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        children: [
                          TextSpan(
                            text: 'SIGN IN',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 18),
      prefixIcon: Icon(icon, color: _green, size: 30),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _green, width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _green, width: 3),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return _fieldDecoration(label: label, icon: Icons.lock_outline).copyWith(
      suffixIcon: IconButton(
        tooltip: hidden ? 'Show password' : 'Hide password',
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 28,
        ),
        onPressed: onToggle,
      ),
    );
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Please enter a valid email address.');
      return;
    }
    if (mobile.length < 10) {
      _showMessage('Please enter a valid mobile number.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw StateError('The created user could not be identified.');
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': name,
        'email': email,
        'mobileNumber': mobile,
        'language': 'English',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _showMessage('Account created successfully. Please sign in.');
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } catch (_) {
      if (mounted) _showMessage('Unable to create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      default:
        return error.message ?? 'Unable to create your account. Please try again.';
    }
  }
}
