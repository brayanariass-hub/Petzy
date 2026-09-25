class CreateBookingCommand {
  const CreateBookingCommand({
    required this.petId,
    required this.sitterServiceId,
    required this.startAt,
    required this.durationMinutes,
    this.locationType = 'owner_home',
    this.serviceAddress,
    this.ownerNotes,
    this.petCount = 1,
  });

  final String petId;
  final String sitterServiceId;
  final DateTime startAt;
  final int durationMinutes;

  final String locationType;
  final String? serviceAddress;
  final String? ownerNotes;
  final int petCount;
}
