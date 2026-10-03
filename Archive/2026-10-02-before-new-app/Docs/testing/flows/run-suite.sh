#!/bin/bash
# ProTip365 E2E suite runner — collects evidence on every failure.
export ANDROID_HOME=~/Library/Android/sdk
export PATH="$PATH:$HOME/.maestro/bin:$ANDROID_HOME/platform-tools"
RESULTS=~/Desktop/protip365-e2e-results
FLOWS=~/protip365-e2e
mkdir -p "$RESULTS"
SUMMARY="$RESULTS/summary.txt"
: > "$SUMMARY"

for flow in "$FLOWS"/flow-*.yaml; do
  name=$(basename "$flow" .yaml)
  echo "===== RUNNING $name ====="
  adb logcat -c -b crash 2>/dev/null
  if maestro test "$flow" --debug-output "$RESULTS/$name-debug" > "$RESULTS/$name-maestro.log" 2>&1; then
    echo "$name PASS" | tee -a "$SUMMARY"
  else
    echo "$name FAIL" | tee -a "$SUMMARY"
    adb exec-out screencap -p > "$RESULTS/$name-failure.png" 2>/dev/null
    {
      echo "=== crash buffer after $name $(date) ==="
      adb logcat -d -b crash -v time
      echo "=== main buffer grep ==="
      adb logcat -d | grep -iE "protip365|AndroidRuntime|FATAL" | tail -60
    } > "$RESULTS/$name-logcat.txt" 2>&1
    # If the app crashed, relaunch so the next flow starts from a live app
    adb shell am start -n com.defacto365.protip365/.MainActivity >/dev/null 2>&1
    sleep 4
  fi
done
echo "===== SUITE DONE ====="
cat "$SUMMARY"
