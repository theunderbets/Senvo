import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../features/vitals_history/domain/repositories/vitals_repository.dart';
import '../../core/theme/senvo_theme.dart';
import 'widgets/privacy_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../features/vitals_history/presentation/bloc/history_bloc.dart';
import '../../features/vitals_history/presentation/bloc/history_event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bloc/app_settings_cubit.dart';
import 'bloc/app_settings_state.dart';

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
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profileSettings),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.symmetric(vertical: SenvoSpacing.md),
        children: [
          // Theme & Language Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.sm),
            child: Text(loc.theme, style: Theme.of(context).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg),
            child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
              builder: (context, state) {
                return SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(value: ThemeMode.light, label: Text(loc.light), icon: const Icon(Icons.light_mode)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(loc.dark), icon: const Icon(Icons.dark_mode)),
                    ButtonSegment(value: ThemeMode.system, label: Text(loc.system), icon: const Icon(Icons.settings_system_daydream)),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    context.read<AppSettingsCubit>().updateThemeMode(newSelection.first);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: SenvoSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.sm),
            child: Text(loc.language, style: Theme.of(context).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg),
            child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
              builder: (context, state) {
                return DropdownButtonFormField<String>(
                  value: state.locale.languageCode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SenvoRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.md),
                  ),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(loc.english)),
                    DropdownMenuItem(value: 'hi', child: Text(loc.hindi)),
                    DropdownMenuItem(value: 'or', child: Text(loc.odia)),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      context.read<AppSettingsCubit>().updateLocale(Locale(newValue));
                    }
                  },
                );
              },
            ),
          ),
          
          const Divider(height: SenvoSpacing.xxl),

          // Basic Profile Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: context.themeColors.accent.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, size: 32, color: context.themeColors.accent),
                ),
                const SizedBox(width: SenvoSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: InputDecoration(
                          hintText: loc.enterName,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => _saveProfile(),
                      ),
                      Text(loc.senvoHealthProfile, style: Theme.of(context).textTheme.bodyMedium),
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
              title: Text(loc.dateOfBirth),
              subtitle: Text(_dob != null ? _dateFormat.format(_dob!) : loc.notSet),
              trailing: const Icon(Icons.calendar_today, color: context.themeColors.accent),
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
                Text(loc.aboutSenvo, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: SenvoSpacing.md),
                Text(loc.version, style: TextStyle(color: context.themeColors.text)),
                const SizedBox(height: SenvoSpacing.sm),
                Text(
                  loc.senvoDescription,
                  style: TextStyle(color: context.themeColors.muted),
                ),
                const SizedBox(height: SenvoSpacing.xxl),
                Text(
                  loc.madeByTeam,
                  style: TextStyle(color: context.themeColors.muted, fontStyle: FontStyle.italic, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SenvoSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${loc.developer}: The_Underbets ',
                      style: TextStyle(color: context.themeColors.muted, fontSize: 12),
                    ),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse('https://github.com/theunderbets/Senvo');
                        if (!await launchUrl(url)) {
                          debugPrint('Could not launch $url');
                        }
                      },
                      child: const Icon(
                        Icons.link,
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
