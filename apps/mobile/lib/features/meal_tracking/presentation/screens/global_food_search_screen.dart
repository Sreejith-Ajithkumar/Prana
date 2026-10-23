import 'package:flutter/material.dart';

import '../../data/global_food_search_provider.dart';
import '../../domain/entities/catalog_food.dart';
import 'barcode_food_confirmation_screen.dart';

/// Separate worldwide food search.
/// Local food search remains available offline.
class GlobalFoodSearchScreen extends StatefulWidget {
  const GlobalFoodSearchScreen({super.key, this.provider});

  final GlobalFoodSearchProvider? provider;

  @override
  State<GlobalFoodSearchScreen> createState() => _GlobalFoodSearchScreenState();
}

class _GlobalFoodSearchScreenState extends State<GlobalFoodSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  late final GlobalFoodSearchProvider _provider;
  late final bool _ownsProvider;

  List<CatalogFood> _foods = const [];

  bool _loading = false;
  bool _searched = false;
  String? _error;
  int _revision = 0;

  @override
  void initState() {
    super.initState();

    _ownsProvider = widget.provider == null;
    _provider = widget.provider ?? OpenFoodFactsGlobalSearchProvider();
  }

  @override
  void dispose() {
    _revision++;
    _controller.dispose();

    if (_ownsProvider) {
      _provider.close();
    }

    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.length < 2 || _loading) {
      return;
    }

    final revision = ++_revision;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
      _foods = const [];
    });

    try {
      final results = await _provider.search(query);

      if (!mounted || revision != _revision) {
        return;
      }

      setState(() {
        _foods = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || revision != _revision) {
        return;
      }

      setState(() {
        _loading = false;
        _error = 'Worldwide search is unavailable. Please try again.';
      });
    }
  }

  Future<void> _review(CatalogFood food) async {
    final confirmed = await Navigator.of(context).push<CatalogFood>(
      MaterialPageRoute(
        builder: (context) => BarcodeFoodConfirmationScreen(food: food),
      ),
    );

    if (!mounted || confirmed == null) {
      return;
    }

    Navigator.of(context).pop(confirmed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search worldwide')),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Search controls
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('global-food-query'),
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        labelText: 'Search packaged foods worldwide',
                        hintText: 'e.g. yogurt, kimchi, biryani',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _search(),
                    ),

                    const SizedBox(height: 12),

                    FilledButton.icon(
                      key: const ValueKey('global-food-submit'),
                      onPressed: _loading ? null : _search,
                      icon: const Icon(Icons.public),
                      label: const Text('Search'),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Results: Open Food Facts '
                      '(community-submitted packaged foods). '
                      'Search when ready; this is not live autocomplete.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Loading
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            // Network/error state
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 40),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _search,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            // Initial / empty state
            else if (_foods.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      _searched
                          ? 'No products with usable nutrition were found.'
                          : 'Enter a food and tap Search.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            // Search results
            else
              SliverList.builder(
                itemCount: _foods.length,
                itemBuilder: (context, index) {
                  final food = _foods[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.restaurant_outlined),
                    ),
                    title: Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      "${food.brand ?? 'Unbranded'} · "
                      '${food.servingDescription} · '
                      'Open Food Facts',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${food.calories.round()} kcal',
                          style: theme.textTheme.titleSmall,
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                    onTap: () => _review(food),
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
