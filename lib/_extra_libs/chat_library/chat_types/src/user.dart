import 'package:meta/meta.dart';

/// A class that represents user.
@immutable
class User {
  /// Creates a user.
  const User({
    this.avatarUrl,
    this.firstName,
    required this.id,
    this.lastName,
    this.metadata,
  });

  /// Remote image URL representing user's avatar
  final String? avatarUrl;

  /// First name of the user
  final String? firstName;

  /// Unique ID of the user
  final String id;

  /// Last name of the user
  final String? lastName;

  /// Additional custom metadata or attributes related to the user
  final Map<String, dynamic>? metadata;
}
