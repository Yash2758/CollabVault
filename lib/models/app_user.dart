import 'package:equatable/equatable.dart';

enum AppUserType {
  student,
  employee,
  teacher,
  companyOwner,
}

extension AppUserTypeExtension on AppUserType {
  String get name => toString().split('.').last;

  static AppUserType fromString(String value) {
    return AppUserType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => AppUserType.student,
    );
  }
}

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePictureUrl;
  final AppUserType userType;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePictureUrl,
    this.userType = AppUserType.student,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString(),
    profilePictureUrl: json['profilePictureUrl']?.toString(),
    userType: AppUserTypeExtension.fromString(
      json['userType']?.toString() ?? AppUserType.student.name,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'profilePictureUrl': profilePictureUrl,
    'userType': userType.name,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    profilePictureUrl,
    userType,
  ];
}
