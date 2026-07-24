import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/features/home/models/ingredient_data.dart';

import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';
import 'package:flutter_application_1/services/auth_service.dart';

import '../steps/allergies_step.dart';
import '../steps/diet_step.dart';
import '../steps/ingredients_step.dart';
import '../steps/tags_step.dart';

class PreferenceFlowPage extends StatefulWidget {
  const PreferenceFlowPage({super.key});

  @override
  State<PreferenceFlowPage> createState() => _PreferenceFlowPageState();
}

class _PreferenceFlowPageState extends State<PreferenceFlowPage> {
  final _controller = PageController();
  final _auth = AuthService();

  int _index = 0;
  bool _saving = false;

  final Set<String> likedIngredients = {};
  final Set<String> allergies = {};
  String? dietType;
  final Set<String> favoriteTags = {};

  final ingredients = IngredientData.defaultNames;

  final allergyOptions = const [
    'Yumurta',
    'Balık',
    'Badem',
    'Gluten',
    'Çikolata',
    'Avokado',
    'Hardal',
    'Şeftali',
    'Findik',
    'Soya',
    'Süt',
    'Kakao',
    'Ceviz',
  ];

  final tags = const [
    'Ozel Gun',
    'Sağlıkli',
    'Soguk icecekler',
    'Diyet Tarifleri',
    'Kolay Pisirilen',
    'Glutensiz',
    'Atistirmaliklar',
    'Tatlilar',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveAndFinish() async {
    if (_saving) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('Oturum bulunamadı. Lutfen tekrar giris yapin.');
      return;
    }

    setState(() => _saving = true);

    try {
      final normalizedDiet = (dietType ?? '').trim();
      final dietValue = normalizedDiet.isEmpty ? null : normalizedDiet;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'likedIngredients': likedIngredients.toList()..sort(),
        'allergies': allergies.toList()..sort(),
        'dietType': dietValue,
        'favoriteTags': favoriteTags.toList()..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _auth.markOnboardingDone();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _snack('Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (!_controller.hasClients) return;
    if (_index < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    }
  }

  void _prev() {
    if (!_controller.hasClients) return;
    if (_index > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = kPrimary;

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tercihler',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveAndFinish,
            child: Text(
              _saving ? 'Kaydediliyor...' : 'Kaydet ve Gec',
              style: const TextStyle(
                color: orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  IngredientsStep(
                    title: 'Evde hangi malzemeler var?',
                    subtitle: 'Bu seçimlere göre sana tarif onerelim.',
                    items: ingredients,
                    selected: likedIngredients,
                  ),
                  AllergiesStep(
                    title: 'Herhangi bir gida alerjin var mi?',
                    subtitle: 'Alerjilerini belirt.',
                    items: allergyOptions,
                    selected: allergies,
                  ),
                  DietStep(
                    title: 'Herhangi bir diyet uyguluyor musun?',
                    selectedDiet: dietType,
                    onSelect: (v) => setState(() => dietType = v),
                  ),
                  TagsStep(
                    title: 'Tercih ettigin tarif turlerini seç',
                    items: tags,
                    selected: favoriteTags,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (_index == 0 || _saving) ? null : _prev,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: orange),
                        foregroundColor: orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Önceki'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (_index < 3) {
                                _next();
                              } else {
                                await _saveAndFinish();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(_index < 3 ? 'Sonraki' : 'Bitir'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
