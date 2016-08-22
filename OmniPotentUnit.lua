-- OmniPotentUnit
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--

local INSPECT = false;
local POWER_BAR_COLORS = {
  MANA={ r=0.00,g=0.00,b=1.00 },
  RAGE={ r=1.00,g=0.00,b=0.00 },
  FOCUS={ r=1.00,g=0.50,b=0.25 },
  ENERGY={ r=1.00,g=1.00,b=0.00 },
  CHI={ r=0.71,g=1.0,b=0.92 },
  RUNES={ r=0.50,g=0.50,b=0.50 }
};

local LFGRoleTexCoords = { TANK={ 0.5,0.75,0,1 }, DAMAGER={ 0.25,0.5,0,1 }, HEALER={ 0.75,1,0,1 }};
local function GetTexCoordsForRole(role, borderless)
  role = role or 'DAMAGER';
  local c = borderless and LFGRoleTexCoords[role] or {GetTexCoordsForRoleSmallCircle(role)};
  return unpack(c);
end

OmniPotentUnit = {
  update=0,
  parent=0,
  dead=false,
  test=false,
  name=nil,
  icon=nil,
  display=nil,
  unit=nil,
  frame=nil,
  spec=nil,
  class=nil,
  role=nil,
  health=1,
  healthMax=1,
  power=1,
  powerMax=1,
  targeted='',
  range=nil,
  track=nil,
  last_update=0,
  update_targeted=true,
  enemy=false,
  auras=nil
};

OmniPotentUnit.__index = OmniPotentUnit;

function OmniPotentUnit:New(parent, count)
  local this = setmetatable({}, OmniPotentUnit);
  this.parent = parent;
  this.frame = CreateFrame('Button', parent.frame:GetName()..'OmniPotentUnit'..count, parent.frame, 'OmniPotentUnitTemplate');
  this.frame:SetScript('OnEvent', function(frame, ...) this:OnEvent(...); end);
  this.frame:SetScript('OnUpdate', function(frame, ...) this:OnUpdate(...); end);
  this.frame:SetScript('OnEnter', function(frame, ...) this:OnEnter(...); end);
  this.frame:SetScript('OnLeave', function(frame, ...) this:OnLeave(...); end);
  this.frame:SetScript('OnDragStart', function(frame, ...) parent:OnDragStart(...); end);
  this.frame:SetScript('OnDragStop', function(frame, ...) parent:OnDragStop(...); end);
  this.frame.UPDATE_TARGETED:SetScript('OnUpdate', function(frame, ...) this:UpdateTargeted(...); end);
  this.frame:EnableMouse(true);
  this.frame:RegisterForDrag('RightButton');
  this.frame:RegisterForClicks('LeftButtonUp', 'RightButtonUp');
  this.frame:SetAttribute('type1', 'macro');
  this.frame:SetAttribute('type2', 'macro');
  this.frame:SetAttribute('macrotext1', '');
  this.frame:SetAttribute('macrotext2', '');
  this.auras = OmniPotentAuras:New(this);
  this.track = OmniPotentRange:New(this);
  return this;
end

function OmniPotentUnit:SetUnit(unit, name, display, class, spec, role, icon, test)
  self.unit = unit;
  self.frame.unit = unit;
  self.test = test;
  if name then
    self.name = name;
    self.display = display;
    self.spec = spec;
    self.class = class;
    self.role = role;
    self.icon = icon;
    self:RegisterEvents();
    self:SetFrameStyle();
    self.frame:Show();
  else
    self.frame:RegisterEvent('INSPECT_READY');
    if not INSPECT then
      INSPECT = unit;
      NotifyInspect(unit);
    end
  end
end

function OmniPotentUnit:UnsetUnit()
  self.name = nil;
  self.display = nil;
  self.class = nil;
  self.spec = nil;
  self.role = nil;
  self.unit = nil;
  self.frame.unit = nil;
  self.dead = false;
  self.test = false;
  self.frame.SPEC:SetText('');
  self.frame.SPEC_ICON:SetTexture(nil);
  self.frame.NAME:SetText('');
  self.health = 1;
  self.healthMax = 1;
  self.power = 1;
  self.powerMax = 1;
  self:UnregisterEvents();
  self:Hide();
end

function OmniPotentUnit:InspectReady(guid)
  if UnitGUID(self.unit) == guid then
    self.frame:UnregisterEvent('INSPECT_READY');
    local name = GetUnitName(self.unit, true) or 'Unknown';
    local display = self.parent:GetDisplayName(name);
    local id = GetInspectSpecialization(self.unit);
    local _, spec, _, icon, _, role, class = GetSpecializationInfoByID(id);
    if spec then
      self:SetUnit(self.unit, name, display, class, spec, role, icon, test);
      INSPECT = false;
    end
  elseif not INSPECT then
    INSPECT = self.unit;
    NotifyInspect(self.unit);
  end
end

function OmniPotentUnit:PlayerRegenEnabled()
  self.frame:UnregisterEvent('PLAYER_REGEN_ENABLED');
  self.frame:SetAttribute('macrotext1', nil);
  self.frame:SetAttribute('macrotext2', nil);
  self.frame:Hide();
end

function OmniPotentUnit:Hide()
  if InCombatLockdown() then
    self.frame:RegisterEvent('PLAYER_REGEN_ENABLED');
  else
    self.frame:Hide();
  end
end

function OmniPotentUnit:Destroy()
  self:UnsetUnit();
  self.auras:Destroy();
end

function OmniPotentUnit:UnitHealthColor()
  local color = RAID_CLASS_COLORS[self.class];
  self.frame.HEALTH_BAR:SetStatusBarColor(color.r, color.g, color.b);
  self.frame.HEALTH_BAR.r, self.frame.HEALTH_BAR.g, self.frame.HEALTH_BAR.b = color.r, color.g, color.b;
end

function OmniPotentUnit:UnitPowerColor()
  local powerType, powerToken = UnitPowerType(self.name);
  local color = POWER_BAR_COLORS[powerToken] or POWER_BAR_COLORS.MANA;
  self.frame.POWER_BAR:SetStatusBarColor(color.r, color.g, color.b);
end

function OmniPotentUnit:UnitUpdate()
  if self.unit then
    self.last_update = GetTime();
    self.enemy = UnitIsEnemy(self.unit, 'player');
    self.health = UnitHealth(self.unit);
    self.healthMax = UnitHealthMax(self.unit);
    self.power = UnitPower(self.unit);
    self.powerMax = UnitPowerMax(self.unit);
    if UnitIsDeadOrGhost(self.unit) or self.health == 0 then
      self.power = 0;
      self.range = nil;
      self.dead = true;
      self.auras:Destroy();
    else
      self.dead = false;
      self.auras:UnitAura(self.unit);
    end
  end
end

function OmniPotentUnit:UnitCheck(unit)
  if UnitIsUnit(self.unit, unit) then
    self:UnitUpdate();
  end
end

function OmniPotentUnit:UpdateTargeted(unit)
  if OmniPotent.OPTIONS.TARGETED then
    if self.update_targeted then
      self.targeted = 0;
      self.update_targeted = false;
      for i=1, GetNumGroupMembers() do
        if UnitIsUnit('raid'..i..'target', self.unit) then
          self.targeted = self.targeted+1;
        end
      end
      self.targeted = self.targeted>0 and self.targeted or '';
      self.update_targeted = true;
    end
  end
end

function OmniPotentUnit:OnUpdate(time)
  self.update = self.update + time;
  if self.update < 0.1 then
    return;
  end
  self.update = 0;
  self:UpdateDisplay();
end

function OmniPotentUnit:UpdateDisplay()
  self.frame.NAME:SetText(self.display);
  self.frame.SPEC:SetText(self.spec);
  self.frame.SPEC_ICON:SetTexture(self.icon);
  self.frame.SPEC_ICON:SetAlpha(1);
  self.frame.HEALTH_BAR:SetMinMaxValues(0, self.healthMax);
  self.frame.HEALTH_BAR:SetValue(self.health);
  self.frame.POWER_BAR:SetMinMaxValues(0, self.powerMax);
  self.frame.POWER_BAR:SetValue(self.power);
  self.frame.TARGETED:SetText(self.targeted);
  self:UnitHealthColor();
  self:UnitPowerColor();
  self:ResetTargetMacro();
  if OmniPotent.OPTIONS.RANGE and self.range == nil then
    self.frame:SetAlpha(0.5);
  else
    self.frame:SetAlpha(1);
  end
end

function OmniPotentUnit:ResetTargetMacro()
  if not InCombatLockdown() then
    self.frame:SetAttribute('macrotext1', '/targetexact '..self.unit);
    self.frame:SetAttribute('macrotext2', '/targetexact '..self.unit..'\n/focus\n/targetlasttarget');
  end
end

function OmniPotentUnit:OnEnter() self.frame.HOVER:Show(); end
function OmniPotentUnit:OnLeave() self.frame.HOVER:Hide(); end

function OmniPotentUnit:OnEvent(event, unit, x, y, z)
  if event == 'INSPECT_READY' then self:InspectReady(unit);
  elseif event == 'UNIT_HEALTH_FREQUENT' then self:UnitCheck(unit);
  elseif event == 'UNIT_COMBAT' then self:UnitCheck(unit);
  elseif event == 'UNIT_TARGET' then self:UnitCheck(unit);
  elseif event == 'UPDATE_MOUSEOVER_UNIT' then self:UnitCheck('mouseover');
  elseif event == 'PLAYER_REGEN_ENABLED' then self:PlayerRegenEnabled();
  end
end

function OmniPotentUnit:RegisterEvents()
  self.frame:RegisterEvent('UNIT_HEALTH_FREQUENT');
  self.frame:RegisterEvent('UPDATE_MOUSEOVER_UNIT');
  self.frame:RegisterEvent('UNIT_COMBAT');
  self.frame:RegisterEvent('UNIT_TARGET');
end

function OmniPotentUnit:UnregisterEvents()
  self.frame:UnregisterEvent('INSPECT_READY');
  self.frame:UnregisterEvent('UNIT_HEALTH_FREQUENT');
  self.frame:UnregisterEvent('UPDATE_MOUSEOVER_UNIT');
  self.frame:UnregisterEvent('UNIT_COMBAT');
  self.frame:UnregisterEvent('UNIT_TARGET');
end

function OmniPotentUnit:SetFrameStyle()
  if OmniPotent.OPTIONS.BORDERLESS then self:SetStyleBorderless();
  else self:SetStyleDefault();
  end
end

function OmniPotentUnit:SetStyleDefault()
  self.frame:EnableDrawLayer('BORDER');
  self.frame.NAME:SetFontObject("GameFontHighlight");
  self.frame.TARGETED:SetFontObject("TextStatusBarTextRed");
  self.frame.HEALTH_BAR:ClearAllPoints();
  self.frame.HEALTH_BAR:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 1, -1);
  if OmniPotent.OPTIONS.POWER then
    self.frame.POWER_BAR:ClearAllPoints();
    self.frame.HEALTH_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', -1, 10);
    self.frame.POWER_BAR:SetPoint('TOPLEFT', self.frame.HEALTH_BAR, 'BOTTOMLEFT', 0, -2);
    self.frame.POWER_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', -1, 0);
    self.frame.POWER_BAR:Show();
    self.frame.horizDivider:Show();
  else
    self.frame.HEALTH_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', -1, 2);
    self.frame.POWER_BAR:Hide();
    self.frame.horizDivider:Hide();
  end
  self.frame.ROLE_ICON:ClearAllPoints();
  self.frame.ROLE_ICON:SetTexture('Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES');
  self.frame.ROLE_ICON:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 2.5, -2.5);
  self.frame.ROLE_ICON:SetTexCoord(GetTexCoordsForRole(self.role, false));
  self.frame.ROLE_ICON:Show();
  self.frame.SPEC:Show();
  self.frame.SPEC_ICON:Hide();
end

function OmniPotentUnit:SetStyleBorderless()
  self.frame:DisableDrawLayer('BORDER');
  self.frame.NAME:SetFontObject("GameFontHighlightBorderless");
  self.frame.TARGETED:SetFontObject("TextStatusBarTextRedBorderless");
  self.frame.HEALTH_BAR:ClearAllPoints();
  self.frame.HEALTH_BAR:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 0, 0);
  if OmniPotent.OPTIONS.POWER then
    self.frame.POWER_BAR:ClearAllPoints();
    self.frame.HEALTH_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', 0, 15);
    self.frame.POWER_BAR:SetPoint('TOPLEFT', self.frame.HEALTH_BAR, 'BOTTOMLEFT', 0, -1);
    self.frame.POWER_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', 0, 1);
    self.frame.POWER_BAR:Show();
    self.frame.horizDivider:Show();
  else
    self.frame.HEALTH_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', 0, 1);
    self.frame.POWER_BAR:Hide();
    self.frame.horizDivider:Hide();
  end
  self.frame.POWER_BAR:ClearAllPoints();
  self.frame.POWER_BAR:SetPoint('TOPLEFT', self.frame.HEALTH_BAR, 'BOTTOMLEFT', 0, -1);
  self.frame.POWER_BAR:SetPoint('BOTTOMRIGHT', self.frame, 'BOTTOMRIGHT', 0, 1);
  self.frame.POWER_BAR:Show();
  self.frame.ROLE_ICON:ClearAllPoints();
  self.frame.ROLE_ICON:SetTexture('Interface\\LFGFrame\\LFGRole');
  self.frame.ROLE_ICON:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 2.5, -3);
  self.frame.ROLE_ICON:SetTexCoord(GetTexCoordsForRole(self.role, true));
  self.frame.ROLE_ICON:Show();
  self.frame.SPEC:Hide();
  if OmniPotent.OPTIONS.ICONS then self.frame.SPEC_ICON:Show();
  else self.frame.SPEC_ICON:Hide();
  end
end

function OmniPotentUnit:UpdateOrientation()
  self.frame.SPEC_ICON:ClearAllPoints();
  if self.parent.reverse then
    self.frame.SPEC_ICON:SetPoint('TOPLEFT', self.frame, 'TOPRIGHT', 1, 0);
  else
    self.frame.SPEC_ICON:SetPoint('TOPRIGHT', self.frame, 'TOPLEFT', -1, 0);
  end
end
