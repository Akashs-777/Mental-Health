import 'package:flutter/material.dart';

class ViewJournalScreen extends StatefulWidget {
  final String title;
  final String overallFeeling;
  final String journalEntry;
  final String date;

  const ViewJournalScreen({
    super.key,
    required this.title,
    required this.overallFeeling,
    required this.journalEntry,
    required this.date,
  });

  @override
  State<ViewJournalScreen> createState() => _ViewJournalScreenState();
}

class _ViewJournalScreenState extends State<ViewJournalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
              widget.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.topLeft,child: Text(widget.date.toString(), style: const TextStyle(fontSize: 16))),
            const SizedBox(height: 16),
            Align(alignment: Alignment.topLeft,child: Text(widget.overallFeeling, style: const TextStyle(fontSize: 18))),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: Text(widget.journalEntry, style: const TextStyle(fontSize: 18)))),
          ],
        ),
      ),
    );
  }
}