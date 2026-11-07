-- Build-time provenance only. Never read GitHub from the game client.
local _,LL=...
-- BEGIN GENERATED BUILD INFO
LL.buildInfo={kind="unstamped",branch="unknown",commit="unknown",prs={},prStatus="unknown"}
-- END GENERATED BUILD INFO
function LL:BuildSummary()
    local b=self.buildInfo or {}
    local source=b.kind=="main" and "Main branch build" or b.kind=="pr" and "Pull request build"
        or b.kind=="branch" and "Branch build" or "Local build (source not verified)"
    local ids={} for _,pr in ipairs(b.prs or {}) do ids[#ids+1]="#"..pr.number end
    local prs=b.kind=="main" and "PRs beyond main: none" or #ids>0 and "PRs: "..table.concat(ids,", ")
        or "PR information unavailable"
    return source,prs
end
function LL:BuildDetails()
    local b=self.buildInfo or {};local source,prs=self:BuildSummary()
    local lines={"Loot Liquidator "..tostring(self.version or "?"),source,prs,
        "Branch: "..tostring(b.branch or "unknown"),"Source commit: "..tostring(b.commit or "unknown")}
    if b.headCommit then lines[#lines+1]="PR head: "..b.headCommit end
    if b.dirty then lines[#lines+1]="Includes local file changes" end
    for _,pr in ipairs(b.prs or {}) do
        lines[#lines+1]="#"..pr.number.." "..(pr.title or "")
        if pr.url then lines[#lines+1]=pr.url end
    end
    if b.runURL then lines[#lines+1]="Build: "..b.runURL end
    if b.repository then lines[#lines+1]="Repository: https://github.com/"..b.repository end
    lines[#lines+1]="Main branch builds include changes already merged into main. PRs above identify additional changes."
    return table.concat(lines,"\n")
end
