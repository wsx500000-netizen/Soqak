import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shop/services/local_database.dart';
import 'package:shop/services/supabase_service.dart';
import 'package:shop/screens/auth/views/components/sign_up_form.dart';
import 'package:shop/route/route_constants.dart';

import '../../../constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isSubmitting = false;
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "assets/images/signUp_dark.png",
              height: MediaQuery.of(context).size.height * 0.35,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "لنبدأ!",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  const Text(
                    "أدخل بياناتك لإنشاء حساب جديد.",
                  ),
                  const SizedBox(height: defaultPadding),
                  SignUpForm(
                    formKey: _formKey,
                    onEmailSaved: (email) => _email = email?.trim() ?? '',
                    onPasswordSaved: (password) => _password = password ?? '',
                  ),
                  const SizedBox(height: defaultPadding),
                  Row(
                    children: [
                      Checkbox(
                        onChanged: (value) {
                          setState(() => _acceptedTerms = value ?? false);
                        },
                        value: _acceptedTerms,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: "أوافق على ",
                            children: [
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(
                                        context, termsOfServicesScreenRoute);
                                  },
                                text: "شروط الخدمة",
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text: " وسياسة الخصوصية.",
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (!_acceptedTerms) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'يجب الموافقة على الشروط وسياسة الخصوصية'),
                                ),
                              );
                              return;
                            }
                            _formKey.currentState!.save();
                            setState(() => _isSubmitting = true);
                            final bool registered;
                            try {
                              registered = SupabaseService.isConfigured
                                  ? await SupabaseService.signUp(
                                      _email, _password)
                                  : await LocalDatabase.instance
                                      .registerLocalUser(_email, _password);
                            } catch (error) {
                              if (!mounted) return;
                              setState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('تعذر إنشاء الحساب. حاول مجددًا.'),
                                ),
                              );
                              return;
                            } finally {
                              _password = '';
                            }
                            if (!mounted) return;
                            setState(() => _isSubmitting = false);
                            if (!registered) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('هذا البريد مسجل مسبقًا أو موقوف'),
                                ),
                              );
                              return;
                            }
                            // There is 2 more screens while user complete their profile
                            // afre sign up, it's available on the pro version get it now
                            // 🔗 https://theflutterway.gumroad.com/l/fluttershop
                            Navigator.pushNamed(context, entryPointScreenRoute);
                          },
                    child: Text(_isSubmitting ? "جارٍ الحفظ..." : "متابعة"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("لديك حساب بالفعل؟"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, logInScreenRoute);
                        },
                        child: const Text("تسجيل الدخول"),
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
