import 'package:flutter/foundation.dart';

import '../models/mom_state.dart';

/// Global controller for the mom mascot.
///
/// Two channels:
///  - [state]    → the calm half-body mascot in the home header (mostly idle).
///  - [reaction] → a full-body pop-in (top-right, Clash-of-Clans style) shown
///                 by [MomPopupHost] when the parent logs something.
class MomController {
  MomController._();

  static final ValueNotifier<MomState> state = ValueNotifier(MomState.idle);

  /// Non-null while a corner pop-in reaction should be visible.
  static final ValueNotifier<MomState?> reaction = ValueNotifier(null);

  static int _token = 0;

  /// Header mascot state (auto-returns to idle).
  static void trigger(MomState newState,
      {Duration holdFor = const Duration(seconds: 3)}) {
    state.value = newState;
    Future.delayed(holdFor, () {
      if (state.value == newState) state.value = MomState.idle;
    });
  }

  /// Full-body corner pop-in. Auto-dismisses; newer reactions replace older.
  static void showReaction(MomState s,
      {Duration holdFor = const Duration(milliseconds: 2600)}) {
    final myToken = ++_token;
    reaction.value = s;
    Future.delayed(holdFor, () {
      if (_token == myToken) reaction.value = null;
    });
  }

  static void setIdle() => state.value = MomState.idle;
}
