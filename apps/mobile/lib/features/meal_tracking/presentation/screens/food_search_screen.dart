import 'package:flutter/material.dart';

import '../../data/food_preferences_storage.dart';
import '../../data/food_repository_factory.dart';
import '../../data/persistent_custom_food_repository.dart';
import '../../domain/entities/catalog_food.dart';
import '../../domain/entities/product_barcode.dart';
import '../../domain/repositories/custom_food_repository.dart';
import '../../domain/repositories/food_preferences_repository.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/services/food_discovery_service.dart';
import 'barcode_scanner_screen.dart';
import 'custom_food_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({
    super.key,
    this.repository,
    this.preferencesRepository,
    this.customFoodRepository,
  });

  final FoodRepository? repository;
  final FoodPreferencesRepository? preferencesRepository;
  final CustomFoodRepository? customFoodRepository;

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchController = TextEditingController();

  late final FoodRepository _repository;
  late final FoodPreferencesRepository _preferencesRepository;

  CustomFoodRepository get _customFoodRepository {
    return widget.customFoodRepository ??
        PersistentCustomFoodRepository.instance;
  }

  late final FoodDiscoveryService _discoveryService;

  List<CatalogFood> _results = [];
  List<CatalogFood> _favorites = [];
  List<CatalogFood> _recents = [];
  Set<String> _favoriteIdentityKeys = <String>{};
  final Set<String> _favoriteUpdates = <String>{};

  ProductBarcode? _lastScannedBarcode;

  bool _isLoading = true;
  String? _errorMessage;
  int _searchRevision = 0;

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? createFoodRepository();

    _preferencesRepository =
        widget.preferencesRepository ?? FoodPreferencesStorage.instance;

    _discoveryService = FoodDiscoveryService(
      foodRepository: _repository,
      preferencesRepository: _preferencesRepository,
    );

    _searchFoods('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFoods(String query) async {
    final revision = ++_searchRevision;
    final isOverview = query.trim().isEmpty;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _repository.searchFoods(query);

      FoodDiscoveryOverview? overview;
      Set<String>? favoriteIdentityKeys;

      if (isOverview) {
        overview = await _discoveryService.loadOverview();
      } else {
        favoriteIdentityKeys = await _preferencesRepository
            .loadFavoriteIdentityKeys();
      }

      if (!mounted || revision != _searchRevision) {
        return;
      }

      setState(() {
        _results = results;

        if (overview != null) {
          _favorites = overview.favorites;
          _recents = overview.recents;
          _favoriteIdentityKeys = overview.favoriteIdentityKeys;
        } else if (favoriteIdentityKeys != null) {
          _favoriteIdentityKeys = favoriteIdentityKeys;
        }

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || revision != _searchRevision) {
        return;
      }

      setState(() {
        _results = [];
        _isLoading = false;
        _errorMessage = 'Prana could not search foods right now.';
      });
    }
  }

  Future<void> _refreshOverview() async {
    if (_searchController.text.trim().isNotEmpty) {
      return;
    }

    try {
      final overview = await _discoveryService.loadOverview();

      if (!mounted) {
        return;
      }

      setState(() {
        _favorites = overview.favorites;
        _recents = overview.recents;
        _favoriteIdentityKeys = overview.favoriteIdentityKeys;
      });
    } catch (_) {
      // Search results remain usable even if preference refresh fails.
    }
  }

  void _selectFood(CatalogFood food) {
    Navigator.of(context).pop(food);
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<ProductBarcode>(
      MaterialPageRoute(
        builder: (context) {
          return const BarcodeScannerScreen();
        },
      ),
    );

    if (!mounted || barcode == null) {
      return;
    }

    setState(() {
      _lastScannedBarcode = barcode;
    });
  }

  Future<void> _createCustomFood() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return CustomFoodScreen(repository: _customFoodRepository);
        },
      ),
    );

    if (!mounted || changed != true) {
      return;
    }

    await _searchFoods(_searchController.text);
  }

  Future<void> _editCustomFood(CatalogFood food) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return CustomFoodScreen(
            food: food,
            repository: _customFoodRepository,
          );
        },
      ),
    );

    if (!mounted || changed != true) {
      return;
    }

    await _searchFoods(_searchController.text);
  }

  Future<void> _toggleFavorite(CatalogFood food) async {
    final identityKey = food.identityKey;

    if (_favoriteUpdates.contains(identityKey)) {
      return;
    }

    final wasFavorite = _favoriteIdentityKeys.contains(identityKey);
    final shouldBeFavorite = !wasFavorite;

    setState(() {
      _favoriteUpdates.add(identityKey);

      if (shouldBeFavorite) {
        _favoriteIdentityKeys = {..._favoriteIdentityKeys, identityKey};
      } else {
        _favoriteIdentityKeys = {
          ..._favoriteIdentityKeys.where((value) => value != identityKey),
        };
      }
    });

    try {
      await _preferencesRepository.setFavorite(
        identityKey,
        isFavorite: shouldBeFavorite,
      );

      await _refreshOverview();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (wasFavorite) {
          _favoriteIdentityKeys = {..._favoriteIdentityKeys, identityKey};
        } else {
          _favoriteIdentityKeys = {
            ..._favoriteIdentityKeys.where((value) => value != identityKey),
          };
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prana could not update this favorite right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoriteUpdates.remove(identityKey);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastScannedBarcode = _lastScannedBarcode;

    return Scaffold(
      appBar: AppBar(title: const Text('Search food')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search foods',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _searchFoods('');
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
                onChanged: (value) {
                  setState(() {});
                  _searchFoods(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select a food to automatically fill its '
                    'nutrition information.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan barcode'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _createCustomFood,
                        icon: const Icon(Icons.add),
                        label: const Text('Custom'),
                      ),
                    ],
                  ),
                  if (lastScannedBarcode != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${lastScannedBarcode.formatLabel} '
                                '${lastScannedBarcode.value} scanned. '
                                'Product lookup is coming in the next phase.',
                                key: const ValueKey(
                                  'last-scanned-barcode-message',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _SearchError(
        message: _errorMessage!,
        onRetry: () => _searchFoods(_searchController.text),
      );
    }

    if (_searchController.text.trim().isNotEmpty) {
      if (_results.isEmpty) {
        return const _NoResults();
      }

      return _buildSearchResults();
    }

    return _buildOverview();
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final food = _results[index];

        return _buildFoodCard(food);
      },
    );
  }

  Widget _buildOverview() {
    final featuredIdentityKeys = <String>{
      ..._favorites.map((food) => food.identityKey),
      ..._recents.map((food) => food.identityKey),
    };

    final allFoods = _results
        .where((food) => !featuredIdentityKeys.contains(food.identityKey))
        .toList(growable: false);

    if (_favorites.isEmpty && _recents.isEmpty && allFoods.isEmpty) {
      return const _NoResults();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        if (_favorites.isNotEmpty) ...[
          const _SectionHeader(icon: Icons.star_outline, title: 'Favorites'),
          ..._sectionCards(_favorites),
          const SizedBox(height: 20),
        ],
        if (_recents.isNotEmpty) ...[
          const _SectionHeader(icon: Icons.history, title: 'Recently used'),
          ..._sectionCards(_recents),
          const SizedBox(height: 20),
        ],
        if (allFoods.isNotEmpty) ...[
          const _SectionHeader(
            icon: Icons.restaurant_menu_outlined,
            title: 'All foods',
          ),
          ..._sectionCards(allFoods),
        ],
      ],
    );
  }

  List<Widget> _sectionCards(List<CatalogFood> foods) {
    final widgets = <Widget>[];

    for (var index = 0; index < foods.length; index++) {
      if (index > 0) {
        widgets.add(const SizedBox(height: 8));
      }

      widgets.add(_buildFoodCard(foods[index]));
    }

    return widgets;
  }

  Widget _buildFoodCard(CatalogFood food) {
    return _FoodResultCard(
      food: food,
      isFavorite: _favoriteIdentityKeys.contains(food.identityKey),
      isUpdatingFavorite: _favoriteUpdates.contains(food.identityKey),
      onTap: () => _selectFood(food),
      onFavoriteToggle: () => _toggleFavorite(food),
      onEdit: food.source == CatalogFoodSource.custom
          ? () => _editCustomFood(food)
          : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _FoodResultCard extends StatelessWidget {
  const _FoodResultCard({
    required this.food,
    required this.isFavorite,
    required this.isUpdatingFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onEdit,
  });

  final CatalogFood food;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final detail = _foodDetail(food);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.restaurant_outlined)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      food.servingDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatNumber(food.proteinGrams)} g protein'
                      ' • '
                      '${_formatNumber(food.carbohydrateGrams)} g carbs'
                      ' • '
                      '${_formatNumber(food.fatGrams)} g fat',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          tooltip: 'Edit ${food.name}',
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      IconButton(
                        tooltip: isFavorite
                            ? 'Remove ${food.name} from favorites'
                            : 'Add ${food.name} to favorites',
                        onPressed: isUpdatingFavorite ? null : onFavoriteToggle,
                        icon: isUpdatingFavorite
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(isFavorite ? Icons.star : Icons.star_border),
                      ),
                    ],
                  ),
                  Text(
                    '${_formatNumber(food.calories)} kcal',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _foodDetail(CatalogFood food) {
    final brand = food.brand?.trim();

    if (brand != null && brand.isNotEmpty) {
      return brand;
    }

    return switch (food.source) {
      CatalogFoodSource.localCatalog => null,
      CatalogFoodSource.custom => 'Custom food',
      CatalogFoodSource.externalCatalog => 'External catalog',
      CatalogFoodSource.aiSuggestion => 'AI suggestion',
    };
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No foods found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try another search or create a custom food.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
