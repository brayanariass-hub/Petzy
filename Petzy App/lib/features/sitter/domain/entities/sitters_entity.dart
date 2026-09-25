class SittersEntity {
  final String id;
  final String profileId;
  final String name;
  final String? bio;
  final int experienceYears;
  final String verificationStatus;
  final String backgroundCheckStatus;
  final double ratingAverage;
  final int totalReviews;
  final int completedBookings;
  final bool isAvailable;

  const SittersEntity({
    required this.id,
    required this.profileId,
    required this.name,
    this.bio,
    required this.experienceYears,
    required this.verificationStatus,
    required this.backgroundCheckStatus,
    required this.ratingAverage,
    required this.totalReviews,
    required this.completedBookings,
    required this.isAvailable,
  });
}
