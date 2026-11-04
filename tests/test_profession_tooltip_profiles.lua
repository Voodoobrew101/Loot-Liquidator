-- Exercise actual projection, condition selection and valuation with synthetic yields/prices.
local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetTime=function()return 100 end
time=function()return 100 end
for _,name in ipairs({'Professions.lua','ConversionEngine.lua','Badges.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.CharacterKey=function()return 'Player'end
local function character(skill)
    return {professions={Inscription=true},recipes={[100]={learned=true}},
        researchProfiles={['Inscription:9']={skill=skill,specialization='none',observed=100}}}
end
LL.db={characters={Player=character(10),Alt=character(40),Other=character(60)},
    professionTooltipProfiles={},tooltipDetail=3,rateProfile=1,manualProfessionProfiles={
        Player={['Inscription:9']={enabled=true,skill=90,specialization='none'}}}}
LL.GetResearchProfessionSnapshot=function()return 10,'none'end
LL.GetCachedOperationInfo=function()end
LL.AHFeeRate=function()return 0 end
LL.GetOutputPrice=function()return 100 end
LL.EligibleDisenchant=function()return false end
LL.Conversions={[1]={{method='Mill',profession='Inscription',recipeID=100,inputCount=5}}}
LL.ResolveEvidenceModel=function(self,f,option)
    local ctx=self:ProcessingPlayerConditions(f,option.name,option.recipeID,option.character)
    return {inputCount=5,confidence=80,context=ctx,materials={{id=10,chance=1,
        expectedQuantity=(ctx.effectiveSkill or 0)/10,minQuantity=1,maxQuantity=10,confidence=80}}}
end
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return {}end
local f={id=1,classID=7,count=5,expansionID=9,context={}}
local original=LL:ConversionOptions(f)
assert(#original==1 and original[1].value==20 and original[1].available)
local baseModel=original[1].yieldModel
local function project(selection)
    LL.db.professionTooltipProfiles.Inscription=selection
    return LL:TooltipConversionOptions(f,original)
end
local alt=project('Alt')
assert(#alt==1 and alt[1].value==80 and alt[1].character=='Alt')
assert(alt[1].yieldModel.context.character=='Alt' and not alt[1].yieldModel.context.simulated)
assert(project('Other')[1].value==120,'selected character replaces previous results')
local hypothetical=project('@hypothetical')
assert(#hypothetical==1 and hypothetical[1].value==180 and hypothetical[1].yieldModel.context.simulated)
assert(hypothetical[1].available==false,'hypothetical never grants profession access')
assert(#project('@hide')==0 and #project('Deleted character')==0)
assert(project('@auto')[1]==original[1],'automatic retains existing available-character quote')
LL.db.characters.Alt.altMethods={M=false}
assert(project('Alt')[1].available==false,'explicit alt exclusion still applies')
assert(original[1].value==20 and original[1].available and original[1].yieldModel==baseModel)
assert(baseModel.context.character=='Player' and LL.db.rateProfile==1,'global rates and cached original model unchanged')
assert(f.currentCanDisenchant==nil,'projected evaluation does not modify original facts')
local function render(selection)
    LL.db.professionTooltipProfiles.Inscription=selection
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
    LL:AppendRecommendationTooltip(tip,{action='A',rawAuction=30,netAuction=30,facts=f,conversionOptions=original})
    return table.concat(tip.lines,'\n')
end
assert(not render('Alt'):find('Milling',1,true),'excluded selected alt is hidden')
LL.db.characters.Alt.altMethods=nil
local text=render('Alt')
assert(text:find('Milling — Alt',1,true) and text:find('80 copper',1,true))
text=render('@hypothetical')
assert(text:find('Milling — Hypothetical',1,true) and text:find('180 copper',1,true))
assert(not render('@hide'):find('Milling',1,true))
print('PASS: selected-character and Hypothetical quotes, hidden mode, exclusions, original decision/model/global-rate isolation')

-- A current enchanter must not lend live spellbook access to a selected alt
-- or to a hypothetical quote, even though it still permits real DE decisions.
LL.CurrentHasEnchanting=function()return true end
LL.EligibleDisenchant=function()return true end
LL.DisenchantEstimate=function()return {value=10}end
LL.db.professionTooltipProfiles={Enchanting='Alt'}
local de={{name='Disenchant',profession='Enchanting',letter='D',available=true,value=10}}
local selectedDE=LL:TooltipConversionOptions(f,de)
assert(#selectedDE==1 and selectedDE[1].available==false,'current enchanting cannot grant access to selected alt')
LL.db.professionTooltipProfiles.Enchanting='@hypothetical'
assert(LL:TooltipConversionOptions(f,de)[1].available==false,'hypothetical cannot use live enchanting access')
assert(de[1].available==true,'actual disenchant recommendation access remains unchanged')
print('PASS: live enchanting access cannot leak into selected-alt or Hypothetical display contexts')
