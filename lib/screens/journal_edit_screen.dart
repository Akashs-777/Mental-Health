import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myapp/screens/journal_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class JournalEditScreen extends StatefulWidget {

  final String journalId;
  final String title;
  final String overallFeeling;
  final String journalEntry;

  const JournalEditScreen({
    super.key,
    required this.journalId,
    required this.title,
    required this.overallFeeling,
    required this.journalEntry,
  });

  @override
  State<JournalEditScreen> createState() => _JournalEditScreenState();
}

class _JournalEditScreenState extends State<JournalEditScreen> {

  late String title;
  late String overallFeeling;
  late String journalEntry;
  late String date;

  final TextEditingController _bodyTextEditingController =
      TextEditingController();
  final TextEditingController _titleTextEditingController =
      TextEditingController();
      final TextEditingController _feelingTextEditingController =
      TextEditingController();
  late final String userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    title = widget.title;
    overallFeeling = widget.overallFeeling;
    journalEntry = widget.journalEntry;

    _bodyTextEditingController.text = journalEntry;
    _titleTextEditingController.text = title;
    _feelingTextEditingController.text = overallFeeling;

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
    final feeling = _feelingTextEditingController.text;
    final body = _bodyTextEditingController.text;
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and body')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.put('journal/${widget.journalId}', {
      'userId': userId,
      'title': title,
      'overall_feeling': feeling,
      'journal_entry': body,
    });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
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
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                      ),
                    ),
                    TextField(
                      controller: _feelingTextEditingController,
                      decoration: const InputDecoration(
                        hintText: 'Overall Feeling',
                        border: InputBorder.none,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _bodyTextEditingController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: 'Start writing your journal entry...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}