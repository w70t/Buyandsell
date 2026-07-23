import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../data/governorates.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../state/auth_provider.dart';
import '../navigation.dart';
import '../widgets/common.dart';

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key, required this.onPublished});

  final VoidCallback onPublished;

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  static const _maxImages = 10;

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();

  bool _negotiable = false;
  String _condition = 'used';
  int? _categoryId;
  String _governorate = iraqGovernorates.first;
  final List<XFile> _images = [];

  List<Category> _categories = [];
  bool _busy = false;
  String _busyLabel = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = (await context.read<ApiService>().categories())
          .where((c) => c.slug != 'all')
          .toList();
      setState(() {
        _categories = cats;
        _categoryId ??= cats.isNotEmpty ? cats.first.id : null;
      });
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.take(_maxImages - _images.length)));
    }
  }

  String? _validate() {
    if (_title.text.trim().length < 3) return 'اكتب عنواناً واضحاً (٣ أحرف على الأقل)';
    if (_description.text.trim().length < 5) return 'اكتب وصفاً أطول قليلاً';
    if (_categoryId == null) return 'اختر قسم الإعلان';
    if (_price.text.trim().isEmpty) return 'حدّد السعر';
    return null;
  }

  Future<void> _publish() async {
    final error = _validate();
    if (error != null) {
      showAppSnack(context, error, type: SnackType.error);
      return;
    }
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _busy = true;
      _busyLabel = 'جارٍ النشر…';
    });
    final api = context.read<ApiService>();
    try {
      final listing = await api.createListing(
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: price,
        negotiable: _negotiable,
        condition: _condition,
        categoryId: _categoryId!,
        governorate: _governorate,
        city: _city.text.trim(),
      );
      for (var i = 0; i < _images.length; i++) {
        if (mounted) {
          setState(() => _busyLabel = 'رفع الصور ${i + 1}/${_images.length}…');
        }
        await api.uploadImage(listing.id, _images[i].path);
      }
      if (!mounted) return;
      showAppSnack(context, 'تم نشر الإعلان بنجاح', type: SnackType.success);
      _resetForm();
      widget.onPublished();
      openListing(context, listing.id);
    } catch (e) {
      if (mounted) {
        showAppSnack(context, apiErrorMessage(e), type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetForm() {
    _title.clear();
    _description.clear();
    _price.clear();
    _city.clear();
    setState(() {
      _images.clear();
      _negotiable = false;
      _condition = 'used';
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(title: const Text('أضف إعلانك')),
      body: !loggedIn
          ? LoginRequired(
              message: 'سجّل الدخول لنشر إعلان',
              onLogin: () => openAuth(context),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, glassTopInset(context) + 16, 16, 16),
              children: [
                _SectionCard(
                  title: 'الصور',
                  subtitle: 'حتى $_maxImages صور — الصورة الأولى هي الغلاف',
                  icon: Icons.photo_camera_outlined,
                  child: _imagesRow(),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'معلومات الإعلان',
                  icon: Icons.description_outlined,
                  child: Column(
                    children: [
                      TextField(
                        controller: _title,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'العنوان',
                          hintText: 'مثال: آيفون 13 برو بحالة ممتازة',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _description,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                          hintText: 'اذكر التفاصيل: الحالة، مدة الاستخدام، سبب البيع…',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: _categoryId,
                        decoration: const InputDecoration(labelText: 'القسم'),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.nameAr)))
                            .toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: 14),
                      _ConditionSelector(
                        value: _condition,
                        onChanged: (v) => setState(() => _condition = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'السعر',
                  icon: Icons.payments_outlined,
                  child: Column(
                    children: [
                      TextField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر',
                          suffixText: 'د.ع',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _negotiable,
                        onChanged: (v) => setState(() => _negotiable = v),
                        title: const Text('قابل للتفاوض'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'الموقع',
                  icon: Icons.location_on_outlined,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _governorate,
                        decoration: const InputDecoration(labelText: 'المحافظة'),
                        items: iraqGovernorates
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _governorate = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _city,
                        decoration: const InputDecoration(
                          labelText: 'المنطقة (اختياري)',
                          hintText: 'مثال: المنصور',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _publish,
                  icon: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rocket_launch_outlined, size: 20),
                  label: Text(_busy ? _busyLabel : 'نشر الإعلان'),
                ),
                SizedBox(height: glassNavInset(context)),
              ],
            ),
    );
  }

  Widget _imagesRow() {
    final sx = context.sx;
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _images.length >= _maxImages ? null : _pickImages,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: sx.accentSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sx.accent.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: sx.accent),
                  const SizedBox(height: 4),
                  Text(
                    '${_images.length}/$_maxImages',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sx.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (int i = 0; i < _images.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_images[i].path),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: SxBadge(label: 'الغلاف', color: sx.accent),
                    ),
                  Positioned(
                    top: 3,
                    left: 3,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// بطاقة قسم في نموذج النشر.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sx.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sx.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: sx.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: sx.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: sx.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: sx.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// مبدّل جديد/مستعمل على شكل شريحتين.
class _ConditionSelector extends StatelessWidget {
  const _ConditionSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    Widget option(String v, String label, IconData icon) {
      final selected = value == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? sx.accent : sx.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? sx.accent : sx.outline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 17, color: selected ? sx.onAccent : sx.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? sx.onAccent : sx.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option('used', 'مستعمل', Icons.autorenew_rounded),
        const SizedBox(width: 10),
        option('new', 'جديد', Icons.fiber_new_outlined),
      ],
    );
  }
}
