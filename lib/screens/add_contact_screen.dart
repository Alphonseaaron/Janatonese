import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/janatonese.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({Key? key}) : super(key: key);

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _sharedSecretController = TextEditingController();
  bool _isLoading = false;
  bool _isManualSecret = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Generate a random shared secret
    _sharedSecretController.text = JanatoneseEncryption.generateSharedSecret();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _sharedSecretController.dispose();
    super.dispose();
  }

  void _addContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final userId = Provider.of<AuthProvider>(context, listen: false).firebaseUser!.uid;
        
        await Provider.of<ChatProvider>(context, listen: false).addContact(
          userId,
          _emailController.text.trim(),
          nickName: _nicknameController.text.trim().isNotEmpty ? _nicknameController.text.trim() : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _regenerateSecret() {
    setState(() {
      _sharedSecretController.text = JanatoneseEncryption.generateSharedSecret();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Contact'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: Colors.blue.shade50,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'About Shared Secrets',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A shared secret is used to encrypt your messages. You and your contact must use the same secret for the encryption to work. Generate one here and share it with your contact securely.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nickname field (optional)
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname (Optional)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Shared secret section
              Row(
                children: [
                  Text(
                    'Shared Secret',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  // Manual vs. Auto toggle
                  Switch(
                    value: _isManualSecret,
                    onChanged: (value) {
                      setState(() {
                        _isManualSecret = value;
                        if (!value) {
                          _regenerateSecret();
                        }
                      });
                    },
                    activeColor: Colors.teal,
                  ),
                  Text(
                    _isManualSecret ? 'Manual' : 'Auto',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Shared secret field
              TextFormField(
                controller: _sharedSecretController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: !_isManualSecret
                      ? IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _regenerateSecret,
                          tooltip: 'Generate New Secret',
                        )
                      : null,
                ),
                readOnly: !_isManualSecret,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Shared secret is required';
                  }
                  if (!JanatoneseEncryption.verifySharedSecret(value)) {
                    return 'Invalid shared secret format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'This secret must be shared with your contact for the encryption to work properly.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),

              // Add contact button
              ElevatedButton(
                onPressed: _isLoading ? null : _addContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Contact',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}