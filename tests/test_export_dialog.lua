-- Exercise the actual export serializer, strict importer and native copy UI.
-- No WoW renderer/clipboard is claimed; the copy field's bytes are checked.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function eq(actual,expected,label)
    check(actual==expected,(label or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in pairs(a) do if not same(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
local widgets={}
local function widget(kind,name,parent,template)
    local w={kind=kind,name=name,parent=parent,template=template,scripts={},shown=true,width=600,height=280,level=0}
    function w:SetScript(event,callback) self.scripts[event]=callback end
    function w:HookScript(event,callback)
        local before=self.scripts[event]
        self.scripts[event]=function(...) if before then before(...) end;callback(...) end
    end
    function w:RegisterEvent() end
    function w:SetSize(width,height) self.width=width;self.height=height end
    function w:SetWidth(width) self.width=width end
    function w:SetHeight(height) self.height=height end
    function w:GetWidth() return self.width end
    function w:GetHeight() return self.height end
    function w:SetPoint(...) self.point={...} end
    function w:ClearAllPoints() self.point=nil end
    function w:SetShown(value) if value then self:Show() else self:Hide() end end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self) end end
    function w:IsShown() return self.shown end
    function w:SetFrameStrata(value) self.strata=value end
    function w:SetFrameLevel(value) self.level=value end
    function w:GetFrameLevel() return self.level end
    function w:SetToplevel(value) self.toplevel=value end
    function w:SetClampedToScreen(value) self.clamped=value end
    function w:SetMovable(value) self.movable=value end
    function w:EnableMouse() end
    function w:RegisterForDrag() end
    function w:StartMoving() self.moving=true end
    function w:StopMovingOrSizing() self.moving=false end
    function w:Raise() self.raised=true end
    function w:SetClipsChildren(value) self.clips=value end
    function w:SetScrollChild(value) self.child=value end
    function w:SetVerticalScroll(value) self.scroll=value end
    function w:SetText(value)
        self.text=value
        if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end
    end
    function w:GetText() return self.text or '' end
    function w:SetFocus() self.focus=true end
    function w:ClearFocus() self.focus=false end
    function w:HighlightText() self.selected=self:GetText() end
    function w:SetCursorPosition(value) self.cursor=value end
    function w:SetAutoFocus(value) self.autoFocus=value end
    function w:SetFontObject(value) self.font=value end
    function w:GetFont() return 'native-font',12 end
    function w:GetNumLines() return math.max(1,math.ceil(#self:GetText()/math.max(1,self.width/6))) end
    function w:SetMultiLine(value) self.multiline=value end
    function w:SetMaxLetters(value) self.maxLetters=value end
    function w:SetMaxBytes(value) self.maxBytes=value end
    function w:SetTextInsets(...) self.insets={...} end
    function w:SetSpacing(value) self.spacing=value end
    function w:SetIndentedWordWrap(value) self.indented=value end
    function w:SetJustifyH(value) self.justify=value end
    function w:SetEnabled(value) self.enabled=value end
    function w:CreateFontString() return widget('FontString',nil,self) end
    function w:StripTextures() self.stripped=true end
    function w:SetTemplate(value) self.skinTemplate=value end
    if template=='BasicFrameTemplateWithInset' then
        w.TitleText=widget('FontString',nil,w)
        w.CloseButton=widget('Button',nil,w)
        w.NineSlice=widget('Frame',nil,w)
        w.Inset=widget('Frame',nil,w,'InsetFrameTemplate')
        w.Inset.NineSlice=widget('Frame',nil,w.Inset)
    elseif template=='UIPanelScrollFrameTemplate' then w.ScrollBar=widget('Slider',nil,w) end
    widgets[#widgets+1]=w
    return w
end
CreateFrame=widget
UIParent=widget('Frame','UIParent');UIParent.level=0
SettingsPanel=widget('Frame','SettingsPanel',UIParent);SettingsPanel.level=200
UISpecialFrames={};SlashCmdList={}
GameFontHighlightSmall='GameFontHighlightSmall';CLOSE='Close'
time=function()return 1000 end
GetTime=function()return 100 end
GetBuildInfo=function()return 'test','70783' end
local LL={db={characters={},recordDisenchants=true,recordConversions=true}}
for _,name in ipairs({'Core.lua','CraftRecording.lua','ImportedResults.lua','Settings.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.CharacterKey=function()return 'Current-Realm' end
local link='|cff0070dd|Hitem:500:0:0|h[A named item]|h|r'
local texture='|TInterface\\Icons\\test:16|t'
local source={records={},contexts={ctx={character='Other-Realm',equipment={link,texture},literal='literal\\u007c and |'}},
    studies={study={name='Recorded study'}},diagnostics={},droppedRecords=0}
for index=1,51 do
    source.records[index]={operationID='operation-'..index,recipeID=13262,method='Disenchant',
        successful=true,character='Other-Realm',build='70783',contextID='ctx',studyID='study',
        inputs={{itemID=100+index,quantity=1,expansionID=11,rarity=3,classID=4,hyperlink=link}},
        outputs={{itemID=500,quantity=2}},outputCoverage='complete',captureVersion=2,
        lootSlots={{itemID=500,quantity=2,hyperlink=link}}}
end
LL.db.craftResearch=source
local raw=LL:ExportCraftResearch(1)
local title,text,page,pages=LL:ExportRecordedResultsPage(1)
eq(page,1);eq(pages,3)
check(not text:find('|',1,true),'recorded JSON must not render link, color or texture sequences')
check(text:find('\\u007c',1,true),'JSON uses a literal safe Unicode escape')
check(same(assert(LL.DecodeImportJSON(text)),assert(LL.DecodeImportJSON(raw))),
    'safe export decodes to exactly the original observations and metadata')
eq(source.records[1].inputs[1].hyperlink,link,'display encoding must not change the stored link')
eq(source.contexts.ctx.equipment[2],texture)
eq(select(3,LL:ExportRecordedResultsPage(999)),3,'explicit pages clamp to final page')
eq(select(3,LL:ExportRecordedResultsPage()),1,'legacy no-argument next-page export still wraps')

-- The strict import path reads the exact copy field, not a rebuilt payload.
-- This rendering-only fixture deliberately lacks a native measured profile;
-- decoding preserves its links, but the importer must now reject its metadata.
local recipient=setmetatable({db={},Invalidate=function()end},{__index=LL})
local ok,message,count=recipient:ImportRecordedResults(text)
check(not ok,'rendering-only fixture cannot become measured evidence');eq(count.damaged,25,'missing native metadata rejected')
eq(count.accepted,0,'no legacy fallback for malformed native contexts')

LL:ShowRecordedResultsExport(true)
local f=assert(LL.copyDialog)
eq(f.template,'BasicFrameTemplateWithInset','dialog uses native Blizzard chrome')
eq(f.scrollFrame.template,'UIPanelScrollFrameTemplate')
eq(f.edit.template,nil,'multiline body must not inherit a single-line input border')
eq(f.strata,'FULLSCREEN_DIALOG');check(f.toplevel and f.raised and f.clamped)
check(f.level>SettingsPanel.level,'copy window must sit above Settings')
eq(f.point[1],'CENTER');eq(f.point[2],SettingsPanel,'dialog opens centered on the visible Settings window')
check(f.scrollFrame.clips,'text is bounded by the scroll viewport')
check(f.edit.multiline and not f.edit.autoFocus)
eq(f.edit.maxLetters,0);eq(f.edit.maxBytes,0,'long export pages must not silently truncate')
eq(f.edit:GetText(),f.contents,'copy field contains the exact safe JSON bytes')
eq(f.edit.selected,f.contents,'native selection is ready for Ctrl+C')
eq(f.edit.cursor,0);eq(f.scrollFrame.scroll,0,'opening starts at the beginning of the page')
check(f.edit.height>f.scrollFrame.height,'long text expands only the scroll child')
eq(f.page,1);eq(f.pages,3);eq(f.previous.enabled,false);eq(f.next.enabled,true)
eq(f.pageLabel.text,'Page 1 of 3')
check(f.previous.shown and f.next.shown and f.pageLabel.shown)
eq(#UISpecialFrames,1,'Escape closes this one reusable dialog')

-- Navigation uses a frozen export session, including the page count, records,
-- contexts and studies while new recording changes the live ledger.
source.records[1].outputs[1].quantity=99
source.contexts.ctx.equipment[1]='changed'
source.studies.study.name='changed'
source.records[52]=source.records[51]
f.next.scripts.OnClick(f.next)
eq(LL.copyDialog,f,'navigation reuses the native window')
eq(f.page,2);eq(f.pages,3)
local copied=assert(LL.DecodeImportJSON(f.edit:GetText()))
eq(copied.records[1].operationID,'operation-26')
eq(copied.retainedRecords,51,'appending a cast cannot shift the export session')
eq(copied.contexts.ctx.equipment[1],link)
eq(copied.studies.study.name,'Recorded study')
f.previous.scripts.OnClick(f.previous)
copied=assert(LL.DecodeImportJSON(f.edit:GetText()))
eq(copied.records[1].outputs[1].quantity,2,'older displayed pages retain their measured values')
f.next.scripts.OnClick(f.next);f.next.scripts.OnClick(f.next)
eq(f.page,3);eq(f.next.enabled,false)
copied=assert(LL.DecodeImportJSON(f.edit:GetText()))
eq(#copied.records,1);eq(copied.records[1].operationID,'operation-51')
f.next.scripts.OnClick(f.next);eq(f.page,3,'the final page cannot wrap unexpectedly')

local canonical=f.contents
f.edit.text='accidental key'
f.edit.scripts.OnTextChanged(f.edit,true)
eq(f.edit:GetText(),canonical,'editing cannot corrupt the selected export')
f.edit.selected=nil;f.selectAll.scripts.OnClick(f.selectAll)
eq(f.edit.selected,canonical)
f.edit.scripts.OnEscapePressed(f.edit)
check(not f:IsShown() and not f.edit.focus);eq(f.onPage,nil,'closing releases the recording snapshot')

-- Other ShowCopy consumers keep their exact data and do not inherit export
-- navigation or JSON encoding. Hidden Settings falls back to the screen.
SettingsPanel:Hide()
local generic='TSM | profile \\ value\nline two'
LL:ShowCopy('Recommended setup',generic)
eq(f.point[2],UIParent);eq(f.TitleText.text,'Recommended setup')
eq(f.edit:GetText(),generic,'generic TSM/CSV/report contents are byte-unchanged')
check(not f.previous.shown and not f.next.shown and not f.pageLabel.shown)
eq(f.onPage,nil);eq(#UISpecialFrames,1,'reopening does not add duplicate Escape handlers')
f.close.scripts.OnClick(f.close);check(not f:IsShown())

-- Optional skinning matches the installed UI; missing modules never prevent
-- a standalone native copy dialog from opening.
local skinCalls={buttons=0,close=0,scroll=0}
local skin={HandleButton=function()skinCalls.buttons=skinCalls.buttons+1 end,
    HandleCloseButton=function()skinCalls.close=skinCalls.close+1 end,
    HandleScrollBar=function()skinCalls.scroll=skinCalls.scroll+1 end}
ElvUI={{GetModule=function()return skin end}}
LL:ShowCopy('Skinned',generic)
eq(f.skinTemplate,'Default');eq(f.Inset.skinTemplate,'Default')
check(f.stripped and not f.NineSlice.shown)
eq(skinCalls.buttons,4);eq(skinCalls.close,1);eq(skinCalls.scroll,1)
LL:ShowCopy('Reuse',generic);eq(skinCalls.buttons,4,'reuse must not reskin the buttons repeatedly')
f.llCopyElvUISkinned=nil
ElvUI={{GetModule=function()error('optional module unavailable')end}}
check(LL:ShowCopy('Still usable',generic)==f,'an unavailable optional skin must not break export')
ElvUI=nil
LL.db.craftResearch=nil
LL:ShowRecordedResultsExport()
eq(f.page,1);eq(f.pages,1)
eq(#assert(LL.DecodeImportJSON(f.edit:GetText())).records,0,'empty recordings are still copyable')
check(not f.previous.shown and not f.next.shown)
-- Contract stubs for the native codec; actual zlib/base64 interoperability is
-- checked separately against the exact raw bytes emitted by this UI fixture.
local sources,encoded,serial={},{},0
C_EncodingUtil={
    CompressString=function(raw,method,level)
        eq(method,1,'native compression uses Zlib');eq(level,2,'native compression optimizes size')
        serial=serial+1;local token=('x%03d'):format(serial);sources[token]=raw;return token
    end,
    EncodeBase64=function(token)encoded[token]=token;return token end,
    DecodeBase64=function(token)return encoded[token] end,
    DecompressString=function(token,method)eq(method,1);return sources[token] end}
CopyToClipboard=function()error('protected clipboard API must never be called by addon export')end
-- Optional full-suite integration: actual successful cast events, new loot-slot
-- evidence and variant identities -> native popup -> the exact copied JSON.
-- Standalone dialog fixtures need no external file; tests/run.sh supplies it.
if arg and arg[1] then
    local file=assert(io.open(arg[1],'r'));local captured=file:read('*a');file:close()
    local measured=assert(LL.DecodeImportJSON(captured))
    LL.db.craftResearch={records=measured.records,contexts=measured.contexts,studies=measured.studies,
        diagnostics=measured.diagnostics,droppedRecords=measured.droppedRecords}
    f.close.scripts.OnClick(f.close);SettingsPanel:Show();LL:ShowRecordedResultsExport(false,true)
    eq(f.page,1);eq(f.pages,1);eq(f.point[2],SettingsPanel)
    local copied=assert(LL.DecodeImportJSON(f.edit:GetText()))
    check(same(copied,measured),'copy field preserves all event-captured facts and provenance')
    eq(copied.records[1].captureVersion,2)
    eq(copied.records[1].lootSlots[1].itemID,109693)
    eq(copied.records[3].inputs[1].itemLevel,280,'consumed variant survives native export')
    eq(copied.records[3].inputs[1].hyperlink,'item:109979:0:0:0:0:0:0:2')
    check(copied.diagnostics[#copied.diagnostics].studyID~=nil,'diagnostic links survive native export')
    local output=assert(io.open('/tmp/loot-disenchant-popup.json','w'))
    output:write(select(3,LL.DecodeImportJSON(f.edit:GetText())));output:close()
    print('PASS: live-event recorder fixture -> native export popup -> unchanged copied research JSON')
end
if arg and arg[2] then
    local file=assert(io.open(arg[2],'r'));local captured=file:read('*a');file:close()
    local measured=assert(LL.DecodeImportJSON(captured))
    LL.db.craftResearch={records=measured.records,contexts=measured.contexts,studies=measured.studies,
        diagnostics=measured.diagnostics,droppedRecords=measured.droppedRecords}
    f.close.scripts.OnClick(f.close);LL:ShowRecordedResultsExport(false,true)
    local copied=assert(LL.DecodeImportJSON(f.edit:GetText()))
    check(same(copied,measured),'Recycling receipts and aggregate reconciliation survive native copy')
    eq(#copied.records,20);eq(copied.records[1].method,'Recycle');eq(copied.records[1].captureVersion,3)
    eq(copied.records[1].bagReconciliation.operations,20)
    local output=assert(io.open('/tmp/loot-recycling-popup.json','w'))
    output:write(select(3,LL.DecodeImportJSON(f.edit:GetText())));output:close()
    print('PASS: Recycling20 receipt replay -> native export popup -> unchanged copied JSON')
end
-- Full-history export remains available to internal callers without becoming
-- the default. Its large payload uses the native codec rather than raw layout.
local merged={records={},contexts={},studies={},diagnostics={},droppedRecords=0}
for i=1,13 do
    local file=assert(io.open(('research/integration/measured-captures/2026-11-07-recycling-200-casts/export-page-%02d.json'):format(i),'r'))
    local page=assert(LL.DecodeImportJSON(file:read('*a')));file:close()
    for _,r in ipairs(page.records)do merged.records[#merged.records+1]=r end
    for k,v in pairs(page.contexts)do merged.contexts[k]=v end
    for k,v in pairs(page.studies)do merged.studies[k]=v end
    merged.diagnostics=page.diagnostics
end
LL.db.craftResearch=merged
f.close.scripts.OnClick(f.close);LL:ShowRecordedResultsExport(false,true)
local all=assert(LL.DecodeImportJSON(f.edit:GetText()))
eq(all.page,1);eq(all.pages,1);eq(#all.records,301);eq(all.retainedRecords,301)
check(not f.previous.shown and not f.next.shown,'one-copy export needs no page navigation')
check(same(all.records,merged.records) and same(all.contexts,merged.contexts)
    and same(all.studies,merged.studies) and same(all.diagnostics,merged.diagnostics),'all evidence survives one copy')
eq(f.edit.selected,f.contents,'all retained results are selected for one Ctrl+C')
local out=assert(io.open('/tmp/loot-recycling-200-popup.json','w'));out:write(select(3,LL.DecodeImportJSON(f.contents)));out:close()
-- Reproduce the 1.8 MB owner upload: export only its latest 169-record batch,
-- preserving all 683 saved records, its coverage flags and its diagnostics.
local path='research/integration/measured-captures/2026-11-07-disenchant-108-export-freeze/export-page-1.json'
local input=assert(io.open(path));local captured=assert(LL.DecodeImportJSON(input:read('*a')));input:close()
LL.db.craftResearch=captured
local history=LL:ExportCraftResearch('all')
LL:ShowRecordedResultsExport()
local latest,_,raw=LL.DecodeImportJSON(f.contents)
eq(#latest.records,169);eq(latest.retainedRecords,169);eq(latest.totalRetainedRecords,683)
eq(latest.exportScope,'latest-batch');eq(latest.exportStudyID,captured.records[#captured.records].studyID)
for _,r in ipairs(latest.records)do eq(r.studyID,latest.exportStudyID)end
local studyCount=0 for _ in pairs(latest.studies)do studyCount=studyCount+1 end;eq(studyCount,1)
check(latest.studies[latest.exportStudyID].coverageGaps['Disenchant:13262'],'filtering must not erase existing coverage gaps')
eq(#latest.diagnostics,50);eq(LL:ExportCraftResearch('all'),history,'export leaves every saved batch unchanged')
check(#f.edit:GetText()<=LL.MaxCopyTextBytes,'copy widget receives bounded compact text')
eq(f.edit.selected,f.contents,'latest batch is ready for one Ctrl+C')
out=assert(io.open('/tmp/loot-latest-batch.json','w'));out:write(raw);out:close()
f.close.scripts.OnClick(f.close)
eq(f.edit:GetText(),'','closing releases native text layout');eq(f.contents,'')
LL:ShowCopy('Oversize report',string.rep('x',LL.MaxCopyTextBytes+1))
check(#f.edit:GetText()<LL.MaxCopyTextBytes and f.TitleText.text:find('too large',1,true),'oversize text never reaches the native widget')
-- An active empty batch is newer than the last completed record.
captured.activeStudy='new-empty';captured.studies['new-empty']={startedAt=9999999999,label='New empty batch'}
LL:ShowRecordedResultsExport()
latest=assert(LL.DecodeImportJSON(f.contents));eq(#latest.records,0);eq(latest.exportStudyID,'new-empty')
eq(#captured.records,683,'starting/exporting another batch preserves history')
captured.activeStudy=nil;C_EncodingUtil=nil
LL:ShowRecordedResultsExport()
check(#f.edit:GetText()<=LL.MaxCopyTextBytes,'missing native codec cannot expose an oversized copy widget')
eq(#captured.records,683,'fallback does not remove older results')
print('PASS: latest-batch export, bounded compact copy, all-history preservation and native text cleanup')
print('PASS: '..checks..' native export dialog, literal JSON, importer, snapshot paging and optional skin assertions')
