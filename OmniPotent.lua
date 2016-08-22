-- OmniPotent v1.0.9
-- =====================================================================
-- Copyright (C) 2014 Lock of War, Developmental (Pty) Ltd
--
-- This Work is provided under the Creative Commons
-- Attribution-NonCommercial-NoDerivatives 4.0 International Public License
--
-- Please send any bugs or feedback to omnipotent@lockofwar.com.
-- Debug /run print((select(4, GetBuildInfo())));

local WIDTH = GetScreenWidth()*UIParent:GetEffectiveScale();
local DEFAULT_OPTIONS = {
  VERSION=1.09,
  ENABLED=true,
  FRIENDLY=true,
  POSITION={
    HARMFUL={ 'RIGHT', nil, 'RIGHT', -250, 100 },
    HELPFUL={ 'LEFT', nil, 'LEFT', 250, 100 }
  },
  BORDERLESS=false,
  ICONS=true,
  SIZE=100,
  NAMING='Transmute',
  POWER=true,
  RANGE=true,
  TARGETED=true,
  AURAS=true
};

local FRIENDS = { 'Garrosh', 'Jaina', 'Uther', 'Anduin', 'Thrall' };
local ENEMIES = { 'Афила', 'Сэйбот', 'Яджун', 'Найнс', 'Айвен' };

OmniPotent = CreateFrame('Frame', 'OmniPotent', UIParent);

function OmniPotent:Load()
  self.active=false;
  self.version=DEFAULT_OPTIONS.VERSION;
  self.version_text='v1.0.9';
  self.frames={};
  self.player={};
  self.objectives=false;
  self:HelloWorld();
  self:Initialize();
  self:Options();
end

function OmniPotent:Initialize()
  self.frames.HELPFUL = OmniPotentGroup:New('HELPFUL', true);
  self.frames.HARMFUL = OmniPotentGroup:New('HARMFUL', false);
end

function OmniPotent:Activate()
  if self.OPTIONS.FRIENDLY then
    self.frames.HELPFUL:Activate();
  end
  self.frames.HARMFUL:Activate();
end

function OmniPotent:ZoneChanged()
  local active, battlefield = IsInInstance();
  if self.OPTIONS.ENABLED and not self.active and battlefield == 'arena' then
    self.active = active;
    self:DisableOptions();
    self:ObjectivesFrame(active);
    self:Activate();
  elseif not active then
    self.active = active;
    self:EnableOptions();
    self:ObjectivesFrame(active);
    self:Destroy();
  end
end

function OmniPotent:ObjectivesFrame(active)
  if ObjectiveTrackerFrame then
    if active and not ObjectiveTrackerFrame.collapsed then
      ObjectiveTracker_Collapse();
      self.objectives = true;
    elseif not active and self.objectives and ObjectiveTrackerFrame.collapsed then
      ObjectiveTracker_Expand();
      self.objectives = false;
    end
  end
end

function OmniPotent:PlayerLogin()
  self.player.NAME = UnitName('player');
  self.player.CLASS = select(2, UnitClass('player'));
  self.player.FACTION = GetBattlefieldArenaFaction();
end

function OmniPotent:HelloWorld()
  local message = '|cFF00FFFF <OmniPotent-'..self.version_text..'>|cFFFF0000 Be OP.|r Type /op for interface options.';
  ChatFrame1:AddMessage(message, 0, 0, 0, GetChatTypeIndex('SYSTEM'));
end

function OmniPotent:Options()
  self.OPTIONS = OMNIPOTENT_OPTIONS or nil;
  if not self.OPTIONS or self.OPTIONS.VERSION ~= self.version then
    self.OPTIONS = DEFAULT_OPTIONS;
  else
    for k, value in pairs(DEFAULT_OPTIONS) do
      if self.OPTIONS[k] == nil then
        self.OPTIONS[k] = value;
      end
    end
  end
  self:InitOptions();
end

function OmniPotent:InitOptions()
  self.options_frame = CreateFrame('Frame', 'OmniPotentOptions', UIParent, 'OmniPotentOptionsTemplate');
  self.options_frame.name = GetAddOnMetadata('OmniPotent', 'Title');
  self.options_frame.Title:SetText(string.upper('Arena/Skirmish'));
  self.options_frame.Subtitle:SetText('OmniPotent '..self.version_text);
  self.options_frame.okay = function() OmniPotent:SaveOptions(); end;
  self.options_frame.default = function() OmniPotent:DefaultOptions(); end;
  self.options_frame.cancel = function() OmniPotent:CancelOptions(); end;
  self.options_frame:SetScript('OnHide', function(self) OmniPotent:CloseOptions(); end);
  self.options_frame:SetScript('OnShow', function(self) OmniPotent:OpenOptions(); end);
  InterfaceOptions_AddCategory(self.options_frame);
  self:SetOptions(self.OPTIONS);
end

function OmniPotent:InitNamingOptions(default)
  UIDropDownMenu_Initialize(self.options_frame.Naming, function()
    for i, option in pairs({ 'Transmute', 'Transliterate', 'Ignore' }) do
      UIDropDownMenu_AddButton({ owner=self.options_frame.Naming, text=option, value=option, checked=nil, arg1=option, func=(function(_, value)
        UIDropDownMenu_ClearAll(self.options_frame.Naming);
        UIDropDownMenu_SetSelectedValue(self.options_frame.Naming, value);
        self:SetOption('naming', value);
      end)});
    end
  end);
  UIDropDownMenu_SetAnchor(self.options_frame.Naming, 16, 22, 'TOPLEFT', self.options_frame.Naming:GetName()..'Left', 'BOTTOMLEFT');
  UIDropDownMenu_JustifyText(self.options_frame.Naming, 'LEFT');
  UIDropDownMenu_SetSelectedValue(self.options_frame.Naming, default);
end

function OmniPotent:SetOptions(options)
  self.options_frame.Enabled:SetChecked(options.ENABLED);
  self.options_frame.Friendly:SetChecked(options.FRIENDLY);
  self.options_frame.Power:SetChecked(options.POWER);
  self.options_frame.Range:SetChecked(options.RANGE);
  self.options_frame.Targeted:SetChecked(options.TARGETED);
  self.options_frame.Auras:SetChecked(options.AURAS);
  self.options_frame.Borderless:SetChecked(options.BORDERLESS);
  self.options_frame.Icons:SetChecked(options.ICONS);
  self.options_frame.Size:SetValue(options.SIZE);
  self:InitNamingOptions(options.NAMING);
  if not InCombatLockdown() then
    self:SetOptionSize(options.SIZE);
    self:SetOptionPosition(options.POSITION);
  end
end

function OmniPotent:SaveOptions()
  OMNIPOTENT_OPTIONS = self.OPTIONS;
  OMNIPOTENT_OPTIONS.ENABLED = self.options_frame.Enabled:GetChecked();
  OMNIPOTENT_OPTIONS.FRIENDLY = self.options_frame.Friendly:GetChecked();
  OMNIPOTENT_OPTIONS.POWER = self.options_frame.Power:GetChecked();
  OMNIPOTENT_OPTIONS.RANGE = self.options_frame.Range:GetChecked();
  OMNIPOTENT_OPTIONS.TARGETED = self.options_frame.Targeted:GetChecked();
  OMNIPOTENT_OPTIONS.AURAS = self.options_frame.Auras:GetChecked();
  OMNIPOTENT_OPTIONS.BORDERLESS = self.options_frame.Borderless:GetChecked();
  OMNIPOTENT_OPTIONS.ICONS = self.options_frame.Icons:GetChecked();
  OMNIPOTENT_OPTIONS.SIZE = self.options_frame.Size:GetValue();
end

function OmniPotent:CancelOptions() OmniPotent:SetOptions(self.OPTIONS); end
function OmniPotent:DefaultOptions() self:SetOptions(DEFAULT_OPTIONS); end

function OmniPotent:DisableOptions()
  UIDropDownMenu_DisableDropDown(self.options_frame.Naming);
  self.options_frame.Enabled:Disable();
  self.options_frame.Friendly:Disable();
  self.options_frame.Power:Disable();
  self.options_frame.Auras:Disable();
  self.options_frame.Borderless:Disable();
  self.options_frame.Icons:Disable();
end

function OmniPotent:EnableOptions()
  UIDropDownMenu_EnableDropDown(self.options_frame.Naming);
  self.options_frame.Enabled:Enable();
  self.options_frame.Friendly:Enable();
  self.options_frame.Power:Enable();
  self.options_frame.Auras:Enable();
  self.options_frame.Borderless:Enable();
  self.options_frame.Icons:Enable();
end

function OmniPotent:SetOption(option, value)
  self.OPTIONS[string.upper(option)] = value;
  self:OpenOptions();
end

function OmniPotent:SetOptionPosition(position)
  self:SetOptionPositionHARMFUL(position.HARMFUL);
  self:SetOptionPositionHELPFUL(position.HELPFUL);
end

function OmniPotent:SetOptionPositionHARMFUL(position)
  self.frames.HARMFUL.frame:ClearAllPoints();
  local ok, point, relativeTo, relativePoint, x, y = pcall(unpack, position);
  if not ok then point, relativeTo, relativePoint, x, y = unpack(DEFAULT_OPTIONS.POSITION.HARMFUL);
  end
  self.frames.HARMFUL.frame:SetPoint(point, relativeTo, relativePoint, x, y);
  self.frames.HARMFUL:UpdateOrientation();
end

function OmniPotent:SetOptionPositionHELPFUL(position)
  self.frames.HELPFUL.frame:ClearAllPoints();
  local ok, point, relativeTo, relativePoint, x, y = pcall(unpack, position);
  if not ok then point, relativeTo, relativePoint, x, y = unpack(DEFAULT_OPTIONS.POSITION.HELPFUL);
  end
  self.frames.HELPFUL.frame:SetPoint(point, relativeTo, relativePoint, x, y);
  self.frames.HELPFUL:UpdateOrientation();
end

function OmniPotent:SetOptionSize(size)
  self.frames.HELPFUL.frame:SetScale(size/100);
  self.frames.HARMFUL.frame:SetScale(size/100);
end

function OmniPotent:OpenOptions()
  if not self.active then
    if self.OPTIONS.ENABLED then
      self:ObjectivesFrame(true);
      if self.OPTIONS.FRIENDLY then self.frames.HELPFUL:CreateStub(FRIENDS);
      end
      self.frames.HARMFUL:CreateStub(ENEMIES);
      if self.OPTIONS.BORDERLESS then self.options_frame.Icons:Show();
      else self.options_frame.Icons:Hide();
      end
    else
      self:Destroy();
    end
  end
end

function OmniPotent:CloseOptions()
  if not self.active then
    self:ObjectivesFrame(false);
    self.options_frame:Hide();
    self:Destroy();
  end
end

function OmniPotent:Destroy()
  self.frames.HARMFUL:Destroy();
  self.frames.HELPFUL:Destroy();
end

function OmniPotent:AddonLoaded(addon)
  if addon == 'OmniPotent' then
    self:Load();
  end
end

function OmniPotent:OnEvent(event, ...)
  if event == 'ADDON_LOADED' then self:AddonLoaded(...);
  elseif event == 'PLAYER_LOGIN' then self:PlayerLogin();
  elseif event == 'ACTIVE_TALENT_GROUP_CHANGED' then self:PlayerLogin();
  elseif event == 'PLAYER_ENTERING_WORLD' then self:ZoneChanged();
  elseif event == 'ZONE_CHANGED' then self:ZoneChanged();
  elseif event == 'ZONE_CHANGED_NEW_AREA' then self:ZoneChanged();
  elseif event == 'ZONE_CHANGED_INDOORS' then self:ZoneChanged();
  end
end

OmniPotent:SetScript('OnEvent', OmniPotent.OnEvent);

OmniPotent:RegisterEvent('PLAYER_ENTERING_WORLD');
OmniPotent:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED');
OmniPotent:RegisterEvent('ZONE_CHANGED');
OmniPotent:RegisterEvent('ZONE_CHANGED_NEW_AREA');
OmniPotent:RegisterEvent('ZONE_CHANGED_INDOORS');
OmniPotent:RegisterEvent('PLAYER_LOGIN');
OmniPotent:RegisterEvent('ADDON_LOADED');

SLASH_OMNIPOTENT1 = '/op';
SLASH_OMNIPOTENT2 = '/omni';
SLASH_OMNIPOTENT3 = '/omnipotent';
function SlashCmdList.OMNIPOTENT(cmd, box)
  InterfaceOptionsFrame_OpenToCategory(OmniPotent.options_frame);
  InterfaceOptionsFrame_OpenToCategory(OmniPotent.options_frame);
end