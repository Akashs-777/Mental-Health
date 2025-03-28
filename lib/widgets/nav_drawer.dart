import 'package:flutter/material.dart';
import 'package:myapp/screens/chat_screen.dart';
import 'package:myapp/screens/journal_list_screen.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/mood_logging_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavDrawer extends StatefulWidget {
  final int selectedIndex;
  const NavDrawer({super.key, required this.selectedIndex});

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  @override
  Widget build(BuildContext context) {
    final Map<int, Widget> screens = {
      0: ChatScreen(chatSessionId: ''), // Replace with actual screen widgets
      1: MoodLoggingScreen(),
      2: JournalListScreen(),
      // 3 is for log out action, not a screen
    };
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface, // Light Gray
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary, // Light Blue
            ),
            child: Text(
              'Options',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary, // Dark blue
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/self-love.png',
              width: 24,
              height: 24,
              color: widget.selectedIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary,
            ),
            title: Text('Aura AI Counselling', style: TextStyle(color: widget.selectedIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary)),
            selected: widget.selectedIndex == 0, // Highlight if selected
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => screens[0]!),
                (Route<dynamic> route) => false, // This removes all previous routes
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/mood.png',
              width: 24,
              height: 24,
              color: widget.selectedIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary,
            ),
            title: Text('Mood Logging', style: TextStyle(color: widget.selectedIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary)),
            selected: widget.selectedIndex == 1, // Highlight if selected
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => screens[1]!),
                (Route<dynamic> route) => false, // This removes all previous routes
              );
            },
          ),
          ListTile(
            leading: Image.asset(
              'assets/images/diary.png',
              width: 24,
              height: 24,
              color: widget.selectedIndex == 2 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary,
            ),
            title: Text('Journaling', style: TextStyle(color: widget.selectedIndex == 2 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary)),
            selected: widget.selectedIndex == 2, // Highlight if selected
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => screens[2]!),
                (Route<dynamic> route) => false, // This removes all previous routes
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: widget.selectedIndex == 3 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary),
            title: Text('Log Out', style: TextStyle(color: widget.selectedIndex == 3 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary)),
            selected: widget.selectedIndex == 3, // Highlight if selected
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.remove("userId");
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LogInScreen()), (route) => false);
            },
          ),
        ],
      ),
    );
  }
}