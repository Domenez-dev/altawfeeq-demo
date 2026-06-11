class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? therapeuticGoal;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.therapeuticGoal,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      therapeuticGoal: json['therapeutic_goal'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'therapeutic_goal': therapeuticGoal,
  };
}
