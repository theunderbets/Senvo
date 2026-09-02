import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../features/vitals_history/domain/repositories/vitals_repository.dart';
import '../../core/theme/senvo_theme.dart';
import 'widgets/privacy_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/vitals_history/presentation/bloc/history_bloc.dart';
import '../../features/vitals_history/presentation/bloc/history_event.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  final VitalsRepository vitalsRepository;

  const ProfilePage({
    super.key,
    required this.vitalsRepository,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _dob;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? 'User';
      final dobStr = prefs.getString('user_dob');
      if (dobStr != null) {
        try {
          _dob = _dateFormat.parse(dobStr);
        } catch (_) {}
      }
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    if (_dob != null) {
      await prefs.setString('user_dob', _dateFormat.format(_dob!));
    }
  }

  Future<void> _selectDOB(BuildContext context) async {
    final initialDate = _dob ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
      _saveProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.symmetric(vertical: SenvoSpacing.md),
        children: [
          // Basic Profile Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: SenvoColors.accent.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, size: 32, color: SenvoColors.accent),
                ),
                const SizedBox(width: SenvoSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: const InputDecoration(
                          hintText: 'Enter Name',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => _saveProfile(),
                      ),
                      Text('Senvo Health Profile', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.sm),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date of Birth'),
              subtitle: Text(_dob != null ? _dateFormat.format(_dob!) : 'Not set'),
              trailing: const Icon(Icons.calendar_today, color: SenvoColors.accent),
              onTap: () => _selectDOB(context),
            ),
          ),
          
          const Divider(height: SenvoSpacing.xxl),
          
          PrivacyCard(
            onClearData: () async {
              await widget.vitalsRepository.wipeAllLocalData();
              if (context.mounted) {
                context.read<HistoryBloc>().add(const ClearHistory());
              }
            },
          ),
          
          const SizedBox(height: SenvoSpacing.xl),
          
          // About Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About Senvo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: SenvoSpacing.md),
                const Text('Version 1.0.0', style: TextStyle(color: SenvoColors.text)),
                const SizedBox(height: SenvoSpacing.sm),
                const Text(
                  'Senvo is your personal health and environmental risk intelligence dashboard.',
                  style: TextStyle(color: SenvoColors.muted),
                ),
                const SizedBox(height: SenvoSpacing.xxl),
                const Text(
                  'Made by Team Underbets\nUnder the guidance of CV Raman Global University',
                  style: TextStyle(color: SenvoColors.muted, fontStyle: FontStyle.italic, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SenvoSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Developer: Abhishek ',
                      style: TextStyle(color: SenvoColors.muted, fontSize: 12),
                    ),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse('https://www.linkedin.com/in/abhishek/');
                        if (!await launchUrl(url)) {
                          debugPrint('Could not launch \$url');
                        }
                      },
                      child: const Icon(
                        Icons.link, // Placeholder for LinkedIn icon
                        size: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SenvoSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
