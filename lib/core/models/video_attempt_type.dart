/// What kind of clip the athlete is analyzing — asked upfront (like the
/// reference app) mainly because a dunk-attempt clip has more going on in
/// frame (ball, rim, net) than a bare jump attempt, which could matter once
/// the detector is tuned with real data from both kinds of clips. Collected
/// and shown in the Analyze result's diagnostics for now; not yet used to
/// change detection behavior — that would need real comparative data first,
/// not another guess.
enum VideoAttemptType {
  dunkAttempt,
  jumpAttempt;

  String get title {
    switch (this) {
      case VideoAttemptType.dunkAttempt:
        return 'Dunk Attempt';
      case VideoAttemptType.jumpAttempt:
        return 'Jump Attempt';
    }
  }

  String get subtitle {
    switch (this) {
      case VideoAttemptType.dunkAttempt:
        return 'Rim or ball in frame';
      case VideoAttemptType.jumpAttempt:
        return 'No rim needed';
    }
  }

  String get storageKey => name;

  static VideoAttemptType? fromStorageKey(String key) {
    for (final v in VideoAttemptType.values) {
      if (v.storageKey == key) return v;
    }
    return null;
  }
}
