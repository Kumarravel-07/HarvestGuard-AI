import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import '../services/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _green = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: _green,
          elevation: 0,
          title: Text(
            tr(context, 'profile'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Text(
            tr(context, 'pleaseSignInToViewProfile'),
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final profileRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final predictionsRef = profileRef.collection('predictions');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _green,
        elevation: 0,
        title: Text(
          tr(context, 'profile'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: profileRef.snapshots(),
                builder: (context, snapshot) {
                  final data =
                      snapshot.data?.data() ?? const <String, dynamic>{};
                  final storedName = data['fullName'] as String?;
                  final name = storedName?.trim().isNotEmpty == true
                      ? storedName!.trim()
                      : (user.displayName?.trim().isNotEmpty == true
                            ? user.displayName!.trim()
                            : tr(context, 'profileNameUnavailable'));
                  final email =
                      user.email ??
                      (data['email'] as String?) ??
                      tr(context, 'emailUnavailable');
                  final mobileNumber = data['mobileNumber'] as String?;
                  final language = data['language'] as String?;

                  return Column(
                    children: [
                      _ProfileHeader(
                        name: name,
                        email: email,
                        createdAt: user.metadata.creationTime,
                      ),
                      const SizedBox(height: 24),
                      _ProfileStatCard(
                        name: name,
                        email: email,
                        mobileNumber: mobileNumber,
                        language: language,
                        createdAt: user.metadata.creationTime,
                      ),
                      const SizedBox(height: 24),
                      _ProfileActionButton(
                        icon: Icons.edit_rounded,
                        title: tr(context, 'editProfile'),
                        subtitle: tr(context, 'updateProfileSubtitle'),
                        onTap: () => _showEditProfile(
                          context,
                          profileRef: profileRef,
                          name: storedName ?? user.displayName ?? '',
                          mobileNumber: mobileNumber,
                          language: language,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: predictionsRef.snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _InfoTile(
                    title: tr(context, 'totalPredictions'),
                    value: '$count',
                    icon: Icons.history_rounded,
                  );
                },
              ),
              const SizedBox(height: 12),
              _ProfileActionButton(
                icon: Icons.info_outline,
                title: tr(context, 'about'),
                subtitle: tr(context, 'learnHowAppHelps'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _AboutHarvestGuardScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ProfileActionButton(
                icon: Icons.privacy_tip_outlined,
                title: tr(context, 'privacy'),
                subtitle: tr(context, 'readPrivacyPractice'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _PrivacyPolicyScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ProfileActionButton(
                icon: Icons.help_outline,
                title: tr(context, 'help'),
                subtitle: tr(context, 'getAppHelp'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _HelpSupportScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, size: 24),
                  label: Text(
                    tr(context, 'logout'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfile(
    BuildContext context, {
    required DocumentReference<Map<String, dynamic>> profileRef,
    required String name,
    required String? mobileNumber,
    required String? language,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditProfileDialog(
        profileRef: profileRef,
        name: name,
        mobileNumber: mobileNumber,
        language: language,
      ),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _AboutHarvestGuardScreen extends StatelessWidget {
  const _AboutHarvestGuardScreen();

  @override
  Widget build(BuildContext context) {
    return _ProfileInfoPage(
      title: tr(context, 'about'),
      icon: Icons.eco_outlined,
      children: [
        const _InfoPageHeading('HarvestGuard AI'),
        _InfoPageText(
          'AI-powered post-harvest tomato loss prediction and management system.',
        ),
        _InfoPageHeading('How it helps'),
        _InfoPageText(
          'HarvestGuard AI helps farmers assess tomato condition, predict post-harvest spoilage risk, estimate shelf life, and receive storage and transport recommendations.',
        ),
        _InfoPageText(
          'Our goal is to help farmers reduce tomato wastage and improve post-harvest handling.',
        ),
      ],
    );
  }
}

class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  @override
  Widget build(BuildContext context) {
    return _ProfileInfoPage(
      title: tr(context, 'privacy'),
      icon: Icons.privacy_tip_outlined,
      children: [
        _InfoPageSection(
          title: 'Information We Collect',
          text:
              'The app uses the account details you provide, selected tomato images, and location or weather information when you use those features.',
        ),
        _InfoPageSection(
          title: 'How We Use Information',
          text:
              'Information is used to provide tomato batch analysis, weather details, prediction history, and account features.',
        ),
        _InfoPageSection(
          title: 'Prediction Data',
          text:
              'Completed prediction results are saved in your account history so you can review them later.',
        ),
        _InfoPageSection(
          title: 'Account Information',
          text:
              'Your name, email, mobile number, and language are used to display and manage your profile.',
        ),
        _InfoPageSection(
          title: 'Data Security',
          text:
              'We use the app services needed to provide your account and prediction history. This student project does not claim advanced security features beyond those services.',
        ),
        _InfoPageSection(
          title: 'Data Sharing',
          text:
              'HarvestGuard AI does not send your prediction results to other farmers or use them for notification delivery.',
        ),
        _InfoPageSection(
          title: 'User Control',
          text:
              'You can edit your profile information, review your prediction history, and clear saved history from the app.',
        ),
      ],
    );
  }
}

class _HelpSupportScreen extends StatelessWidget {
  const _HelpSupportScreen();

  @override
  Widget build(BuildContext context) {
    return _ProfileInfoPage(
      title: tr(context, 'help'),
      icon: Icons.help_outline,
      children: [
        const _InfoPageSection(
          title: 'How to make a prediction',
          text:
              'Open Predict, add one overall batch photo and at least two close-up tomato photos, then tap Predict Shelf Life.',
        ),
        const _InfoPageSection(
          title: 'View prediction history',
          text:
              'Open the History tab to review your completed batch predictions and their details.',
        ),
        const _InfoPageSection(
          title: 'Edit profile information',
          text:
              'Open Profile and tap Edit Profile to update your name, mobile number, or language.',
        ),
        const _InfoPageSection(
          title: 'If image prediction does not work',
          text:
              'Check that the photos are clear, show tomatoes properly, and include the required overall and close-up images. Then try again.',
        ),
        const _InfoPageSection(
          title: 'If weather or location is unavailable',
          text:
              'Check your internet connection and location permission. You can also enter a location manually on the Prediction page.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'For support, please contact the HarvestGuard AI project team.',
              ),
            ),
          ),
          icon: const Icon(Icons.contact_support_outlined),
          label: Text(tr(context, 'contactSupport')),
        ),
      ],
    );
  }
}

class _ProfileInfoPage extends StatelessWidget {
  const _ProfileInfoPage({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, color: const Color(0xFF1B5E20), size: 48),
                  const SizedBox(height: 18),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPageHeading extends StatelessWidget {
  const _InfoPageHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        trContent(context, text),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoPageText extends StatelessWidget {
  const _InfoPageText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        trContent(context, text),
        style: const TextStyle(fontSize: 17, height: 1.4),
      ),
    );
  }
}

class _InfoPageSection extends StatelessWidget {
  const _InfoPageSection({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trContent(context, title),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            trContent(context, text),
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.profileRef,
    required this.name,
    required this.mobileNumber,
    required this.language,
  });

  final DocumentReference<Map<String, dynamic>> profileRef;
  final String name;
  final String? mobileNumber;
  final String? language;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late String _selectedLanguage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _mobileController = TextEditingController(text: widget.mobileNumber ?? '');
    _selectedLanguage = widget.language == 'Tamil' ? 'Tamil' : 'English';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.profileRef.set({
        'fullName': name,
        'mobileNumber': _mobileController.text.trim(),
        'language': _selectedLanguage,
      }, SetOptions(merge: true));
      await AppLocalizations.controllerOf(
        context,
      ).setLanguage(_selectedLanguage);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update profile. Please try again.'),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(labelText: tr(context, 'language')),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Tamil', child: Text('தமிழ்')),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _selectedLanguage = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String name;
  final String email;
  final DateTime? createdAt;

  static const _green = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: _green.withOpacity(0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'F',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _green,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        createdAt != null
                            ? _formatDate(createdAt!.toLocal())
                            : 'Account date not available',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day/$month/$year';
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.language,
    this.createdAt,
  });

  final String name;
  final String email;
  final String? mobileNumber;
  final String? language;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoTile(title: 'Name', value: name, icon: Icons.person),
            const SizedBox(height: 12),
            _InfoTile(title: 'Email', value: email, icon: Icons.email_outlined),
            const SizedBox(height: 12),
            _InfoTile(
              title: 'Mobile Number',
              value: mobileNumber?.isNotEmpty == true
                  ? mobileNumber!
                  : 'Not available',
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              title: 'Language',
              value: language?.isNotEmpty == true ? language! : 'Not available',
              icon: Icons.language,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              title: 'Account Created',
              value: createdAt != null
                  ? _formatDate(createdAt!)
                  : 'Not available',
              icon: Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day/$month/$year';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1B5E20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        leading: Icon(icon, color: const Color(0xFF1B5E20), size: 28),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
