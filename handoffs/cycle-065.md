# Cycle 065 handoff — compact Stage layout

Base: `1a6ba16` (`v0.64.0-alpha.1`). The workspace selector moves onto its own
row in compact windows, leaving audio, transport, scene, diagnostics, and
panic visible. Macro controls use a readable fixed width and a horizontal
scroll area; lane cards also scroll instead of compressing. Segmented picker
labels no longer consume drawer width. Both drawers open together only at a
larger window width.

`make verify-release` passed the normal, ASan/UBSan, Swift, script and signed
bundle checks. Bundle UUID `368B297A-579E-314A-A21B-4A73E3F0084A`, version
`0.65.0-alpha.1`, build 72. Native review of one app instance showed the
transport, panic and inspector within the window, with readable macro labels;
the app was closed afterwards. The horizontal scroll areas appeared in the
accessibility tree, but automated scrolling returned a computer-use error, so
the gesture itself and every supported window size remain unverified.

No listening or audio-device result is claimed. Commit, tag, push, and hosted
verification are reported in the cycle response.
