import 'package:flutter/foundation.dart';

import '../models/mom_state.dart';

/// Global, app-wide controller for the mom mascot. Any widget can call
/// [MomController.trigger] to play a reaction; she returns to idle automatically.
class MomController {
  MomController._();

  static final ValueNotifier<MomState> state = ValueNotifier(MomState.idle);

  static void trigger(MomState newState,
      {Duration holdFor = const Duration(seconds: 3)}) {
    state.value = newState;
    Future.delayed(holdFor, () {
      // Only revert if still showing the state we set (avoid clobbering a
      // newer reaction that arrived in the meantime).
      if (state.value == newState) state.value = MomState.idle;
    });
  }

  static void setIdle() => state.value = MomState.idle;
}
