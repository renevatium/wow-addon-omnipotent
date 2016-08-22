-- OmniPotentGroup
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--

local NAME_OPTIONS = {
  'Pikachu', 'Bellsprout', 'Zubat', 'Bulbasaur', 'Charmander', 'Diglett', 'Slowpoke', 'Squirtle', 'Oddish', 'Geodude'
};

local CYRILLIC = {
  ["А"]="A", ["а"]="a", ["Б"]="B", ["б"]="b", ["В"]="V", ["в"]="v", ["Г"]="G", ["г"]="g", ["Д"]="D", ["д"]="d", ["Е"]="E",
  ["е"]="e", ["Ё"]="E", ["ё"]="e", ["Ж"]="Zh", ["ж"]="zh", ["З"]="Z", ["з"]="z", ["И"]="I", ["и"]="i", ["Й"]="I", ["й"]="i",
  ["К"]="K", ["к"]="k", ["Л"]="L", ["л"]="l", ["М"]="M", ["м"]="m", ["Н"]="N", ["н"]="n", ["О"]="O", ["о"]="o", ["П"]="P", ["п"]="p",
  ["Р"]="R",["р"]="r", ["С"]="S", ["с"]="s", ["Т"]="T", ["т"]="t", ["У"]="U", ["у"]="u", ["Ф"]="F", ["ф"]="f", ["Х"]="Kh", ["х"]="kh",
  ["Ц"]="Ts", ["ц"]="ts", ["Ч"]="Ch", ["ч"]="ch", ["Ш"]="Sh", ["ш"]="sh", ["Щ"]="Shch", ["щ"]="shch", ["Ъ"]="Ie", ["ъ"]="ie",
  ["Ы"]="Y", ["ы"]="y", ["Ь"]="X", ["ь"]="x", ["Э"]="E", ["э"]="e", ["Ю"]="Iu", ["ю"]="iu", ["Я"]="Ia", ["я"]="ia"
};

local ROLES = {};
for classID=1, MAX_CLASSES do
  local className, classTag, classID = GetClassInfoByID(classID);
  local numTabs = GetNumSpecializationsForClassID(classID);
  ROLES[classTag] = {};
  for i=1, numTabs do
    local id, name, description, icon, background, role = GetSpecializationInfoForClassID(classID, i);
    ROLES[classTag][name] = { class=className, role=role, id=id, description=description, icon=icon, spec=name };
  end
end

OmniPotentGroup = {
  active=false,
  faction=nil,
  friendly=true,
  update=0,
  tick=1,
  max=5,
  frame=nil,
  reverse=false,
  frames={},
  units={},
  next_name=1,
  update_units=false
};

OmniPotentGroup.__index = OmniPotentGroup;

local function SortUnits(u,v)
  if v ~= nil and u ~= nil then
    if u.role == v.role then
      if u.class == v.class then
        if u.name < v.name then
          return true;
        end
      elseif u.class < v.class then
        return true;
      end
    elseif u.role > v.role then
      return true;
    end
  elseif u then
    return true;
  end
end

function OmniPotentGroup:New(group, friendly)
  local this = setmetatable({}, OmniPotentGroup);
  this.units = setmetatable({}, nil);
  this.frames = setmetatable({}, nil);
  this.group = group;
  this.friendly = friendly;
  this.frame = CreateFrame('Frame', 'OmniPotentGroup'..group, UIParent, 'OmniPotentGroupTemplate');
  this.frame:SetScript('OnEvent', function(frame, ...) this:OnEvent(...); end);
  this.frame:SetScript('OnUpdate', function(frame, ...) this:OnUpdate(...); end);
  this.frame:SetScript('OnDragStart', function(frame, ...) this:OnDragStart(...); end);
  this.frame:SetScript('OnDragStop', function(frame, ...) this:OnDragStop(...); end);
  this.frame:RegisterEvent('ARENA_OPPONENT_UPDATE');
  this.frame:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS');
  this.frame:RegisterEvent('GROUP_ROSTER_UPDATE');
  this.frame:RegisterEvent('UPDATE_WORLD_STATES');
  this:InitFrame();
  this:CreateFrames();
  return this;
end

function OmniPotentGroup:Activate()
  self.frame:RegisterEvent('UNIT_NAME_UPDATE');
  self.frame:RegisterEvent('PLAYER_TARGET_CHANGED');
  self.frame:RegisterEvent('UNIT_TARGET');
  self.frame:RegisterEvent('PLAYER_DEAD');
  self:GroupRosterUpdate();
  self:Show();
end

function OmniPotentGroup:Show()
  if not InCombatLockdown() then
    self:SetFrameStyle();
    self:UpdateOrientation();
    self.frame:Show();
  end
end

function OmniPotentGroup:SetTarget(frame)
  if frame then
    self.frame.TARGET:ClearAllPoints();
    if self.reverse then self.frame.TARGET:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 4, -2);
    else self.frame.TARGET:SetPoint('TOPRIGHT', frame, 'TOPLEFT', -4, -2);
    end
    self.frame.TARGET:Show();
  else
    self.frame.TARGET:Hide();
  end
end

function OmniPotentGroup:PlayerTargetChanged()
  if not UnitIsDeadOrGhost('player') then
    for i=1, #self.frames do
      if self.frames[i].unit then
        if UnitIsUnit('playertarget', self.frames[i].unit) then
          self:SetTarget(self.frames[i].frame);
          return;
        end
      end
    end
  end
  self:SetTarget(nil);
end

function OmniPotentGroup:SetAssist(frame)
  if frame then
    self.frame.ASSIST:ClearAllPoints();
    if self.reverse then self.frame.ASSIST:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 8, -4);
    else self.frame.ASSIST:SetPoint('TOPRIGHT', frame, 'TOPLEFT', -6, -4);
    end
    self.frame.ASSIST:Show();
  else
    self.frame.ASSIST:Hide();
  end
end

function OmniPotentGroup:UnitTarget(unit)
  if UnitIsGroupLeader(unit) then
    if not UnitIsDeadOrGhost(unit) then
      for i=1, #self.frames do
        if self.frames[i].unit then
          if UnitIsUnit(unit..'target', self.frames[i].unit) then
            self:SetAssist(self.frames[i].frame);
            return;
          end
        end
      end
    end
    self:SetAssist(nil);
  end
end

function OmniPotentGroup:IsOnBattlefield()
  if not self.active then
    for i=1, GetMaxBattlefieldID() do
      local status, name, size = GetBattlefieldStatus(i);
      if status == 'active' then
        self.active = true;
      end
    end
  end
  return self.active;
end

function OmniPotentGroup:GroupRosterUpdate()
  if self.friendly and self:IsOnBattlefield() then
    self.next_name = 1;
    self.units = table.wipe(self.units);
    for i=1, self.max do
      if UnitExists('raid'..i) then
        table.insert(self.units, { unit='raid'..i, name=nil, display=nil, class=nil, spec=nil, role=nil, icon=nil });
      end
    end
    self:ArenaOpponentUpdate();
    self.update_units = true;
  end
end

function OmniPotentGroup:ArenaOpponentUpdate()
  if not self.friendly and self:IsOnBattlefield() then
    self.next_name = 1;
    self.units = table.wipe(self.units);
    for i=1, self.max do
      local id = GetArenaOpponentSpec(i);
      if id then
        local _, spec, _, icon, _, role, class = GetSpecializationInfoByID(id);
        if spec then
          local unit = 'arena'..i;
          local name = GetUnitName(unit, true) or 'Unknown';
          table.insert(self.units, {
            unit=unit,
            name=name,
            display=self:GetDisplayName(name),
            class=class,
            spec=spec,
            role=ROLES[class][spec].role,
            icon=icon
          });
        end
      end

    end
    self.update_units = true;
  end
end

function OmniPotentGroup:InitFrame()
  self.frame:RegisterForDrag('RightButton');
  self.frame:SetClampedToScreen(true);
  self.frame:EnableMouse(true);
  self.frame:SetMovable(true);
  self.frame:SetUserPlaced(true);
end

function OmniPotentGroup:CreateFrames()
  for i=1, 15 do
    if not self.frames[i] then self.frames[i] = OmniPotentUnit:New(self, i); end
    if i > 1 then
      self.frames[i].frame:ClearAllPoints();
      self.frames[i].frame:SetPoint('TOP', self.frames[i-1].frame, 'BOTTOM', 0, 0);
    end
  end
end

function OmniPotentGroup:Hide()
  if InCombatLockdown() then
    self.frame:RegisterEvent('PLAYER_REGEN_ENABLED');
  else
    self.frame:Hide();
  end
end

function OmniPotentGroup:PlayerDead()
  self:SetTarget(nil);
  self:SetAssist(nil);
end

function OmniPotentGroup:PlayerRegenEnabled()
  self.frame:UnregisterEvent('PLAYER_REGEN_ENABLED');
  self.frame:Hide();
end

function OmniPotentGroup:Destroy()
  for i=1, #self.frames do
    if self.frames[i] then
      self.frames[i]:Destroy();
    end
  end
  self.frame:UnregisterEvent('UNIT_NAME_UPDATE');
  self.frame:UnregisterEvent('PLAYER_TARGET_CHANGED');
  self.frame:UnregisterEvent('UNIT_TARGET');
  self.frame:UnregisterEvent('PLAYER_DEAD');
  self.units = table.wipe(self.units);
  self:Hide();
end

function OmniPotentGroup:OnUpdate(time)
  self.update = self.update + time;
  if self.update < self.tick or (WorldStateScoreFrame and WorldStateScoreFrame:IsShown()) then
    return;
  end
  if self.update_units and not InCombatLockdown() and #self.units > 0 then
    for i=1, #self.frames do
      if self.units[i] then
        self.frames[i]:SetUnit(
          self.units[i].unit,
          self.units[i].name,
          self.units[i].display,
          self.units[i].class,
          self.units[i].spec,
          self.units[i].role,
          self.units[i].icon,
          self.units[i].test
        );
      elseif self.frames[i] then
        self.frames[i]:UnsetUnit();
      end
    end
    self.frame:SetSize(101, math.min(#self.units, #self.frames)*self.frames[1].frame:GetHeight()+14);
    self.update_units = false;
  elseif #self.units == 0 then
    self:GroupRosterUpdate();
  end
  self.update = 0;
end

function OmniPotentGroup:OnEvent(event, ...)
  if event == 'GROUP_ROSTER_UPDATE' then self:GroupRosterUpdate();
  elseif event == 'ARENA_OPPONENT_UPDATE' then self:ArenaOpponentUpdate();
  elseif event == 'ARENA_PREP_OPPONENT_SPECIALIZATIONS' then self:ArenaOpponentUpdate();
  elseif event == 'UPDATE_WORLD_STATES' then self:GroupRosterUpdate();
  elseif event == 'PLAYER_TARGET_CHANGED' then self:PlayerTargetChanged(...);
  elseif event == 'UNIT_TARGET' then self:UnitTarget(...);
  elseif event == 'PLAYER_REGEN_ENABLED' then self:PlayerRegenEnabled();
  elseif event == 'PLAYER_DEAD' then self:PlayerDead();
  end
end

function OmniPotentGroup:GetDisplayName(name)
  if OmniPotent.OPTIONS.NAMING == 'Transmute' then
    name = self:Transmute(name);
  elseif OmniPotent.OPTIONS.NAMING == 'Transliterate' then
    name = self:Transliterate(name);
  end
  return name;
end

function OmniPotentGroup:Transliterate(name)
  if name then
    for c, r in pairs(CYRILLIC) do
      name = string.gsub(name, c, r);
    end
  end
  return name;
end

function OmniPotentGroup:Transmute(name)
  if name and self:IsUTF8(name) then
    name = NAME_OPTIONS[self.next_name];
    self.next_name = self.next_name+1;
  end
  return name;
end

function OmniPotentGroup:IsUTF8(name)
  local c,a,n,i = nil,nil,0,1;
  while true do
    c = string.sub(name,i,i);
    i = i + 1;
    if c == '' then
        break;
    end
    a = string.byte(c);
    if a > 191 or a < 127 then
        n = n + 1;
    end
  end
  return (strlen(name) > n*1.5);
end

function OmniPotentGroup:SetFrameStyle()
  if OmniPotent.OPTIONS.BORDERLESS then self.frame.borderFrame:Hide();
  else self.frame.borderFrame:Show();
  end
end

local function RandomKey(t)
  local keys, i = {}, 1;
  for k in pairs(t) do
    keys[i] = k;
    i = i+1;
  end
  return keys[math.random(1, #keys)];
end

function OmniPotentGroup:CreateStub(names)
  self.next_name = 1;
  if #self.units == 0 then
    local class, spec = nil, nil;
    for i=1, self.max do
      class = RandomKey(ROLES);
      spec = RandomKey(ROLES[class]);
      table.insert(self.units, {
        test=true,
        name=names[i],
        display=self:GetDisplayName(names[i]),
        class=class,
        spec=spec,
        role=ROLES[class][spec].role,
        icon=ROLES[class][spec].icon,
        unit=names[i]
      });
    end
  else
    for i=1, self.max do
      self.units[i].display = self:GetDisplayName(names[i]);
    end
  end
  self.update_units = true;
  self:Show();
end

function OmniPotentGroup:UpdateOrientation()
  local point, relativeTo, relativePoint, x, y = unpack(self:GetPosition());
  self.reverse = x < 0 or x > GetScreenWidth()/2;
  for i=1, #self.frames do
    self.frames[i]:UpdateOrientation();
  end
end

function OmniPotentGroup:GetPosition()
  for i=1, self.frame:GetNumPoints() do
    local point, relativeTo, relativePoint, x, y = self.frame:GetPoint(i);
    return { point, relativeTo, relativePoint, x, y };
  end
end

function OmniPotentGroup:OnDragStart()
  if InterfaceOptionsFrame:IsShown() then
    self.frame:ClearAllPoints();
    self.frame:StartMoving();
  end
end

function OmniPotentGroup:OnDragStop()
  if InterfaceOptionsFrame:IsShown() then
    OmniPotent.OPTIONS.POSITION[self.group] = self:GetPosition();
    self.frame:StopMovingOrSizing();
    self:UpdateOrientation();
  end
end