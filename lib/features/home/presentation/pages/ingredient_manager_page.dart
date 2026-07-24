import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/models/ingredient_data.dart';

class IngredientManagerPage extends StatefulWidget {
  final String uid;

  const IngredientManagerPage({super.key, required this.uid});

  @override
  State<IngredientManagerPage> createState() => _IngredientManagerPageState();
}

class _IngredientManagerPageState extends State<IngredientManagerPage> {
  final TextEditingController _customController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _amountControllers =
      <String, TextEditingController>{};

  final Set<String> _selected = <String>{};
  final Set<String> _customItems = <String>{};

  bool _loading = true;
  bool _saving = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customController.dispose();
    _searchController.dispose();
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _amountControllerFor(
    String name, {
    String amount = '',
  }) {
    return _amountControllers.putIfAbsent(
      name,
      () => TextEditingController(text: amount),
    );
  }

  List<String> get _filteredDefaultIngredients {
    final query = _query.trim().toLowerCase();
    final all = IngredientData.defaultNames;
    if (query.isEmpty) return all;
    return all.where((item) => item.toLowerCase().contains(query)).toList();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();

    final data = doc.data() ?? <String, dynamic>{};

    final pantryItems = data['pantryItems'];

    setState(() {
      _selected
        ..clear()
        ..addAll(
          pantryItems is Iterable
              ? pantryItems.whereType<Map>().map((item) {
                  final ingredient = IngredientData.fromMap(
                    Map<String, dynamic>.from(item),
                  );
                  _amountControllerFor(
                    ingredient.title,
                    amount: ingredient.amount,
                  );
                  return ingredient.title;
                })
              : ((data['likedIngredients'] as List?) ?? []).map(
                  (item) => IngredientData.fromName(item.toString()).title,
                ),
        );
      _customItems
        ..clear()
        ..addAll(
          ((data['customIngredients'] as List?) ?? []).map(
            (item) => IngredientData.fromName(item.toString()).title,
          ),
        );
      _loading = false;
    });
  }

  void _toggleDefaultIngredient(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
        _amountControllers.remove(name)?.dispose();
      } else {
        _selected.add(name);
        _amountControllerFor(name);
      }
    });
  }

  void _addCustomIngredient() {
    final value = IngredientData.fromName(_customController.text).title;
    if (value.isEmpty) return;

    setState(() {
      _customItems.add(value);
      _selected.add(value);
      _amountControllerFor(value);
      _customController.clear();
    });
  }

  void _removeCustomIngredient(String name) {
    setState(() {
      _customItems.remove(name);
      _selected.remove(name);
      _amountControllers.remove(name)?.dispose();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final pantryItems = (_selected.toList()..sort()).map((name) {
        final ingredient = IngredientData.fromName(name);
        return ingredient
            .copyWithAmount(_amountControllers[name]?.text.trim() ?? '')
            .toMap();
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'likedIngredients': _selected.toList()..sort(),
        'customIngredients': _customItems.toList()..sort(),
        'pantryItems': pantryItems,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Malzemeler güncellendi')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Malzemelerim')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Evde olan malzemeleri seç veya yeni bir malzeme ekle. Home ekranindaki tarif önerileri buna göre güncellenir.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Varsayılan Malzemeler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Malzeme ara',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _filteredDefaultIngredients.map((name) {
                    final selected = _selected.contains(name);

                    return FilterChip(
                      selected: selected,
                      onSelected: (_) => _toggleDefaultIngredient(name),
                      label: Text('${IngredientData.emojiFor(name)} $name'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kendi Malzemeni Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addCustomIngredient(),
                        decoration: const InputDecoration(
                          hintText: 'Örnek: Tahin, Susam, Nar ekşisi',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _addCustomIngredient,
                      child: const Text('Ekle'),
                    ),
                  ],
                ),
                if (_customItems.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _customItems.map((name) {
                      return InputChip(
                        label: Text('${IngredientData.emojiFor(name)} $name'),
                        onDeleted: () => _removeCustomIngredient(name),
                      );
                    }).toList(),
                  ),
                ],
                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Miktarlar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...(_selected.toList()..sort()).map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: _amountControllerFor(name),
                        decoration: InputDecoration(
                          labelText: '${IngredientData.emojiFor(name)} $name',
                          hintText: 'Örnek: 500 g, 2 adet, 1 litre',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kaydet'),
          ),
        ),
      ),
    );
  }
}
