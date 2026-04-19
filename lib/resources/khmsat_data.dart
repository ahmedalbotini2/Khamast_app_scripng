class KhamsatUser {
  final String name;
  final String rank;
  final String balance;
  final String imageUrl;
  final String profileUrl;

  KhamsatUser({
    required this.name, 
    required this.rank, 
    required this.balance, 
    required this.imageUrl,
    required this.profileUrl,
  });

  // تحويل البيانات القادمة من جافا سكريبت إلى كائن دارت
  factory KhamsatUser.fromMap(Map<String, dynamic> map, String url) {
    return KhamsatUser(
      name: map['name'] ?? 'غير معروف',
      rank: map['rank'] ?? 'بائع جديد',
      balance: map['balance'] ?? '0.00',
      imageUrl: map['image'] ?? '',
      profileUrl: url,
    );
  }
}