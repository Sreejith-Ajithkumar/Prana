import 'package:flutter/material.dart';

import '../../domain/entities/catalog_food.dart';

class BarcodeFoodConfirmationScreen extends StatefulWidget {
  const BarcodeFoodConfirmationScreen({super.key, required this.food});

  final CatalogFood food;

  @override
  State<BarcodeFoodConfirmationScreen> createState() =>
      _BarcodeFoodConfirmationScreenState();
}

class _BarcodeFoodConfirmationScreenState
    extends State<BarcodeFoodConfirmationScreen> {
  late final TextEditingController _quantityController;
  double _quantity = 1;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(String value) {
    final parsed = double.tryParse(value.trim());

    setState(() {
      _quantity = parsed != null && parsed > 0 ? parsed : 0;
    });
  }

  void _confirm() {
    if (_quantity <= 0) {
      return;
    }

    final food = widget.food;

    Navigator.of(context).pop(
      CatalogFood(
        id: food.id,
        name: food.name,
        calories: food.calories * _quantity,
        proteinGrams: food.proteinGrams * _quantity,
        carbohydrateGrams: food.carbohydrateGrams * _quantity,
        fatGrams: food.fatGrams * _quantity,
        servingDescription: _quantity == 1
            ? food.servingDescription
            : '${_formatNumber(_quantity)} × ${food.servingDescription}',
        servingQuantity: food.servingQuantity * _quantity,
        servingUnit: food.servingUnit,
        source: food.source,
        providerId: food.providerId,
        brand: food.brand,
        barcode: food.barcode,
        searchTerms: food.searchTerms,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;

    return Scaffold(
      appBar: AppBar(title: const Text('Review barcode food')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              food.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (food.brand?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                food.brand!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Source',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Open Food Facts'),
                    if (food.barcode?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text('Barcode: ${food.barcode}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Amount',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('barcode-food-quantity'),
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Number of servings',
                helperText: '1 serving = ${food.servingDescription}',
                border: const OutlineInputBorder(),
              ),
              onChanged: _updateQuantity,
            ),
            if (_quantity <= 0) ...[
              const SizedBox(height: 8),
              Text(
                'Enter an amount greater than zero.',
                key: const ValueKey('barcode-food-quantity-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Nutrition',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _NutritionRow(
                      label: 'Calories',
                      value: '${_formatNumber(food.calories * _quantity)} kcal',
                      emphasize: true,
                    ),
                    const Divider(),
                    _NutritionRow(
                      label: 'Protein',
                      value:
                          '${_formatNumber(food.proteinGrams * _quantity)} g',
                    ),
                    const SizedBox(height: 10),
                    _NutritionRow(
                      label: 'Carbohydrates',
                      value:
                          '${_formatNumber(food.carbohydrateGrams * _quantity)} g',
                    ),
                    const SizedBox(height: 10),
                    _NutritionRow(
                      label: 'Fat',
                      value: '${_formatNumber(food.fatGrams * _quantity)} g',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nutrition is scaled from the source serving. Prana does not '
              'infer conversions between grams, millilitres, and servings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              key: const ValueKey('confirm-barcode-food'),
              onPressed: _quantity > 0 ? _confirm : null,
              icon: const Icon(Icons.check),
              label: const Text('Use this food'),
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
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
