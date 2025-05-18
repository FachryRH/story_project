class User {
  final String id;
  final String name;
  final String token;

  User({required this.id, required this.name, required this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] ?? json['id'],
      name: json['name'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'name': name,
      'token': token,
    };
  }
}
