class UserProfile {
  const UserProfile(
      {required this.name,
      required this.email,
      this.tutorialCompleted = false});
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      // Profiles created before the tour was added belong to returning users.
      tutorialCompleted: json['tutorialCompleted'] != false);
  final bool tutorialCompleted;
  final String name;
  final String email;
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'tutorialCompleted': tutorialCompleted,
      };
}
