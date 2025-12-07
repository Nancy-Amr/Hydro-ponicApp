// lib/screens/profile_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController; // <--- NEW CONTROLLER
  
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final appUser = authProvider.appUser;
    
    // Initialize controllers with current user data
    _nameController = TextEditingController(text: appUser?.name ?? '');
    _emailController = TextEditingController(text: appUser?.email ?? '');
    _phoneController = TextEditingController(text: appUser?.phoneNumber ?? '');
    
    // NEW: Initialize age controller
    _ageController = TextEditingController(text: appUser?.age?.toString() ?? '');
    _selectedGender = appUser?.gender;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose(); // <--- DISPOSE AGE CONTROLLER
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.firebaseUser == null) {
      _showSnackBar("Error: User not logged in.", Colors.red);
      return;
    }

    _showSnackBar("Saving changes...", Colors.grey.shade600);
    
    final int? ageValue = int.tryParse(_ageController.text.trim());

    try {
      // 🚨 FIX: Call the high-level updateProfile method with the new 'age' field
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gender: _selectedGender,
        age: ageValue, // <--- PASSING AGE VALUE
      );

      _showSnackBar("Profile updated successfully!", Colors.green.shade700);
      Navigator.of(context).pop(); 
      
    } catch (e) {
      _showSnackBar("Failed to save changes: ${e.toString()}", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Colors.green.shade700;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.appUser;
    
    if (user == null) {
      return const Center(child: Text("Access Denied: Please log in."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Section
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: primaryGreen.withOpacity(0.7),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 1. Display Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Display Name",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Email Field (Disabled)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  enabled: false,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Age Field (NEW)
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  prefixIcon: Icon(Icons.cake_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 1) {
                      return 'Please enter a valid age.';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),


              // 5. Gender Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: "Gender",
                  prefixIcon: Icon(Icons.face_unlock_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),
              const SizedBox(height: 30),
              
              // Change Password Button
              TextButton.icon(
                onPressed: () {
                  _showSnackBar("Redirecting to Change Password flow...", primaryGreen);
                },
                icon: const Icon(Icons.lock_outline),
                label: const Text("Change Password"),
                style: TextButton.styleFrom(
                  foregroundColor: primaryGreen,
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              ElevatedButton.icon(
                onPressed: _saveProfileChanges,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}