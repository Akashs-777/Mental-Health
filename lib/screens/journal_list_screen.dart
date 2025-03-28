// Suggested code may be subject to a license. Learn more: ~LicenseLog:1487831153.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:myapp/screens/view_journal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../models/journal_model.dart';
import '../widgets/nav_drawer.dart';
import 'journaling_chat_screen.dart';
import 'journal_entry_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final List<JournalModel> _journalEntries = [];
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
    await _loadJournalsList();
  }

  Future<void> _loadJournalsList() async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.get('journals/$userId');
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      final responseData = jsonDecode(apiResponse.body);
      setState(() {
        _journalEntries.clear();
        for (var journal in responseData) {
          if (journal['message'] == null) {
            _journalEntries.add(JournalModel.fromJson(journal));
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _deleteJournal(String journalId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.delete('journal/$journalId');
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Journal deleted successfully: $journalId');
        }
        setState(() {
          _isLoading = false;
        });
        _loadJournalsList();
      } else {
        throw Exception('Failed to delete journal');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting journal: $e');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete journal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => JournalingChatScreen()),
              );
            },
          ),
        ],

        title: const Text('Journal Entries'),
      ),
      drawer: const NavDrawer(selectedIndex: 2),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _journalEntries.length,
                itemBuilder: (context, index) {
                  final journal = _journalEntries[index];
                  DateTime dateTime =
                      DateTime.parse(journal.createdAt).toLocal();
                  var format = DateFormat('dd MMM, yyyy hh:MM a');
                  String formattedDate = format.format(
                    dateTime.toUtc().add(const Duration(hours: -8)),
                  );
                  return ListTile(
                    title: Text(journal.title),
                    subtitle: Text(formattedDate),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => ViewJournalScreen(
                                title: journal.title,
                                overallFeeling: journal.overallFeeling,
                                journalEntry: journal.journalEntry,
                                date: formattedDate,
                              ),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // Handle edit action
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteJournal(journal.journalId);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const JournalEntryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}