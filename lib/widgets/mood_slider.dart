import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MoodSlider extends StatefulWidget {
  final Function(String moodText)? onMoodChanged;

  MoodSlider({this.onMoodChanged});
  @override
  _MoodSliderState createState() => _MoodSliderState();
}

class _MoodSliderState extends State<MoodSlider> {
  double _moodValue = 50.0; // Starting at neutral (0-100 scale)

  // Mood descriptions and corresponding emojis
  final List<String> moodEmojis = ['😢', '😣', '😐', '😊', '😍'];
  final List<String> moodTexts = [
    'Very Unpleasant',
    'Unpleasant',
    'Neutral',
    'Pleasant',
    'Very Pleasant'
  ];

  Color _getMoodColor(double value, BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    if (value < 20) return theme.error.withAlpha(179); // 0.7 opacity
    if (value < 40) return Color(0xFF90CAF9); // Darker Light Blue
    if (value < 60) return theme.primary.withAlpha(153); // 0.6 opacity
    if (value < 80) return theme.secondary.withAlpha(179); // 0.7 opacity
    return theme.secondary; // Full Green
  }

  String _getMoodEmoji(double value) {
    if (value < 20) return moodEmojis[0];
    if (value < 40) return moodEmojis[1];
    if (value < 60) return moodEmojis[2];
    if (value < 80) return moodEmojis[3];
    return moodEmojis[4];
  }

  String _getMoodText(double value) {
    if (value < 20) return moodTexts[0];
    if (value < 40) return moodTexts[1];
    if (value < 60) return moodTexts[2];
    if (value < 80) return moodTexts[3];
    return moodTexts[4];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated mood indicator
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: _getMoodColor(_moodValue, context),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getMoodColor(_moodValue, context).withAlpha(128), // 0.5 opacity
                spreadRadius: 5,
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getMoodEmoji(_moodValue),
              style: TextStyle(fontSize: 50),
            ),
          ),
        ),
        SizedBox(height: 20),
        
        // Mood text
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: Text(
            _getMoodText(_moodValue),
            key: ValueKey(_getMoodText(_moodValue)),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getMoodColor(_moodValue, context).withAlpha(204), // 0.8 opacity
            ),
          ),
        ),
        SizedBox(height: 30),
        
        // Slider with custom theme
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16), // Wider slider
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0, // Thin track for transparency
              activeTrackColor: _getMoodColor(_moodValue, context).withAlpha(102), // More transparent (0.4 opacity)
              inactiveTrackColor: theme.surface.withAlpha(76), // Very transparent (0.3 opacity)
              thumbColor: _getMoodColor(_moodValue, context),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 16.0, // Larger thumb
              ),
              overlayColor: _getMoodColor(_moodValue, context).withAlpha(51), // Very transparent overlay (0.2 opacity)
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: 24.0, // Larger overlay circle
              ),
            ),
            child: Slider(
              value: _moodValue,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  _moodValue = value;
                  final moodText = _getMoodText(value);
                  widget.onMoodChanged?.call(moodText);
                  if (kDebugMode) {
                    print('Mood logged: ${value.toStringAsFixed(1)} - ${_getMoodText(value)}');
                  }
                });
              },
            ),
          ),
        ),
        
        // Scale indicators
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20), // Adjusted to align with wider slider
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Very\nUnpleasant',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('Very\nPleasant',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}