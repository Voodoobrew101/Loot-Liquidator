-- Statistical helpers shared by disenchanting and other processing research.
-- Prior SavedVariables brackets remain untouched. Nearby observations are
-- borrowed only when expansion, rarity, gear/source and specialization
-- mechanics are compatible; never assume a Blizzard probability formula.
local _, LL = ...
local exp, abs, min = math.exp, math.abs, math.min
local SAFE_BREAKPOINTS = {1,5,10,15,20,25,30}
local MIDNIGHT = {[107649]=true,[107648]=true,[107647]=true,[107646]=true}
local RELEVANT = {[2]=107648,[3]=107647,[4]=107646}

function LL:ResearchTolerance()
    local n=tonumber(self.db and self.db.researchSkillTolerance)
    if not n then return 10 end
    return math.max(0,math.min(40,n))
end

local function ParseSpec(s)
    if type(s)~="string" or s:find("unverified",1,true) then return nil end
    if s:sub(1,9)=="verified:" then s=s:sub(10) end
    local nodes={}
    if s=="none" or s=="" then return nodes end
    for id,rank in s:gmatch("(%d+)=(%d+)") do
        nodes[tonumber(id)]=tonumber(rank)
    end
    if not next(nodes) then return nil end
    return nodes
end
local function CrossesBreakpoint(a,b)
    for _,point in ipairs(SAFE_BREAKPOINTS) do
        if (a<point and b>=point) or (b<point and a>=point) then return true end
    end
    return false
end

-- Returns the skill equivalent correction for permitted spec-point changes.
-- A root/rarity specialization point grants skill; crossing a perk milestone
-- is never interpolated. For unknown specialization trees require exact match.
function LL:ResearchSpecSkillCorrection(oldSpec,newSpec,quality,method,expansion)
    if oldSpec==newSpec then return 0 end
    if method~="Disenchant" or expansion~=11 then return nil end
    local old,new=ParseSpec(oldSpec),ParseSpec(newSpec)
    if not old or not new then return nil end
    for id in pairs(old) do if not MIDNIGHT[id] then return nil end end
    for id in pairs(new) do if not MIDNIGHT[id] then return nil end end
    local correction=0
    for id in pairs(MIDNIGHT) do
        local from,to=old[id] or 0,new[id] or 0
        if from~=to and (id==107649 or id==RELEVANT[quality]) then
            if CrossesBreakpoint(from,to) then return nil end
            correction=correction+(to-from)
        end
    end
    return correction
end

-- 'observed' and 'current' are bracket tables with skill/spec fields.
-- Returning nil prevents borrowing. The slider is a HARD distance cap.
function LL:ResearchWeight(observed,current,quality,method,expansion)
    if not observed or not current then return nil end
    if type(observed.specialization)~="string" or type(current.specialization)~="string"
        or observed.specialization:find("unverified",1,true)
        or current.specialization:find("unverified",1,true) then
        -- A string like unverified@Character is NOT proof that the spec stayed
        -- constant between skill increases. Exact legacy keys still match.
        return nil
    end
    local correction=self:ResearchSpecSkillCorrection(observed.specialization,
        current.specialization,quality,method,expansion)
    if correction==nil then return nil end
    local oldSkill,newSkill=tonumber(observed.skill),tonumber(current.skill)
    if not oldSkill or not newSkill then return nil end
    local delta=abs(oldSkill+correction-newSkill)
    local tolerance=self:ResearchTolerance()
    if delta>tolerance or (tolerance==0 and delta~=0) then return nil end
    return tolerance==0 and 1 or exp(-0.5*(delta/tolerance)^2),delta,oldSkill+correction
end

-- Input entries = [{bracket=b, weight=w}]. Zero-drop outcomes are included
-- automatically through the bracket denominator; do NOT multiply by chance
-- twice. Histogram counts are weighted just like material quantities.
function LL:CombineResearchEntries(entries,currentSkill,minimum)
    local mats,weighted,weightSquares,raw={},0,0,0
    local exact,borrowed=0,0
    for _,entry in ipairs(entries or {}) do
        local b,w=entry.bracket,entry.weight
        if b and type(b.total)=="number" and b.total>0 and type(w)=="number" and w>0 then
            weighted=weighted+w*b.total
            weightSquares=weightSquares+w*w*b.total
            raw=raw+b.total
            if entry.exact then exact=exact+b.total else borrowed=borrowed+b.total end
            for id,m in pairs(b.mats or {}) do
                local target=mats[id] or {quantity=0,occurrences=0,quantityCounts={},min=nil,max=nil}
                target.quantity=target.quantity+(m.quantity or 0)*w
                target.occurrences=target.occurrences+(m.occurrences or 0)*w
                if m.min then target.min=math.min(target.min or m.min,m.min) end
                if m.max then target.max=math.max(target.max or m.max,m.max) end
                for q,n in pairs(m.quantityCounts or {}) do
                    target.quantityCounts[q]=(target.quantityCounts[q] or 0)+n*w
                end
                mats[id]=target
            end
        end
    end
    if weighted<=0 then return nil end
    local trendApplied=false
    currentSkill=tonumber(currentSkill)
    minimum=tonumber(minimum) or 30
    -- A conservative local trend is only calculated after enough independently
    -- populated, compatible skill levels exist. No extrapolation beyond the
    -- observed interval, no assumptions about a per-point Blizzard formula.
    if currentSkill and weighted>=minimum then
        local levels,lo,hi={},nil,nil
        local sx,sxx=0,0
        for _,entry in ipairs(entries or {}) do
            local x=entry.adjustedSkill
            local b,w=entry.bracket,entry.weight
            if type(x)=="number" and b and b.total and w then
                levels[x]=(levels[x] or 0)+b.total
                lo=math.min(lo or x,x);hi=math.max(hi or x,x)
                sx=sx+b.total*w*x
                sxx=sxx+b.total*w*x*x
            end
        end
        local distinct,allLarge=0,true
        for _,n in pairs(levels) do
            distinct=distinct+1
            if n<10 then allLarge=false end
        end
        local variance=sxx-sx*sx/weighted
        if distinct>=3 and allLarge and lo and hi and hi-lo>=4
            and currentSkill>=lo and currentSkill<=hi and variance>0.001 then
            local xbar=sx/weighted
            -- Material absent from a bracket contributes zero to that
            -- observation's outcome. Occurrence and quantity fits are separate.
            for id,mat in pairs(mats) do
                local sy=mat.occurrences
                local sq=mat.quantity
                local sxy,sxq=0,0
                for _,entry in ipairs(entries) do
                    local b,x,w=entry.bracket,entry.adjustedSkill,entry.weight
                    if type(x)=="number" and b and w then
                        local m=b.mats and b.mats[id]
                        if m then
                            sxy=sxy+w*x*(m.occurrences or 0)
                            sxq=sxq+w*x*(m.quantity or 0)
                        end
                    end
                end
                local slopeOccurrence=(sxy-xbar*sy)/variance
                local slopeQty=(sxq-xbar*sq)/variance
                local oldChance=sy/weighted
                local oldQty=sq/weighted
                -- 50% shrinkage protects against noise in sparse skill groups.
                local chance=math.max(0,math.min(1,oldChance+.5*slopeOccurrence*(currentSkill-xbar)))
                local qty=math.max(chance,oldQty+.5*slopeQty*(currentSkill-xbar))
                qty=math.min(qty,math.max(chance,oldQty*2))
                mat.occurrences=chance*weighted
                mat.quantity=qty*weighted
            end
            trendApplied=true
        end
    end
    return {mats=mats,total=raw,exactSamples=exact,borrowedSamples=borrowed,
        trendApplied=trendApplied,effectiveSamples=weighted,
        independentEquivalent=weightSquares>0 and weighted*weighted/weightSquares or 0}
end

-- Processing confidence: evidence-strength index (0..100), NOT the
-- probability that the next random operation will equal its expected value.
-- Item-specific recorded results gradually improve an existing source model.
-- Exact fixed-output recipes are rated independently of a market quote.
-- No WoW/TSM drop rates are invented to manufacture high confidence numbers.
local function bounded(n,lo,hi)
    n=tonumber(n) or 0
    return math.max(lo,math.min(hi,n))
end
function LL:ProcessingConfidenceScore(f,option,model,materialsOnly)
    if type(option)~="table" then return nil end
    local method=option.name
    if method~="Disenchant" and method~="Mill" and method~="Prospect"
        and method~="Smelt" and method~="Craft" and method~="Recycle"
        and method~="Research" then return nil end
    local kind=model and model.kind
    if method=="Smelt" and option.outputID and option.outputCount
        and option.inputCount and option.dataSource then
        return 99,"fixed recipe"
    end
    if kind=="fixed" then return 99,"fixed recipe" end
    local sample=model and model.samples or 0
    local estimate=option.personalResearch or option.estimate
    -- The observation tracker records exact and compatible nearby profiles.
    -- Prefer their independent effective sample count, not the number of
    -- item redraws or the total amount of reagents returned.
    local observed=estimate and (estimate.independentEquivalent
        or estimate.effectiveSamples or estimate.samples) or 0
    if kind=="observed" and (model.samples or 0)>observed then
        observed=model.samples
    end
    observed=bounded(observed,0,1e8)
    local prior,priorWeight,baseLabel=45,0,"possible outputs"
    if kind=="fixed" then prior,baseLabel=99,"fixed recipe"
    elseif kind=="mean" or kind=="marginal" then
        prior=72; baseLabel="published yield reference"
        if model and model.referenceURL then prior=75 end
        if model and model.referenceFamily then prior=73 end
    elseif kind=="observed" then prior,baseLabel=52,"personal observations"
    elseif kind=="candidates" then prior,baseLabel=35,"documented possible outputs"
    elseif model and model.materials and #model.materials>0 then
        prior,baseLabel=50,"identified outputs"
    end
    -- Qualitative source labels by themselves do not justify high scores.
    -- A documented sample adds evidence but does not imply the current
    -- skill/spec/quality is identical to the sampled one.
    local referenceN=bounded(sample,0,1e8)
    if (kind=="mean" or kind=="marginal") and referenceN>0 then
        prior=prior+18*(referenceN/(referenceN+1200))
    end
    if kind=="marginal" and model then
        for _,m in ipairs(model.materials or {}) do
            if m.assumedQuality or m.quantityLowerBound then
                prior=math.min(prior,64)
                break
            end
        end
    end
    if type(option.confidence)=="string" then
        if option.confidence=="personal-observed-pooled" then
            prior=40; baseLabel="observed research, pooled conditions"
        elseif option.confidence=="borrowed-other-gear-kind" then
            prior=24; baseLabel="borrowed equipment-type estimate"
        elseif option.confidence=="published-historical-mean" then
            prior=35; baseLabel="historical published average"
        elseif option.confidence=="generic-multi-item-empirical" then
            prior=36; baseLabel="pooled community results, profession unverified"
        elseif option.confidence=="generic-mixed-era-proxy" then
            prior=25; baseLabel="historical or version-mixed pooled results"
        end
    end
    if model and model.confidenceCap and method~="Disenchant" then
        prior=math.min(prior,model.confidenceCap)
    end
    -- A tiny sample cannot masquerade as a verified probability.
    local gameN=option.estimate and option.estimate.samples or 0
    if gameN>0 and option.estimate and option.estimate.modelKind=="observed" then
        local boost=32*math.min(1,gameN/(gameN+160))
        prior=math.min(88,prior+boost)
    end
    if type(option.confidence)=="string" and option.confidence=="observed-local" then
        prior=math.max(prior,67)
    end
    -- More independent local casts progressively improve the confidence,
    -- with diminishing returns. A low-confidence prior needs many samples
    -- before it approaches a high evidence score.
    local improvement=observed/(observed+180)
    local score=prior+(97-prior)*improvement
    if observed==0 and kind=="assumed" then score=25 end
    -- Large generic page counts are not hundreds of condition-matched
    -- personal disenchants. Prevent unjustifiably high confidence where
    -- skill, patch, item variants or quantity ranges have been pooled.
    if option.confidence=="generic-multi-item-empirical" then
        local types=estimate and estimate.inputTypes or 1
        score=math.min(score,56+math.min(14,(types or 1)*1.5))
    elseif option.confidence=="generic-mixed-era-proxy" then
        local types=estimate and estimate.inputTypes or 1
        score=math.min(score,35+math.min(17,(types or 1)*1.5))
    end
    if model and model.confidenceCap and method~="Disenchant" then
        score=math.min(score,model.confidenceCap)
    end
    score=math.floor(bounded(score,1,99)+.5)
    return score, observed>0 and ("%d matching observations"):format(observed) or baseLabel
end
