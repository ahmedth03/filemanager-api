import '../entities/craftsman.dart';
import '../repositories/craftsmen_repository.dart';

class CreateCraftsmanProfileParams {
  const CreateCraftsmanProfileParams({
    required this.specialty,
    required this.bio,
    required this.wilaya,
    required this.city,
    required this.phone,
    required this.experience,
    this.hourlyRate,
  });

  final CraftsmanSpecialty specialty;
  final String bio;
  final String wilaya;
  final String city;
  final String phone;
  final int experience;
  final double? hourlyRate;

  Map<String, dynamic> toJson() {
    return {
      'specialty': specialty.key,
      'bio': bio,
      'wilaya': wilaya,
      'city': city,
      'phone': phone,
      'experience': experience,
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
    };
  }
}

class CreateCraftsmanProfileUseCase {
  const CreateCraftsmanProfileUseCase(this._repository);

  final CraftsmenRepository _repository;

  Future<Craftsman> call(CreateCraftsmanProfileParams params) async {
    if (params.bio.trim().length < 10) {
      throw ArgumentError('Bio must be at least 10 characters');
    }
    if (params.experience < 0 || params.experience > 50) {
      throw ArgumentError('Experience must be between 0 and 50 years');
    }
    return _repository.createCraftsmanProfile(params.toJson());
  }
}
