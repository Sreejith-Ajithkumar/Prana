import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/food_preferences_storage.dart';
import '../../data/meal_storage.dart';
import '../../domain/entities/catalog_food.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/enums/meal_type.dart';

typedef SaveMealAction = Future<void> Function(MealEntry meal);
typedef RecordRecentFoodAction = Future<void> Function(CatalogFood food);
typedef SearchFoodAction = Future<CatalogFood?> Function();

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({
    super.key,
    this.saveMealAction,
    this.recordRecentFoodAction,
    this.searchFoodAction,
  });

  final SaveMealAction? saveMealAction;
  final RecordRecentFoodAction? recordRecentFoodAction;
  final SearchFoodAction? searchFoodAction;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();

  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'serving');

  MealType _selectedMealType = MealType.breakfast;
  CatalogFood? _selectedCatalogFood;

  bool _isSaving = false;
  bool _isUpdatingNutrition = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  double _parseOptionalNumber(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> _saveMeal() async {
    if (_isSaving) {
      return;
    }

    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final id = now.microsecondsSinceEpoch.toString();

      final food = FoodEntry(
        id: 'food-$id',
        name: _foodNameController.text.trim(),
        calories: double.parse(_caloriesController.text.trim()),
        proteinGrams: _parseOptionalNumber(_proteinController),
        carbohydrateGrams: _parseOptionalNumber(_carbsController),
        fatGrams: _parseOptionalNumber(_fatController),
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unitController.text.trim(),
      );

      final meal = MealEntry(
        id: 'meal-$id',
        type: _selectedMealType,
        loggedAt: now,
        foods: [food],
      );

      final saveMealAction =
          widget.saveMealAction ?? MealStorage.instance.addMeal;

      await saveMealAction(meal);

      final selectedCatalogFood = _selectedCatalogFood;

      if (selectedCatalogFood != null) {
        final recordRecentFoodAction =
            widget.recordRecentFoodAction ??
            (CatalogFood selectedFood) {
              return FoodPreferencesStorage.instance.recordRecent(
                selectedFood.identityKey,
              );
            };

        try {
          await recordRecentFoodAction(selectedCatalogFood);
        } catch (_) {
          // Meal logging is the primary action. A non-critical recents update
          // must never make an already-saved meal look like it failed.
        }
      }

      if (!mounted) {
        return;
      }

      context.pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not save this meal. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateRequiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $fieldName.';
    }

    return null;
  }

  String? _validatePositiveNumber(String? value, String fieldName) {
    final parsed = double.tryParse(value?.trim() ?? '');

    if (parsed == null) {
      return 'Enter a valid $fieldName.';
    }

    if (parsed <= 0) {
      return '$fieldName must be greater than zero.';
    }

    return null;
  }

  String? _validateOptionalNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parsed = double.tryParse(value.trim());

    if (parsed == null) {
      return 'Enter a valid $fieldName.';
    }

    if (parsed < 0) {
      return '$fieldName cannot be negative.';
    }

    return null;
  }

  Future<void> _searchFood() async {
    final searchFoodAction =
        widget.searchFoodAction ??
        () => context.push<CatalogFood>('/foods/search');

    final selectedFood = await searchFoodAction();

    if (!mounted || selectedFood == null) {
      return;
    }

    setState(() {
      _selectedCatalogFood = selectedFood;

      _foodNameController.text = selectedFood.name;
      _caloriesController.text = _formatEditableNumber(selectedFood.calories);
      _proteinController.text = _formatEditableNumber(
        selectedFood.proteinGrams,
      );
      _carbsController.text = _formatEditableNumber(
        selectedFood.carbohydrateGrams,
      );
      _fatController.text = _formatEditableNumber(selectedFood.fatGrams);
      _quantityController.text = _formatEditableNumber(
        selectedFood.servingQuantity,
      );
      _unitController.text = selectedFood.servingUnit;
    });
  }

  void _recalculateNutrition() {
    final food = _selectedCatalogFood;

    if (food == null || _isUpdatingNutrition) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());

    if (quantity == null || quantity <= 0 || food.servingQuantity <= 0) {
      return;
    }

    final multiplier = quantity / food.servingQuantity;

    _isUpdatingNutrition = true;

    _caloriesController.text = _formatEditableNumber(
      food.calories * multiplier,
    );

    _proteinController.text = _formatEditableNumber(
      food.proteinGrams * multiplier,
    );

    _carbsController.text = _formatEditableNumber(
      food.carbohydrateGrams * multiplier,
    );

    _fatController.text = _formatEditableNumber(food.fatGrams * multiplier);

    _isUpdatingNutrition = false;
  }

  void _clearCatalogSelection() {
    _selectedCatalogFood = null;
  }

  static String _formatEditableNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCatalogFood = _selectedCatalogFood;

    return Scaffold(
      appBar: AppBar(title: const Text('Add meal')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Meal type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<MealType>(
                initialValue: _selectedMealType,
                decoration: const InputDecoration(labelText: 'Meal type'),
                items: MealType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_formatMealType(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedMealType = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _searchFood,
                icon: const Icon(Icons.search),
                label: const Text('Search food database'),
              ),
              const SizedBox(height: 12),
              Text(
                'Or enter the food manually below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (selectedCatalogFood != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nutrition values are based on '
                            '${selectedCatalogFood.servingDescription}.',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Use manual values',
                          onPressed: () {
                            setState(() {
                              _clearCatalogSelection();
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _foodNameController,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  hintText: 'Example: Tea or chicken rice bowl',
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_selectedCatalogFood != null) {
                    setState(() {
                      _clearCatalogSelection();
                    });
                  }
                },
                validator: (value) {
                  return _validateRequiredText(value, 'a food name');
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  suffixText: 'kcal',
                  helperText: 'Required for manual food entry.',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,5}(\.\d{0,1})?'),
                  ),
                ],
                onChanged: (_) {
                  if (_selectedCatalogFood != null && !_isUpdatingNutrition) {
                    setState(() {
                      _clearCatalogSelection();
                    });
                  }
                },
                validator: (value) {
                  return _validatePositiveNumber(value, 'calories');
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        suffixText: 'g',
                        hintText: 'Optional',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,4}(\.\d{0,1})?'),
                        ),
                      ],
                      onChanged: (_) {
                        if (_selectedCatalogFood != null &&
                            !_isUpdatingNutrition) {
                          setState(() {
                            _clearCatalogSelection();
                          });
                        }
                      },
                      validator: (value) {
                        return _validateOptionalNumber(value, 'protein');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs',
                        suffixText: 'g',
                        hintText: 'Optional',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,4}(\.\d{0,1})?'),
                        ),
                      ],
                      onChanged: (_) {
                        if (_selectedCatalogFood != null &&
                            !_isUpdatingNutrition) {
                          setState(() {
                            _clearCatalogSelection();
                          });
                        }
                      },
                      validator: (value) {
                        return _validateOptionalNumber(value, 'carbohydrates');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(
                  labelText: 'Fat',
                  suffixText: 'g',
                  hintText: 'Optional',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,4}(\.\d{0,1})?'),
                  ),
                ],
                onChanged: (_) {
                  if (_selectedCatalogFood != null && !_isUpdatingNutrition) {
                    setState(() {
                      _clearCatalogSelection();
                    });
                  }
                },
                validator: (value) {
                  return _validateOptionalNumber(value, 'fat');
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Protein, carbs, and fat are optional for manual entries.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text('Serving', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,4}(\.\d{0,2})?'),
                        ),
                      ],
                      onChanged: (_) {
                        _recalculateNutrition();
                      },
                      validator: (value) {
                        return _validatePositiveNumber(value, 'quantity');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'cup, serving, bowl',
                      ),
                      onChanged: (_) {
                        if (_selectedCatalogFood != null) {
                          setState(() {
                            _clearCatalogSelection();
                          });
                        }
                      },
                      validator: (value) {
                        return _validateRequiredText(value, 'a unit');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _saveMeal,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMealType(MealType type) {
    return switch (type) {
      MealType.breakfast => 'Breakfast',
      MealType.lunch => 'Lunch',
      MealType.dinner => 'Dinner',
      MealType.snack => 'Snack',
    };
  }
}
