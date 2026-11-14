class Worker {
  const Worker({
    required this.userId,
    required this.name,
    required this.headline,
    required this.city,
    required this.categoryId,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.isAvailable,
    this.bio = '',
  });

  final String userId;
  final String name;
  final String headline;
  final String city;
  final String categoryId;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isAvailable;
  final String bio;

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      userId: map['user_id']?.toString() ?? '',
      name: map['display_name']?.toString() ?? 'استادکار',
      headline: map['headline']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? 'other',
      experienceYears: (map['years_experience'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      isVerified: map['is_verified'] == true,
      isAvailable: map['is_available'] != false,
      bio: map['bio']?.toString() ?? '',
    );
  }
}
