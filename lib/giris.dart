import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tema.dart';
import 'yonetim.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;
  Timer? _authWaitTimer;
  bool _isRecoveryFlow = Uri.base.path.endsWith('/reset-password');
  bool _hasReceivedAuthState = false;

  @override
  void initState() {
    super.initState();
    _authWaitTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _hasReceivedAuthState) return;
      setState(() => _hasReceivedAuthState = true);
    });
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (authState) {
        _authWaitTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _hasReceivedAuthState = true;
          if (authState.event == AuthChangeEvent.passwordRecovery) {
            _isRecoveryFlow = true;
          } else if (authState.event == AuthChangeEvent.signedOut) {
            _isRecoveryFlow = false;
          }
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        _authWaitTimer?.cancel();
        debugPrint('Kimlik doğrulama durumu alınamadı: $error');
        if (!mounted) return;
        setState(() => _hasReceivedAuthState = true);
      },
    );
  }

  @override
  void dispose() {
    _authWaitTimer?.cancel();
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    if (_isRecoveryFlow) {
      if (!_hasReceivedAuthState) {
        return const AuthLoadingPage();
      }
      if (auth.currentSession != null) {
        return const PasswordRecoveryPage();
      }
      return RecoveryLinkExpiredPage(
        onBackToLogin: () => setState(() => _isRecoveryFlow = false),
      );
    }
    if (auth.currentSession != null) return const AntiqueAdminPage();
    if (!_hasReceivedAuthState) return const AuthLoadingPage();
    return const LoginPage();
  }
}

class AuthLoadingPage extends StatelessWidget {
  const AuthLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: accentColor(context)),
      ),
    );
  }
}

class RecoveryLinkExpiredPage extends StatelessWidget {
  const RecoveryLinkExpiredPage({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_off_rounded,
                      color: accentColor(context),
                      size: 44,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bağlantı kullanılamıyor',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Şifre yenileme bağlantısının süresi dolmuş veya '
                      'bağlantı daha önce kullanılmış olabilir. Giriş '
                      'ekranından yeni bir bağlantı iste.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onBackToLogin,
                      child: const Text('Giriş ekranına dön'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isBusy = false;
  bool _isComplete = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      await auth.updateUser(UserAttributes(password: _passwordController.text));
      if (mounted) {
        setState(() {
          _isComplete = true;
          _errorMessage = null;
        });
      }
    } catch (error) {
      debugPrint('Yeni şifre kaydedilemedi: $error');
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _returnToLogin() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      debugPrint('Giriş ekranına dönülemedi: $error');
      if (mounted) {
        setState(() => _errorMessage = 'Çıkış yapılamadı: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        _isComplete
                            ? Icons.check_circle_outline_rounded
                            : Icons.lock_reset_rounded,
                        color: accentColor(context),
                        size: 44,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isComplete
                            ? 'Şifren güncellendi'
                            : 'Yeni şifre belirle',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isComplete
                            ? 'Yeni şifrenle artık hesabına giriş yapabilirsin.'
                            : 'Hesabın için en az 8 karakterli yeni bir şifre oluştur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ],
                      if (!_isComplete) ...[
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Yeni şifre',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Şifre en az 8 karakter olmalıdır.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Yeni şifreyi doğrula',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Şifreler eşleşmiyor.';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isBusy
                            ? null
                            : _isComplete
                            ? _returnToLogin
                            : _savePassword,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        child: _isBusy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF101010),
                                ),
                              )
                            : Text(
                                _isComplete
                                    ? 'Giriş ekranına dön'
                                    : 'Şifreyi güncelle',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _isBusy = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // E-POSTA İLE GİRİŞ VE HESAP OLUŞTURMA İŞLEMİ BAŞLANGICI
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final auth = Supabase.instance.client.auth;
    try {
      if (_isSignUp) {
        final response = await auth.signUp(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
          data: {'full_name': _nameController.text.trim()},
        );

        if (response.session == null && mounted) {
          setState(() {
            _isSignUp = false;
            _infoMessage =
                'Kayıt isteği tamamlandı. E-posta doğrulamasını etkinleştirdiysen, '
                'doğrulama bağlantısını açıp giriş yapabilirsin.';
          });
        }
      } else {
        await auth.signInWithPassword(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
        );
      }
    } catch (error) {
      debugPrint('Kimlik doğrulama hatası: $error');
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
  // E-POSTA İLE GİRİŞ VE HESAP OLUŞTURMA İŞLEMİ BİTİŞİ

  Future<void> _sendPasswordReset() async {
    if (!(_emailFieldKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim().toLowerCase(),
        redirectTo: kIsWeb
            ? Uri.base.resolve('/reset-password').toString()
            : null,
      );
      if (mounted) {
        setState(() {
          _infoMessage =
              'Şifre yenileme bağlantısı e-posta adresine gönderildi. '
              'Gelen kutunu ve spam klasörünü kontrol et.';
        });
      }
    } catch (error) {
      debugPrint('Şifre sıfırlama e-postası gönderilemedi: $error');
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight - 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 760;
                        final form = _buildForm(context);
                        if (!isWide) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBrandPanel(context, compact: true),
                              Padding(
                                padding: const EdgeInsets.all(28),
                                child: form,
                              ),
                            ],
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildBrandPanel(context)),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(44),
                                  child: form,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel(BuildContext context, {bool compact = false}) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 0 : 520),
      padding: EdgeInsets.all(compact ? 28 : 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLightTheme
              ? const [Color(0xFFE8E8E8), Color(0xFFF5F5F5), Colors.white]
              : const [Color(0xFF30270F), Color(0xFF17140D), Color(0xFF101010)],
        ),
      ),
      child: Column(
        mainAxisAlignment: compact
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accentColor(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor(context).withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: accentColor(context),
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          const EskilerdenBrand(fontSize: 38),
          const SizedBox(height: 14),
          Text(
            'Değerli parçalarını güvenle yönet, '
            'koleksiyonunun her detayını tek yerde takip et.',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 36),
            const LoginFeature(
              icon: Icons.inventory_2_outlined,
              label: 'Envanter ve stok kontrolü',
            ),
            const SizedBox(height: 16),
            const LoginFeature(
              icon: Icons.gavel_rounded,
              label: 'Açık artırma takibi',
            ),
            const SizedBox(height: 16),
            const LoginFeature(
              icon: Icons.lock_outline_rounded,
              label: 'Hesabına özel güvenli erişim',
            ),
          ],
        ],
      ),
    );
  }

  // GİRİŞ EKRANI FORMU BAŞLANGICI
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Hesap oluştur' : 'Tekrar hoş geldin',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _isSignUp
                ? 'Envanterini yönetmeye başlamak için bilgilerini gir.'
                : 'Devam etmek için hesabına giriş yap.',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          if (_errorMessage != null)
            _buildMessage(_errorMessage!, isError: true),
          if (_infoMessage != null) _buildMessage(_infoMessage!),
          if (_isSignUp) ...[
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Ad soyad (isteğe bağlı)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: _emailFieldKey,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-posta adresi',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty || !email.contains('@')) {
                return 'Geçerli bir e-posta adresi gir.';
              }
              return null;
            },
          ),
          if (!_isSignUp) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isBusy ? null : _sendPasswordReset,
                child: const Text('Şifremi unuttum'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: [
              _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
            ],
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if ((value ?? '').length < 8) {
                return 'Şifre en az 8 karakter olmalıdır.';
              }
              return null;
            },
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Şifreyi doğrula',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Şifreler eşleşmiyor.';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isBusy ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF101010),
                    ),
                  )
                : Text(_isSignUp ? 'Hesap oluştur' : 'Giriş yap'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isBusy
                ? null
                : () => setState(() {
                    _isSignUp = !_isSignUp;
                    _errorMessage = null;
                    _infoMessage = null;
                  }),
            child: Text(
              _isSignUp
                  ? 'Zaten hesabın var mı? Giriş yap'
                  : 'İlk kez mi kullanıyorsun? Hesap oluştur',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hesap bilgilerin Supabase Auth üzerinde güvenli şekilde saklanır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  // GİRİŞ EKRANI FORMU BİTİŞİ

  Widget _buildMessage(String text, {bool isError = false}) {
    final color = isError ? const Color(0xFFFF6B6B) : accentColor(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: TextStyle(color: color, height: 1.4)),
    );
  }
}

class LoginFeature extends StatelessWidget {
  const LoginFeature({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accentColor(context), size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
