import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/persistent_custom_food_repository.dart';
import '../../domain/entities/catalog_food.dart';
import '../../domain/entities/custom_food_draft.dart';
import '../../domain/repositories/custom_food_repository.dart';

class CustomFoodScreen extends StatefulWidget {
  const CustomFoodScreen({super.key, this.food, this.repository});

  final CatalogFood? food;
  final CustomFoodRepository? repository;

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  late final CustomFoodRepository _repository;

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.food != null;

  @override
  void initState() {
    super.initState();

    _repository = widget.repository ?? PersistentCustomFoodRepository.instance;

    final food = widget.food;

    _nameController = TextEditingController(text: food?.name ?? '');
    _brandController = TextEditingController(text: food?.brand ?? '');
    _quantityController = TextEditingController(
      text: food == null ? '1' : _formatEditableNumber(food.servingQuantity),
    );
    _unitController = TextEditingController(
      text: food?.servingUnit ?? 'serving',
    );
    _caloriesController = TextEditingController(
      text: food == null ? '' : _formatEditableNumber(food.calories),
    );
    _proteinController = TextEditingController(
      text: food == null ? '' : _formatEditableNumber(food.proteinGrams),
    );
    _carbsController = TextEditingController(
      text: food == null ? '' : _formatEditableNumber(food.carbohydrateGrams),
    );
    _fatController = TextEditingController(
      text: food == null ? '' : _formatEditableNumber(food.fatGrams),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
      final draft = CustomFoodDraft(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        servingQuantity: double.parse(_quantityController.text.trim()),
        servingUnit: _unitController.text.trim(),
        calories: double.parse(_caloriesController.text.trim()),
        proteinGrams: _parseOptionalNumber(_proteinController),
        carbohydrateGrams: _parseOptionalNumber(_carbsController),
        fatGrams: _parseOptionalNumber(_fatController),
      );

      final existing = widget.food;

      if (existing == null) {
        await _repository.createCustomFood(draft);
      } else {
        await _repository.updateCustomFood(existing.identityKey, draft);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Prana could not update this custom food.'
                : 'Prana could not create this custom food.',
          ),
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

  Future<void> _delete() async {
    final food = widget.food;

    if (food == null || _isSaving || _isDeleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete custom food?'),
          content: Text(
            '${food.name} will be removed from your custom foods. '
            'Meals you already logged will stay in your history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      await _repository.deleteCustomFood(food.identityKey);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prana could not delete this custom food.'),
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

  double _parseOptionalNumber(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
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

  static String _formatEditableNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit custom food' : 'Create custom food'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete custom food',
              onPressed: busy ? null : _delete,
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
              TextFormField(
                key: const ValueKey('custom-food-name'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  hintText: 'Example: Homemade protein oats',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  return _validateRequiredText(value, 'a food name');
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('custom-food-brand'),
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  hintText: 'Optional',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              Text('Serving', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('custom-food-quantity'),
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,5}(\.\d{0,2})?'),
                        ),
                      ],
                      validator: (value) {
                        return _validatePositiveNumber(value, 'quantity');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('custom-food-unit'),
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'g, cup, serving',
                      ),
                      validator: (value) {
                        return _validateRequiredText(value, 'a unit');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Nutrition per serving',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('custom-food-calories'),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('custom-food-protein'),
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
                      validator: (value) {
                        return _validateOptionalNumber(value, 'protein');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('custom-food-carbs'),
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
                      validator: (value) {
                        return _validateOptionalNumber(value, 'carbohydrates');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('custom-food-fat'),
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
                validator: (value) {
                  return _validateOptionalNumber(value, 'fat');
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: busy ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Save custom food'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
