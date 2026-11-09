# Unrecognized spells must not close a profession capture

The owner's first compact check identifies the running source commit as 477e27c
and recorder revision 4. It retains twenty complete Disenchant records, nineteen
R1 Radiant Shards and one R2 shard, all with actual START evidence, Enchanting
skill 64, bonus skill 0 and no specialization. No Disenchant diagnostic or scoped
gap exists. Twenty Craft diagnostics precede them; nevertheless, the study has
an unscoped Overlapping cast has unresolved coverage flag. The compact transfer
is 5,808 bytes and decodes to the original 107,896-byte JSON, confirming native
client zlib/base64 interoperability rather than just a codec-contract fixture.

BeginCraftCapture described the incoming spell, then finalized a pending capture
before rejecting an unrecognized description. The player's normal spell event
stream can therefore force-finish an unsettled Craft and call coverageGap with
no method, creating a global blocker. It can also discard a real Disenchant
START that has not yet succeeded. The historical export does not retain the
unrecognized incoming spell ID; the regression's ID is synthetic.

Revision 5 rejects unrecognized operations before touching pending state.
Recognized tracked overlaps still mark their recipe; inventory interference,
unknown Disenchant success without an isolated start, interrupted sessions and
truncation remain blocked. After upgrading, a blocked batch from an older
revision is retained and the next tracked capture starts a fresh batch. Existing
raw flags and research are not rewritten, reset or automatically approved.

The regression fails against 477e27c because an unrecognized spell immediately
adds a Craft diagnostic and global gap. With the repair, that spell leaves the
pending capture alone; the genuine Craft failure stays scoped. Replay all twenty
actual Disenchant receipts, with synthetic unrecognized events before their
successes: all twenty enter recipe-scoped baselines and preserve 19 R1 / 1 R2.
Two recognized overlapping Disenchant casts still block Disenchant. Upgrade
rollover is covered for both Disenchant and ordinary Craft.

The owner separately confirms exactly twenty attempts after crafting finished,
with no failed/interrupted disenchants. coverage-review.json pins the original
wire/decoded SHA256s, exact twenty operation IDs, this operator denominator and
the narrow recipe scope. reviewed-disenchant-subset.json is explicitly a derived
research view; it retains the same records, contexts, diagnostics and scoped
Craft gap and refers to the preserved original global flag. Four unscored exact
contexts total twenty observations. This review does not rehabilitate older
batches, approve Craft, change runtime rates or define specialization effects.
