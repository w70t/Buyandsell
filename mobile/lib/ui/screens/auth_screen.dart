import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../state/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      if (_isLogin) {
        await auth.login(_phone.text.trim(), _password.text);
      } else {
        await auth.register(
            _name.text.trim(), _phone.text.trim(), _password.text);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sx = context.sx;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // ترويسة متدرجة بهوية العلامة.
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 42,
                            color: AppTheme.brandDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'سوقنا',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'بيع واشترِ كل شيء بالقرب منك',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color: Colors.black.withOpacity(0.25),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // مبدّل دخول/تسجيل.
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: sx.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sx.outline),
                    ),
                    child: Row(
                      children: [
                        _segment('تسجيل الدخول', _isLogin,
                            () => _switchMode(true)),
                        _segment('حساب جديد', !_isLogin,
                            () => _switchMode(false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: !_isLogin
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'الاسم',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      hintText: '07XXXXXXXXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sx.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sx.danger.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: sx.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: sx.danger,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLogin ? 'دخول' : 'إنشاء الحساب'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin
                        ? 'بالدخول أنت توافق على شروط استخدام سوقنا'
                        : 'بإنشاء الحساب أنت توافق على شروط استخدام سوقنا',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: sx.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _switchMode(bool login) {
    if (_busy) return;
    setState(() {
      _isLogin = login;
      _error = null;
    });
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    final sx = context.sx;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? sx.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? sx.onAccent : sx.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
