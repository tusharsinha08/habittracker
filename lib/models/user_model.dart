class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? height;
  final Map<String, dynamic>? otherDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDarkMode;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.otherDetails,
    required this.createdAt,
    required this.updatedAt,
    this.isDarkMode = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth']) 
          : null,
      height: map['height']?.toDouble(),
      otherDetails: map['otherDetails'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isDarkMode: map['isDarkMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'height': height,
      'otherDetails': otherDetails,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDarkMode': isDarkMode,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    Map<String, dynamic>? otherDetails,
    bool? isDarkMode,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      otherDetails: otherDetails ?? this.otherDetails,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
