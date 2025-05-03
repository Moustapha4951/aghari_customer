class UserModel {
  final String id;
  final String name;
  final String phone;
  final String password;
  final String? imageUrl;
  final bool isSeller;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    this.imageUrl,
    this.isSeller = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      imageUrl: json['imageUrl'],
      isSeller: json['isSeller'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'password': password,
      'imageUrl': imageUrl,
      'isSeller': isSeller,
    };
  }
}
