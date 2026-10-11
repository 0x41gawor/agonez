import '../../api/atlas_models.dart';
import '../../data/mobile_repository.dart';

/// Narrow Atlas read boundary used by the UI and easy to replace in widget
/// tests. The production adapter delegates to the shared mobile repository so
/// device headers, locale negotiation and cache semantics stay centralized.
abstract interface class AtlasDataSource {
  Future<AtlasSearchResponse> search({String? query, int? planRunId});

  Future<LoadedValue<AtlasPeek>> loadPeek(
    int exerciseId, {
    AtlasPeek? embedded,
  });

  Future<LoadedValue<ExerciseDetail>> loadArticle(
    String slug, {
    bool preferCache = false,
  });
}

class MobileAtlasDataSource implements AtlasDataSource {
  const MobileAtlasDataSource(this.repository);

  final MobileRepository repository;

  @override
  Future<LoadedValue<ExerciseDetail>> loadArticle(
    String slug, {
    bool preferCache = false,
  }) => repository.loadAtlasArticle(slug, preferCache: preferCache);

  @override
  Future<LoadedValue<AtlasPeek>> loadPeek(
    int exerciseId, {
    AtlasPeek? embedded,
  }) => repository.loadAtlasPeek(exerciseId, embedded: embedded);

  @override
  Future<AtlasSearchResponse> search({String? query, int? planRunId}) =>
      repository.searchAtlas(query: query, planRunId: planRunId);
}
