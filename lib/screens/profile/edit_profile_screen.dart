import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _otherDetailsController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _hasDateOfBirth = false;
  bool _hasHeight = false;
  bool _hasOtherDetails = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _heightController.dispose();
    _otherDetailsController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userData;
    
    if (user != null) {
      _displayNameController.text = user.displayName;
      _selectedGender = user.gender;
      _selectedDate = user.dateOfBirth;
      _hasDateOfBirth = user.dateOfBirth != null;
      _hasHeight = user.height != null;
      _hasOtherDetails = user.otherDetails != null && user.otherDetails!.isNotEmpty;
      
      if (user.height != null) {
        _heightController.text = user.height.toString();
      }
      
      if (user.otherDetails != null && user.otherDetails!['notes'] != null) {
        _otherDetailsController.text = user.otherDetails!['notes'];
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime.now().subtract(const Duration(days: 36500)),
      lastDate: DateTime.now().subtract(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Prepare other details
    Map<String, dynamic>? otherDetails;
    if (_hasOtherDetails && _otherDetailsController.text.isNotEmpty) {
      otherDetails = {
        'notes': _otherDetailsController.text.trim(),
      };
    }

    final success = await authProvider.updateUserProfile(
      displayName: _displayNameController.text.trim(),
      gender: _selectedGender,
      dateOfBirth: _hasDateOfBirth ? _selectedDate : null,
      height: _hasHeight && _heightController.text.isNotEmpty 
          ? double.tryParse(_heightController.text)
          : null,
      otherDetails: otherDetails,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
                 title: const Text(
           'Edit Profile',
           style: TextStyle(
             fontWeight: FontWeight.bold,
           ),
         ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display Name Field
              CustomTextField(
                controller: _displayNameController,
                labelText: 'Display Name *',
                hintText: 'Enter your display name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Display name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Gender Field
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                items: _genderOptions.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Date of Birth Section
              Row(
                children: [
                  Checkbox(
                    value: _hasDateOfBirth,
                    onChanged: (value) {
                      setState(() {
                        _hasDateOfBirth = value ?? false;
                        if (!_hasDateOfBirth) {
                          _selectedDate = null;
                        }
                      });
                    },
                  ),
                  const Text('Set date of birth'),
                ],
              ),
              
              if (_hasDateOfBirth) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate != null
                              ? 'Date of Birth: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select Date of Birth',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Height Section
              Row(
                children: [
                  Checkbox(
                    value: _hasHeight,
                    onChanged: (value) {
                      setState(() {
                        _hasHeight = value ?? false;
                        if (!_hasHeight) {
                          _heightController.clear();
                        }
                      });
                    },
                  ),
                  const Text('Set height'),
                ],
              ),
              
              if (_hasHeight) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _heightController,
                  labelText: 'Height (cm)',
                  hintText: 'Enter your height in cm',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.height,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Other Details Section
              Row(
                children: [
                  Checkbox(
                    value: _hasOtherDetails,
                    onChanged: (value) {
                      setState(() {
                        _hasOtherDetails = value ?? false;
                        if (!_hasOtherDetails) {
                          _otherDetailsController.clear();
                        }
                      });
                    },
                  ),
                  const Text('Add other details'),
                ],
              ),
              
              if (_hasOtherDetails) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _otherDetailsController,
                  labelText: 'Additional Notes',
                  hintText: 'Any additional information about yourself...',
                  maxLines: 3,
                  prefixIcon: Icons.note_outlined,
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Save Button
              CustomButton(
                onPressed: authProvider.isLoading ? null : _saveProfile,
                text: authProvider.isLoading ? 'Saving...' : 'Save Changes',
                isLoading: authProvider.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
