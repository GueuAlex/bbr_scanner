import 'package:equatable/equatable.dart';

/// Entité Utilisateur (Agent de contrôle)
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'AGENT',
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role];

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, role: $role)';
}
