import 'package:backpackr/shared/services/app_flow_service.dart';
import 'package:flutter/foundation.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController({AppFlowService? appFlowService})
    : _appFlowService = appFlowService ?? AppFlowService();

  final AppFlowService _appFlowService;

  Future<void> markIntroAsSeen() {
    return _appFlowService.markIntroAsSeen();
  }
}
