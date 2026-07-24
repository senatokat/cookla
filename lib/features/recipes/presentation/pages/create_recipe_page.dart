import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/features/home/models/ingredient_data.dart';

import '../../data/recipe_service.dart';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = RecipeService();

  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _stepsC = TextEditingController();
  final _imageUrlC = TextEditingController();
  final _durationC = TextEditingController();
  final _ingredientSearchC = TextEditingController();
  final _customIngredientC = TextEditingController();

  final Set<String> _selectedIngredients = <String>{};
  final Set<String> _customIngredients = <String>{};
  final Map<String, TextEditingController> _amountControllers =
      <String, TextEditingController>{};

  String _difficulty = 'Kolay';
  bool _loading = false;
  String _ingredientQuery = '';

  static const Color accent = kPrimary;

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _stepsC.dispose();
    _imageUrlC.dispose();
    _durationC.dispose();
    _ingredientSearchC.dispose();
    _customIngredientC.dispose();
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _amountControllerFor(String name) {
    return _amountControllers.putIfAbsent(name, () => TextEditingController());
  }

  List<String> get _filteredIngredients {
    final query = _ingredientQuery.trim().toLowerCase();
    final items = IngredientData.defaultNames;
    if (query.isEmpty) return items;
    return items.where((item) => item.toLowerCase().contains(query)).toList();
  }

  void _addCustomIngredient() {
    final normalized = IngredientData.fromName(_customIngredientC.text).title;
    if (normalized.isEmpty) return;

    setState(() {
      _customIngredients.add(normalized);
      _selectedIngredients.add(normalized);
      _amountControllerFor(normalized);
      _customIngredientC.clear();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir malzeme seçmelisin')),
      );
      return;
    }

    final title = _titleC.text.trim();
    final description = _descC.text.trim();
    final steps = _stepsC.text.trim();
    final imageUrl = _imageUrlC.text.trim();
    final duration = int.tryParse(_durationC.text.trim());
    final ingredientAmounts = <String, String>{
      for (final name in _selectedIngredients)
        name: (_amountControllers[name]?.text.trim() ?? ''),
    };

    setState(() => _loading = true);

    try {
      final status = await _svc.createRecipe(
        title: title,
        description: description,
        ingredientNames: _selectedIngredients.toList()..sort(),
        ingredientAmounts: ingredientAmounts,
        steps: steps,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        durationMinutes: duration,
        difficulty: _difficulty,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Tarif başarıyla yayınlandı'
                : 'Tarif onaya gönderildi',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
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

  String? _requiredValidator(String? value, String name) {
    if (value == null || value.trim().isEmpty) {
      return '$name zorunlu';
    }
    return null;
  }

  String? _durationValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Geçerli bir sayı gir';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarif Paylaş'), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _titleC,
                  enabled: !_loading,
                  decoration: _dec('Tarif adı'),
                  validator: (v) => _requiredValidator(v, 'Tarif adı'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descC,
                  enabled: !_loading,
                  maxLines: 3,
                  decoration: _dec('Kısa açıklama'),
                  validator: (v) => _requiredValidator(v, 'Açıklama'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlC,
                  enabled: !_loading,
                  decoration: _dec('Görsel URL (opsiyonel)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationC,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Süre (dakika)'),
                  validator: _durationValidator,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _difficulty,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Kolay', child: Text('Kolay')),
                      DropdownMenuItem(value: 'Orta', child: Text('Orta')),
                      DropdownMenuItem(value: 'Zor', child: Text('Zor')),
                    ],
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _difficulty = v!),
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Malzemeler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ingredientSearchC,
                  enabled: !_loading,
                  onChanged: (value) =>
                      setState(() => _ingredientQuery = value),
                  decoration: _dec('Malzeme ara'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _filteredIngredients.map((name) {
                    final selected = _selectedIngredients.contains(name);
                    return FilterChip(
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            _selectedIngredients.remove(name);
                            _amountControllers.remove(name)?.dispose();
                          } else {
                            _selectedIngredients.add(name);
                            _amountControllerFor(name);
                          }
                        });
                      },
                      label: Text('${IngredientData.emojiFor(name)} $name'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customIngredientC,
                        enabled: !_loading,
                        onSubmitted: (_) => _addCustomIngredient(),
                        decoration: _dec('Kendi malzemeni ekle'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _loading ? null : _addCustomIngredient,
                      child: const Text('Ekle'),
                    ),
                  ],
                ),
                if (_selectedIngredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_selectedIngredients.toList()..sort()).map((
                        name,
                      ) {
                        final isCustom = _customIngredients.contains(name);
                        return InputChip(
                          label: Text('${IngredientData.emojiFor(name)} $name'),
                          onDeleted: () {
                            setState(() {
                              _selectedIngredients.remove(name);
                              _amountControllers.remove(name)?.dispose();
                              if (isCustom) {
                                _customIngredients.remove(name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (_selectedIngredients.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Malzeme Miktarları',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_selectedIngredients.toList()..sort()).map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: _amountControllerFor(name),
                        enabled: !_loading,
                        decoration: _dec(
                          '${IngredientData.emojiFor(name)} $name miktarı',
                        ).copyWith(hintText: 'Örnek: 1 çay kaşığı, 200 g'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stepsC,
                  enabled: !_loading,
                  maxLines: 8,
                  decoration: _dec('Hazırlanış'),
                  validator: (v) => _requiredValidator(v, 'Hazırlanış'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Tarifi Gönder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
