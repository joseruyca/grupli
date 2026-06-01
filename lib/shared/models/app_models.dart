class GroupSummary {
  final String id;
  final String name;
  final String type;
  final String privacy;
  final String? location;
  final String inviteCode;
  final int membersCount;
  final String role;
  final double balance;

  GroupSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.privacy,
    required this.inviteCode,
    required this.membersCount,
    required this.role,
    this.location,
    this.balance = 0,
  });

  factory GroupSummary.fromMap(Map<String, dynamic> map) => GroupSummary(
        id: map['id'].toString(),
        name: (map['name'] ?? 'Grupo') as String,
        type: (map['type'] ?? 'otro') as String,
        privacy: (map['privacy'] ?? 'privado') as String,
        inviteCode: (map['invite_code'] ?? '') as String,
        membersCount: (map['members_count'] ?? 0) as int,
        role: (map['role'] ?? 'member') as String,
        location: map['default_location'] as String?,
        balance: ((map['balance'] ?? 0) as num).toDouble(),
      );
}
