import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/repositories/plan_template_repository.dart';

import 'in_memory_crud.dart';

class InMemoryPlanTemplateRepository extends InMemoryCrud<PlanTemplate>
    implements PlanTemplateRepository {
  InMemoryPlanTemplateRepository({Iterable<PlanTemplate> seed = const []})
    : super((p) => p.id, seed);
}
