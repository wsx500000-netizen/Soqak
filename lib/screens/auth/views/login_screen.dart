import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/local_database.dart';
import 'package:shop/services/supabase_service.dart';

import 'components/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectRoute});

  final String? redirectRoute;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "assets/images/login_dark.png",
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "مرحباً بعودتك!",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  const Text(
                    "سجّل الدخول باستخدام بياناتك المسجلة.",
                  ),
                  const SizedBox(height: defaultPadding),
                  LogInForm(
                    formKey: _formKey,
                    onEmailSaved: (email) => _email = email?.trim() ?? '',
                    onPasswordSaved: (password) => _password = password ?? '',
                  ),
                  Align(
                    child: TextButton(
                      child: const Text("نسيت كلمة المرور؟"),
                      onPressed: () {
                        Navigator.pushNamed(
                            context, passwordRecoveryScreenRoute);
                      },
                    ),
                  ),
                  SizedBox(
                    height:
                        size.height > 700 ? size.height * 0.1 : defaultPadding,
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            _formKey.currentState!.save();
                            setState(() => _isSubmitting = true);
                            final bool authenticated;
                            try {
                              authenticated = SupabaseService.isConfigured
                                  ? await SupabaseService.signIn(
                                      _email, _password)
                                  : await LocalDatabase.instance
                                      .authenticateLocalUser(_email, _password);
                            } catch (error) {
                              if (!mounted) return;
                              setState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('تعذر تسجيل الدخول. حاول مجددًا.'),
                                ),
                              );
                              return;
                            } finally {
                              _password = '';
                            }
                            if (!mounted) return;
                            setState(() => _isSubmitting = false);
                            if (!authenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'بيانات الدخول غير صحيحة أو الحساب موقوف'),
                                ),
                              );
                              return;
                            }
                            if (widget.redirectRoute != null) {
                              Navigator.pushReplacementNamed(
                                  context, widget.redirectRoute!);
                            } else {
                              Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  entryPointScreenRoute,
                                  ModalRoute.withName(logInScreenRoute));
                            }
                          },
                    child:
                        Text(_isSubmitting ? "جارٍ التحقق..." : "تسجيل الدخول"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("ليس لديك حساب؟"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, signUpScreenRoute);
                        },
                        child: const Text("إنشاء حساب"),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
