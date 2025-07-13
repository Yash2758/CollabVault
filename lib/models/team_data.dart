class TeamMember {
  final String name;
  final String role;
  final String status;
  final String statusColor;

  TeamMember({
    required this.name,
    required this.role,
    required this.status,
    required this.statusColor,
  });
}

List<TeamMember> teamMembers = [
  TeamMember(
    name: 'Astha',
    role: 'Designer',
    status: 'online',
    statusColor: 'green',
  ),
  TeamMember(
    name: 'Shreepriya',
    role: 'Developer',
    status: 'online',
    statusColor: 'green',
  ),
  TeamMember(
    name: 'Snehil',
    role: 'Manager',
    status: 'away',
    statusColor: 'amber',
  ),
  TeamMember(
    name: 'Yash',
    role: 'Developer',
    status: 'offline',
    statusColor: 'grey',
  ),
];
