import 'package:flutter/material.dart';

import 'package:flutter_application_1/features/diet_plans/data/diet_plan_service.dart';
import 'package:flutter_application_1/features/diet_plans/models/weekly_diet_plan.dart';
import 'package:flutter_application_1/features/recipes/data/recipe_service.dart';
import 'package:flutter_application_1/features/recipes/models/recipe.dart';

class CreateWeeklyDietPlanPage extends StatefulWidget {
  const CreateWeeklyDietPlanPage({super.key});

  @override
  State<CreateWeeklyDietPlanPage> createState() =>
      _CreateWeeklyDietPlanPageState();
}

class _CreateWeeklyDietPlanPageState extends State<CreateWeeklyDietPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _dietPlanService = DietPlanService();
  final _recipeService = RecipeService();

  final _titleC = TextEditingController();
  final _notesC = TextEditingController();
  final List<TextEditingController> _morningSnackControllers = List.generate(
    _dayNames.length,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _afternoonSnackControllers = List.generate(
    _dayNames.length,
    (_) => TextEditingController(),
  );

  final Map<String, String?> _selectedRecipeIds = <String, String?>{};
  bool _saving = false;

  static const Color accent = Color(0xFF00897B);

  @override
  void dispose() {
    _titleC.dispose();
    _notesC.dispose();
    for (final controller in _morningSnackControllers) {
      controller.dispose();
    }
    for (final controller in _afternoonSnackControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _selectionKey(int dayIndex, String mealKey) => '$dayIndex-$mealKey';

  Recipe? _recipeById(List<Recipe> recipes, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final recipe in recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(List<Recipe> recipes) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final days = _dayNames.asMap().entries.map((entry) {
      final dayIndex = entry.key;
      final dayName = entry.value;
      return DietPlanDay(
        dayIndex: dayIndex,
        dayName: dayName,
        breakfast: _mealFor(recipes, dayIndex, 'breakfast'),
        lunch: _mealFor(recipes, dayIndex, 'lunch'),
        dinner: _mealFor(recipes, dayIndex, 'dinner'),
        snacks: _snacksForDay(dayIndex),
      );
    }).toList();

    setState(() => _saving = true);

    try {
      await _dietPlanService.createWeeklyPlan(
        title: _titleC.text,
        notes: _notesC.text,
        days: days,
      );

      if (!mounted) return;
      _snack('Haftalık diyet programı kaydedildi.');
      Navigator.of(context).pop(true);
    } catch (error) {
      _snack('Hata: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  DietPlanMeal? _mealFor(List<Recipe> recipes, int dayIndex, String mealKey) {
    final selectedId = _selectedRecipeIds[_selectionKey(dayIndex, mealKey)];
    final recipe = _recipeById(recipes, selectedId);
    if (recipe == null) return null;
    return DietPlanMeal.fromRecipe(recipe);
  }

  List<String> _snacksForDay(int dayIndex) {
    return [
      _morningSnackControllers[dayIndex].text.trim(),
      _afternoonSnackControllers[dayIndex].text.trim(),
    ].where((item) => item.isNotEmpty).toList();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    );
  }

  Widget _recipeDropdown({
    required List<Recipe> recipes,
    required int dayIndex,
    required String mealKey,
    required String label,
  }) {
    final key = _selectionKey(dayIndex, mealKey);
    final selectedId = _selectedRecipeIds[key];

    return InputDecorator(
      decoration: _decoration(label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          hint: const Text('Tarif seç'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Bos birak'),
            ),
            ...recipes.map(
              (recipe) => DropdownMenuItem<String?>(
                value: recipe.id,
                child: Text(
                  '${recipe.title} - ${recipe.authorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() => _selectedRecipeIds[key] = value),
        ),
      ),
    );
  }

  Widget _dayCard({
    required List<Recipe> recipes,
    required int dayIndex,
    required String dayName,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: ExpansionTile(
        initiallyExpanded: dayIndex == 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          dayName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        children: [
          _recipeDropdown(
            recipes: recipes,
            dayIndex: dayIndex,
            mealKey: 'breakfast',
            label: 'Kahvalti',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _morningSnackControllers[dayIndex],
            enabled: !_saving,
            decoration: _decoration('1. Ara ogun'),
          ),
          const SizedBox(height: 10),
          _recipeDropdown(
            recipes: recipes,
            dayIndex: dayIndex,
            mealKey: 'lunch',
            label: 'Ogle',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _afternoonSnackControllers[dayIndex],
            enabled: !_saving,
            decoration: _decoration('2. Ara ogun'),
          ),
          const SizedBox(height: 10),
          _recipeDropdown(
            recipes: recipes,
            dayIndex: dayIndex,
            mealKey: 'dinner',
            label: 'Akşam',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Haftalik Diyet Programi')),
      body: StreamBuilder<List<Recipe>>(
        stream: _recipeService.streamApprovedRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Tarifler yuklenemedi: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chefRecipes = snapshot.data!
              .where((recipe) => recipe.authorRole == 'chef')
              .toList();

          if (chefRecipes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Program oluşturmak için önce yayında olan şef tarifleri gerekir.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleC,
                  enabled: !_saving,
                  decoration: _decoration('Program basligi'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Baslik zorunlu'
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesC,
                  enabled: !_saving,
                  maxLines: 3,
                  decoration: _decoration('Notlar'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ana ogunler yalnizca yayındaki şef tariflerinden seçilir.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ..._dayNames.asMap().entries.map(
                  (entry) => _dayCard(
                    recipes: chefRecipes,
                    dayIndex: entry.key,
                    dayName: entry.value,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(chefRecipes),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Programi Kaydet',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const List<String> _dayNames = [
  'Pazartesi',
  'Sali',
  'Carsamba',
  'Persembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];
