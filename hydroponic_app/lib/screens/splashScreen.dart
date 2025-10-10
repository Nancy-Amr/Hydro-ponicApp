import 'package:flutter/material.dart';
import 'package:hydroponic_app/screens/signup.dart';
import 'package:hydroponic_app/screens/forgotpass.dart';
import 'package:hydroponic_app/screens/dashboard.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _Splashscreen();
}

class _Splashscreen extends State<Splashscreen>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;
    final Color accentBlue = Colors.lightBlue.shade300;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: const Interval(
                                        0.0,
                                        0.5,
                                        curve: Curves.elasticOut,
                                      ),
                                    ),
                                  ),
                              child: Icon(
                                Icons.eco_outlined,
                                size: 80,
                                color: primaryGreen,
                              ),
                            ),
                            _gap(height: 10),
                            Text(
                              "Welcome to Hydro-Smart!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                            _gap(height: 4),
                            Text(
                              "Manage your hydroponic garden easily.",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            _gap(height: 24),
                            // --- Email Input ---
                            _buildTextFormField(
                              context,
                              'Email',
                              Icons.email_outlined,
                              (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                bool emailValid = RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                ).hasMatch(value);
                                if (!emailValid) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              false,
                              null,
                            ),
                            _gap(),
                            // --- Password Input ---
                            _buildTextFormField(
                              context,
                              'Password',
                              Icons.lock_outline_rounded,
                              (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              !_isPasswordVisible,
                              IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: primaryGreen.withOpacity(0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            _gap(height: 8),

                            // --- Remember Me & Forgot Password Row ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: CheckboxListTile(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _rememberMe = value;
                                      });
                                    },
                                    title: Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: const EdgeInsets.only(
                                      left: 0,
                                      right: 8,
                                    ),
                                    dense: true,
                                  ),
                                ),
                                TextButton(
                                  // **FORGOT PASSWORD NAVIGATION**
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const Forgotpass(), // Navigate to ForgotPassScreen
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: accentBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _gap(),

                            // --- Sign In Button ---
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 4,
                                ),
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DashboardScreen(),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            _gap(height: 24),

                            // --- Sign Up Link ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                TextButton(
                                  // **SIGN UP NAVIGATION**
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpScreen(), // Navigate to SignUpScreen
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: accentBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _gap({double height = 16}) => SizedBox(height: height);

  Widget _buildTextFormField(
    BuildContext context,
    String labelText,
    IconData prefixIcon,
    String? Function(String?) validator,
    bool obscureText,
    Widget? suffixIcon,
  ) {
    return TextFormField(
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: 'Enter your $labelText'.toLowerCase(),
        prefixIcon: Icon(prefixIcon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
