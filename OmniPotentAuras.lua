-- OmniPotentAuras
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--

OmniPotentAuras = {
  parent=nil,
  max=9,
  count=1
};

OmniPotentAuras.__index = OmniPotentAuras;

function OmniPotentAuras:New(parent)
  local this = setmetatable({}, OmniPotentAuras);
  this.frames = setmetatable({}, nil);
  this.auras = setmetatable({}, nil);
  this.parent = parent;
  for i=1, this.max do
    this.frames[i] = CreateFrame('Button', parent.frame:GetName()..'Aura'..i, parent.frame, 'OmniPotentAuraTemplate');
    this.frames[i]:SetScript('OnUpdate', function(frame) this:OnUpdate(frame); end);
    this.frames[i]:Show();
  end
  return this;
end

function OmniPotentAuras:SetAura(count, frame, id, name, duration, expires, icon)
  if not self.auras[id] then
    self.auras[id] = name;
    frame.id = id;
    frame.spell = name;
    frame.update = GetTime();
    frame.duration = duration;
    frame.time = expires-GetTime();
    frame.icon = icon;
    frame.ICON:SetTexture(icon);
    frame:ClearAllPoints();
    if self.parent.reverse then frame:SetPoint('TOPRIGHT', frame:GetParent(), 'TOPLEFT', -4-((count-1)*38), 0);
    else frame:SetPoint('TOPLEFT', frame:GetParent(), 'TOPRIGHT', 4+((count-1)*38), 0);
    end
    return 1;
  end
  return 0;
end

function OmniPotentAuras:UnsetAura(frame)
  frame.id = nil;
  frame.spell = nil;
  frame.update = GetTime();
  frame.duration = 0;
  frame.time = 0;
  frame.icon = nil;
  frame.ICON:SetTexture(nil);
  frame.expires:SetText('');
end

function OmniPotentAuras:UnitAura(unit)
  if OmniPotent.OPTIONS.AURAS then
    self.auras = table.wipe(self.auras);
    self.count = self:UpdatePlayerDebuff(1, unit);
    self.count = self:UpdateDebuff(self.count, unit);
    for i=self.count,self.max do
      self:UnsetAura(self.frames[i]);
    end
  end
end

function OmniPotentAuras:UpdatePlayerDebuff(count, unit)
  for i=1,40 do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, i, 'PLAYER');
    if name and icon then
      count = count+self:SetAura(count, self.frames[count], id, name, duration, expires, icon);
    end
  end
  return count;
end

function OmniPotentAuras:UpdateDebuff(count, unit)
  for i=1,40 do
    if count > self.max then break; end
    local name, rank, icon, stack, type, duration, expires, source, _, _, id = UnitDebuff(unit, i);
    if name and icon then
      count = count+self:SetAura(count, self.frames[count], id, name, duration, expires, icon);
    end
  end
  return count;
end

function OmniPotentAuras:UpdatePositions()
  local count = 1;
  for i=1,self.max do
    if self.frames[i].id then
      self.frames[i]:ClearAllPoints();
      if self.parent.reverse then self.frames[i]:SetPoint('TOPRIGHT', self.frames[i]:GetParent(), 'TOPLEFT', -4-((count-1)*38), 0);
      else self.frames[i]:SetPoint('TOPLEFT', self.frames[i]:GetParent(), 'TOPRIGHT', 4+((count-1)*38), 0);
      end
      count = count+1;
    end
  end
end

function OmniPotentAuras:Destroy()
  for i=1,self.max do
    self:UnsetAura(self.frames[i]);
  end
end

function OmniPotentAuras:UpdateExpires(frame)
  if frame.time then
    frame.time = tonumber(frame.time) - (GetTime()-frame.update);
    frame.time = math.floor((frame.time*10)+0.5)/10;
    if frame.duration == 0 then
      frame.expires:SetText('');
    elseif frame.time < 0 then
      self:UnsetAura(frame);
      self:UpdatePositions();
    elseif frame.time <= 60 then
      local time = frame.time > 0 and frame.time or '';
      frame.expires:SetText(time);
    else
      local msg, val = SecondsToTimeAbbrev(frame.time);
      frame.expires:SetText(format(msg, val));
    end
  end
end

function OmniPotentAuras:OnUpdate(frame)
  if frame.id then
    if GetTime()-frame.update >= 0.1 then
      self:UpdateExpires(frame);
      frame.ICON:SetTexture(frame.icon);
      frame.update = GetTime();
    end
  end
end