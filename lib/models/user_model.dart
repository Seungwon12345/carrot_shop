class UserModel {
  final String id;
  final String name;
  final String email;
  final String? nickname;
  final String? profileImage;
  final String? birthday;
  final String? age;
  final String? gender;
  final String? mobile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.nickname,
    this.profileImage,
    this.birthday,
    this.age,
    this.gender,
    this.mobile,
  });

  // JSON to Model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'],
      profileImage: json['profileImage'],
      birthday: json['birthday'],
      age: json['age'],
      gender: json['gender'],
      mobile: json['mobile'],
    );
  }

  // Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nickname': nickname,
      'profileImage': profileImage,
      'birthday': birthday,
      'age': age,
      'gender': gender,
      'mobile': mobile,
    };
  }
}