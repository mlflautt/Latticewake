# Cycle 067 — per-lane note-gate indicators

Publish the callback's bounded per-lane scheduled note state through an atomic
mask. Display each role's own gate instead of inferring every lane's activity
from the total active-lane count. Verify isolated lane activity, stop, panic,
and allocation checks. Label the indicator as a note gate, not an audio meter.
