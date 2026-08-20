import 'event_checklist_model.dart';

/// Predefined checklist steps for arisan events
class EventChecklistSteps {
  static const List<String> defaultSteps = [
    'Kumpul',
    'Yasin & Sholawat',
    'Makan',
    'Kocokan',
    'Serah Terima Uang',
    'Foto Bersama',
    'Penutupan',
  ];

  static List<EventChecklistModel> createDefaultForPeriod(String periodId) {
    return List.generate(defaultSteps.length, (index) {
      return EventChecklistModel(
        id: '',
        periodId: periodId,
        stepName: defaultSteps[index],
        stepOrder: index + 1,
      );
    });
  }
}