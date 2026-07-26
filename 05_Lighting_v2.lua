--[[
================================================================================
  05_Lighting_v2.lua
  Miami-Farbstimmung, Atmosphaere, Wasser, Post-Processing, Streaming.
--------------------------------------------------------------------------------
  Ausfuehren ueber die BEFEHLSLEISTE (nicht im Play-Modus!).
  Lighting.Technology ist zur Laufzeit gesperrt.

  Der Tag-Nacht-Wechsel wird spaeter von 06_Runtime.lua uebernommen. Dieses
  Script setzt nur den Ausgangszustand.
================================================================================
]]

local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

local function clear(class)
	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA(class) then v:Destroy() end
	end
end

--------------------------------------------------------------------------------
-- CORE
--------------------------------------------------------------------------------
pcall(function() Lighting.Technology = Enum.Technology.Future end)
Lighting.GlobalShadows            = true
Lighting.ShadowSoftness           = 0.2
Lighting.Brightness               = 2.4
Lighting.ExposureCompensation     = 0.1
Lighting.EnvironmentDiffuseScale  = 0.6
Lighting.EnvironmentSpecularScale = 0.85
Lighting.Ambient                  = Color3.fromRGB(52, 58, 72)
Lighting.OutdoorAmbient           = Color3.fromRGB(126, 138, 158)
Lighting.ColorShift_Top           = Color3.fromRGB(255, 232, 198)
Lighting.ColorShift_Bottom        = Color3.fromRGB(42, 50, 66)
Lighting.ClockTime                = 14.0      -- fester Tag, passt zu ALWAYS_DAY in Script 06
Lighting.GeographicLatitude       = 25.8      -- Breitengrad Miami
Lighting.FogEnd                   = 100000

--------------------------------------------------------------------------------
-- ATMOSPHAERE
--------------------------------------------------------------------------------
clear("Atmosphere")
local atmo = Instance.new("Atmosphere")
atmo.Density = 0.31
atmo.Offset  = 0.2
atmo.Color   = Color3.fromRGB(204, 214, 226)
atmo.Decay   = Color3.fromRGB(118, 134, 158)
atmo.Glare   = 0.4
atmo.Haze    = 1.7
atmo.Parent  = Lighting

clear("Sky")
local sky = Instance.new("Sky")
sky.SunAngularSize  = 13
sky.MoonAngularSize = 12
sky.StarCount       = 5200
sky.Parent          = Lighting

--------------------------------------------------------------------------------
-- POST-PROCESSING
--------------------------------------------------------------------------------
clear("PostEffect")

local bloom = Instance.new("BloomEffect")
bloom.Name      = "CityBloom"
bloom.Intensity = 0.8
bloom.Size      = 28
bloom.Threshold = 1.35        -- niedrig genug, damit Neon und LED strahlen
bloom.Parent    = Lighting

local rays = Instance.new("SunRaysEffect")
rays.Intensity = 0.11
rays.Spread    = 0.6
rays.Parent    = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Name       = "CityGrade"
cc.Brightness = 0.01
cc.Contrast   = 0.18
cc.Saturation = 0.14
cc.TintColor  = Color3.fromRGB(255, 248, 240)
cc.Parent     = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.FarIntensity  = 0.14
dof.NearIntensity = 0
dof.FocusDistance = 70
dof.InFocusRadius = 950
dof.Parent        = Lighting

--------------------------------------------------------------------------------
-- WASSER
--------------------------------------------------------------------------------
-- Transparenz 0.78 zusammen mit Reflexion 0.55 liess das Wasser wie eine
-- Glasplatte aussehen. Diese Werte wirken deutlich natuerlicher.
Terrain.WaterColor        = Color3.fromRGB(20, 116, 146)
Terrain.WaterTransparency = 0.55
Terrain.WaterReflectance  = 0.3
Terrain.WaterWaveSize     = 0.25
Terrain.WaterWaveSpeed    = 9

--------------------------------------------------------------------------------
-- TERRAIN-MATERIALFARBEN
--------------------------------------------------------------------------------
local M = Enum.Material
Terrain:SetMaterialColor(M.Sand,       Color3.fromRGB(226, 212, 182))
Terrain:SetMaterialColor(M.Grass,      Color3.fromRGB(104, 130, 76))
Terrain:SetMaterialColor(M.LeafyGrass, Color3.fromRGB(82, 108, 62))
Terrain:SetMaterialColor(M.Rock,       Color3.fromRGB(132, 128, 120))
Terrain:SetMaterialColor(M.Ground,     Color3.fromRGB(126, 110, 86))
Terrain:SetMaterialColor(M.Slate,      Color3.fromRGB(98, 98, 102))
Terrain.Decoration = true

--------------------------------------------------------------------------------
-- PERFORMANCE
--------------------------------------------------------------------------------
workspace.StreamingEnabled = true
pcall(function()
	workspace.StreamingIntegrityMode = Enum.StreamingIntegrityMode.MinimumRadiusPause
end)
workspace.StreamingTargetRadius = 2800
workspace.StreamingMinRadius    = 512

local SP = game:GetService("StarterPlayer")
SP.CameraMaxZoomDistance = 500
SP.EnableMouseLockOption = true

print("[Lighting] FERTIG. Naechster Schritt: 06_Runtime.lua in ServerScriptService, optional 07_AssetPlacer.lua")
