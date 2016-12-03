scoredItemTypes = { INVTYPE_2HWEAPON, INVTYPE_CHEST, INVTYPE_CLOAK,
  INVTYPE_FEET, INVTYPE_FINGER, INVTYPE_HAND, INVTYPE_HEAD, INVTYPE_HOLDABLE,
  INVTYPE_LEGS, INVTYPE_NECK, INVTYPE_RANGED, INVTYPE_RELIC, INVTYPE_ROBE, INVTYPE_SHIELD,
  INVTYPE_SHOULDER, INVTYPE_TRINKET, INVTYPE_WAIST, INVTYPE_WEAPON,
  INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPONOFFHAND, INVTYPE_WRIST,
  -- deDE
  "Schusswaffe", "Zauberstab", "Armbrust",
  -- enGB
  "Gun", "Wand", "Crossbow" }

function round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

function ShaguCheckItemType(slot)
  for id, scoredSlot in pairs(scoredItemTypes) do
    if slot == scoredSlot then
      return true
    end
  end
  return nil
end

function ShaguScoreCalculate(slot, rarity, ilvl, plvl)
  local bonus = 1

  if not ShaguCheckItemType(slot) then return nil end
  if not rarity then return nil end
  if not ilvl or ilvl == 0 then ilvl = plvl - 5 end
  if slot == INVTYPE_2HWEAPON then bonus = 2 end

  score = (rarity * ilvl) * bonus

  return score
end

function ShaguPlayerScore (target)
  if not UnitIsPlayer(target) then return nil end
  local count, ar, ag, ab, score = 0, 0, 0, 0, 0

  for i=1,19 do
    if GetInventoryItemLink(target, i) then
      local link = GetInventoryItemLink(target, i)
      _, _, itemLink = string.find(link, "(item:%d+:%d+:%d+:%d+)");
      _, _, itemRarity, itemLevel, _, _, _, itemEquipLoc, _ = GetItemInfo(itemLink)

      if itemRarity and itemEquipLoc then
        r,g,b, _ = GetItemQualityColor(itemRarity)
        ar = ar + r ; ag = ag + g ; ab = ab + b
        cscore = ShaguScoreCalculate(getglobal(itemEquipLoc), itemRarity, itemLevel, UnitLevel(target))
      end

      if cscore then
        score = score + cscore
        count = count + 1
      end
    end
  end
  ar = round(ar / count, 2);
  ag = round(ag / count, 2);
  ab = round(ab / count, 2);

  if score ~= 0 then return score, ar, ag, ab else return nil end
end

local ShaguPlayerScoreTooltip = CreateFrame("Frame")
ShaguPlayerScoreTooltip:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
ShaguPlayerScoreTooltip:SetScript("OnEvent", function()
    score, r, g, b = ShaguPlayerScore("mouseover")
    if score and r and g and b then
      GameTooltip:AddLine("ShaguScore: " .. score, r,g,b)
      GameTooltip:Show()
    end
  end)

ShaguItemScoreTooltip = CreateFrame( "Frame" , "ShaguItemScoreTooltip", GameTooltip )
ShaguItemScoreTooltip:SetScript("OnShow", function (self)
    local itemLevel = nil
    local itemRarity = nil
    local itemSlot = nil

    local lbl = getglobal("GameTooltipTextLeft1")
    if lbl then
      for i=1,GameTooltip:NumLines() do
        tmpText = getglobal("GameTooltipTextLeft"..i);

        if ShaguCheckItemType(tmpText:GetText()) then
          itemSlot = tmpText:GetText()
        end

        if (tmpText ~= nil) and (tmpText:GetText()) then
          local searchstr = string.gsub(ITEM_MIN_LEVEL, "%%[^%s]+", "(.+)")
          _, _, iLvl = string.find(tmpText:GetText(), searchstr);
          if iLvl ~= nil then itemLevel = iLvl end
        end
      end

      r,g,b = GameTooltipTextLeft1:GetTextColor()
      for i = -1, 6 do
        if round(ITEM_QUALITY_COLORS[i].r, 2) == round(r,2 )
        and round(ITEM_QUALITY_COLORS[i].g, 2) == round(g, 2)
        and round(ITEM_QUALITY_COLORS[i].b, 2) == round(b, 2) then
          itemRarity = i
        end
      end

      score = ShaguScoreCalculate(itemSlot, itemRarity, itemLevel, UnitLevel("player"))

      if score then
        GameTooltip:AddLine("ShaguScore: " .. score, r,g,b)
        GameTooltip:Show()
      end
    end
  end)

origInspectUnit = InspectUnit
InspectUnit = function (unit)
  origInspectUnit(unit)
  if not ShaguScoreInspect then
    ShaguScoreInspect = CreateFrame("Frame",nil,InspectModelFrame)
    ShaguScoreInspect:SetFrameStrata("HIGH")
    ShaguScoreInspect:SetWidth(200)
    ShaguScoreInspect:SetHeight(25)
    ShaguScoreInspect:SetPoint("BOTTOM", 0, 0)
    ShaguScoreInspect.text = ShaguScoreInspect:CreateFontString("Status", "TOOLTIP", "GameFontNormal")
    ShaguScoreInspect.text:SetPoint("CENTER", 0, 0)
  end

  score, r, g, b = ShaguPlayerScore("target")
  if score and r and g and b then
    ShaguScoreInspect.text:SetText("ShaguScore: " .. score)
    ShaguScoreInspect.text:SetTextColor(r, g, b)
  end
end

local ShaguScoreCharacterFrame = CreateFrame("Frame",nil,CharacterModelFrame)
ShaguScoreCharacterFrame:SetFrameStrata("HIGH")
ShaguScoreCharacterFrame:SetWidth(200)
ShaguScoreCharacterFrame:SetHeight(50)
ShaguScoreCharacterFrame:SetPoint("BOTTOM", 0, 0)
ShaguScoreCharacterFrame.text = ShaguScoreCharacterFrame:CreateFontString("Status", "LOW", "GameFontNormal")
ShaguScoreCharacterFrame.text:SetPoint("CENTER", 0, 0)

ShaguScoreCharacterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ShaguScoreCharacterFrame:RegisterEvent("UNIT_NAME_UPDATE")
ShaguScoreCharacterFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
ShaguScoreCharacterFrame:RegisterEvent("BAG_UPDATE")
ShaguScoreCharacterFrame:SetScript("OnEvent", function()
    score, r, g, b = ShaguPlayerScore("player")
    if score and r and g and b then
      ShaguScoreCharacterFrame.text:SetText("ShaguScore: " .. score)
      ShaguScoreCharacterFrame.text:SetTextColor(r, g, b)
    end
  end)

SLASH_SSCORE1, SLASH_SSCORE2 = '/ssc', '/shaguscore';
function SlashCmdList.SSCORE(msg, editbox)
  if UnitIsPlayer("target") then
    score, r, g, b = ShaguPlayerScore("target")
  else
    score, r, g, b = ShaguPlayerScore("player")
  end
  if score and r and g and b then
    DEFAULT_CHAT_FRAME:AddMessage(score, r, g, b)
  end
end
