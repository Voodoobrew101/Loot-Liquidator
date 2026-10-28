-- Optional recommended TSM setup. TSM owns profile/group/operation imports.
-- A real TSM group+operations export can be inserted in this bundle later.
-- Never generate or modify another addon's SavedVariables.
local _, LL = ...

-- User-supplied TSM export, provided verbatim. We never change TSM settings;
-- this is only a selectable text field for Ctrl+C, then paste into TSM.
LL.RecommendedTSMExport = [=[fE5YUTrYvyyqnlYUaBfmoiRgcniawckc19QlhGKiAzheKyehjNjZQXQjztYgMIDJMnLLZs(eeOhb9imlYdGFe8kUwpcZISoNQQ(sDk7Xwa2GF95u)Nl1P6ldU7vx8Ix)SV)L)9ZF1xD(Pvxvu9Fg87)q(tOeLqBEYtY5Y98OMqaulArQgHcvps5gPDTsQhvkUUxkafbsbysJu3Brn3fxMsT37TSjX07mJsyuafKoKJqjdHktiszceYJqncXsbPzyAWiiNzuKumgd5mtHSIJlJlXyKZji016cqCGeyLf4KuGLsX(ySxkfhBLJTI7gkngXbsJZznoqACG0OUbx4gcPTOBtH3UwUlN5mhk0cMDTkshQ6rjJ4gZuSomjafjHfO0qvumgzvGrnc1yRjyRU5zgTbzmsOvgZeIcJBAx2HO0qsyiKHTg6SwNeE(1yiuwF5dOlneDw9hR6q)iApMGrthYiKMwhDVTwKkejEdgJ0USeI9CoJjKUgHurBzJlJiT2veRosPF5w2vTjDM5ULl6yD0YtAwEdtjnH7dbSw3z2QU0O7mZrrZDapizOsV5wuHq)MA3ID3oOVsvmbo1CZT2y3WCAeh1z4rR3XH21H1Iw56SAUZmNlKE352BWcE7hiLEY4gt6iJSNGXTg6EhjKAhYBz3Prl792fMU16MkAxlvN4KYW6yxsK0XgsJD3Q5U76R9fim442B7ImWgmtjrmnITPgvjrCSDMQlEUDB4Mgio0UD7hEufId1t7SZI4E)JQhphOFu9XIQhglI5rCu(WI0JtW1hpQ)XJIhpkE8O4XJ6pUbYqoQEDpvlO)iI2peQi7r9BHoY)y9JQxj)tXWRC0YrXxkJ4O(PI9P4M6vjK(9Ng9TSiILrSkI1rCcM5r6ZJ8xWXSmkEksetJydM1r(BIIVbxF(BMgWmSEkoUEafqSHI0xXOO4N4FjjM20Y((pW2NbPHh94FAKMcppQ9xCD7Ve9)YRGgEFoxg2mXPz(NlhW(tij9m7tXb(ZJyreRIyDehfFbnILrScNpIi9JRpzu(lJYp)etG9i98plO3Ukk)DVsyGDnnIJIVoQFPJINosVesODrI)eJ2pHOLSM7OAAzVDzddp7mCIfy0eiWsweJT7FNVqUDI0nzP4npCgElmt4zReymufXAeRmKiMhXce7)oTqoYo6SKL5rSkI1rC7zv4jZC4TiA(sGgkjKA)oVgIIiwizcxN)Wxhjzises6M3QOH4iBHAYq5jtrqehrHrGJ0KRX2KisfKl(TXEBjikS(ebVXfq(TJwIfQIGJ8e1pfjO1zcZmjn0tjpm6sblyDksOnLkuffkRvMG(Pw7gcHxMUk)jcsIYjNaE1sBsbVXVNCt(TK2fyQ3tzZNQYAi)N9W9KW)1hn2essajDt3neCk20rGfVMQgY)98EcQ6(wILybKuATXjEsj0b2uYMMqLL0WZvC)ir6QdL2FFBEILsGVXK0PeqM(rPew4WAcC)DAi5)Q3M1XKeeH809Ml92qAkLikjKuivuAeH80ni3fHesOTegIq5sckxseHKbvrMgvE0Ex(O9MD3PBMuNxSkF18Fz5V6PlZsRsxnjB4VByJHTfxNvvLpn7YTpTkDwT1XTF7zzZs3SSE3G)0LBVyrrzP9Y7gmYEHXxSkVmRQfV97YwnTOYfG9ddG)6wx(X)vAv2IInRduz2Ub)HhTBWF8)TnDmKcVi9MTxLEZlRYNKD348PVmRAs2Q6V69tSQT88SYI11xw(1H4RwuLTErXYPhqNFV3W)C1uyHBQVC70nvP267xu(W85RkQY(BfV9SMRn49VjlR8FSjDvDE972NChe5NDtzoi3(KDd(lLFlB4rdNyRLXPRZGF)yYjgYWFy4QnxL5D8WTxLVYLU36CCDDr5pcX5Q0LURw(BPNi)YQuzlKNMww(n5ZMx)yN3GWhpSt0JhspEi5W7kTQEE26S6rRkwLTDttPEazYUbNcTYrpV8btSBHU4)IS6fft3ZwAWIQlM8MdyKBD5CXS86rucz(Da2AKcf(tDQanGTthFvA1BYQ)PkV5(E19nx5IInWo06NpkDz96fBt9ttRxmAC6Q3S485BYxoDr5dH9N3EAZgSlVUC3GZSH5r3noBzXBDx7MbFpKMp(A3aZ6SLlpEORBC2OZZMdQ(cxUC61ZpEiC8f(d(b5KKFEVOKoV0)8E1lL6leqNtYVq8Coj(8HZ5d)ZeTwFyF(G58XoxCcrEyZFWa2h59H7g8mOB)8)7TzRshVmB0M3T4o)pVa6Zxw5oi4od0UtBHDdMm7G0fl2ny6Ik7g8RDWm4FZxm6Q08LlkFGDJ60z1zv(Jot3N8b7LGbJLJlGPZf3F96ZarRkE33LUCtw5VzwomrBpeypym1BcQNjh(HRx7tzNJBBpfu(q71VbjYx7fjCwbeO8bopdez3GxTBWF2oPD9pzlYrPZ7hIlFG)sRcgSF)vWuAGl)6MgYF9J8C3GXwjApiuNc)x()oBFYTR7)T62Ut(LV2NZthx52DwNcwGDYw2Ful8klYbPHtgPlpU9Ki8JGRsjh13bGn5Rl)g6jSJ6c5rUB18db3Ob6hLhypLXorgS2JPNWpQDRqo)W))]=]

function LL:RecommendedTSMExportAvailable()
    return type(self.RecommendedTSMExport)=="string"
        and self.RecommendedTSMExport:match("%S")~=nil
end

function LL:RecommendedTSMSetupText()
    if self:RecommendedTSMExportAvailable() then
        return self.RecommendedTSMExport
    end
    return table.concat({
        "Voodoo's Recommended TSM Setup - export not yet bundled", "",
        "Loot Liquidator does not include Voodoo's actual TSM group/operation export yet.",
        "This text is INFORMATION ONLY; it is NOT a TSM import string.", "",
        "When the actual TSM export is provided, the bundled import text will",
        "appear here. Copy that text into TSM's own import interface.", "",
        "Strategy overview:",
        "- Auction valuable items before dumping them at vendor value.",
        "- Aim for quick turnover, with 48-hour posting and a decreasing price",
        "  target after unsuccessful listings, where supported by TSM.",
        "- Avoid posting when the operation's minimum is not met.",
        "- Keep reagents on a separate lower-margin auctioning operation.", "",
        "Use TSM to configure or import operations; Loot Liquidator only",
        "reads the active settings and makes recommendations.",
    }, "\n")
end

function LL:CreateTSMRecommendedPanel()
    local panel=CreateFrame("Frame")
    local function label(text,template,y,width)
        local fs=panel:CreateFontString(nil,"ARTWORK",template or "GameFontHighlight")
        fs:SetPoint("TOPLEFT",panel,"TOPLEFT",18,y)
        fs:SetWidth(width or 650)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        return fs
    end
    label("Voodoo's Recommended TSM Setup", "GameFontNormalLarge",-20)
    label("An optional TradeSkillMaster import preset for Loot Liquidator users.",
        "GameFontHighlight",-59)
    local status=label("", "GameFontHighlightSmall",-94,690)
    local button=self:CreateSettingsButton(panel)
    button:SetSize(290,29)
    button:SetPoint("TOPLEFT",panel,"TOPLEFT",18,-129)
    button:SetText("View recommended setup")
    button:SetScript("OnClick",function()
        if LL.ShowCopy then
            LL:ShowCopy("Voodoo's Recommended TSM Setup",LL:RecommendedTSMSetupText())
        end
    end)
    label("How to use", "GameFontNormal",-182)
    label("1. Open the text above. Once the TSM export is bundled, select and copy it.\n"..
        "2. In TSM, use its own group/operation import feature.\n"..
        "3. Your existing TSM settings remain unchanged unless you explicitly import there.\n"..
        "4. Loot Liquidator automatically reads your active TSM pricing and operations.",
        "GameFontHighlightSmall",-208,720)
    label("This addon never writes another addon's profile or SavedVariables.",
        "GameFontDisableSmall",-315)
    panel:HookScript("OnShow",function()
        status:SetText(LL:RecommendedTSMExportAvailable()
            and "|cff44dd88Ready: import text is bundled. Use the button to copy it.|r"
            or "|cffffbb55Pending: Voodoo's actual TSM export has not been provided yet.|r")
    end)
    return panel
end
