import 'package:flutter/material.dart';

/// Screen for creating a new jar with a title input and save button.
class JarCreationScreen extends StatefulWidget {
  const JarCreationScreen({super.key});

  @override
  JarCreationScreenState createState() => JarCreationScreenState();
}

class JarCreationScreenState extends State<JarCreationScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for managing form state

  /// Validates and saves the form, then closes the screen
  void _saveJar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Placeholder for saving jar data (implementation needed)
      Navigator.pop(context); // Closes the screen after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Jar'), // Title of the app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the form
        child: Form(
          key: _formKey, // Associates the form with the global key
          child: Column(
            children: [
              // Input field for jar title
              TextFormField(
                decoration: const InputDecoration(labelText: 'Jar Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title'; // Validation message
                  }
                  return null;
                },
                onSaved: (value) {
                  // Placeholder for storing the saved title
                },
              ),
              const SizedBox(height: 20), // Spacing between input and button

              // Button to save the jar
              ElevatedButton(
                onPressed: _saveJar,
                child: const Text('Save Jar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
