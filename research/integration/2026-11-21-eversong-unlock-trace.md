# Eversong Diamond eligibility through the baseline pipeline

The reported Umbral Tin tooltip retained a calculator material with the text
condition `Proficient Processor per-ore unlock`. Fusion kept its conditional
mean separate from unconditional yields, but no runtime rule resolved that text
against the selected profession profile. Thus a known locked output remained
unavailable instead of becoming a numerical zero.

Current native build70961 binds each ore's one-point milestone to the Eversong
Diamond family242608/242712. Copper Consumer106981, Tin-vestigator106980, Silver
Scrapper106979 and Thorium Thresher106978 each have maximum rank1 and a matching
rank1 output milestone. Their learning-at-zero effects do not unlock the output.
The compiler validates the native entry, ore identities and output quality family.

Primary trait text: https://www.wowhead.com/profession-trait/tin-vestigator-106980
Current guide crosschecks:
https://www.wowhead.com/guide/midnight/professions/jewelcrafting-specializations
https://www.wow-professions.com/midnight/jewelcrafting-guide

The resolved model applies the gate before benchmarks and valuation. A known
invested allocation without the relevant point yields E=0 and P=0 for both
qualities. Unknown, stale, foreign-profession and mismatched-expansion contexts
remain unknown. No source observations or casts are rewritten. Structural zero
rows remain visible in tooltips even when ordinary zero modeled ranks are hidden.

An unlocked profile may use the existing conditional calculator mean when no
other positive family quantity anchors the model. The Tin reference is0.045
Diamonds per five ore, unranked and confidence10. This is not a measured hit
probability or a new cohort. Alternative qualitative unlock priors are not added
on top of it. Independent unknown source outcomes keep their partial status.

`tests/test_prospecting_output_gates.lua` exercises all seven ore variants through
real profile resolution and tooltip dispatch, zero versus one invested point,
learning at zero, foreign ore/profession/expansion isolation, conditional-only
source activation, partial-status preservation and immutable source fields.
