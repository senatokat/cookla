import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_clock.dart';
import '../../../../core/role_norm.dart';
import '../../../../services/workshop_service.dart';

class CreateWorkshopPage extends StatefulWidget {
  const CreateWorkshopPage({super.key});

  @override
  State<CreateWorkshopPage> createState() => _CreateWorkshopPageState();
}

class _CreateWorkshopPageState extends State<CreateWorkshopPage> {
  final WorkshopService _svc = WorkshopService();

  final TextEditingController _titleC = TextEditingController();
  final TextEditingController _descC = TextEditingController();
  final TextEditingController _locC = TextEditingController();
  final TextEditingController _capacityC = TextEditingController();
  final TextEditingController _durationC = TextEditingController();
  final TextEditingController _recipeTitleC = TextEditingController();
  final TextEditingController _recipeIngredientsC = TextEditingController();
  final TextEditingController _recipeStepsC = TextEditingController();

  DateTime _date = AppClock.now().add(const Duration(days: 1));

  bool _loading = false;
  String? _chefName;
  List<ChefOption> _coChefOptions = const [];
  String? _selectedCoChefId;

  @override
  void initState() {
    super.initState();
    _loadChefName();
    _loadCoChefOptions();
  }

  Future<void> _loadChefName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};
      final name = (data['name'] ?? '').toString().trim();
      final surname = (data['surname'] ?? '').toString().trim();
      final fullName = '$name $surname'.trim();

      if (!mounted) return;

      setState(() {
        _chefName = fullName.isNotEmpty
            ? fullName
            : (user.displayName ?? user.email ?? 'Bilinmeyen Şef');
      });
    } catch (_) {
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted) return;

      setState(() {
        _chefName = user?.displayName ?? user?.email ?? 'Bilinmeyen Şef';
      });
    }
  }

  Future<void> _loadCoChefOptions() async {
    try {
      final options = await _svc.listAvailableCoChefs();
      if (!mounted) return;
      setState(() => _coChefOptions = options);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _locC.dispose();
    _capacityC.dispose();
    _durationC.dispose();
    _recipeTitleC.dispose();
    _recipeIngredientsC.dispose();
    _recipeStepsC.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: AppClock.now(),
      lastDate: AppClock.now().add(const Duration(days: 365 * 3)),
      initialDate: _date,
    );
    if (picked == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null) return;

    final selectedDate = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );

    if (selectedDate.isBefore(AppClock.now())) {
      _snack('Geçmiş tarih ve saat seçilemez.');
      return;
    }

    setState(() {
      _date = selectedDate;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final role = await _svc.getMyRole();
    if (!isChefRole(role)) {
      return _snack('Sadece şef hesabı workshop oluşturabilir.');
    }

    final title = _titleC.text.trim();
    final desc = _descC.text.trim();
    final loc = _locC.text.trim();
    final chef = (_chefName ?? '').trim();
    final capacity = int.tryParse(_capacityC.text.trim()) ?? 0;
    final duration = int.tryParse(_durationC.text.trim()) ?? 0;
    final recipeTitle = _recipeTitleC.text.trim();
    final recipeIngredients = _recipeIngredientsC.text.trim();
    final recipeSteps = _recipeStepsC.text.trim();

    if (title.length < 3) return _snack('Baslik en az 3 karakter olmali.');
    if (loc.length < 2) return _snack('Konum zorunlu.');
    if (chef.isEmpty) return _snack('Şef bilgisi yuklenemedi.');
    if (capacity <= 0) return _snack("Kontenjan 0'dan buyuk olmali.");
    if (duration <= 0) return _snack("Tahmini süre 0'dan buyuk olmali.");
    if (recipeTitle.length < 2) return _snack('Tarif adı zorunlu.');
    if (recipeIngredients.isEmpty) return _snack('Malzemeler zorunlu.');
    if (recipeSteps.isEmpty) return _snack('Yapilis zorunlu.');

    if (_date.isBefore(AppClock.now())) {
      return _snack('Geçmiş tarih için etkinlik oluşturulamaz.');
    }

    setState(() => _loading = true);

    try {
      await _svc.createWorkshop(
        title: title,
        description: desc,
        location: loc,
        date: _date,
        chefName: chef,
        capacity: capacity,
        durationMinutes: duration,
        recipeTitle: recipeTitle,
        recipeIngredients: recipeIngredients,
        recipeSteps: recipeSteps,
        coChefId: _selectedCoChefId,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workshop oluşturuldu')));
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _selectedCoChefEmail() {
    for (final option in _coChefOptions) {
      if (option.uid == _selectedCoChefId) return option.email;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = AppClock.compactDateTime(_date);

    return FutureBuilder<String?>(
      future: _svc.getMyRole(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final allowed = isChefRole(snap.data);

        if (!allowed) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workshop Oluştur')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Bu sayfaya erişimin yok.\nSadece şef ve admin workshop oluşturabilir.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: AppBar(title: const Text('Workshop Oluştur')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleC,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Baslik'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locC,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Konum'),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withAlpha(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _chefName ?? 'Şef bilgisi yukleniyor...',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedCoChefId,
                  decoration: const InputDecoration(
                    labelText: 'İkinci şef (opsiyonel)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('İkinci şef ekleme'),
                    ),
                    ..._coChefOptions.map(
                      (option) => DropdownMenuItem<String?>(
                        value: option.uid,
                        child: Text(option.fullName),
                      ),
                    ),
                  ],
                  onChanged: _loading
                      ? null
                      : (value) => setState(() => _selectedCoChefId = value),
                ),
                if (_selectedCoChefId != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _selectedCoChefEmail() ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _capacityC,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Kontenjan'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _durationC,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Tahmini Süre (dakika)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descC,
                  enabled: !_loading,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Workshop Tarifi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _recipeTitleC,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Tarif Adı'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _recipeIngredientsC,
                  enabled: !_loading,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Malzemeler',
                    hintText: 'Her malzemeyi alt alta yazabilirsin',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _recipeStepsC,
                  enabled: !_loading,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Yapilis',
                    hintText: 'Adımlari sirayla yaz',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loading ? null : _pickDate,
                  child: Text('Tarih/Saat Seç: $dateText'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
