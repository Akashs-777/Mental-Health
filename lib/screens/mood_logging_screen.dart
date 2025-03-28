import 'package:flutter/material.dart';
import '../widgets/mood_slider.dart';
import '../widgets/nav_drawer.dart';
import 'select_mood_screen.dart';

class MoodLoggingScreen extends StatefulWidget {
  const MoodLoggingScreen({super.key});

  @override
  State<MoodLoggingScreen> createState() => _MoodLoggingScreenState();
}

class _MoodLoggingScreenState extends State<MoodLoggingScreen> {
  String _selectedMoodText = 'Neutral'; // Default starting mood

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: const NavDrawer(selectedIndex: 1),
        appBar: AppBar(title: const Text('Mood Logging')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              children: [
                Expanded(
                  child: MoodSlider(
                    onMoodChanged: (newMoodText) {
                      setState(() {
                        _selectedMoodText = newMoodText;
                      });
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => SelectMoodScreen(
                              initialMoodCategory: _selectedMoodText,
                            ),
                      ),
                    );
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}