import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/food_repository_factory.dart';
import '../../domain/entities/catalog_food.dart';
import '../../domain/repositories/food_repository.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key, this.repository});

  final FoodRepository? repository;

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _searchController = TextEditingController();

  late final FoodRepository _repository;

  List<CatalogFood> _results = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _searchRevision = 0;

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? createFoodRepository();
    _searchFoods('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFoods(String query) async {
    final revision = ++_searchRevision;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _repository.searchFoods(query);

      if (!mounted || revision != _searchRevision) {
        return;
      }

      setState(() {
        _results = results;
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

  void _selectFood(CatalogFood food) {
    context.pop(food);
  }

  @override
  Widget build(BuildContext context) {
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select a food to automatically fill its '
                  'nutrition information.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _SearchError(
        message: _errorMessage!,
        onRetry: () => _searchFoods(_searchController.text),
      );
    }

    if (_results.isEmpty) {
      return const _NoResults();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        final food = _results[index];

        return _FoodResultCard(food: food, onTap: () => _selectFood(food));
      },
    );
  }
}

class _FoodResultCard extends StatelessWidget {
  const _FoodResultCard({required this.food, required this.onTap});

  final CatalogFood food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = _foodDetail(food);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      ' \u2022 '
                      '${_formatNumber(food.carbohydrateGrams)} g carbs'
                      ' \u2022 '
                      '${_formatNumber(food.fatGrams)} g fat',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatNumber(food.calories)} kcal',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
              'Try another search or enter the food manually.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
