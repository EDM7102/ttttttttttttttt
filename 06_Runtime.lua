--[[
================================================================================
  06_Runtime.lua
  Laeuft im Spiel: Ampelsteuerung mit gruener Welle + Tag-Nacht-Zyklus.
--------------------------------------------------------------------------------
  DIESES SCRIPT GEHOERT NICHT IN DIE BEFEHLSLEISTE.

  Einbauen:
    1. Im Explorer ServerScriptService anklicken
    2. Plus-Symbol -> Script
    3. Den vorhandenen Inhalt loeschen, diesen Code einfuegen
    4. Script umbenennen in "CityRuntime"
    5. Play druecken

  Was passiert:
    - Alle Ampeln schalten rot / gelb / gruen im 36-Sekunden-Takt
    - Kreuzungen sind zeitversetzt: wer Tempo haelt, faehrt eine gruene Welle
    - Tag-Nacht-Zyklus (12 Minuten pro voller Tag)
    - Bei Sonnenuntergang gehen Laternen, Fenster und Leuchtreklame an
================================================================================
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------
-- EINSTELLUNGEN
--------------------------------------------------------------------------------
local CFG = {
	-- Ampelphasen in Sekunden
	NS_GREEN  = 14,
	NS_YELLOW = 3,
	CLEAR_1   = 2,
	EW_GREEN  = 12,
	EW_YELLOW = 3,
	CLEAR_2   = 2,

	GREEN_WAVE = 0.022,   -- Sekunden Versatz pro Stud in X-Richtung

	-- ============================================================
	--  ALWAYS_DAY = true   -> es ist dauerhaft Tag, kein Zyklus
	--  ALWAYS_DAY = false  -> Tag-Nacht-Wechsel laeuft
	--  Ampeln schalten in beiden Faellen ganz normal.
	-- ============================================================
	ALWAYS_DAY = true,

	DAY_SECONDS  = 720,   -- Dauer eines vollen 24h-Zyklus in Echtzeit
	START_HOUR   = 14.0,  -- feste Uhrzeit bei ALWAYS_DAY (14 Uhr = hoher Sonnenstand)
	NIGHT_START  = 18.6,
	NIGHT_END    = 6.2,

	LIT_WINDOW_CHANCE = 0.72,   -- Anteil der Fenster, die nachts leuchten
}

local CYCLE = CFG.NS_GREEN + CFG.NS_YELLOW + CFG.CLEAR_1
	+ CFG.EW_GREEN + CFG.EW_YELLOW + CFG.CLEAR_2

--------------------------------------------------------------------------------
-- STADT FINDEN
--------------------------------------------------------------------------------
local city = workspace:WaitForChild("CITY", 30)
if not city then
	warn("[Runtime] Ordner CITY nicht gefunden - Script beendet.")
	return
end

local function getFolder(name)
	return city:FindFirstChild(name)
end

--------------------------------------------------------------------------------
-- AMPELN EINSAMMELN
--------------------------------------------------------------------------------
local LENS_NAMES = {Red = true, Yellow = true, Green = true}

local function collectLenses(model)
	local out = {Red = {}, Yellow = {}, Green = {}}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and LENS_NAMES[d.Name] then
			table.insert(out[d.Name], d)
		end
	end
	return out
end

local intersections = {}
local tlFolder = getFolder("TrafficLights")

if tlFolder then
	for _, m in ipairs(tlFolder:GetChildren()) do
		local ns = m:FindFirstChild("NS")
		local ew = m:FindFirstChild("EW")
		if ns and ew then
			table.insert(intersections, {
				ns = collectLenses(ns),
				ew = collectLenses(ew),
				offset = (m:GetAttribute("PosX") or 0) * CFG.GREEN_WAVE,
				lastNS = "",
				lastEW = "",
			})
		end
	end
end
print("[Runtime] " .. #intersections .. " Ampelanlagen uebernommen.")

local BLACK = Color3.new(0, 0, 0)

local function applyState(group, active)
	for name, list in pairs(group) do
		local on = (name == active)
		for _, p in ipairs(list) do
			local base = p:GetAttribute("OnColor") or p.Color
			if on then
				p.Material = Enum.Material.Neon
				p.Color = base
			else
				p.Material = Enum.Material.SmoothPlastic
				p.Color = base:Lerp(BLACK, 0.8)
			end
			local glow = p:FindFirstChild("Glow")
			if glow then glow.Enabled = on end
		end
	end
end

-- Phasenlogik: liefert Zustand fuer NS und EW
local function phaseAt(t)
	local x = t % CYCLE
	local a = CFG.NS_GREEN
	local b = a + CFG.NS_YELLOW
	local c = b + CFG.CLEAR_1
	local d = c + CFG.EW_GREEN
	local e = d + CFG.EW_YELLOW

	if x < a then return "Green", "Red"
	elseif x < b then return "Yellow", "Red"
	elseif x < c then return "Red", "Red"
	elseif x < d then return "Red", "Green"
	elseif x < e then return "Red", "Yellow"
	else return "Red", "Red" end
end

--------------------------------------------------------------------------------
-- LATERNEN, FENSTER, NEON EINSAMMELN
--------------------------------------------------------------------------------
local lampLEDs = {}
local lampBeams = {}
do
	local function registerLamp(d)
		if not d:IsA("BasePart") or d.Name ~= "LED" then return end
		table.insert(lampLEDs, d)
		local beam = d:FindFirstChild("Beam")
		if beam then table.insert(lampBeams, beam) end
	end
	local f = getFolder("StreetLamps")
	if f then
		for _, d in ipairs(f:GetDescendants()) do registerLamp(d) end
	end
end

local windows = {}
do
	local function registerWindow(d)
		if not d:IsA("BasePart") then return end
		local r = Random.new(math.floor(d.Position.X * 17 + d.Position.Z * 31))
		local on = r:NextNumber() < CFG.LIT_WINDOW_CHANCE
		d:SetAttribute("NightOn", on)
		d:SetAttribute("NightColor",
			Color3.fromRGB(r:NextInteger(240, 255), r:NextInteger(214, 244), r:NextInteger(170, 220)))
		table.insert(windows, d)
	end

	local f = getFolder("LitWindows")
	if f then
		for _, d in ipairs(f:GetChildren()) do registerWindow(d) end
	end
	-- Fenster in eingesetzten Creator-Store-Gebaeuden
	local ab = getFolder("AssetBuildings")
	if ab then
		for _, m in ipairs(ab:GetDescendants()) do
			if m:IsA("BasePart") and (m.Name == "WindowProxy" or m.Name == "LitWindow") then
				registerWindow(m)
			end
		end
	end
end

local neonSigns = {}
do
	local function registerNeon(d)
		if d:IsA("BasePart") then table.insert(neonSigns, d) end
	end
	local f = getFolder("NeonSigns")
	if f then
		for _, d in ipairs(f:GetDescendants()) do registerNeon(d) end
	end
	local ab = getFolder("AssetBuildings")
	if ab then
		for _, d in ipairs(ab:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "NeonSign" then registerNeon(d) end
		end
	end
	local al = getFolder("AssetLandmarks")
	if al then
		for _, d in ipairs(al:GetDescendants()) do
			if d:IsA("BasePart") and (d.Name == "NeonSign" or d.Name == "SignBoard") then
				registerNeon(d)
			end
		end
	end
end

local warnLights = {}
for _, d in ipairs(city:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == "WarnLight" then
		table.insert(warnLights, d)
	end
end

print(("[Runtime] %d Laternen, %d Fenster, %d Neonflaechen, %d Warnlichter.")
	:format(#lampLEDs, #windows, #neonSigns, #warnLights))

--------------------------------------------------------------------------------
-- TAG / NACHT UMSCHALTEN
--------------------------------------------------------------------------------
local LAMP_OFF_COL = Color3.fromRGB(120, 122, 126)
local LAMP_ON_COL  = Color3.fromRGB(255, 246, 226)
local WIN_DAY_COL  = Color3.fromRGB(30, 34, 42)

local grade = Lighting:FindFirstChild("CityGrade")
local bloomFx = Lighting:FindFirstChild("CityBloom")
local atmo = Lighting:FindFirstChildOfClass("Atmosphere")

local function setNight(night)
	-- Laternen
	for _, led in ipairs(lampLEDs) do
		if night then
			led.Material = Enum.Material.Neon
			led.Color = LAMP_ON_COL
		else
			led.Material = Enum.Material.SmoothPlastic
			led.Color = LAMP_OFF_COL
		end
	end
	for _, beam in ipairs(lampBeams) do
		beam.Enabled = night
	end

	-- Bueros und Wohnungen
	for _, w in ipairs(windows) do
		if night and w:GetAttribute("NightOn") then
			w.Material = Enum.Material.Neon
			w.Color = w:GetAttribute("NightColor")
		else
			w.Material = Enum.Material.Glass
			w.Color = WIN_DAY_COL
		end
	end

	-- Leuchtreklame: tagsueber blasser
	for _, s in ipairs(neonSigns) do
		s.Transparency = night and 0 or 0.4
	end

	-- Stimmung
	if night then
		Lighting.Brightness = 1.1
		Lighting.Ambient = Color3.fromRGB(26, 30, 46)
		Lighting.OutdoorAmbient = Color3.fromRGB(38, 46, 70)
		Lighting.ExposureCompensation = 0.42
		if atmo then
			atmo.Density = 0.42
			atmo.Color = Color3.fromRGB(96, 108, 140)
			atmo.Haze = 2.4
			atmo.Glare = 0.15
		end
		if grade then
			grade.Contrast = 0.24
			grade.Saturation = 0.2
			grade.TintColor = Color3.fromRGB(226, 232, 255)
		end
		if bloomFx then
			bloomFx.Intensity = 1.35
			bloomFx.Threshold = 0.9
		end
	else
		Lighting.Brightness = 2.4
		Lighting.Ambient = Color3.fromRGB(52, 58, 72)
		Lighting.OutdoorAmbient = Color3.fromRGB(126, 138, 158)
		Lighting.ExposureCompensation = 0.1
		if atmo then
			atmo.Density = 0.31
			atmo.Color = Color3.fromRGB(204, 214, 226)
			atmo.Haze = 1.7
			atmo.Glare = 0.4
		end
		if grade then
			grade.Contrast = 0.18
			grade.Saturation = 0.14
			grade.TintColor = Color3.fromRGB(255, 248, 240)
		end
		if bloomFx then
			bloomFx.Intensity = 0.8
			bloomFx.Threshold = 1.35
		end
	end
end

--------------------------------------------------------------------------------
-- HAUPTSCHLEIFE
--------------------------------------------------------------------------------
local t0 = os.clock()
local isNight = nil
local warnOn = false
local lastWarnFlip = 0
local lastTick = 0

setNight(false)

if CFG.ALWAYS_DAY then
	isNight = false
	Lighting.ClockTime = CFG.START_HOUR
	print("[Runtime] ALWAYS_DAY aktiv - feste Uhrzeit " .. CFG.START_HOUR .. ":00, kein Nachtwechsel.")
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local elapsed = now - t0

	------------------------------------------------------------------
	-- Ampeln (4x pro Sekunde reicht voellig)
	------------------------------------------------------------------
	if now - lastTick > 0.25 then
		lastTick = now
		for _, node in ipairs(intersections) do
			local ns, ew = phaseAt(elapsed + node.offset)
			if ns ~= node.lastNS then
				node.lastNS = ns
				applyState(node.ns, ns)
			end
			if ew ~= node.lastEW then
				node.lastEW = ew
				applyState(node.ew, ew)
			end
		end
	end

	------------------------------------------------------------------
	-- Tageszeit  (wird bei ALWAYS_DAY komplett uebersprungen)
	------------------------------------------------------------------
	if CFG.ALWAYS_DAY then
		-- Uhrzeit dauerhaft festnageln. Falls noch ein altes Script oder ein
		-- Plugin an ClockTime dreht, gewinnt hier der Tag.
		if math.abs(Lighting.ClockTime - CFG.START_HOUR) > 0.01 then
			Lighting.ClockTime = CFG.START_HOUR
		end
	else
		local ct = (CFG.START_HOUR + (elapsed / CFG.DAY_SECONDS) * 24) % 24
		Lighting.ClockTime = ct

		local night = (ct >= CFG.NIGHT_START) or (ct <= CFG.NIGHT_END)
		if night ~= isNight then
			isNight = night
			setNight(night)
			print("[Runtime] " .. (night and "Nacht" or "Tag") .. " - Beleuchtung umgeschaltet.")
		end
	end

	------------------------------------------------------------------
	-- Blinkende Warnlichter auf den Antennen
	------------------------------------------------------------------
	if now - lastWarnFlip > 1.1 then
		lastWarnFlip = now
		warnOn = not warnOn
		for _, w in ipairs(warnLights) do
			w.Transparency = warnOn and 0 or 0.75
		end
	end
end)

print("[Runtime] Ampelsteuerung und Tag-Nacht-Zyklus laufen. Zykluslaenge: "
	.. CYCLE .. "s / Tag: " .. CFG.DAY_SECONDS .. "s")
