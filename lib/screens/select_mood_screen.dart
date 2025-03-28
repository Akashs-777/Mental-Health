// Suggested code may be subject to a license. Learn more: ~LicenseLog:878702767.
import 'package:flutter/material.dart';

class SelectMoodScreen extends StatefulWidget {
  final String initialMoodCategory;

  const SelectMoodScreen({Key? key, required this.initialMoodCategory})
      : super(key: key);

  @override
  _SelectMoodScreenState createState() => _SelectMoodScreenState();
}

class _SelectMoodScreenState extends State<SelectMoodScreen> {
  List<String> _selectedMoods = [];
  bool _showAllMoods = false;

  final Map<String, List<String>> _moodCategories = {
    'Very unpleasent': [
      'Angry',
      'Frustrated',
      'Anxious',
      'Sad',
      'Depressed',
      'Scared',
      'Helpless'
    ],
    'unpleasent': ['Irritated', 'Annoyed', 'Tired', 'Bored', 'Lonely', 'Guilty'],
    'neutral': ['Calm', 'Content', 'Neutral', 'Tolerant', 'Indifferent'],

    'pleasent': [
      'Happy',
      'Excited',
      'Energetic',
      'Hopeful',
      'Relaxed',
      'Proud'
    ],
    'Very pleasent': [
      'Joyful',
      'Passionate',
      'Loving',
      'Grateful',
      'Thrilled',
      'Inspired',
      'Peaceful'
    ],
  };

    List<String> get _initialMoods {
     return _moodCategories[widget.initialMoodCategory] ?? [];
   }

  List<String> get _remainingMoods {
    List<String> allMoods = _moodCategories.values.expand((moods) => moods).toList();
    return allMoods.where((mood) => !_initialMoods.contains(mood)).toList();
  }

  List<String> get _displayedMoods {
    List<String> displayedMoods = [..._initialMoods];
    if (_showAllMoods) {
     displayedMoods.addAll(_remainingMoods);
    }

    return displayedMoods;
  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Moods'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8.0,
              children: _displayedMoods.map((mood) {
                final isSelected = _selectedMoods.contains(mood);
                return FilterChip(
                  label: Text(mood),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMoods.add(mood);
                      } else {
                        _selectedMoods.remove(mood);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            if (!_showAllMoods)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAllMoods = true;
                  });
                },
                child: Text('Show More'),
              ),
            SizedBox(height: 16),
            Text('Selected Moods: ${_selectedMoods.join(", ")}'),
          ],
        ),
      ),
    );
  }
}