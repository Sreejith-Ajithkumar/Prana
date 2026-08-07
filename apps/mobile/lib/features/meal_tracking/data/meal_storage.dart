import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/meal_entry.dart';

class MealStorage {
  MealStorage._();

  static final MealStorage instance = MealStorage._();

  static const String _mealsKey = 'prana_meals';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<MealEntry>> loadMeals() async {
    final encodedMeals = await _preferences.getString(_mealsKey);

    if (encodedMeals == null || encodedMeals.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(encodedMeals);

      if (decoded is! List<dynamic>) {
        return [];
      }

      return decoded
          .map((item) => MealEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    } on ArgumentError {
      return [];
    }
  }

  Future<void> saveMeals(List<MealEntry> meals) async {
    final encodedMeals = jsonEncode(
      meals.map((meal) => meal.toJson()).toList(),
    );

    await _preferences.setString(_mealsKey, encodedMeals);
  }

  Future<void> addMeal(MealEntry meal) async {
    final meals = await loadMeals();

    final updatedMeals = [...meals, meal];

    await saveMeals(updatedMeals);
  }

  Future<void> updateMeal(MealEntry updatedMeal) async {
    final meals = await loadMeals();

    final updatedMeals = meals.map((meal) {
      if (meal.id == updatedMeal.id) {
        return updatedMeal;
      }

      return meal;
    }).toList();

    await saveMeals(updatedMeals);
  }

  Future<void> deleteMeal(String mealId) async {
    final meals = await loadMeals();

    final updatedMeals = meals.where((meal) => meal.id != mealId).toList();

    await saveMeals(updatedMeals);
  }

  Future<List<MealEntry>> loadMealsForDate(DateTime date) async {
    final meals = await loadMeals();

    return meals.where((meal) {
      final loggedAt = meal.loggedAt;

      return loggedAt.year == date.year &&
          loggedAt.month == date.month &&
          loggedAt.day == date.day;
    }).toList()..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Future<void> clearMeals() async {
    await _preferences.remove(_mealsKey);
  }
}
