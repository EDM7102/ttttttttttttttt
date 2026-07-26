--[[
================================================================================
  07_AssetPlacer.lua
  Tauscht meine Platzhalter-Kloetze gegen echte Modelle aus dem Creator Store.
--------------------------------------------------------------------------------
  WARUM DU DIE MODELLE SELBST AUSSUCHST:
  Ich kann den Creator Store nicht durchsuchen und kenne keine verlaesslichen
  Asset-IDs. Geratene IDs laden entweder nichts oder irgendetwas Zufaelliges.
  Du suchst also aus, ich setze es an die richtige Stelle.

  VORBEREITUNG (einmalig, ca. 15 Minuten):

    1. In Studio: Ansicht -> Toolbox  (Creator Store)
    2. Filter auf "Modelle" stellen
    3. Suchbegriffe die gut funktionieren:
         Gebaeude   "city building", "skyscraper", "shop building", "warehouse"
         Landmarks  "police station", "hospital", "fire station", "car dealership"
         Laternen   "street light", "modern street lamp"
         Baeume     "palm tree", "low poly tree"
         Props      "bench", "trash can", "bus stop", "fire hydrant"
    4. Modell in den Workspace ziehen
    5. Im Explorer den Ordner ReplicatedStorage anklicken, dort per Rechtsklick
       -> Objekt einfuegen -> Folder anlegen, benennen: CityAssets
       Darin fuenf weitere Folder:  Buildings  Landmarks  Lamps  Trees  Props
    6. Die gezogenen Modelle in den passenden Ordner verschieben
    7. Erst dann dieses Script ausfuehren

  Pro Ordner reichen 5-10 verschiedene Modelle. Mehr Vielfalt ist besser als
  mehr Menge.

  ############################################################################
  #  SICHERHEIT - BITTE NICHT UEBERSPRINGEN                                  #
  #                                                                          #
  #  Ein grosser Teil der kostenlosen Toolbox-Modelle enthaelt versteckte     #
  #  Scripts, die Fremden Admin-Rechte in deinem Spiel geben oder Werbung     #
  #  einblenden. Das ist auf Roblox ein bekanntes und verbreitetes Problem.   #
  #                                                                          #
  #  Dieses Script loescht deshalb JEDES Script, LocalScript und             #
  #  ModuleScript aus allem, was es einbaut. Das ist nicht optional und      #
  #  laesst sich hier auch nicht abschalten.                                 #
  #                                                                          #
  #  Modelle mit eigener Funktion (oeffnende Tueren, Fahrzeuge) verlieren    #
  #  dadurch ihre Funktion. Fuer Kulisse ist das genau richtig.              #
  ############################################################################

  Ausfuehren ueber die BEFEHLSLEISTE, nachdem 02 bis 04 gelaufen sind.
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CFG = {
	BUILDING_RATIO  = 0.45,
	LANDMARK_RATIO  = 1.0,
	LAMP_RATIO      = 1.0,
	TREE_RATIO      = 0.65,

	MAX_PARTS_BUILDING  = 220,
	MAX_PARTS_LANDMARK  = 450,
	MAX_PARTS_SMALL     = 40,

	PART_BUDGET = 45000,

	WINDOW_PROXIES = 3,   -- unsichtbare LitWindow-Teile pro Asset-Gebaeude

	RANDOM_YAW = true,
	SEED = 5150,
}

local rng = Random.new(CFG.SEED)
local pi = math.pi

--------------------------------------------------------------------------------
local root = workspace:FindFirstChild("CITY")
if not root then error("[Assets] Ordner CITY fehlt. Zuerst 02_City_v3.lua ausfuehren.") end

local assets = ReplicatedStorage:FindFirstChild("CityAssets")
if not assets then
	error("[Assets] ReplicatedStorage/CityAssets fehlt.\n" ..
		"Bitte den Ordner anlegen und darin Buildings / Lamps / Trees / Props,\n" ..
		"dann Modelle aus der Toolbox hineinziehen. Siehe Kommentar oben.")
end

local function bucket(name)
	local f = assets:FindFirstChild(name)
	local out = {}
	if f then
		for _, m in ipairs(f:GetChildren()) do
			if m:IsA("Model") or m:IsA("BasePart") then table.insert(out, m) end
		end
	end
	return out
end

local BUILDINGS = bucket("Buildings")
local LANDMARKS = bucket("Landmarks")
local LAMPS     = bucket("Lamps")
local TREES     = bucket("Trees")
local PROPS     = bucket("Props")

print(("[Assets] Gefunden: %d Gebaeude, %d Landmarks, %d Laternen, %d Baeume, %d Props.")
	:format(#BUILDINGS, #LANDMARKS, #LAMPS, #TREES, #PROPS))

--------------------------------------------------------------------------------
-- SICHERHEIT + AUFRAEUMEN
--------------------------------------------------------------------------------
local strippedScripts = 0

local function sanitize(inst)
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			-- Script, LocalScript und ModuleScript fallen alle hierunter
			d:Destroy()
			strippedScripts = strippedScripts + 1
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = true
		elseif d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			-- haeufigster Traeger von Werbeeinblendungen in Free Models
			if d:FindFirstChildWhichIsA("TextLabel") == nil
				and d:FindFirstChildWhichIsA("ImageLabel") ~= nil then
				d:Destroy()
			end
		end
	end
	if inst:IsA("BasePart") then
		inst.Anchored = true
	end
end

local function countParts(inst)
	local n = 0
	if inst:IsA("BasePart") then n = 1 end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then n = n + 1 end
	end
	return n
end

-- Modelle einmal vorbereiten statt bei jedem Klon
local prepared = {}
local function prepare(list, maxParts, label)
	local ok = {}
	for _, m in ipairs(list) do
		local clone = m:Clone()
		sanitize(clone)
		local n = countParts(clone)
		if n == 0 then
			warn("[Assets] " .. m.Name .. " enthaelt keine Teile - uebersprungen.")
			clone:Destroy()
		elseif n > maxParts then
			warn(("[Assets] %s hat %d Teile (Limit %d) - uebersprungen. %s")
				:format(m.Name, n, maxParts, label))
			clone:Destroy()
		else
			clone.Parent = nil
			table.insert(ok, {model = clone, parts = n})
		end
	end
	return ok
end

prepared.buildings  = prepare(BUILDINGS, CFG.MAX_PARTS_BUILDING, "Zu detailliert fuer Massenersatz.")
prepared.landmarks  = prepare(LANDMARKS, CFG.MAX_PARTS_LANDMARK, "Landmark zu gross.")
prepared.lamps      = prepare(LAMPS, CFG.MAX_PARTS_SMALL, "")
prepared.trees      = prepare(TREES, CFG.MAX_PARTS_SMALL, "")
prepared.props      = prepare(PROPS, CFG.MAX_PARTS_SMALL, "")

print(("[Assets] %d Scripts entfernt (Backdoor-Schutz)."):format(strippedScripts))

--------------------------------------------------------------------------------
-- EINSETZEN MIT GROESSENANPASSUNG
--------------------------------------------------------------------------------
local budgetUsed = 0

local function extents(inst)
	if inst:IsA("Model") then
		local ok, size = pcall(function() return inst:GetExtentsSize() end)
		if ok then return size end
	end
	if inst:IsA("BasePart") then return inst.Size end
	return Vector3.new(1, 1, 1)
end

-- Setzt eine Kopie so, dass sie in targetX x targetZ passt und mit der
-- Unterkante auf baseY steht.
local function placeScaled(entry, cx, cz, baseY, targetX, targetZ, targetH, yaw)
	if budgetUsed + entry.parts > CFG.PART_BUDGET then return nil end

	local c = entry.model:Clone()
	local ext = extents(c)
	if ext.X < 0.1 or ext.Z < 0.1 or ext.Y < 0.1 then c:Destroy() return nil end

	local fx = targetX / ext.X
	local fz = targetZ / ext.Z
	local f = math.min(fx, fz)
	if targetH then f = math.min(f, targetH / ext.Y) end
	f = math.clamp(f, 0.05, 40)

	if c:IsA("Model") then
		if not c.PrimaryPart then
			c.PrimaryPart = c:FindFirstChildWhichIsA("BasePart", true)
		end
		local okScale = pcall(function() c:ScaleTo(c:GetScale() * f) end)
		if not okScale then
			-- aeltere Modelle ohne Scale-Unterstuetzung: unskaliert lassen
		end
		local newExt = extents(c)
		c.Parent = workspace
		c:PivotTo(CFrame.new(cx, baseY + newExt.Y / 2, cz) * CFrame.Angles(0, yaw or 0, 0))
	else
		c.Size = c.Size * f
		c.CFrame = CFrame.new(cx, baseY + c.Size.Y / 2, cz) * CFrame.Angles(0, yaw or 0, 0)
		c.Parent = workspace
	end

	budgetUsed = budgetUsed + entry.parts
	return c
end

--------------------------------------------------------------------------------
-- 1) GEBAEUDE TAUSCHEN
--------------------------------------------------------------------------------
local Y = root:GetAttribute("CityLevel")
local F_BUILD = root:FindFirstChild("Buildings")
local F_WINDOWS = root:FindFirstChild("LitWindows")
local F_NEON = root:FindFirstChild("NeonSigns")

local swappedB = 0

if #prepared.buildings > 0 and F_BUILD then
	local newFolder = Instance.new("Folder")
	newFolder.Name = "AssetBuildings"
	newFolder.Parent = root

	local seen = 0
	for _, bm in ipairs(F_BUILD:GetChildren()) do
		seen = seen + 1
		if bm:IsA("Model") and bm.Name == "Bldg" and rng:NextNumber() < CFG.BUILDING_RATIO then
			local cx = bm:GetAttribute("CX")
			local cz = bm:GetAttribute("CZ")
			local fx = bm:GetAttribute("FootX")
			local fz = bm:GetAttribute("FootZ")
			local hh = bm:GetAttribute("Height")

			if cx and fx then
				local entry = prepared.buildings[rng:NextInteger(1, #prepared.buildings)]
				local yaw = CFG.RANDOM_YAW and (rng:NextInteger(0, 3) * pi / 2) or 0
				local placed = placeScaled(entry, cx, cz, Y, fx, fz, nil, yaw)

				if placed then
					placed.Name = "AssetBldg"
					placed.Parent = newFolder
					bm:Destroy()

					-- Leuchtfenster und Neonschilder dieses Grundstuecks entfernen,
					-- sonst schweben sie im echten Modell herum
					for _, folder in ipairs({F_WINDOWS, F_NEON}) do
						if folder then
							for _, p in ipairs(folder:GetChildren()) do
								if p:IsA("BasePart") then
									local dx = math.abs(p.Position.X - cx)
									local dz = math.abs(p.Position.Z - cz)
									if dx < fx * 0.75 and dz < fz * 0.75 then p:Destroy() end
								end
							end
						end
					end
					swappedB = swappedB + 1
				end
			end
		end
		if seen % 25 == 0 then task.wait() end
	end
end
print(("[Assets] %d Gebaeude ersetzt."):format(swappedB))

--------------------------------------------------------------------------------
-- 1b) LANDMARKS TAUSCHEN
--------------------------------------------------------------------------------
local F_LANDMARKS = root:FindFirstChild("Landmarks")
local swappedLm = 0

if #prepared.landmarks > 0 and F_LANDMARKS then
	local newFolder = Instance.new("Folder")
	newFolder.Name = "AssetLandmarks"
	newFolder.Parent = root

	for _, lm in ipairs(F_LANDMARKS:GetChildren()) do
		if lm:IsA("Model") and lm:GetAttribute("IsLandmark") and rng:NextNumber() < CFG.LANDMARK_RATIO then
			local cx = lm:GetAttribute("CX")
			local cz = lm:GetAttribute("CZ")
			local fx = lm:GetAttribute("FootX")
			local fz = lm:GetAttribute("FootZ")

			if cx and fx then
				local entry = prepared.landmarks[rng:NextInteger(1, #prepared.landmarks)]
				local yaw = CFG.RANDOM_YAW and (rng:NextInteger(0, 3) * pi / 2) or 0
				local placed = placeScaled(entry, cx, cz, Y, fx, fz, nil, yaw)

				if placed then
					placed.Name = "AssetLandmark"
					placed.Parent = newFolder
					lm:Destroy()

					-- Der Neon-Streifen des Landmarks liegt separat in NeonSigns
					if F_NEON then
						for _, p in ipairs(F_NEON:GetChildren()) do
							if p:IsA("BasePart") then
								local dx = math.abs(p.Position.X - cx)
								local dz = math.abs(p.Position.Z - cz)
								if dx < fx * 0.75 and dz < fz * 0.75 then p:Destroy() end
							end
						end
					end
					swappedLm = swappedLm + 1
				end
			end
		end
	end
	task.wait()
end
print(("[Assets] %d Landmarks ersetzt."):format(swappedLm))

--------------------------------------------------------------------------------
-- 2) LATERNEN TAUSCHEN
--------------------------------------------------------------------------------
local swappedL = 0
local F_LAMPS = root:FindFirstChild("StreetLamps")

if #prepared.lamps > 0 and F_LAMPS then
	for _, lamp in ipairs(F_LAMPS:GetChildren()) do
		if lamp:IsA("Model") and rng:NextNumber() < CFG.LAMP_RATIO then
			local pole = lamp:FindFirstChild("Pole")
			local led = lamp:FindFirstChild("LED")
			if pole then
				local px, pz = pole.Position.X, pole.Position.Z
				local entry = prepared.lamps[rng:NextInteger(1, #prepared.lamps)]
				local placed = placeScaled(entry, px, pz, Y, 12, 12, 36, rng:NextNumber(0, pi * 2))
				if placed then
					placed.Name = "Lamp"
					-- Damit 06_Runtime die Laterne weiterhin nachts anschaltet,
					-- wandert das LED-Teil samt Spotlight ins neue Modell.
					-- Unsichtbar, weil das echte Modell seinen eigenen Kopf hat -
					-- das Teil ist ab hier nur noch Traeger der Lichtquelle.
					if led then
						led.Transparency = 1
						led.CanCollide = false
						led.Parent = placed
					end
					placed.Parent = F_LAMPS
					lamp:Destroy()
					swappedL = swappedL + 1
				end
			end
		end
	end
	task.wait()
end
print(("[Assets] %d Laternen ersetzt."):format(swappedL))

--------------------------------------------------------------------------------
-- 3) BAEUME TAUSCHEN
--------------------------------------------------------------------------------
local swappedT = 0
local F_TREES = root:FindFirstChild("Trees")

if #prepared.trees > 0 and F_TREES then
	for _, t in ipairs(F_TREES:GetChildren()) do
		if t:IsA("Model") and rng:NextNumber() < CFG.TREE_RATIO then
			local trunk = t:FindFirstChild("Trunk")
			if trunk then
				local px, pz = trunk.Position.X, trunk.Position.Z
				local entry = prepared.trees[rng:NextInteger(1, #prepared.trees)]
				local s = rng:NextNumber(0.8, 1.35)
				local placed = placeScaled(entry, px, pz, Y, 26 * s, 26 * s, 40 * s,
					rng:NextNumber(0, pi * 2))
				if placed then
					placed.Name = "AssetTree"
					placed.Parent = F_TREES
					t:Destroy()
					swappedT = swappedT + 1
				end
			end
		end
		if swappedT % 40 == 0 then task.wait() end
	end
end
print(("[Assets] %d Baeume ersetzt."):format(swappedT))

--------------------------------------------------------------------------------
-- 4) PROPS AUF DIE GEHWEGE STREUEN
--------------------------------------------------------------------------------
local placedP = 0
if #prepared.props > 0 then
	local F_STREET = root:FindFirstChild("StreetFurniture")
	if F_STREET then
		local function nums(a)
			local t = {}
			for _, v in ipairs(string.split(root:GetAttribute(a), ",")) do
				table.insert(t, tonumber(v))
			end
			return t
		end
		local AX, AW = nums("AvenueX"), nums("AvenueW")
		local SZ = nums("StreetZ")
		local SW_ = root:GetAttribute("SidewalkW")

		for i, ax in ipairs(AX) do
			local off = AW[i] / 2 + 2.5 + SW_ / 2
			local z = SZ[1] + 60
			while z < SZ[#SZ] - 60 do
				if rng:NextNumber() < 0.45 then
					local s = (rng:NextNumber() < 0.5) and -1 or 1
					local entry = prepared.props[rng:NextInteger(1, #prepared.props)]
					local placed = placeScaled(entry, ax + s * off, z, Y + 0.9, 11, 11, 14,
						rng:NextNumber(0, pi * 2))
					if placed then
						placed.Parent = F_STREET
						placedP = placedP + 1
					end
				end
				z = z + rng:NextNumber(80, 170)
			end
			task.wait()
		end
	end
end
print(("[Assets] %d Props gesetzt."):format(placedP))

--------------------------------------------------------------------------------
for _, e in ipairs(prepared.buildings) do e.model:Destroy() end
for _, e in ipairs(prepared.landmarks) do e.model:Destroy() end
for _, e in ipairs(prepared.lamps) do e.model:Destroy() end
for _, e in ipairs(prepared.trees) do e.model:Destroy() end
for _, e in ipairs(prepared.props) do e.model:Destroy() end

print("================================================================")
print(("[Assets] FERTIG. Teile durch Modelle hinzugefuegt: %d von %d Budget.")
	:format(budgetUsed, CFG.PART_BUDGET))
print(("[Assets] %d Scripts wurden aus den Modellen entfernt."):format(strippedScripts))
print("[Assets] Gesamtteile in CITY: " .. #root:GetDescendants())
print("================================================================")
