--[[
================================================================================
  08_StreetAsset.lua
  Ersetzt die generierte Asphalt-Fahrbahn (Avenues, Streets, Diagonale,
  Kreisverkehr, Kuestenstrasse) durch das Creator-Store-Modell mit der
  Asset-ID 9382524421, gekachelt entlang jeder Fahrbahn.
--------------------------------------------------------------------------------
  HINWEIS ZUR ASSET-QUALITAET:
  Das Asset heisst im Roblox-Katalog nur "Strasse" (Ersteller pascal_vogel1,
  keine Verkaufshistorie) - vermutlich ein einzelnes Hobby-Modell, keine
  kuratierte Strassen-Serie. Ich kenne seine genaue Geometrie nicht, deshalb:

    1. Erst ausfuehren, dann EINE Kreuzung in Studio ansehen.
    2. Liegen die Kacheln quer zur Fahrbahn?  -> ROTATE_TILE_90 = true
    3. Schwebt die Strasse oder versinkt sie? -> Y_OFFSET anpassen
    4. Danach nochmal ausfuehren (baut die Kacheln komplett neu auf).

  Voraussetzung: 02_City_v3.lua ist gelaufen (CITY/Roads existiert).
  Ausfuehren ueber die BEFEHLSLEISTE. Bei "Dangerous Command Detected" auf
  Continue klicken - das Script laedt ein Modell aus dem Creator Store.
================================================================================
]]

local InsertService = game:GetService("InsertService")

local CFG = {
	ASSET_ID = 9382524421,

	-- Falls die Kacheln quer statt laengs zur Fahrbahn liegen: auf true stellen.
	ROTATE_TILE_90 = false,

	-- Manuelle Hoehenkorrektur, falls die Strasse schwebt oder versinkt.
	Y_OFFSET = 0,
}

local root = workspace:FindFirstChild("CITY")
if not root then error("[StreetAsset] Ordner CITY fehlt. Zuerst 02_City_v3.lua ausfuehren.") end

local F_ROADS = root:FindFirstChild("Roads")
if not F_ROADS then error("[StreetAsset] Ordner Roads fehlt in CITY.") end

--------------------------------------------------------------------------------
-- SICHERHEIT - gleiche Regel wie in 07_AssetPlacer.lua: jedes Script raus.
--------------------------------------------------------------------------------
local strippedScripts = 0
local function sanitize(inst)
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
			strippedScripts = strippedScripts + 1
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = true
		elseif d:IsA("Sound") then
			d:Destroy()
		end
	end
	if inst:IsA("BasePart") then inst.Anchored = true end
end

--------------------------------------------------------------------------------
-- ASSET LADEN
--------------------------------------------------------------------------------
local ok, container = pcall(function() return InsertService:LoadAsset(CFG.ASSET_ID) end)
if not ok or not container then
	error("[StreetAsset] Asset " .. CFG.ASSET_ID .. " konnte nicht geladen werden: " .. tostring(container))
end

local sourceModel = container:FindFirstChildWhichIsA("Model") or container:FindFirstChildWhichIsA("BasePart")
if not sourceModel then
	container:Destroy()
	error("[StreetAsset] Im Asset wurde weder Model noch Part gefunden.")
end
sourceModel.Parent = nil
container:Destroy()

sanitize(sourceModel)

if sourceModel:IsA("Model") and not sourceModel.PrimaryPart then
	sourceModel.PrimaryPart = sourceModel:FindFirstChildWhichIsA("BasePart", true)
end

local function extents(inst)
	if inst:IsA("Model") then
		local ok2, size = pcall(function() return inst:GetExtentsSize() end)
		if ok2 then return size end
	end
	if inst:IsA("BasePart") then return inst.Size end
	return Vector3.new(1, 1, 1)
end

local tileExt = extents(sourceModel)
if tileExt.X < 0.1 or tileExt.Z < 0.1 then
	sourceModel:Destroy()
	error("[StreetAsset] Asset hat keine brauchbare Grundflaeche (X/Z zu klein).")
end
print(("[StreetAsset] Asset %d geladen: %.1f x %.1f x %.1f Studs (X/Y/Z)."):format(
	CFG.ASSET_ID, tileExt.X, tileExt.Y, tileExt.Z))

--------------------------------------------------------------------------------
-- FAHRBAHN-TEILE FINDEN (nur die eigentliche Asphaltflaeche, keine
-- Buergersteige/Mittelstreifen - die haengen als eigene Teile daneben)
--------------------------------------------------------------------------------
local targets = {}
for _, p in ipairs(F_ROADS:GetChildren()) do
	if p:IsA("BasePart") and p.Material == Enum.Material.Asphalt then
		table.insert(targets, p)
	end
end
print(("[StreetAsset] %d Fahrbahnabschnitte gefunden."):format(#targets))

--------------------------------------------------------------------------------
-- KACHELN
--------------------------------------------------------------------------------
local newFolder = root:FindFirstChild("StreetAssets")
if newFolder then newFolder:Destroy() end
newFolder = Instance.new("Folder")
newFolder.Name = "StreetAssets"
newFolder.Parent = root

local placed = 0

-- Laengsachse des Assets: standardmaessig Z (Roblox-Konvention "vorne" = -Z).
local tileWidth  = CFG.ROTATE_TILE_90 and tileExt.Z or tileExt.X
local tileLength = CFG.ROTATE_TILE_90 and tileExt.X or tileExt.Z
local extraSpin  = CFG.ROTATE_TILE_90 and CFrame.Angles(0, math.rad(90), 0) or CFrame.new()

local function tileSegment(baseCF, length, width)
	local wScale = math.clamp(width / tileWidth, 0.05, 40)
	local effTileLen = tileLength * wScale
	local n = math.max(1, math.floor(length / effTileLen + 0.5))
	local lScale = length / (n * tileLength)   -- nur fuer einzelne Parts nutzbar (nicht-uniform)

	for k = 0, n - 1 do
		local offsetZ = -length / 2 + (k + 0.5) * (length / n)
		local clone = sourceModel:Clone()

		if clone:IsA("Model") then
			-- Models lassen nur gleichfoermiges Skalieren zu -> an der Breite ausgerichtet.
			pcall(function() clone:ScaleTo(clone:GetScale() * wScale) end)
			clone.Parent = newFolder
			clone:PivotTo(baseCF * extraSpin * CFrame.new(0, CFG.Y_OFFSET, offsetZ))
		else
			clone.Size = Vector3.new(clone.Size.X * wScale, clone.Size.Y, clone.Size.Z * lScale)
			clone.Parent = newFolder
			clone.CFrame = baseCF * extraSpin * CFrame.new(0, CFG.Y_OFFSET, offsetZ)
		end
		placed = placed + 1
	end
end

for _, p in ipairs(targets) do
	local lenIsX = p.Size.X > p.Size.Z
	local length = lenIsX and p.Size.X or p.Size.Z
	local width  = lenIsX and p.Size.Z or p.Size.X
	local baseCF = p.CFrame
	if lenIsX then
		baseCF = baseCF * CFrame.Angles(0, math.rad(90), 0)
	end

	tileSegment(baseCF, length, width)

	-- Original-Asphalt nur ausblenden statt loeschen: Gehwege/Mittelstreifen
	-- sind eigene Teile und bleiben unveraendert, egal was hier passiert.
	p.Transparency = 1
	p.CanCollide = false
end

sourceModel:Destroy()

print(("[StreetAsset] %d Kacheln platziert, %d Scripts aus dem Asset entfernt."):format(placed, strippedScripts))
print("[StreetAsset] Sieht es falsch aus? ROTATE_TILE_90 bzw. Y_OFFSET oben anpassen und erneut ausfuehren.")
print("[StreetAsset] ---- FERTIG ----")
