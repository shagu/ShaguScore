ShaguScore = CreateFrame( "Frame" , "ShaguScoreTooltip", GameTooltip )
ShaguScore:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
ShaguScore:SetScript("OnEvent", function()
  score, r, g, b = ShaguScore:ScanUnit("mouseover")
  if score and r and g and b then
    GameTooltip:AddLine("ShaguScore: " .. score, r,g,b)
    GameTooltip:Show()
  end
end)

ShaguScore:SetScript("OnShow", function()
  if GameTooltip.itemLink then
    local _, _, itemID = string.find(GameTooltip.itemLink, "item:(%d+):%d+:%d+:%d+")
    local _, _, itemLink = string.find(GameTooltip.itemLink, "(item:%d+:%d+:%d+:%d+)");

    if not itemLink then return end

    local itemLevel = ShaguScore.Database[tonumber(itemID)] or 0
    local _, _, itemRarity, _, _, _, _, itemSlot, _ = GetItemInfo(itemLink)
    local r,g,b = GetItemQualityColor(itemRarity)

    local score = ShaguScore:Calculate(itemSlot, itemRarity, itemLevel)
    if score and score > 0 then
      GameTooltip:AddLine("ShaguScore: " .. score, r, g, b)
      GameTooltip:Show()
    end
  end
end)

ShaguScore:SetScript("OnHide", function()
  GameTooltip.itemLink = nil
end)

local function GetItemLinkByName(name)
  for itemID = 1, 65536 do
    local itemName, hyperLink, itemQuality = GetItemInfo(itemID)
    if (itemName and itemName == name) then
      local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
      return hex.. "|H"..hyperLink.."|h["..itemName.."]|h|r"
    end
  end
end

-- target inspect
ShaguScoreHookInspectUnit = InspectUnit
function InspectUnit(unit)
  ShaguScoreHookInspectUnit(unit)
  ShaguScore.Inspect = ShaguScore.Inspect or CreateFrame("Frame", nil, InspectModelFrame)
  ShaguScore.Inspect:SetFrameStrata("HIGH")
  ShaguScore.Inspect:SetWidth(200)
  ShaguScore.Inspect:SetHeight(25)
  ShaguScore.Inspect:SetPoint("BOTTOM", 0, 0)
  ShaguScore.Inspect.text = ShaguScore.Inspect.text or ShaguScore.Inspect:CreateFontString("Status", "TOOLTIP", "GameFontNormal")
  ShaguScore.Inspect.text:SetPoint("CENTER", 0, 0)

  local score, r, g, b = ShaguScore:ScanUnit("target")
  if score and r and g and b then
    ShaguScore.Inspect.text:SetText("ShaguScore: " .. score)
    ShaguScore.Inspect.text:SetTextColor(r, g, b)
  end
end

-- player inspect
ShaguScore.CharacterFrame = CreateFrame("Frame", nil, CharacterModelFrame)
ShaguScore.CharacterFrame:SetFrameStrata("HIGH")
ShaguScore.CharacterFrame:SetWidth(200)
ShaguScore.CharacterFrame:SetHeight(50)
ShaguScore.CharacterFrame:SetPoint("BOTTOM", 0, 0)
ShaguScore.CharacterFrame.text = ShaguScore.CharacterFrame:CreateFontString("Status", "LOW", "GameFontNormal")
ShaguScore.CharacterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ShaguScore.CharacterFrame:RegisterEvent("UNIT_NAME_UPDATE")
ShaguScore.CharacterFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
ShaguScore.CharacterFrame:RegisterEvent("BAG_UPDATE")
ShaguScore.CharacterFrame:SetScript("OnEvent", function()
  score, r, g, b = ShaguScore:ScanUnit("player")
  if score and r and g and b then
    ShaguScore.CharacterFrame.text:SetText("ShaguScore: " .. score)
    ShaguScore.CharacterFrame.text:SetTextColor(r, g, b)
  end
end)

--- BetterCharacterStats compatibility check
if BCSFrame then
  ShaguScore.CharacterFrame.text:SetPoint("CENTER", 0, 20)
else
  ShaguScore.CharacterFrame.text:SetPoint("CENTER", 0, 0)
end

-- functions
function ShaguScore:round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

function ShaguScore:Calculate(slot, rarity, ilvl)
  if not rarity then return nil end
  return (rarity * ilvl) * (slot == "INVTYPE_2HWEAPON" and 2 or 1)
end

function ShaguScore:ScanUnit(target)
  if not UnitIsPlayer(target) then return nil end

  local count, ar, ag, ab, score = 0, 0, 0, 0, 0

  for i=1,19 do
    if GetInventoryItemLink(target, i) then
      local _, _, itemID = string.find(GetInventoryItemLink(target, i), "item:(%d+):%d+:%d+:%d+")
      local _, _, itemLink = string.find(GetInventoryItemLink(target, i), "(item:%d+:%d+:%d+:%d+)");

      local itemLevel = ShaguScore.Database[tonumber(itemID)] or 0
      local _, _, itemRarity, _, _, _, _, itemSlot, _ = GetItemInfo(itemLink)
      local r, g, b = .2, .2, .2

      local cscore = 0

      if itemRarity and itemSlot then
        r,g,b, _ = GetItemQualityColor(itemRarity)
        ar = ar + r ; ag = ag + g ; ab = ab + b
        cscore = ShaguScore:Calculate(itemSlot, itemRarity, itemLevel)
      end

      score = score + cscore
      count = count + 1
    end
  end

  local ar = ShaguScore:round(ar / count, 2);
  local ag = ShaguScore:round(ag / count, 2);
  local ab = ShaguScore:round(ab / count, 2);

  if score ~= 0 then return score, ar, ag, ab else return nil end
end

function ShaguScore:GetItemLinkByName(name)
  for itemID = 1, 25818 do
    local itemName, hyperLink, itemQuality = GetItemInfo(itemID)
    if (itemName and itemName == name) then
      local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
      return hex.. "|H"..hyperLink.."|h["..itemName.."]|h|r"
    end
  end
end

-- hooks
local ShaguScoreHookSetBagItem = GameTooltip.SetBagItem
function GameTooltip.SetBagItem(self, container, slot)
  GameTooltip.itemLink = GetContainerItemLink(container, slot)
  _, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
  return ShaguScoreHookSetBagItem(self, container, slot)
end

local ShaguScoreHookSetQuestLogItem = GameTooltip.SetQuestLogItem
function GameTooltip.SetQuestLogItem(self, itemType, index)
  GameTooltip.itemLink = GetQuestLogItemLink(itemType, index)
  if not GameTooltip.itemLink then return end
  return ShaguScoreHookSetQuestLogItem(self, itemType, index)
end

local ShaguScoreHookSetQuestItem = GameTooltip.SetQuestItem
function GameTooltip.SetQuestItem(self, itemType, index)
  GameTooltip.itemLink = GetQuestItemLink(itemType, index)
  return ShaguScoreHookSetQuestItem(self, itemType, index)
end

local ShaguScoreHookSetLootItem = GameTooltip.SetLootItem
function GameTooltip.SetLootItem(self, slot)
  GameTooltip.itemLink = GetLootSlotLink(slot)
  ShaguScoreHookSetLootItem(self, slot)
end

local ShaguScoreHookSetInboxItem = GameTooltip.SetInboxItem
function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
  local itemName, itemTexture, inboxItemCount, inboxItemQuality = GetInboxItem(mailID)
  GameTooltip.itemLink = ShaguScore:GetItemLinkByName(itemName)
  return ShaguScoreHookSetInboxItem(self, mailID, attachmentIndex)
end

local ShaguScoreHookSetInventoryItem = GameTooltip.SetInventoryItem
function GameTooltip.SetInventoryItem(self, unit, slot)
  GameTooltip.itemLink = GetInventoryItemLink(unit, slot)
  return ShaguScoreHookSetInventoryItem(self, unit, slot)
end

local ShaguScoreHookSetLootRollItem = GameTooltip.SetLootRollItem
function GameTooltip.SetLootRollItem(self, id)
  GameTooltip.itemLink = GetLootRollItemLink(id)
  return ShaguScoreHookSetLootRollItem(self, id)
end

local ShaguScoreHookSetLootRollItem = GameTooltip.SetLootRollItem
function GameTooltip.SetLootRollItem(self, id)
  GameTooltip.itemLink = GetLootRollItemLink(id)
  return ShaguScoreHookSetLootRollItem(self, id)
end

local ShaguScoreHookSetMerchantItem = GameTooltip.SetMerchantItem
function GameTooltip.SetMerchantItem(self, merchantIndex)
  GameTooltip.itemLink = GetMerchantItemLink(merchantIndex)
  return ShaguScoreHookSetMerchantItem(self, merchantIndex)
end

local ShaguScoreHookSetCraftItem = GameTooltip.SetCraftItem
function GameTooltip.SetCraftItem(self, skill, slot)
  GameTooltip.itemLink = GetCraftReagentItemLink(skill, slot)
  return ShaguScoreHookSetCraftItem(self, skill, slot)
end

local ShaguScoreHookSetCraftSpell = GameTooltip.SetCraftSpell
function GameTooltip.SetCraftSpell(self, slot)
  GameTooltip.itemLink = GetCraftItemLink(slot)
  return ShaguScoreHookSetCraftSpell(self, slot)
end

local ShaguScoreHookSetTradeSkillItem = GameTooltip.SetTradeSkillItem
function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
  if reagentIndex then
    GameTooltip.itemLink = GetTradeSkillReagentItemLink(skillIndex, reagentIndex)
  else
    GameTooltip.itemLink = GetTradeSkillItemLink(skillIndex)
  end
  return ShaguScoreHookSetTradeSkillItem(self, skillIndex, reagentIndex)
end

local HookSetAuctionItem = GameTooltip.SetAuctionItem
function GameTooltip.SetAuctionItem(self, atype, index)
  local itemName, _, itemCount = GetAuctionItemInfo(atype, index)
  GameTooltip.itemCount = itemCount
  GameTooltip.itemLink = GetItemLinkByName(itemName)
  return HookSetAuctionItem(self, atype, index)
end

local ShaguScoreHookSetAuctionSellItem = GameTooltip.SetAuctionSellItem
function GameTooltip.SetAuctionSellItem(self)
  local itemName, _, itemCount = GetAuctionSellItemInfo()
  GameTooltip.itemCount = itemCount
  GameTooltip.itemLink = ShaguScore:GetItemLinkByName(itemName)
  return ShaguScoreHookSetAuctionSellItem(self)
end

local ShaguScoreHookSetTradePlayerItem = GameTooltip.SetTradePlayerItem
function GameTooltip.SetTradePlayerItem(self, index)
  GameTooltip.itemLink = GetTradePlayerItemLink(index)
  return ShaguScoreHookSetTradePlayerItem(self, index)
end

local ShaguScoreHookSetTradeTargetItem = GameTooltip.SetTradeTargetItem
function GameTooltip.SetTradeTargetItem(self, index)
  GameTooltip.itemLink = GetTradeTargetItemLink(index)
  return ShaguScoreHookSetTradeTargetItem(self, index)
end

-- database
ShaguScore.Database = {}
