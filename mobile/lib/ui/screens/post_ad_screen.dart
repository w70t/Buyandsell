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
      setState(() => _images.addAll(picked.take(10 - _images.length)));
    }
  }

  Future<void> _publish() async {
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (_title.text.trim().length < 3 || _description.text.trim().length < 5 || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة العنوان والوصف واختيار القسم')),
      );
      return;
    }
    setState(() => _busy = true);
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
      for (final img in _images) {
        await api.uploadImage(listing.id, img.path);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر الإعلان بنجاح')),
      );
      _resetForm();
      widget.onPublished();
      openListing(context, listing.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
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
      appBar: AppBar(title: const Text('أضف إعلان')),
      body: !loggedIn
          ? LoginRequired(message: 'سجّل الدخول لنشر إعلان', onLogin: () => openAuth(context))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _imagesRow(),
                const SizedBox(height: 16),
                TextField(controller: _title, decoration: const InputDecoration(labelText: 'العنوان')),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'الوصف', alignLabelWithHint: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السعر (د.ع)'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _negotiable,
                  onChanged: (v) => setState(() => _negotiable = v),
                  title: const Text('قابل للتفاوض'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: 'used',
                        groupValue: _condition,
                        onChanged: (v) => setState(() => _condition = v!),
                        title: const Text('مستعمل'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: 'new',
                        groupValue: _condition,
                        onChanged: (v) => setState(() => _condition = v!),
                        title: const Text('جديد'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'القسم'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _governorate,
                  decoration: const InputDecoration(labelText: 'المحافظة'),
                  items: iraqGovernorates
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _governorate = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: _city, decoration: const InputDecoration(labelText: 'المنطقة (اختياري)')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : _publish,
                  child: _busy
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('نشر الإعلان'),
                ),
              ],
            ),
    );
  }

  Widget _imagesRow() {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _images.length >= 10 ? null : _pickImages,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.tile,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppTheme.accent),
                  SizedBox(height: 4),
                  Text('إضافة', style: TextStyle(fontSize: 11, color: AppTheme.accent)),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_images[i].path), width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
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
