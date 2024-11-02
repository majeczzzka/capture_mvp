import 'package:flutter/material.dart';

class JarCreationScreen extends StatefulWidget {
  const JarCreationScreen({super.key});
  @override
  JarCreationScreenState createState() => JarCreationScreenState();
}

class JarCreationScreenState extends State<JarCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  void _saveJar() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Here we would save the jar data (to be implemented)
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Jar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Jar Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {},
              ),
              const SizedBox(height: 20),
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
