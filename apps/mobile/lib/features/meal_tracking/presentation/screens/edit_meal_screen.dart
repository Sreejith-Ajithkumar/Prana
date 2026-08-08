import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/meal_storage.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/enums/meal_type.dart';

class EditMealScreen extends StatefulWidget {
  const EditMealScreen({super.key, required this.meal});

  final MealEntry meal;

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _foodNameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;

  late MealType _selectedMealType;

  bool _isSaving = false;
  bool _isDeleting = false;

  FoodEntry get _food => widget.meal.foods.first;

  @override
  void initState() {
    super.initState();

    final food = _food;

    _selectedMealType = widget.meal.type;

    _foodNameController = TextEditingController(text: food.name);

    _caloriesController = TextEditingController(
      text: _formatNumber(food.calories),
    );

    _proteinController = TextEditingController(
      text: _formatNumber(food.proteinGrams),
    );

    _carbsController = TextEditingController(
      text: _formatNumber(food.carbohydrateGrams),
    );

    _fatController = TextEditingController(text: _formatNumber(food.fatGrams));

    _quantityController = TextEditingController(
      text: _formatNumber(food.quantity),
    );

    _unitController = TextEditingController(text: food.unit);
  }

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

  Future<void> _saveChanges() async {
    if (_isSaving || _isDeleting) {
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
      final updatedFood = FoodEntry(
        id: _food.id,
        name: _foodNameController.text.trim(),
        calories: double.parse(_caloriesController.text.trim()),
        proteinGrams: _parseOptionalNumber(_proteinController),
        carbohydrateGrams: _parseOptionalNumber(_carbsController),
        fatGrams: _parseOptionalNumber(_fatController),
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unitController.text.trim(),
      );

      final updatedMeal = MealEntry(
        id: widget.meal.id,
        type: _selectedMealType,
        loggedAt: widget.meal.loggedAt,
        foods: [updatedFood],
      );

      await MealStorage.instance.updateMeal(updatedMeal);

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
          content: Text('We could not update this meal. Please try again.'),
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

  Future<void> _deleteMeal() async {
    if (_isSaving || _isDeleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete meal?'),
          content: const Text('This meal will be removed from today\'s log.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await MealStorage.instance.deleteMeal(widget.meal.id);

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
          content: Text('We could not delete this meal. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit meal'),
        actions: [
          IconButton(
            tooltip: 'Delete meal',
            onPressed: _isDeleting ? null : _deleteMeal,
            icon: _isDeleting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
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
              TextFormField(
                controller: _foodNameController,
                decoration: const InputDecoration(labelText: 'Food name'),
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
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,5}(\.\d{0,1})?'),
                  ),
                ],
                validator: (value) {
                  return _validatePositiveNumber(value, 'calories');
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  return _validateOptionalNumber(value, 'fat');
                },
              ),
              const SizedBox(height: 24),
              Text('Serving', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        return _validatePositiveNumber(value, 'quantity');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      validator: (value) {
                        return _validateRequiredText(value, 'a unit');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
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

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}
