import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://rvwwrhyeknagygybbvqz.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_7dmqmOpXQSPj2uztm7yfjw_QUswItSv';

const List<String> antiqueCategories = [
  'Bakır ve Pirinç Eşyalar',
  'Saatler ve Koleksiyonluk Ürünler',
  'Seramik ve Porselen',
  'Kitap, Belge ve Hat Eserleri',
  'Mobilya ve Dekorasyon',
  'Para, Madalya ve Koleksiyon',
  'Diğer',
];

String? _validateAuctionAmount(String? value, String fieldName) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) return '$fieldName girin.';

  final normalized = input.replaceAll(',', '.');
  final amount = double.tryParse(normalized);
  if (amount == null || !amount.isFinite || amount < 0) {
    return 'Geçerli bir $fieldName girin.';
  }
  if (amount >= 10000000000) {
    return '$fieldName en fazla 9.999.999.999,99 ₺ olabilir.';
  }
  final decimalPart = normalized.split('.').elementAtOrNull(1);
  if (decimalPart != null && decimalPart.length > 2) {
    return '$fieldName en fazla 2 ondalık basamak içerebilir.';
  }
  return null;
}

String _formatNumber(num value, {int decimalDigits = 0}) {
  final fixed = value.toStringAsFixed(decimalDigits);
  final parts = fixed.split('.');
  final isNegative = parts.first.startsWith('-');
  final integer = isNegative ? parts.first.substring(1) : parts.first;
  final groupedInteger = integer.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  final sign = isNegative ? '-' : '';
  if (decimalDigits == 0) return '$sign$groupedInteger';
  return '$sign$groupedInteger,${parts[1]}';
}

String _formatCurrency(num value) =>
    '${_formatNumber(value, decimalDigits: 2)} ₺';

String _formatDate(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const AntiqueAdminApp());
}

class AntiqueAdminApp extends StatelessWidget {
  const AntiqueAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF101010);

    return MaterialApp(
      title: 'Antika Yönetimi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101010),
          foregroundColor: Color(0xFFFFD76A),
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1B1B1B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF353020)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF202020),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
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
        return const _AuthLoadingPage();
      }
      if (auth.currentSession != null) {
        return const _PasswordRecoveryPage();
      }
      return _RecoveryLinkExpiredPage(
        onBackToLogin: () => setState(() => _isRecoveryFlow = false),
      );
    }
    if (auth.currentSession != null) return const AntiqueAdminPage();
    if (!_hasReceivedAuthState) return const _AuthLoadingPage();
    return const _LoginPage();
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
    );
  }
}

class _RecoveryLinkExpiredPage extends StatelessWidget {
  const _RecoveryLinkExpiredPage({required this.onBackToLogin});

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
                    const Icon(
                      Icons.link_off_rounded,
                      color: Color(0xFFFFD76A),
                      size: 44,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bağlantı kullanılamıyor',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Şifre yenileme bağlantısının süresi dolmuş veya '
                      'bağlantı daha önce kullanılmış olabilir. Giriş '
                      'ekranından yeni bir bağlantı iste.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.5),
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

class _PasswordRecoveryPage extends StatefulWidget {
  const _PasswordRecoveryPage();

  @override
  State<_PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<_PasswordRecoveryPage> {
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
                        color: const Color(0xFFFFD76A),
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
                        style: const TextStyle(
                          color: Colors.white60,
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

class _LoginPage extends StatefulWidget {
  const _LoginPage();

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
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
                              _buildBrandPanel(compact: true),
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
                              Expanded(child: _buildBrandPanel()),
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

  Widget _buildBrandPanel({bool compact = false}) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 0 : 520),
      padding: EdgeInsets.all(compact ? 28 : 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF30270F), Color(0xFF17140D), Color(0xFF101010)],
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
              color: const Color(0xFFFFD76A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x66FFD76A)),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD76A),
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ANTİKA\nYÖNETİMİ',
            style: TextStyle(
              color: Color(0xFFFFD76A),
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Değerli parçalarını güvenle yönet, '
            'koleksiyonunun her detayını tek yerde takip et.',
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
          if (!compact) ...[
            const SizedBox(height: 36),
            const _LoginFeature(
              icon: Icons.inventory_2_outlined,
              label: 'Envanter ve stok kontrolü',
            ),
            const SizedBox(height: 16),
            const _LoginFeature(
              icon: Icons.gavel_rounded,
              label: 'Açık artırma takibi',
            ),
            const SizedBox(height: 16),
            const _LoginFeature(
              icon: Icons.lock_outline_rounded,
              label: 'Hesabına özel güvenli erişim',
            ),
          ],
        ],
      ),
    );
  }

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
            style: const TextStyle(color: Colors.white60, height: 1.5),
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
                labelText: 'Ad soyad',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (_isSignUp && (value == null || value.trim().isEmpty)) {
                  return 'Ad soyad alanı zorunludur.';
                }
                return null;
              },
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
          const Text(
            'Hesap bilgilerin Supabase Auth üzerinde güvenli şekilde saklanır.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white38, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, {bool isError = false}) {
    final color = isError ? const Color(0xFFFF6B6B) : const Color(0xFFFFD76A);
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

class _LoginFeature extends StatelessWidget {
  const _LoginFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFD76A), size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class Antique {
  const Antique({
    this.id,
    required this.name,
    required this.category,
    required this.year,
    required this.history,
    required this.value,
    required this.quantity,
    required this.offer,
    required this.auctionLocation,
  });

  final int? id;
  final String name;
  final String category;
  final int year;
  final String history;
  final double value;
  final int quantity;
  final String offer;
  final String auctionLocation;
}

class Auction {
  const Auction({
    this.id,
    required this.productId,
    required this.startingPrice,
    required this.currentBid,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  final int? id;
  final int productId;
  final double startingPrice;
  final double currentBid;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
}

class AntiqueSale {
  const AntiqueSale({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.buyer,
    required this.soldAt,
  });

  final int id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String buyer;
  final DateTime soldAt;

  double get total => quantity * unitPrice;
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.createdAt,
  });

  final int id;
  final String productName;
  final String type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final DateTime createdAt;
}

class CustomerSummary {
  const CustomerSummary({
    required this.name,
    required this.purchaseCount,
    required this.itemCount,
    required this.totalSpent,
    required this.lastPurchase,
    required this.products,
  });

  final String name;
  final int purchaseCount;
  final int itemCount;
  final double totalSpent;
  final DateTime lastPurchase;
  final List<String> products;
}

class AntiqueAdminPage extends StatefulWidget {
  const AntiqueAdminPage({super.key});

  @override
  State<AntiqueAdminPage> createState() => _AntiqueAdminPageState();
}

class _AntiqueAdminPageState extends State<AntiqueAdminPage> {
  final List<Antique> _antiques = [];
  final List<Auction> _auctions = [];
  final List<AntiqueSale> _sales = [];
  final List<StockMovement> _stockMovements = [];
  _AdminPage _currentPage = _AdminPage.menu;
  bool _isLoading = true;
  String? _loadError;
  String? _salesError;
  String? _stockMovementsError;

  SupabaseClient get _supabase => Supabase.instance.client;

  List<CustomerSummary> get _customers {
    final grouped = <String, List<AntiqueSale>>{};
    for (final sale in _sales) {
      final name = sale.buyer.trim();
      if (name.isEmpty) continue;
      grouped.putIfAbsent(name.toLowerCase(), () => []).add(sale);
    }

    final summaries = grouped.values.map((customerSales) {
      final latestFirst = [...customerSales]
        ..sort((a, b) => b.soldAt.compareTo(a.soldAt));
      final products = customerSales
          .map((sale) => sale.productName)
          .toSet()
          .toList();
      return CustomerSummary(
        name: latestFirst.first.buyer.trim(),
        purchaseCount: customerSales.length,
        itemCount: customerSales.fold<int>(
          0,
          (sum, sale) => sum + sale.quantity,
        ),
        totalSpent: customerSales.fold<double>(
          0,
          (sum, sale) => sum + sale.total,
        ),
        lastPurchase: latestFirst.first.soldAt,
        products: products,
      );
    }).toList()..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return summaries;
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Çıkış yapılamadı: $error')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAntiques();
    _loadAuctions();
    _loadSales();
    _loadStockMovements();
  }

  Future<void> _loadAntiques() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final rows = await _supabase.from('urunler').select().order('id');
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        final offerValue = item['teklif'] ?? item['teklif_miktari'] ?? 0;
        final auctionLocationValue =
            item['acik_arttirma_yeri'] ??
            item['acik_artirma_yeri'] ??
            item['acik_arttirma_yeri'] ??
            item['acik_arttirma_yeri'] ??
            item['acik_arttirma_yer'] ??
            '';

        return Antique(
          id: (item['id'] as num).toInt(),
          name: (item['ad'] ?? '').toString(),
          category: (item['kategori'] ?? 'Diğer').toString(),
          year: (item['antika_yili'] as num?)?.toInt() ?? 0,
          history: (item['aciklama'] ?? '').toString(),
          value: (item['satis_fiyati'] as num?)?.toDouble() ?? 0,
          quantity: (item['stok'] as num?)?.toInt() ?? 0,
          offer: offerValue.toString(),
          auctionLocation: auctionLocationValue.toString(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _antiques
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _loadAuctions() async {
    try {
      final rows = await _supabase.from('acik_artirmalar').select().order('id');
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        return Auction(
          id: (item['id'] as num?)?.toInt(),
          productId: (item['urun_id'] as num?)?.toInt() ?? 0,
          startingPrice: (item['baslangic_fiyati'] as num?)?.toDouble() ?? 0,
          currentBid: (item['mevcut_teklif'] as num?)?.toDouble() ?? 0,
          startDate:
              DateTime.tryParse((item['baslangic_tarihi'] ?? '').toString()) ??
              DateTime.now(),
          endDate:
              DateTime.tryParse((item['bitis_tarihi'] ?? '').toString()) ??
              DateTime.now(),
          status: (item['durum'] ?? 'Aktif').toString(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _auctions
          ..clear()
          ..addAll(loaded);
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Açık artırma yükleme hatası: $error');
    }
  }

  Future<void> _loadSales() async {
    try {
      final rows = await _supabase
          .from('satislar')
          .select()
          .order('satis_tarihi', ascending: false);
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        return AntiqueSale(
          id: (item['id'] as num).toInt(),
          productName: (item['urun_adi'] ?? '').toString(),
          quantity: (item['adet'] as num).toInt(),
          unitPrice: (item['birim_fiyat'] as num).toDouble(),
          buyer: (item['alici'] ?? '').toString(),
          soldAt:
              DateTime.tryParse((item['satis_tarihi'] ?? '').toString()) ??
              DateTime.now(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _sales
          ..clear()
          ..addAll(loaded);
        _salesError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _salesError = error.toString());
      debugPrint('Satış kayıtları yüklenemedi: $error');
    }
  }

  Future<void> _loadStockMovements() async {
    try {
      final rows = await _supabase
          .from('stok_hareketleri')
          .select()
          .order('created_at', ascending: false)
          .limit(300);
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        return StockMovement(
          id: (item['id'] as num).toInt(),
          productName: (item['urun_adi'] ?? 'Silinmiş ürün').toString(),
          type: (item['hareket_tipi'] ?? 'Stok hareketi').toString(),
          quantity: (item['miktar'] as num?)?.toInt() ?? 0,
          previousStock: (item['onceki_stok'] as num?)?.toInt() ?? 0,
          newStock: (item['yeni_stok'] as num?)?.toInt() ?? 0,
          createdAt:
              DateTime.tryParse((item['created_at'] ?? '').toString()) ??
              DateTime.now(),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _stockMovements
          ..clear()
          ..addAll(loaded);
        _stockMovementsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _stockMovementsError = error.toString());
      debugPrint('Stok hareketleri yüklenemedi: $error');
    }
  }

  Future<void> _saveSale({
    required Antique antique,
    required int quantity,
    required double unitPrice,
    required String buyer,
  }) async {
    try {
      await _supabase.rpc(
        'satis_olustur',
        params: {
          'p_urun_id': antique.id,
          'p_adet': quantity,
          'p_birim_fiyat': unitPrice,
          'p_alici': buyer,
        },
      );

      await Future.wait([_loadAntiques(), _loadSales(), _loadStockMovements()]);
      if (!mounted) return;
      setState(() => _currentPage = _AdminPage.sales);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satış kaydedildi ve stok güncellendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satış kaydedilemedi: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _insertAntique(Antique antique) async {
    final result = await _supabase.from('urunler').insert({
      'ad': antique.name,
      'kategori': antique.category,
      'antika_yili': antique.year,
      'aciklama': antique.history,
      'alis_fiyati': 0,
      'satis_fiyati': antique.value,
      'stok': antique.quantity,
      'teklif': antique.offer,
      'acik_arttirma_yeri': antique.auctionLocation,
    }).select();

    debugPrint('SUPABASE KAYIT SONUCU: $result');
  }

  Future<void> _saveAuction(Auction auction) async {
    try {
      await _supabase.from('acik_artirmalar').insert({
        'urun_id': auction.productId,
        'baslangic_fiyati': auction.startingPrice,
        'mevcut_teklif': auction.currentBid,
        'baslangic_tarihi': auction.startDate.toUtc().toIso8601String(),
        'bitis_tarihi': auction.endDate.toUtc().toIso8601String(),
        'durum': auction.status,
      }).select();

      await _loadAuctions();
      if (!mounted) return;
      setState(() => _currentPage = _AdminPage.auction);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Açık artırma kaydı oluşturuldu.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Açık artırma kaydı oluşturulamadı: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _deleteAuction(Auction auction) async {
    if (auction.id == null) return;

    try {
      await _supabase.from('acik_artirmalar').delete().eq('id', auction.id!);
      await _loadAuctions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Açık artırma kaydı silindi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme işlemi başarısız: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _saveAntique(Antique antique) async {
    final matchingIndices = <int>[];
    for (var i = 0; i < _antiques.length; i++) {
      if (_antiques[i].name.trim().toLowerCase() ==
          antique.name.trim().toLowerCase()) {
        matchingIndices.add(i);
      }
    }

    try {
      if (matchingIndices.isNotEmpty) {
        final selectedIndex = await showDialog<int>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Bu antika zaten kayıtlı'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '"${antique.name}" adlı ürün için hangi kayda '
                      '${_formatNumber(antique.quantity)} adet eklemek istiyorsun?',
                    ),
                    const SizedBox(height: 12),
                    ...matchingIndices.map((index) {
                      final existing = _antiques[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(existing.name),
                          subtitle: Text(
                            'Kategori: ${existing.category}\n'
                            'Yıl: ${existing.year} • Mevcut adet: ${_formatNumber(existing.quantity)}\n'
                            'Değer: ${_formatCurrency(existing.value)}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => Navigator.pop(dialogContext, index),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, -1),
                      icon: const Icon(Icons.add),
                      label: const Text('Hayır, ayrı kayıt oluştur'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
            ],
          ),
        );

        if (!mounted || selectedIndex == null) return;

        if (selectedIndex == -1) {
          await _insertAntique(antique);
        } else {
          final existing = _antiques[selectedIndex];
          if (existing.id == null) {
            throw Exception('Seçilen kaydın veritabanı kimliği bulunamadı.');
          }
          await _supabase
              .from('urunler')
              .update({'stok': existing.quantity + antique.quantity})
              .eq('id', existing.id!);
        }

        await _loadAntiques();
        await _loadStockMovements();
        if (!mounted) return;
        setState(() => _currentPage = _AdminPage.menu);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedIndex == -1
                  ? 'Ayrı antika kaydı oluşturuldu.'
                  : 'Seçtiğin kaydın stok adedi artırıldı.',
            ),
          ),
        );
        return;
      }

      await _insertAntique(antique);
      await _loadAntiques();
      await _loadStockMovements();
      if (!mounted) return;
      setState(() => _currentPage = _AdminPage.menu);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antika kaydı oluşturuldu.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme başarısız: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _deleteAntique(Antique antique) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ürünü sil'),
        content: Text(
          '"${antique.name}" adlı ürünü silmek istediğine emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true || antique.id == null) return;

    try {
      await _supabase.from('urunler').delete().eq('id', antique.id!);
      await _loadAntiques();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ürün başarıyla silindi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme işlemi başarısız: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Antika Yönetimi'),
          actions: [
            IconButton(
              tooltip: 'Çıkış yap',
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Color(0xFFD4AF37)),
                const SizedBox(height: 12),
                const Text('Supabase bağlantısı kurulamadı.'),
                const SizedBox(height: 8),
                SelectableText(_loadError!),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadAntiques,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Widget page;
    switch (_currentPage) {
      case _AdminPage.menu:
        page = _AdminMenu(
          antiqueCount: _antiques.length,
          totalStock: _antiques.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          ),
          totalValue: _antiques.fold<double>(
            0,
            (sum, item) => sum + item.value * item.quantity,
          ),
          categoryCount: _antiques.map((item) => item.category).toSet().length,
          onSignOut: _signOut,
          onCreateAntique: () =>
              setState(() => _currentPage = _AdminPage.create),
          onShowAntiques: () => setState(() => _currentPage = _AdminPage.list),
          onShowAuctions: () =>
              setState(() => _currentPage = _AdminPage.auction),
          onShowSales: () => setState(() => _currentPage = _AdminPage.sales),
          onShowReports: () =>
              setState(() => _currentPage = _AdminPage.reports),
          onShowCustomers: () =>
              setState(() => _currentPage = _AdminPage.customers),
          onShowStockMovements: () =>
              setState(() => _currentPage = _AdminPage.stockMovements),
        );
      case _AdminPage.create:
        page = _AddAntiquePage(
          onCancel: () => setState(() => _currentPage = _AdminPage.menu),
          onSave: _saveAntique,
        );
      case _AdminPage.list:
        page = _AntiqueListPage(
          antiques: _antiques,
          onBack: () => setState(() => _currentPage = _AdminPage.menu),
          onCreateAntique: () =>
              setState(() => _currentPage = _AdminPage.create),
          onDelete: _deleteAntique,
        );
      case _AdminPage.auction:
        page = _AuctionPage(
          auctions: _auctions,
          antiques: _antiques,
          onBack: () => setState(() => _currentPage = _AdminPage.menu),
          onCreateAuction: () =>
              setState(() => _currentPage = _AdminPage.createAuction),
          onDelete: _deleteAuction,
        );
      case _AdminPage.createAuction:
        page = _AddAuctionPage(
          antiques: _antiques,
          onCancel: () => setState(() => _currentPage = _AdminPage.auction),
          onSave: _saveAuction,
        );
      case _AdminPage.sales:
        page = _SalesPage(
          sales: _sales,
          error: _salesError,
          onBack: () => setState(() => _currentPage = _AdminPage.menu),
          onCreateSale: () =>
              setState(() => _currentPage = _AdminPage.createSale),
        );
      case _AdminPage.createSale:
        page = _CreateSalePage(
          antiques: _antiques,
          onCancel: () => setState(() => _currentPage = _AdminPage.sales),
          onSave: _saveSale,
        );
      case _AdminPage.reports:
        page = _ReportsPage(
          antiques: _antiques,
          auctions: _auctions,
          sales: _sales,
          onBack: () => setState(() => _currentPage = _AdminPage.menu),
        );
      case _AdminPage.customers:
        page = _CustomersPage(
          customers: _customers,
          error: _salesError,
          onBack: () => setState(() => _currentPage = _AdminPage.menu),
        );
      case _AdminPage.stockMovements:
        page = _StockMovementsPage(
          movements: _stockMovements,
          error: _stockMovementsError,
          onBack: () => setState(() => _currentPage = _AdminPage.menu),
          onRefresh: _loadStockMovements,
        );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 850;
        if (!showSidebar) return page;
        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 245,
                decoration: const BoxDecoration(
                  color: Color(0xFF080808),
                  border: Border(right: BorderSide(color: Color(0xFF3A3016))),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(22, 26, 18, 24),
                        child: Row(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Color(0xFFFFD76A),
                              size: 34,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ANTİKA YÖNETİMİ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  height: 1.3,
                                  color: Color(0xFFFFD76A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(color: Color(0xFF3A3016)),
                      ),
                      const SizedBox(height: 12),
                      _SidebarItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Genel Bakış',
                        selected: _currentPage == _AdminPage.menu,
                        onTap: () =>
                            setState(() => _currentPage = _AdminPage.menu),
                      ),
                      _SidebarItem(
                        icon: Icons.inventory_2_rounded,
                        label: 'Ürünler',
                        selected: _currentPage == _AdminPage.list,
                        onTap: () =>
                            setState(() => _currentPage = _AdminPage.list),
                      ),
                      _SidebarItem(
                        icon: Icons.add_box_rounded,
                        label: 'Yeni Ürün Ekle',
                        selected: _currentPage == _AdminPage.create,
                        onTap: () =>
                            setState(() => _currentPage = _AdminPage.create),
                      ),
                      _SidebarItem(
                        icon: Icons.gavel_rounded,
                        label: 'Açık Artırma',
                        selected:
                            _currentPage == _AdminPage.auction ||
                            _currentPage == _AdminPage.createAuction,
                        onTap: () =>
                            setState(() => _currentPage = _AdminPage.auction),
                      ),
                      _SidebarItem(
                        icon: Icons.point_of_sale_rounded,
                        label: 'Satışlar',
                        selected:
                            _currentPage == _AdminPage.sales ||
                            _currentPage == _AdminPage.createSale,
                        onTap: () =>
                            setState(() => _currentPage = _AdminPage.sales),
                      ),
                      _SidebarItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Raporlar',
                        selected: _currentPage == _AdminPage.reports,
                        onTap: () =>
                            setState(() => _currentPage = _AdminPage.reports),
                      ),
                      _SidebarItem(
                        icon: Icons.people_alt_rounded,
                        label: 'Müşteriler',
                        selected: _currentPage == _AdminPage.customers,
                        onTap: () =>
                            setState(() => _currentPage = _AdminPage.customers),
                      ),
                      _SidebarItem(
                        icon: Icons.swap_vert_circle_outlined,
                        label: 'Stok Hareketleri',
                        selected: _currentPage == _AdminPage.stockMovements,
                        onTap: () => setState(
                          () => _currentPage = _AdminPage.stockMovements,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17140D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF3A3016)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YAPIMCILAR',
                              style: TextStyle(
                                color: Color(0xFFFFD76A),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 12),
                            _SidebarCreator(name: 'Yusuf Alparslan Kala'),
                            SizedBox(height: 10),
                            _SidebarCreator(name: 'Ömer Mithat Kayaoğlu'),
                          ],
                        ),
                      ),
                      _SidebarItem(
                        icon: Icons.logout_rounded,
                        label: 'Çıkış yap',
                        selected: false,
                        onTap: _signOut,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'STOK TAKİP SİSTEMİ  •  v1.0',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: page),
            ],
          ),
        );
      },
    );
  }
}

enum _AdminPage {
  menu,
  create,
  list,
  auction,
  createAuction,
  sales,
  createSale,
  reports,
  customers,
  stockMovements,
}

class _AdminMenu extends StatelessWidget {
  const _AdminMenu({
    required this.antiqueCount,
    required this.totalStock,
    required this.totalValue,
    required this.categoryCount,
    required this.onSignOut,
    required this.onCreateAntique,
    required this.onShowAntiques,
    required this.onShowAuctions,
    required this.onShowSales,
    required this.onShowReports,
    required this.onShowCustomers,
    required this.onShowStockMovements,
  });

  final int antiqueCount;
  final int totalStock;
  final double totalValue;
  final int categoryCount;
  final VoidCallback onSignOut;
  final VoidCallback onCreateAntique;
  final VoidCallback onShowAntiques;
  final VoidCallback onShowAuctions;
  final VoidCallback onShowSales;
  final VoidCallback onShowReports;
  final VoidCallback onShowCustomers;
  final VoidCallback onShowStockMovements;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Bakış'),
        actions: [
          IconButton(
            tooltip: 'Çıkış yap',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoş geldin 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Antika envanterinin güncel durumuna göz at.'),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 1050
                    ? 4
                    : constraints.maxWidth > 600
                    ? 2
                    : 1;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * 14) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        icon: Icons.inventory_2_rounded,
                        title: 'Toplam ürün',
                        value: _formatNumber(antiqueCount),
                        subtitle: 'Kayıtlı ürün çeşidi',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        icon: Icons.layers_rounded,
                        title: 'Toplam stok',
                        value: _formatNumber(totalStock),
                        subtitle: 'Depodaki toplam adet',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Stok değeri',
                        value: _formatCurrency(totalValue),
                        subtitle: 'Satış fiyatı × stok',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        icon: Icons.category_rounded,
                        title: 'Kategoriler',
                        value: _formatNumber(categoryCount),
                        subtitle: 'Kullanılan kategori',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hızlı işlemler',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Envanterini buradan yönetebilirsin.'),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: onCreateAntique,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Yeni ürün ekle'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowAntiques,
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('Ürünleri görüntüle'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowAuctions,
                          icon: const Icon(Icons.gavel_rounded),
                          label: const Text('Açık artırma'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowSales,
                          icon: const Icon(Icons.point_of_sale_rounded),
                          label: const Text('Satışlar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowReports,
                          icon: const Icon(Icons.bar_chart_rounded),
                          label: const Text('Raporları görüntüle'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowCustomers,
                          icon: const Icon(Icons.people_alt_rounded),
                          label: const Text('Müşteriler'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowStockMovements,
                          icon: const Icon(Icons.swap_vert_circle_outlined),
                          label: const Text('Stok hareketleri'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesPage extends StatelessWidget {
  const _SalesPage({
    required this.sales,
    required this.error,
    required this.onBack,
    required this.onCreateSale,
  });

  final List<AntiqueSale> sales;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onCreateSale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Satışlar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: onCreateSale,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Satış kaydet'),
            ),
          ),
        ],
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText('Satışlar yüklenemedi: $error'),
              ),
            )
          : sales.isEmpty
          ? const Center(
              child: Text('Henüz satış kaydı yok. İlk satışı kaydedebilirsin.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: sales.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sale = sales[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF30270F),
                      child: Icon(
                        Icons.sell_outlined,
                        color: Color(0xFFFFD76A),
                      ),
                    ),
                    title: Text(sale.productName),
                    subtitle: Text(
                      '${_formatNumber(sale.quantity)} adet × '
                      '${_formatCurrency(sale.unitPrice)}'
                      '${sale.buyer.isEmpty ? '' : ' • ${sale.buyer}'}'
                      ' • ${_formatDate(sale.soldAt)}',
                    ),
                    trailing: Text(
                      _formatCurrency(sale.total),
                      style: const TextStyle(
                        color: Color(0xFFFFD76A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CreateSalePage extends StatefulWidget {
  const _CreateSalePage({
    required this.antiques,
    required this.onCancel,
    required this.onSave,
  });

  final List<Antique> antiques;
  final VoidCallback onCancel;
  final Future<void> Function({
    required Antique antique,
    required int quantity,
    required double unitPrice,
    required String buyer,
  })
  onSave;

  @override
  State<_CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends State<_CreateSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _buyerController = TextEditingController();
  int? _selectedProductId;
  bool _isSaving = false;

  List<Antique> get _availableAntiques => widget.antiques
      .where((antique) => antique.id != null && antique.quantity > 0)
      .toList();

  Antique? get _selectedAntique {
    for (final antique in _availableAntiques) {
      if (antique.id == _selectedProductId) return antique;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final first = _availableAntiques.firstOrNull;
    _selectedProductId = first?.id;
    if (first != null) {
      _priceController.text = first.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _buyerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final antique = _selectedAntique;
    if (antique == null || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        antique: antique,
        quantity: int.parse(_quantityController.text.trim()),
        unitPrice: double.parse(
          _priceController.text.trim().replaceAll(',', '.'),
        ),
        buyer: _buyerController.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableAntiques;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Satışlara dön',
        ),
        title: const Text('Satış kaydet'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: available.isEmpty
                    ? const Text(
                        'Satış yapabilmek için stokta ürünü olan bir kayıt '
                        'bulunmalıdır.',
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _selectedProductId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Ürün',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              items: available
                                  .map(
                                    (antique) => DropdownMenuItem<int>(
                                      value: antique.id,
                                      child: Text(
                                        '${antique.name} • stok: '
                                        '${_formatNumber(antique.quantity)}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isSaving
                                  ? null
                                  : (id) {
                                      final selected = available
                                          .where((item) => item.id == id)
                                          .firstOrNull;
                                      setState(() {
                                        _selectedProductId = id;
                                        _quantityController.text = '1';
                                        _priceController.text =
                                            selected?.value.toStringAsFixed(
                                              2,
                                            ) ??
                                            '';
                                      });
                                    },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Satılan adet',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                final quantity = int.tryParse(value ?? '');
                                if (quantity == null || quantity < 1) {
                                  return 'Geçerli bir adet girin.';
                                }
                                final selected = _selectedAntique;
                                if (selected != null &&
                                    quantity > selected.quantity) {
                                  return 'Stokta yalnızca '
                                      '${_formatNumber(selected.quantity)} adet var.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Birim satış fiyatı (₺)',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9,.]'),
                                ),
                              ],
                              validator: (value) {
                                final price = double.tryParse(
                                  (value ?? '').trim().replaceAll(',', '.'),
                                );
                                if (price == null ||
                                    !price.isFinite ||
                                    price < 0) {
                                  return 'Geçerli bir fiyat girin.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _buyerController,
                              decoration: const InputDecoration(
                                labelText: 'Alıcı (isteğe bağlı)',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _isSaving ? null : _save,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Satışı kaydet'),
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

class _ReportsPage extends StatelessWidget {
  const _ReportsPage({
    required this.antiques,
    required this.auctions,
    required this.sales,
    required this.onBack,
  });

  final List<Antique> antiques;
  final List<Auction> auctions;
  final List<AntiqueSale> sales;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final stockCount = antiques.fold<int>(
      0,
      (sum, antique) => sum + antique.quantity,
    );
    final stockValue = antiques.fold<double>(
      0,
      (sum, antique) => sum + antique.value * antique.quantity,
    );
    final revenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final soldCount = sales.fold<int>(0, (sum, sale) => sum + sale.quantity);
    final categories = <String, int>{};
    for (final antique in antiques) {
      categories.update(
        antique.category,
        (count) => count + antique.quantity,
        ifAbsent: () => antique.quantity,
      );
    }
    final maxCategoryCount = categories.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Raporlar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 14) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: width,
                      child: _StatCard(
                        icon: Icons.layers_rounded,
                        title: 'Mevcut stok',
                        value: _formatNumber(stockCount),
                        subtitle: 'Satışta olan toplam adet',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _StatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Tahmini stok değeri',
                        value: _formatCurrency(stockValue),
                        subtitle: 'Ürün fiyatı × mevcut stok',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _StatCard(
                        icon: Icons.payments_rounded,
                        title: 'Toplam satış geliri',
                        value: _formatCurrency(revenue),
                        subtitle: '${_formatNumber(soldCount)} adet satıldı',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _StatCard(
                        icon: Icons.gavel_rounded,
                        title: 'Açık artırmalar',
                        value: '${auctions.length}',
                        subtitle: 'Kayıtlı açık artırma',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategoriye göre stok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (categories.isEmpty)
                      const Text('Raporlanacak ürün bulunmuyor.')
                    else
                      ...categories.entries.map((entry) {
                        final ratio = maxCategoryCount == 0
                            ? 0.0
                            : entry.value / maxCategoryCount;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(entry.key)),
                                  Text('${_formatNumber(entry.value)} adet'),
                                ],
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFF30270F),
                                  color: const Color(0xFFFFD76A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomersPage extends StatelessWidget {
  const _CustomersPage({
    required this.customers,
    required this.error,
    required this.onBack,
  });

  final List<CustomerSummary> customers;
  final String? error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Müşteriler'),
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Müşteri satış kayıtları yüklenemedi.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : customers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Müşteri listesi, satış kaydederken alıcı adı '
                  'girildikçe burada oluşur.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: customers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF30270F),
                      child: Text(
                        customer.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFFFD76A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(customer.name),
                    subtitle: Text(
                      '${_formatNumber(customer.purchaseCount)} satış • '
                      '${_formatNumber(customer.itemCount)} ürün • '
                      'Son alışveriş ${_formatDate(customer.lastPurchase)}',
                    ),
                    trailing: Text(
                      _formatCurrency(customer.totalSpent),
                      style: const TextStyle(
                        color: Color(0xFFFFD76A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(72, 0, 20, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Aldığı ürünler: ${customer.products.join(', ')}',
                            style: const TextStyle(color: Colors.white70),
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

class _StockMovementsPage extends StatelessWidget {
  const _StockMovementsPage({
    required this.movements,
    required this.error,
    required this.onBack,
    required this.onRefresh,
  });

  final List<StockMovement> movements;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Stok Hareketleri'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Stok hareketleri yüklenemedi. Supabase SQL kurulumunu '
                  'çalıştırdıktan sonra yenile.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : movements.isEmpty
          ? const Center(child: Text('Henüz stok hareketi kaydedilmemiş.'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: movements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final movement = movements[index];
                final isDecrease = movement.newStock < movement.previousStock;
                final color = isDecrease
                    ? const Color(0xFFFF8A80)
                    : const Color(0xFFFFD76A);
                final difference = movement.newStock - movement.previousStock;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(
                        isDecrease
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: color,
                      ),
                    ),
                    title: Text(movement.productName),
                    subtitle: Text(
                      '${movement.type} • '
                      '${_formatDate(movement.createdAt)} '
                      '${movement.createdAt.toLocal().hour.toString().padLeft(2, '0')}:'
                      '${movement.createdAt.toLocal().minute.toString().padLeft(2, '0')}'
                      '\nStok: ${_formatNumber(movement.previousStock)} → '
                      '${_formatNumber(movement.newStock)}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      '${difference > 0 ? '+' : ''}${_formatNumber(difference)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3016),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFFD76A)),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFD76A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarCreator extends StatelessWidget {
  const _SidebarCreator({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.person_outline_rounded,
          color: Color(0xFFFFD76A),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Yapımcı',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        selected: widget.selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedTileColor: const Color(0xFF30270F),
        leading: AnimatedRotation(
          turns: _turns,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          child: Icon(
            widget.icon,
            color: widget.selected ? const Color(0xFFFFD76A) : Colors.white60,
          ),
        ),
        title: Text(
          widget.label,
          style: TextStyle(
            color: widget.selected ? const Color(0xFFFFD76A) : Colors.white70,
            fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() => _turns += 1);
          widget.onTap();
        },
      ),
    );
  }
}

class _AuctionPage extends StatefulWidget {
  const _AuctionPage({
    required this.auctions,
    required this.antiques,
    required this.onBack,
    required this.onCreateAuction,
    required this.onDelete,
  });

  final List<Auction> auctions;
  final List<Antique> antiques;
  final VoidCallback onBack;
  final VoidCallback onCreateAuction;
  final Future<void> Function(Auction) onDelete;

  @override
  State<_AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<_AuctionPage> {
  String _selectedStatus = 'Tümü';

  List<Auction> get _filteredAuctions {
    return widget.auctions.where((auction) {
      final matchesStatus =
          _selectedStatus == 'Tümü' || auction.status == _selectedStatus;
      return matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = ['Tümü', 'Aktif', 'Bekliyor', 'Tamamlandı', 'İptal'];
    final visibleAuctions = _filteredAuctions;
    final antiquesById = {
      for (final antique in widget.antiques)
        if (antique.id != null) antique.id!: antique,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Açık Artırma'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: widget.onCreateAuction,
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Durum filtresi',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items: statusOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                ),
                Text('${visibleAuctions.length} açık artırma'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: visibleAuctions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gavel_outlined,
                                size: 48,
                                color: Colors.white60,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.auctions.isEmpty
                                    ? 'Henüz açık artırma kaydı yok.'
                                    : 'Bu duruma uygun açık artırma bulunamadı.',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Ürün')),
                              DataColumn(label: Text('Kategori')),
                              DataColumn(label: Text('Stok')),
                              DataColumn(label: Text('Ürün Değeri')),
                              DataColumn(label: Text('Başlangıç Fiyatı')),
                              DataColumn(label: Text('Mevcut Teklif')),
                              DataColumn(label: Text('Başlangıç Tarihi')),
                              DataColumn(label: Text('Bitiş Tarihi')),
                              DataColumn(label: Text('Durum')),
                              DataColumn(label: Text('İşlem')),
                            ],
                            rows: visibleAuctions.map((auction) {
                              final product = antiquesById[auction.productId];
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      product?.name ??
                                          'Ürün #${auction.productId}',
                                    ),
                                  ),
                                  DataCell(Text(product?.category ?? '—')),
                                  DataCell(
                                    Text(
                                      product == null
                                          ? '—'
                                          : '${_formatNumber(product.quantity)} adet',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      product == null
                                          ? '—'
                                          : _formatCurrency(product.value),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatCurrency(auction.startingPrice),
                                    ),
                                  ),
                                  DataCell(
                                    Text(_formatCurrency(auction.currentBid)),
                                  ),
                                  DataCell(
                                    Text(_formatDate(auction.startDate)),
                                  ),
                                  DataCell(Text(_formatDate(auction.endDate))),
                                  DataCell(Text(auction.status)),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'Açık artırmayı sil',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFFF6B6B),
                                      ),
                                      onPressed: () => widget.onDelete(auction),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAuctionPage extends StatefulWidget {
  const _AddAuctionPage({
    required this.antiques,
    required this.onCancel,
    required this.onSave,
  });

  final List<Antique> antiques;
  final VoidCallback onCancel;
  final Future<void> Function(Auction) onSave;

  @override
  State<_AddAuctionPage> createState() => _AddAuctionPageState();
}

class _AddAuctionPageState extends State<_AddAuctionPage> {
  final _formKey = GlobalKey<FormState>();
  final _startingPriceController = TextEditingController();
  final _currentBidController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  String _selectedStatus = 'Aktif';
  int? _selectedProductId;

  List<Antique> get _availableAntiques => widget.antiques
      .where((antique) => antique.id != null && antique.quantity > 0)
      .toList();

  Antique? get _selectedAntique {
    for (final antique in _availableAntiques) {
      if (antique.id == _selectedProductId) return antique;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final firstAntique = _availableAntiques.firstOrNull;
    _selectedProductId = firstAntique?.id;
    if (firstAntique != null) {
      _startingPriceController.text = firstAntique.value.toStringAsFixed(2);
      _currentBidController.text = '0';
    }
  }

  @override
  void dispose() {
    _startingPriceController.dispose();
    _currentBidController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final productId = _selectedProductId;
    if (productId == null) return;

    final startDate = DateTime.tryParse(_startDateController.text.trim());
    final endDate = DateTime.tryParse(_endDateController.text.trim());

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Başlangıç ve bitiş tarihleri için geçerli tarih girin.',
          ),
        ),
      );
      return;
    }

    await widget.onSave(
      Auction(
        productId: productId,
        startingPrice: double.parse(
          _startingPriceController.text.trim().replaceAll(',', '.'),
        ),
        currentBid: double.parse(
          _currentBidController.text.trim().replaceAll(',', '.'),
        ),
        startDate: startDate,
        endDate: endDate,
        status: _selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Yeni Açık Artırma'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Açık Artırma Bilgileri',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  if (_availableAntiques.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Açık artırma oluşturmak için stokta ürünü olan '
                          'bir antika kaydı bulunmalıdır.',
                        ),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<int>(
                      initialValue: _selectedProductId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ürün seç',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableAntiques
                          .map(
                            (antique) => DropdownMenuItem<int>(
                              value: antique.id,
                              child: Text(
                                '${antique.name} • ${antique.category} • '
                                'Stok: ${_formatNumber(antique.quantity)} • '
                                '${_formatCurrency(antique.value)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (value) =>
                          value == null ? 'Bir ürün seçin.' : null,
                      onChanged: (id) {
                        final selected = _availableAntiques
                            .where((antique) => antique.id == id)
                            .firstOrNull;
                        setState(() {
                          _selectedProductId = id;
                          if (selected != null) {
                            _startingPriceController.text = selected.value
                                .toStringAsFixed(2);
                          }
                        });
                      },
                    ),
                    if (_selectedAntique != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Seçilen ürün: ${_selectedAntique!.name} • '
                        '${_selectedAntique!.category} • '
                        '${_formatNumber(_selectedAntique!.quantity)} adet stok • '
                        '${_formatCurrency(_selectedAntique!.value)}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _startingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç fiyatı (₺)',
                      hintText: 'Örn. 2500',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    validator: (value) =>
                        _validateAuctionAmount(value, 'Başlangıç fiyatı'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentBidController,
                    decoration: const InputDecoration(
                      labelText: 'Mevcut teklif (₺)',
                      hintText: 'Örn. 3200',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    validator: (value) =>
                        _validateAuctionAmount(value, 'Mevcut teklif'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç tarihi',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Başlangıç tarihini girin.';
                      }
                      return DateTime.tryParse(value.trim()) == null
                          ? 'Geçerli tarih girin.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Bitiş tarihi',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitiş tarihini girin.';
                      }
                      return DateTime.tryParse(value.trim()) == null
                          ? 'Geçerli tarih girin.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                      DropdownMenuItem(
                        value: 'Bekliyor',
                        child: Text('Bekliyor'),
                      ),
                      DropdownMenuItem(
                        value: 'Tamamlandı',
                        child: Text('Tamamlandı'),
                      ),
                      DropdownMenuItem(value: 'İptal', child: Text('İptal')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AntiqueListPage extends StatefulWidget {
  const _AntiqueListPage({
    required this.antiques,
    required this.onBack,
    required this.onCreateAntique,
    required this.onDelete,
  });

  final List<Antique> antiques;
  final VoidCallback onBack;
  final VoidCallback onCreateAntique;
  final Future<void> Function(Antique) onDelete;

  @override
  State<_AntiqueListPage> createState() => _AntiqueListPageState();
}

class _AntiqueListPageState extends State<_AntiqueListPage> {
  String _selectedCategory = 'Tüm kategoriler';
  String _searchText = '';

  List<Antique> get _filteredAntiques {
    return widget.antiques.where((antique) {
      final matchesCategory =
          _selectedCategory == 'Tüm kategoriler' ||
          antique.category == _selectedCategory;
      final matchesSearch = antique.name.toLowerCase().contains(
        _searchText.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleAntiques = _filteredAntiques;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Antika Kayıtları'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: widget.onCreateAntique,
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ürün ara',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchText = value.trim());
                    },
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategori filtresi',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'Tüm kategoriler',
                        child: Text(
                          'Tüm kategoriler',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ...antiqueCategories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
                Text('${visibleAntiques.length} kayıt'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: visibleAntiques.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.antiques.isEmpty
                                    ? 'Henüz antika kaydı yok.'
                                    : 'Bu aramaya uygun ürün bulunamadı.',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Arama veya kategori filtresini değiştirebilirsin.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Antika Adı')),
                              DataColumn(label: Text('Kategori')),
                              DataColumn(label: Text('Antika Yılı')),
                              DataColumn(label: Text('Teklif')),
                              DataColumn(label: Text('Açık Artırma Yeri')),
                              DataColumn(label: Text('Tarihsel Geçmişi')),
                              DataColumn(label: Text('Değeri')),
                              DataColumn(label: Text('Adet')),
                              DataColumn(label: Text('İşlem')),
                            ],
                            rows: visibleAntiques.map((antique) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(antique.name)),
                                  DataCell(Text(antique.category)),
                                  DataCell(Text(antique.year.toString())),
                                  DataCell(Text(antique.offer)),
                                  DataCell(Text(antique.auctionLocation)),
                                  DataCell(
                                    SizedBox(
                                      width: 280,
                                      child: Text(
                                        antique.history,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(_formatCurrency(antique.value)),
                                  ),
                                  DataCell(
                                    Text(_formatNumber(antique.quantity)),
                                  ),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'Ürünü sil',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: const Color(0xFFFF6B6B),
                                      ),
                                      onPressed: () => widget.onDelete(antique),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAntiquePage extends StatefulWidget {
  const _AddAntiquePage({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final Future<void> Function(Antique) onSave;

  @override
  State<_AddAntiquePage> createState() => _AddAntiquePageState();
}

class _AddAntiquePageState extends State<_AddAntiquePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _historyController = TextEditingController();
  final _valueController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _offerController = TextEditingController();
  final _auctionLocationController = TextEditingController();
  String _selectedCategory = 'Diğer';

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _historyController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    _offerController.dispose();
    _auctionLocationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final value = double.parse(
      _valueController.text.trim().replaceAll(',', '.'),
    );

    await widget.onSave(
      Antique(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        history: _historyController.text.trim(),
        value: value,
        quantity: int.parse(_quantityController.text.trim()),
        offer: _offerController.text.trim(),
        auctionLocation: _auctionLocationController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Yeni Antika Kaydı'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Antika Bilgileri',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Antika adı',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Antika adını girin.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: antiqueCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Antika yılı (isteğe bağlı)',
                      hintText: 'Örn. 1920',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          int.tryParse(value.trim()) == null) {
                        return 'Geçerli bir yıl girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _historyController,
                    decoration: const InputDecoration(
                      labelText: 'Tarihsel geçmişi',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Tarihsel geçmişi girin.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _valueController,
                    decoration: const InputDecoration(
                      labelText: 'Değeri (₺)',
                      hintText: 'Örn. 12500,50',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Antikanın değerini girin.';
                      }
                      final parsed = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );
                      if (parsed == null || !parsed.isFinite || parsed < 0) {
                        return 'Geçerli bir değer girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _offerController,
                    decoration: const InputDecoration(
                      labelText: 'Teklif',
                      hintText: 'Örn. 8500 ₺',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Teklifi girin.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _auctionLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Açık artırma yeri',
                      hintText: 'Örn. İstanbul / Online',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Açık artırma yerini girin.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Adet',
                      hintText: 'Örn. 3',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final quantity = int.tryParse(value?.trim() ?? '');
                      if (quantity == null || quantity < 1) {
                        return 'En az 1 adet girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
