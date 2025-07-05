import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSignUp = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '請輸入電子郵件和密碼';
      });
      return;
    }

    if (_isSignUp && _displayNameController.text.isEmpty) {
      setState(() {
        _errorMessage = '請輸入顯示名稱';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _authService.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
          _displayNameController.text,
        );
      } else {
        await _authService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      }
      // Pop back to previous screen (LandingScreen/HomePage) after successful auth
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getLocalizedErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = '發生錯誤，請稍後再試';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLocalizedErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return '此電子郵件已被使用';
      case 'invalid-email':
        return '無效的電子郵件格式';
      case 'operation-not-allowed':
        return '此登入方式尚未啟用';
      case 'weak-password':
        return '密碼強度不足';
      case 'user-disabled':
        return '此帳號已被停用';
      case 'user-not-found':
        return '找不到此帳號';
      case 'wrong-password':
        return '密碼錯誤';
      default:
        return '發生錯誤，請稍後再試';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isSignUp ? '註冊帳號' : '登入'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isSignUp) ...[
                CupertinoTextField(
                  controller: _displayNameController,
                  placeholder: '顯示名稱',
                  padding: const EdgeInsets.all(12),
                  clearButtonMode: OverlayVisibilityMode.editing,
                ),
                const SizedBox(height: 16),
              ],
              CupertinoTextField(
                controller: _emailController,
                placeholder: '電子郵件',
                keyboardType: TextInputType.emailAddress,
                padding: const EdgeInsets.all(12),
                clearButtonMode: OverlayVisibilityMode.editing,
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: '密碼',
                obscureText: true,
                padding: const EdgeInsets.all(12),
                clearButtonMode: OverlayVisibilityMode.editing,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const CupertinoActivityIndicator()
              else
                CupertinoButton.filled(
                  onPressed: _handleSubmit,
                  child: Text(_isSignUp ? '註冊' : '登入'),
                ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _errorMessage = null;
                  });
                },
                child: Text(_isSignUp ? '已有帳號？登入' : '沒有帳號？註冊'),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () async {
                  await _authService.signInAnonymously();
                },
                child: const Text('以訪客身份繼續'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInAnonymously();
      // Navigation will be handled by auth state change
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getLocalizedErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = '發生錯誤，請稍後再試';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLocalizedErrorMessage(String code) {
    switch (code) {
      case 'operation-not-allowed':
        return '此登入方式尚未啟用';
      default:
        return '發生錯誤，請稍後再試';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('歡迎'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                '歡迎使用 dCBT-i',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '數位認知行為治療失眠',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 17,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: CupertinoColors.destructiveRed,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (_isLoading)
                const CupertinoActivityIndicator()
              else ...[
                CupertinoButton.filled(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  },
                  child: const Text('註冊/登入帳號'),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: _signInAnonymously,
                  child: const Text('以訪客身份繼續'),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
