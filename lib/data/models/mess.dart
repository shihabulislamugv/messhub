class Mess {
  final String id;
  final String name;
  final String area;
  final String inviteCode;
  final int cycleStartDay;
  final String? description;
  final String createdBy;
  final DateTime createdAt;

  const Mess({
    required this.id,
    required this.name,
    required this.area,
    required this.inviteCode,
    this.cycleStartDay = 1,
    this.description,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'area': area,
    'invite_code': inviteCode,
    'cycle_start_day': cycleStartDay,
    'description': description,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
  };

  factory Mess.fromJson(Map<String, dynamic> json) => Mess(
    id: json['id'] as String,
    name: json['name'] as String,
    area: json['area'] as String,
    inviteCode: json['invite_code'] as String,
    cycleStartDay: json['cycle_start_day'] as int? ?? 1,
    description: json['description'] as String?,
    createdBy: json['created_by'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

enum MemberRole {
  admin,
  member,
}

class MessMember {
  final String id;
  final String messId;
  final String userId;
  final MemberRole role;
  final DateTime joinedAt;
  final String? userName;
  final String? userEmail;
  final String? userAvatar;

  const MessMember({
    required this.id,
    required this.messId,
    required this.userId,
    this.role = MemberRole.member,
    required this.joinedAt,
    this.userName,
    this.userEmail,
    this.userAvatar,
  });

  bool get isAdmin => role == MemberRole.admin;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'user_id': userId,
    'role': role == MemberRole.admin ? 'ADMIN' : 'MEMBER',
    'joined_at': joinedAt.toIso8601String(),
  };

  factory MessMember.fromJson(Map<String, dynamic> json) => MessMember(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    userId: json['user_id'] as String,
    role: (json['role'] as String?) == 'ADMIN' ? MemberRole.admin : MemberRole.member,
    joinedAt: DateTime.parse(json['joined_at'] as String),
    userName: json['user_name'] as String? ?? json['profiles']?['name'] as String?,
    userEmail: json['user_email'] as String? ?? json['profiles']?['email'] as String?,
    userAvatar: json['user_avatar'] as String? ?? json['profiles']?['avatar_url'] as String?,
  );
}
