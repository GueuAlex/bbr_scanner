import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.role = 'AGENT',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    );
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
    );
  }
}
