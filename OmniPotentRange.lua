 -- OmniPotentRange
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--

OmniPotentRange = {
  frame=nil,
  parent=nil,
  update=0,
  range=nil,
  harmful={},
  helpful={}
};

OmniPotentRange.__index = OmniPotentRange;

function OmniPotentRange:New(parent)
  local this = setmetatable({}, OmniPotentRange);
  this.harmful = setmetatable({}, nil);
  this.helpful = setmetatable({}, nil);
  this.parent = parent;
  this.frame = CreateFrame('Frame', parent.frame:GetName()..'Range', parent.frame);
  this.frame:SetScript('OnUpdate', function(frame, time) this:OnUpdate(time); end);
  this.frame:SetScript('OnEvent', function(frame, ...) this:OnEvent(...); end);
  this.frame:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED');
  this:UpdateSpells();
  this.frame:Show();
  return this;
end

local function SortByRange(u,v)
  if v and u then
    if u.range > v.range then
      return true;
    end
  elseif u then
    return true;
  end
end

function OmniPotentRange:UpdateSpells()
  self.harmful = table.wipe(self.harmful);
  self.helpful = table.wipe(self.helpful);
  local numTabs = GetNumSpellTabs();
  for i=1,numTabs do
    local name,texture,offset,numSpells = GetSpellTabInfo(i);
    for j=1,numSpells do
      local id = j+offset;
      local name, rank = GetSpellBookItemName(id, 'spell');
      local range = select(6, GetSpellInfo(name));
      if range then
        if IsHarmfulSpell(id, 'spell') then
          table.insert(self.harmful, { name=name, range=range });
        elseif IsHelpfulSpell(id, 'spell') then
          table.insert(self.helpful, { name=name, range=range });
        end
      end
    end
  end
  table.sort(self.harmful, SortByRange)
  table.sort(self.helpful, SortByRange)
end

function OmniPotentRange:GetHarmfulRange()
  local range = nil;
  for i=1, #self.harmful do
    if IsSpellInRange(self.harmful[i].name, self.parent.unit) == 1 then
      range = range == nil and self.harmful[i].range or math.min(range, self.harmful[i].range);
    end
  end
  return range;
end

function OmniPotentRange:GetHelpfulRange()
  local range = nil;
  for i=1, #self.helpful do
    if IsSpellInRange(self.helpful[i].name, self.parent.unit) == 1 then
      range = range == nil and self.helpful[i].range or math.min(range, self.helpful[i].range);
    end
  end
  return range;
end

function OmniPotentRange:OnUpdate(time)
  self.update = self.update + time;
  if self.update > 1 then
    self.range = nil;
    if UnitIsConnected(self.parent.unit) and not UnitIsDeadOrGhost(self.parent.unit) then
      if UnitIsEnemy('player', self.parent.unit) then
        self.range = self:GetHarmfulRange();
      else
        self.range = self:GetHelpfulRange();
      end
    end
    self.parent.range = self.range;
    self.update = 0;
  end
end

function OmniPotentRange:OnEvent(event, unit)
  if event == 'ACTIVE_TALENT_GROUP_CHANGED' then
    self:UpdateSpells();
  end
end