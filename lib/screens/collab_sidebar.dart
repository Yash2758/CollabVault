import 'package:flutter/material.dart';
import '../models/team_data.dart';

class CollabSideBar extends StatelessWidget {
  const CollabSideBar({super.key});

  Color getStatusColor(String color) {
    switch (color) {
      case 'green':
        return Colors.green;
      case 'amber':
        return Colors.amber;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Text(
                    "CollabVault",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      onTap: () {
                        print('Search bar tapped');
                      },
                      decoration: InputDecoration(
                        hintText: 'Search projects, files, or team members...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    tooltip: 'Notifications',
                    onPressed: () {
                      // TODO: Show notification panel or dialog
                      print('Notifications tapped');
                    },
                  ),
                  const SizedBox(width: 16),

                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (value) {
                      // TODO: Implement actions like navigate to profile/settings
                      print('Selected: $value');
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Text('👤 View Profile'),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Text('⚙️ Settings'),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('🚪 Logout'),
                      ),
                    ],
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Main Content
            Expanded(
              child: Row(
                children: [
                  // Team Workspace (Left)
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Team Workspace",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Project Alpha Collaboration",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Team Members (${teamMembers.length})",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: teamMembers.length,
                              itemBuilder: (context, index) {
                                final member = teamMembers[index];
                                return InkWell(
                                  onTap: () {
                                    print('${member.name} tapped');
                                    // TODO: Show profile, open DM, etc.
                                  },
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey.shade200,
                                      child: Text(member.name[0]),
                                    ),
                                    title: Text(
                                      member.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(member.role),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 10,
                                          color: getStatusColor(
                                            member.statusColor,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          member.status,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quick Actions (Right)
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Quick Actions",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              children: [
                                _buildActionCard(
                                  Icons.videocam,
                                  "Start Video Call",
                                  Colors.blue,
                                ),
                                _buildActionCard(
                                  Icons.description,
                                  "New Document",
                                  Colors.green,
                                ),
                                _buildActionCard(
                                  Icons.person_add,
                                  "Invite Members",
                                  Colors.purple,
                                ),
                                _buildActionCard(
                                  Icons.settings,
                                  "Settings",
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        print('$label tapped');
        // TODO: Implement navigation or action here
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    ;
  }
}
