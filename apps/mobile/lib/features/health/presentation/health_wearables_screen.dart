import 'package:flutter/material.dart';

import '../../weight_tracking/data/weight_storage.dart';
import '../data/repositories/health_connect_data_repository.dart';
import '../domain/entities/health_data_type.dart';
import '../domain/repositories/health_data_repository.dart';
import '../domain/services/health_weight_sync_service.dart';

typedef HealthWeightSyncAction = Future<HealthWeightSyncResult> Function();

class HealthWearablesScreen extends StatefulWidget {
  const HealthWearablesScreen({
    super.key,
    this.repository,
    this.weightSyncAction,
  });

  final HealthDataRepository? repository;

  final HealthWeightSyncAction? weightSyncAction;

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
  late final HealthWeightSyncAction? _weightSyncAction;

  HealthAvailability? _availability;
  HealthAccessStatus _accessStatus = HealthAccessStatus.unknown;

  bool _loading = true;
  bool _acting = false;
  bool _syncingWeight = false;

  String? _errorMessage;
  String? _weightSyncMessage;
  bool _weightSyncMessageIsError = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _repository = widget.repository ?? HealthConnectDataRepository();

    _weightSyncAction =
        widget.weightSyncAction ?? _createDefaultWeightSyncAction(_repository);

    Future<void>.microtask(_refresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  HealthWeightSyncAction? _createDefaultWeightSyncAction(
    HealthDataRepository repository,
  ) {
    if (repository is! HealthWeightDataRepository) {
      return null;
    }

    final syncService = HealthWeightSyncService(
      repository,
      WeightStorage.instance,
    );

    return () => syncService.sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_loading &&
        !_acting &&
        !_syncingWeight) {
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
    if (_acting || _syncingWeight) {
      return;
    }

    setState(() {
      _acting = true;
      _errorMessage = null;
      _weightSyncMessage = null;
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
    if (_acting || _syncingWeight) {
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

  Future<void> _syncWeight() async {
    final syncAction = _weightSyncAction;

    if (syncAction == null || _syncingWeight || _acting) {
      return;
    }

    setState(() {
      _syncingWeight = true;
      _errorMessage = null;
      _weightSyncMessage = null;
      _weightSyncMessageIsError = false;
    });

    try {
      final result = await syncAction();

      if (!mounted) {
        return;
      }

      setState(() {
        switch (result.status) {
          case HealthWeightSyncStatus.synced:
            _weightSyncMessage = _formatSuccessfulSync(result);
            _weightSyncMessageIsError = false;

          case HealthWeightSyncStatus.unavailable:
            _weightSyncMessage =
                'Health Connect is not available, so '
                'weight could not be synced.';
            _weightSyncMessageIsError = true;

          case HealthWeightSyncStatus.accessNeeded:
            _weightSyncMessage =
                'Body-weight access is needed before '
                'Prana can sync measurements.';
            _weightSyncMessageIsError = true;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _weightSyncMessage = 'Prana could not sync weight right now.';
        _weightSyncMessageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _syncingWeight = false;
        });
      }
    }
  }

  String _formatSuccessfulSync(HealthWeightSyncResult result) {
    if (result.importedCount == 0 && result.updatedCount == 0) {
      if (result.fetchedCount == 0) {
        return 'No Health Connect weight measurements '
            'were found in the last 30 days.';
      }

      return 'Weight history is already up to date.';
    }

    final parts = <String>[];

    if (result.importedCount > 0) {
      parts.add(
        'Imported ${result.importedCount} new '
        '${_measurementLabel(result.importedCount)}',
      );
    }

    if (result.updatedCount > 0) {
      parts.add(
        'updated ${result.updatedCount} existing '
        '${_measurementLabel(result.updatedCount)}',
      );
    }

    return '${parts.join(' and ')}.';
  }

  String _measurementLabel(int count) {
    return count == 1 ? 'weight measurement' : 'weight measurements';
  }

  bool get _isAvailable => _availability?.isAvailable == true;

  bool get _canAttemptWeightSync =>
      _isAvailable &&
      (_accessStatus == HealthAccessStatus.granted ||
          _accessStatus == HealthAccessStatus.partiallyGranted);

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
        'Prana can read the health information '
            'you approved.',
      HealthAccessStatus.partiallyGranted =>
        'Some requested health information is '
            'available. You can review access to '
            'enable the rest.',
      HealthAccessStatus.denied =>
        'Connect Prana to import approved health '
            'and activity information.',
      HealthAccessStatus.notRequested =>
        'Connect your health data when you are ready.',
      HealthAccessStatus.unavailable =>
        'Health Connect is not currently available '
            'on this device.',
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

            if (_weightSyncAction != null && _isAvailable) ...[
              const SizedBox(height: 16),
              _buildWeightSyncCard(context),
            ],

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
                  onPressed: _loading || _acting || _syncingWeight
                      ? null
                      : _refresh,
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
                    onPressed: _acting || _syncingWeight
                        ? null
                        : _requestAccess,
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
                    onPressed: _acting || _syncingWeight ? null : _openSettings,
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

  Widget _buildWeightSyncCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Weight sync',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Last 30 days',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              'Import approved body-weight '
              'measurements from Health Connect into '
              'your existing Prana weight history.',
            ),

            const SizedBox(height: 8),

            Text(
              'Re-syncing updates existing Health '
              'Connect measurements instead of '
              'creating duplicates.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _canAttemptWeightSync && !_syncingWeight && !_acting
                    ? _syncWeight
                    : null,
                icon: _syncingWeight
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  _syncingWeight ? 'Syncing weight...' : 'Sync weight now',
                ),
              ),
            ),

            if (!_canAttemptWeightSync) ...[
              const SizedBox(height: 10),
              Text(
                'Grant health access before syncing '
                'body-weight measurements.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (_weightSyncMessage != null) ...[
              const SizedBox(height: 14),
              _WeightSyncMessage(
                message: _weightSyncMessage!,
                isError: _weightSyncMessageIsError,
              ),
            ],

            const SizedBox(height: 12),

            Text(
              'After syncing, open Progress and pull '
              'down to refresh if it is already open.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
              'You stay in control. Prana only '
              'requests the health information needed '
              'for the features below.',
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
              description:
                  'Understand daily movement and '
                  'activity.',
            ),

            const _HealthDataRow(
              icon: Icons.local_fire_department_outlined,
              title: 'Active energy',
              description:
                  'Add activity context without '
                  'treating device estimates as exact.',
            ),

            const _HealthDataRow(
              icon: Icons.fitness_center_outlined,
              title: 'Workouts',
              description:
                  'Recognize exercise sessions '
                  'recorded by connected health apps '
                  'and devices.',
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
                    'health information only. It does '
                    'not write changes back to Health '
                    'Connect.',
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Activity calories are kept '
                    'separate from your nutrition '
                    'target and are not automatically '
                    'added back to your food budget.',
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

class _WeightSyncMessage extends StatelessWidget {
  const _WeightSyncMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
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
