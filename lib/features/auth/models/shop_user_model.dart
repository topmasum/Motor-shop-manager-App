class ShopUserModel {
  final String uid;
  final String email;
  final String shopName;
  final DateTime createdAt;

  ShopUserModel({
    required this.uid,
    required this.email,
    required this.shopName,
    required this.createdAt,
  });

  // Converts the object into a map to save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'shopName': shopName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Creates an object from Firestore data
  factory ShopUserModel.fromMap(Map<String, dynamic> map) {
    return ShopUserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      shopName: map['shopName'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}