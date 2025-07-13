import 'package:collab/main.dart';
import 'package:collab/models/app_user.dart';
import 'package:flutter/material.dart';
import '../controllers/auth_data_controller.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final AuthDataController authController;
  const HomeScreen({super.key, required this.authController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    // Use the actual authenticated user from the controller
    AppUser? user = widget.authController.user;
    final String userName = user?.name ?? "User";
    final String userEmail = user?.email ?? "User@gmail.com";

    void _toggleTheme() {
      setState(() {
        _isDarkMode = !_isDarkMode;
      });
    }

    return MaterialApp(
      title: 'Collaborative Whiteboard',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
        ),
      )
          : ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
        ),
      ),
      home: HomePage(
        toggleTheme: _toggleTheme,
        userName: userName,
        userEmail: userEmail,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final String userName;
  final String userEmail;

  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTagIndex = 0;
  int _selectedIndex = 0;
  final List<String> _tags = ['All', 'Favorites'];

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onMenuSelected(int value) async {
    if (value == 3) {
      // Sign Out
      // Find the AuthDataController from ancestor widget
      final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeScreenState != null) {
        await homeScreenState.widget.authController.signOut();
        // After sign out, navigate to login or root
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    }
    // Add other menu actions if needed
  }

  @override
  Widget build(BuildContext context) {
    String userInitial = widget.userName.isNotEmpty ? widget.userName[0] : '?';

    Widget bodyContent;
    switch (_selectedIndex) {
      case 1:
        bodyContent = const Center(child: Text('Meetings'));
        break;
      case 2:
        bodyContent = const Center(child: Text('Bin'));
        break;
      default:
        bodyContent = Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search notes...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Notifications'),
                            content: const Text('No new notifications.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final selected = await showMenu<int>(
                        context: context,
                        position: const RelativeRect.fromLTRB(
                          1000,
                          80,
                          10,
                          100,
                        ),
                        items: <PopupMenuEntry<int>>[
                          PopupMenuItem<int>(
                            value: 0,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  userInitial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(widget.userName),
                              subtitle: Text(widget.userEmail),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<int>(
                            value: 1,
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text("Customize Avatar"),
                            ),
                          ),
                          const PopupMenuItem<int>(
                            value: 2,
                            child: ListTile(
                              leading: Icon(Icons.settings),
                              title: Text("Settings"),
                            ),
                          ),
                          const PopupMenuItem<int>(
                            value: 3,
                            child: ListTile(
                              leading: Icon(Icons.logout),
                              title: Text("Sign Out"),
                            ),
                          ),
                        ],
                      );
                      if (selected != null) {
                        _onMenuSelected(selected);
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(_tags.length, (index) {
                  final bool isSelected = _selectedTagIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        _tags[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.blue,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTagIndex = index;
                        });
                      },
                    ),
                  );
                }),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                  Image.asset('assets/images/illustration.jpeg', height: 200),
                    const SizedBox(height: 20),
                    const Text(
                      'Start creating your first note here.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("New note"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NoteCreationPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userName),
              accountEmail: Text(widget.userEmail),
              currentAccountPicture: GestureDetector(
                onTap: () {},
                child: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    widget.userName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.brightness_7
                    : Icons.brightness_2,
              ),
              title: const Text('Toggle Dark Mode'),
              onTap: widget.toggleTheme,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About App'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In / Log Out'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // close drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),

      body: bodyContent,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Meet'),
          BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Bin'),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WhiteboardPage()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteCreationPage extends StatelessWidget {
  const NoteCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Note")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Save Note"),
            ),
          ],
        ),
      ),
    );
  }
}

class WhiteboardPage extends StatelessWidget {
  const WhiteboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Collaborative Whiteboard")),
      body: const Center(
        child: Text(
          "This is the whiteboard workspace.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Switch between light and dark modes'),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Change Theme'),
                  content: const Text(
                    'Use the drawer to toggle the theme mode.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Collaborative Whiteboard',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 CollabVault',
              );
            },
          ),
        ],
      ),
    );
  }
}
