import '../../../models/complement.dart';
import '../data/complement_repository.dart';

class ComplementEligibility {
  const ComplementEligibility({
    required this.eligible,
    required this.automatic,
  });
  final List<Complement> eligible;
  final Complement? automatic;
}

class ComplementEligibilityService {
  ComplementEligibilityService({ComplementRepository? repository})
    : _repository = repository ?? SqliteComplementRepository();

  final ComplementRepository _repository;

  Future<ComplementEligibility> evaluate({
    required double paidTotal,
    required int? selectedComplementId,
  }) async {
    final eligible = await _repository.getEligibleComplements(paidTotal);
    final currentIsValid = eligible.any(
      (item) => item.id == selectedComplementId,
    );
    if (currentIsValid) {
      return ComplementEligibility(eligible: eligible, automatic: null);
    }
    return ComplementEligibility(
      eligible: eligible,
      automatic: eligible.length == 1 ? eligible.single : null,
    );
  }
}
