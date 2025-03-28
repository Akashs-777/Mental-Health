// Suggested code may be subject to a license. Learn more: ~LicenseLog:561218062.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2083398100.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:4078478684.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myapp/screens/journal_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _bodyTextEditingController = TextEditingController();
  final TextEditingController _titleTextEditingController = TextEditingController();
  late final String userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
  }

  @override
  void dispose() {
    _bodyTextEditingController.dispose();
    _titleTextEditingController.dispose();
    super.dispose();
  }

  Future<void> _saveJournalEntry() async {
    final title = _titleTextEditingController.text;
    final body = _bodyTextEditingController.text;
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title and body')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.post('journal', {'userId': userId, 'title': title, 'journal_entry': body});
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const JournalListScreen()),
        (Route<dynamic> route) => false, // This removes all previous routes
      );
    } else {
      final responseData = jsonDecode(apiResponse.body);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveJournalEntry();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleTextEditingController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _bodyTextEditingController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(hintText: 'Start writing your journal entry...', border: InputBorder.none),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}