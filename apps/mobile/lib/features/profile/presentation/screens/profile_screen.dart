import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/profile_storage.dart';
import '../../domain/entities/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileStorage.instance.loadProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  Future<void> _editProfile() async {
    final profile = _profile;

    if (profile == null) {
      return;
    }

    final changed = await context.push<bool>('/profile/edit', extra: profile);

    if (!mounted) {
      return;
    }

    if (changed == true) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (profile != null)
            IconButton(
              tooltip: 'Edit profile',
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : profile == null
            ? const Center(child: Text('Profile information is unavailable.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  _ProfileHeader(profile: profile),

                  const SizedBox(height: 24),

                  Text(
                    'Personal information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _ProfileSection(
                    children: [
                      _ProfileRow(
                        icon: Icons.cake_outlined,
                        label: 'Age',
                        value: '${profile.age} years',
                      ),
                      _ProfileRow(
                        icon: Icons.person_outline,
                        label: 'Calculation basis',
                        value: _formatBiologicalSex(profile.biologicalSex),
                      ),
                      _ProfileRow(
                        icon: Icons.height,
                        label: 'Height',
                        value: '${_formatNumber(profile.heightCm)} cm',
                      ),
                      _ProfileRow(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Starting weight',
                        value: '${_formatNumber(profile.weightKg)} kg',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Goals',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _ProfileSection(
                    children: [
                      _ProfileRow(
                        icon: Icons.flag_outlined,
                        label: 'Health goal',
                        value: _formatGoal(profile.goal),
                      ),
                      _ProfileRow(
                        icon: Icons.track_changes_outlined,
                        label: 'Goal weight',
                        value: '${_formatNumber(profile.goalWeightKg)} kg',
                      ),
                      _ProfileRow(
                        icon: Icons.directions_run_outlined,
                        label: 'Activity level',
                        value: _formatActivityLevel(profile.activityLevel),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Changing your profile or goals may '
                              'update your estimated calorie, macro, '
                              'and hydration targets.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile & goals'),
                  ),
                ],
              ),
      ),
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  static String _formatBiologicalSex(BiologicalSex value) {
    return switch (value) {
      BiologicalSex.male => 'Male',
      BiologicalSex.female => 'Female',
      BiologicalSex.unspecified => 'Not specified',
    };
  }

  static String _formatGoal(HealthGoal value) {
    return switch (value) {
      HealthGoal.loseWeight => 'Weight loss',
      HealthGoal.maintainWeight => 'Maintain weight',
      HealthGoal.gainMuscle => 'Gain muscle',
      HealthGoal.improveHealth => 'Improve health',
    };
  }

  static String _formatActivityLevel(ActivityLevel value) {
    return switch (value) {
      ActivityLevel.sedentary => 'Sedentary',
      ActivityLevel.lightlyActive => 'Lightly active',
      ActivityLevel.moderatelyActive => 'Moderately active',
      ActivityLevel.veryActive => 'Very active',
      ActivityLevel.athlete => 'Athlete',
    };
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.firstName.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstName.isEmpty ? 'Prana user' : firstName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your health profile',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
