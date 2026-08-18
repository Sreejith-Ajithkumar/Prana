import 'package:flutter/material.dart';

import '../data/repositories/health_connect_data_repository.dart';
import '../domain/entities/health_data_type.dart';
import '../domain/repositories/health_data_repository.dart';

class HealthWearablesScreen extends StatefulWidget {
  const HealthWearablesScreen({super.key, this.repository});

  final HealthDataRepository? repository;

  @override
  State<HealthWearablesScreen> createState() => _HealthWearablesScreenState();
}

class _HealthWearablesScreenState extends State<HealthWearablesScreen>
    with WidgetsBindingObserver {
  static const Set<HealthDataType> _requestedTypes = {
    HealthDataType.bodyWeight,
    HealthDataType.steps,
    HealthDataType.activeEnergyBurned,
    HealthDataType.workout,
  };

  late final HealthDataRepository _repository;

  HealthAvailability? _availability;
  HealthAccessStatus _accessStatus = HealthAccessStatus.unknown;

  bool _loading = true;
  bool _acting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _repository = widget.repository ?? HealthConnectDataRepository();

    Future<void>.microtask(_refresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && !_acting) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final availability = await _repository.checkAvailability();

      HealthAccessStatus accessStatus;

      if (!availability.isAvailable) {
        accessStatus = HealthAccessStatus.unavailable;
      } else {
        accessStatus = await _repository.getAccessStatus(_requestedTypes);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _availability = availability;
        _accessStatus = accessStatus;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Prana could not check health access right now.';
      });
    }
  }

  Future<void> _requestAccess() async {
    if (_acting) {
      return;
    }

    setState(() {
      _acting = true;
      _errorMessage = null;
    });

    try {
      final status = await _repository.requestAccess(_requestedTypes);

      if (!mounted) {
        return;
      }

      setState(() {
        _accessStatus = status;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Prana could not update health access.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _acting = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    if (_acting) {
      return;
    }

    setState(() {
      _acting = true;
      _errorMessage = null;
    });

    try {
      await _repository.openHealthSettings();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Health Connect settings could not be opened.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _acting = false;
        });
      }
    }
  }

  bool get _isAvailable => _availability?.isAvailable == true;

  String get _platformName {
    return switch (_availability?.platform) {
      HealthPlatform.healthConnect => 'Health Connect',
      HealthPlatform.appleHealth => 'Apple Health',
      HealthPlatform.unsupported || null => 'Health integration',
    };
  }

  String get _statusTitle {
    return switch (_accessStatus) {
      HealthAccessStatus.granted => 'Connected',
      HealthAccessStatus.partiallyGranted => 'Some access granted',
      HealthAccessStatus.denied => 'Access needed',
      HealthAccessStatus.notRequested => 'Not connected',
      HealthAccessStatus.unavailable => 'Unavailable',
      HealthAccessStatus.unknown => 'Checking access',
    };
  }

  String get _statusDescription {
    return switch (_accessStatus) {
      HealthAccessStatus.granted =>
        'Prana can read the health information you approved.',
      HealthAccessStatus.partiallyGranted =>
        'Some requested health information is available. '
            'You can review access to enable the rest.',
      HealthAccessStatus.denied =>
        'Connect Prana to import approved health and '
            'activity information.',
      HealthAccessStatus.notRequested =>
        'Connect your health data when you are ready.',
      HealthAccessStatus.unavailable =>
        'Health Connect is not currently available on '
            'this device.',
      HealthAccessStatus.unknown => 'Prana is checking your health connection.',
    };
  }

  IconData get _statusIcon {
    return switch (_accessStatus) {
      HealthAccessStatus.granted => Icons.check_circle_outline,
      HealthAccessStatus.partiallyGranted => Icons.info_outline,
      HealthAccessStatus.denied => Icons.lock_outline,
      HealthAccessStatus.notRequested => Icons.link_outlined,
      HealthAccessStatus.unavailable => Icons.block_outlined,
      HealthAccessStatus.unknown => Icons.sync_outlined,
    };
  }

  String get _connectButtonLabel {
    return switch (_accessStatus) {
      HealthAccessStatus.granted => 'Review access',
      HealthAccessStatus.partiallyGranted => 'Complete access',
      _ => 'Connect Health Connect',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health & wearables')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildConnectionCard(context),
            const SizedBox(height: 16),
            _buildDataAccessCard(context),
            const SizedBox(height: 16),
            _buildNutritionBehaviorCard(context),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_platformName, style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading || _acting ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_statusIcon, size: 28, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusTitle, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(_statusDescription),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isAvailable) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _acting ? null : _requestAccess,
                    icon: _acting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.health_and_safety_outlined),
                    label: Text(_connectButtonLabel),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _acting ? null : _openSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Manage access'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataAccessCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What Prana can read', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'You stay in control. Prana only requests '
              'the health information needed for the '
              'features below.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            const _HealthDataRow(
              icon: Icons.monitor_weight_outlined,
              title: 'Body weight',
              description:
                  'Use approved measurements in your '
                  'weight history and progress.',
            ),
            const _HealthDataRow(
              icon: Icons.directions_walk_outlined,
              title: 'Steps',
              description: 'Understand daily movement and activity.',
            ),
            const _HealthDataRow(
              icon: Icons.local_fire_department_outlined,
              title: 'Active energy',
              description:
                  'Add activity context without treating '
                  'device estimates as exact.',
            ),
            const _HealthDataRow(
              icon: Icons.fitness_center_outlined,
              title: 'Workouts',
              description:
                  'Recognize exercise sessions recorded '
                  'by connected health apps and devices.',
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionBehaviorCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Read-only and user controlled',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Prana currently reads approved '
                    'health information only. It does not '
                    'write changes back to Health Connect.',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Activity calories are kept separate '
                    'from your nutrition target and are '
                    'not automatically added back to your '
                    'food budget.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthDataRow extends StatelessWidget {
  const _HealthDataRow({
    required this.icon,
    required this.title,
    required this.description,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
