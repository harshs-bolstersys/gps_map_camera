// templates_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';

class TemplatesState {
  final List<StampTemplate> templates;
  final String selectedTemplateId;

  const TemplatesState({
    this.templates = const [],
    this.selectedTemplateId = 'classic',
  });

  TemplatesState copyWith({List<StampTemplate>? templates, String? selectedTemplateId}) =>
      TemplatesState(
        templates: templates ?? this.templates,
        selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      );
}

class TemplatesController extends StateNotifier<TemplatesState> {
  TemplatesController() : super(const TemplatesState()) {
    _loadTemplates();
  }

  void _loadTemplates() {
    state = state.copyWith(templates: _defaultTemplates);
  }

  void selectTemplate(String id) => state = state.copyWith(selectedTemplateId: id);

  static final _defaultTemplates = [
    StampTemplate(
      id: 'classic',
      name: 'Classic',
      description: 'Location, date, time & coordinates',
      config: const StampConfig(showLocation: true, showDate: true, showTime: true, showCoordinates: true, showMap: true),
    ),
    StampTemplate(
      id: 'minimal',
      name: 'Minimal',
      description: 'Date, time only',
      config: const StampConfig(showLocation: false, showDate: true, showTime: true, showCoordinates: false, showMap: false),
    ),
    StampTemplate(
      id: 'advanced',
      name: 'Advanced',
      description: 'Full GPS data with altitude & compass',
      config: const StampConfig(showLocation: true, showDate: true, showTime: true, showCoordinates: true, showMap: true, showAltitude: true, showCompass: true, showAccuracy: true),
    ),
    StampTemplate(
      id: 'professional',
      name: 'Professional',
      description: 'Logo + coordinates + date for business',
      config: const StampConfig(showLocation: true, showDate: true, showTime: true, showCoordinates: true, showMap: true, showLogo: true),
      isPremium: false,
    ),
    StampTemplate(
      id: 'site_inspection',
      name: 'Site Inspection',
      description: 'Person name, note & full location',
      config: const StampConfig(showLocation: true, showDate: true, showTime: true, showCoordinates: true, showMap: true, showPersonName: true, showNote: true),
    ),
    StampTemplate(
      id: 'travel',
      name: 'Travel',
      description: 'Map + location + compass for explorers',
      config: const StampConfig(showLocation: true, showDate: true, showTime: true, showMap: true, showCompass: true, mapType: MapType.satellite),
    ),
    StampTemplate(
      id: 'real_estate',
      name: 'Real Estate',
      description: 'Address + contact + logo',
      config: const StampConfig(showAddress: true, showDate: true, showMap: true, showLogo: true, showContactNumber: true),
    ),
    StampTemplate(
      id: 'delivery',
      name: 'Delivery Proof',
      description: 'GPS + timestamp for delivery confirmation',
      config: const StampConfig(showLocation: true, showDate: true, showTime: true, showCoordinates: true, showAccuracy: true),
    ),
  ];
}

final templatesControllerProvider =
    StateNotifierProvider<TemplatesController, TemplatesState>(
  (ref) => TemplatesController(),
);
