import 'package:flutter/material.dart';

class Forgotpass extends StatefulWidget {
  const Forgotpass({super.key});

  @override
  State<Forgotpass> createState() => _ForgotpassState();
}

// Add SingleTickerProviderStateMixin for animation control
class _ForgotpassState extends State<Forgotpass>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Animation Variables
  // Changed 'late' to 'late final' for variables initialized in initState.
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the Animation Controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Define Fade Animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Define Slide Animation
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.2), // Starts slightly below
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_formKey.currentState?.validate() ?? false) {
      // Logic to send email goes here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent! Check your email.'),
          backgroundColor: Colors.green,
        ),
      );
      // Optional: Navigate back to the login screen after a short delay
      // Future.delayed(const Duration(seconds: 2), () {
      //   Navigator.pop(context);
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme consistency
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
            // Apply Fade and Slide Animations
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
                            // Icon and Title
                            Icon(
                              Icons
                                  .lock_reset, // Icon related to resetting password
                              size: 70,
                              color: primaryGreen,
                            ),
                            _gap(height: 16),
                            Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                            _gap(height: 8),
                            Text(
                              "Enter your email address to receive a password reset link.",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            _gap(height: 32),

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
                            _gap(height: 32),

                            // --- Reset Button ---
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
                                onPressed: _sendResetLink,
                                child: const Text(
                                  'SEND RESET LINK',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            _gap(height: 24),

                            // --- Back to Login Link ---
                            TextButton(
                              onPressed: () => Navigator.pop(
                                context,
                              ), // Navigates back to the previous screen (Login)
                              child: Text(
                                '← Back to Sign In',
                                style: TextStyle(
                                  color: accentBlue,
                                  fontWeight: FontWeight.bold,
                                ),
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
