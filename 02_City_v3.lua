--[[
================================================================================
  02_City_v3.lua   -   RASTER AUFGEBROCHEN
--------------------------------------------------------------------------------
  Was gegen "alles gerade, eng und gleich" hilft:

  1. UNREGELMAESSIGES RASTER    Abstaende zwischen 170 und 300 Studs statt
                                ueberall gleich
  2. UNTERSCHIEDLICHE BREITEN   zwei Boulevards mit begruentem Mittelstreifen,
                                dazwischen schmale Nebenstrassen
  3. DIAGONALE                  ein Boulevard schneidet quer durch das Raster
  4. KREISVERKEHR               bricht eine Kreuzung komplett auf
  5. VIER STADTTEILE            Strand, Downtown, Wohnviertel, Hafen - jeder
                                mit eigenen Hoehen, Farben und Materialien
  6. SECHS BEBAUUNGSMUSTER      pro Block gewuerfelt: ein Turm, Karree,
                                Reihe, Innenhof, gemischt oder Park
  7. VERSATZ                    jedes Gebaeude sitzt leicht anders im Grundstueck

  Ausfuehren ueber die BEFEHLSLEISTE. Dauer ca. 90-150 Sekunden.
  Voraussetzung: 01_Terrain_flat.lua ist gelaufen.
================================================================================
]]

local Terrain = workspace.Terrain

--------------------------------------------------------------------------------
-- LAYOUT
--------------------------------------------------------------------------------
local C = {
	SEED = 20260726,
	CITY_LEVEL = 16,

	FLAT_X0 = -380, FLAT_X1 = 1540, FLAT_Z0 = -1580, FLAT_Z1 = 1540,

	-- Bewusst ungleiche Abstaende: 260 / 180 / 290 / 170 / 290 / 240
	AVENUE_X = {-120, 140, 320, 610, 780, 1070, 1310},
	AVENUE_W = {  42,  74,  38,  34,  74,  42,   50},

	-- Abstaende: 250 / 210 / 290 / 240 / 250 / 190 / 300 / 260 / 210 / 280
	STREET_Z = {-1180, -930, -720, -430, -190, 60, 250, 550, 810, 1020, 1300},
	STREET_W = {   36,   42,   30,   58,   32, 36,  30,  58,  34,   42,   36},

	SIDEWALK_W = 14,
	CURB_H = 0.9,

	PROMENADE_X = -250, PROM_W = 46,

	-- Diagonale
	DIAG_A = Vector3.new(140, 0, 1300),
	DIAG_B = Vector3.new(1070, 0, -930),
	DIAG_W = 58,
	DIAG_CLEAR = 62,

	-- Kreisverkehr auf AVENUE_X[4] / STREET_Z[6]
	RB_I = 4, RB_J = 6, RB_R = 78,

	FLOOR_H = 14,
	LIT_WINDOWS = 3,

	TRACK_X = 500, TRACK_Z = -1420, TRACK_RX = 500, TRACK_RZ = 120,
	TRACK_SEGS = 72, TRACK_W = 62,

	-- Bruecke: Diagonale liegt leicht ueber Kreuzungen
	DIAG_BRIDGE_H = 1.8,
	ROAD_DIAG_GAP = 36,
}

local rng = Random.new(C.SEED)
local Y = C.CITY_LEVEL
local pi = math.pi
local PAD_TOP = Y - 2

--------------------------------------------------------------------------------
local old = workspace:FindFirstChild("CITY")
if old then old:Destroy() end
local root = Instance.new("Folder")
root.Name = "CITY"
root.Parent = workspace

-- Layout fuer Script 03 und 04 hinterlegen, damit nichts auseinanderlaeuft
root:SetAttribute("AvenueX",   table.concat(C.AVENUE_X, ","))
root:SetAttribute("AvenueW",   table.concat(C.AVENUE_W, ","))
root:SetAttribute("StreetZ",   table.concat(C.STREET_Z, ","))
root:SetAttribute("StreetW",   table.concat(C.STREET_W, ","))
root:SetAttribute("CityLevel", C.CITY_LEVEL)
root:SetAttribute("SidewalkW", C.SIDEWALK_W)
root:SetAttribute("PromenadeX", C.PROMENADE_X)
root:SetAttribute("PromW",     C.PROM_W)
root:SetAttribute("FlatZ0",    C.FLAT_Z0)
root:SetAttribute("FlatX0",    C.FLAT_X0)
root:SetAttribute("FlatX1",    C.FLAT_X1)
root:SetAttribute("FlatZ1",    C.FLAT_Z1)
root:SetAttribute("DiagAX",    C.DIAG_A.X)
root:SetAttribute("DiagAZ",    C.DIAG_A.Z)
root:SetAttribute("DiagBX",    C.DIAG_B.X)
root:SetAttribute("DiagBZ",    C.DIAG_B.Z)
root:SetAttribute("DiagW",     C.DIAG_W)

local function folder(name)
	local f = Instance.new("Folder") f.Name = name f.Parent = root return f
end

local F_ROADS   = folder("Roads")
local F_MARKS   = folder("RoadMarkings")
local F_WALKS   = folder("Sidewalks")
local F_BUILD   = folder("Buildings")
local F_WINDOWS = folder("LitWindows")
local F_NEON    = folder("NeonSigns")
local F_PARKS   = folder("Parks")
local F_TRACK   = folder("Racetrack")
local F_LAND    = folder("Landmarks")

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Concrete
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- Diagonale frueh berechnen (wird fuer Strassenluecken + Bruecke gebraucht)
local dA, dB = C.DIAG_A, C.DIAG_B
local dDir = (dB - dA).Unit
local dLen = (dB - dA).Magnitude

local function distToDiag(px, pz)
	local ap = Vector3.new(px - dA.X, 0, pz - dA.Z)
	local t = math.clamp(ap:Dot(dDir), 0, dLen)
	local closest = dA + dDir * t
	return (Vector3.new(px, 0, pz) - Vector3.new(closest.X, 0, closest.Z)).Magnitude
end

local function onRoundabout(px, pz, margin)
	local rbX = C.AVENUE_X[C.RB_I]
	local rbZ = C.STREET_Z[C.RB_J]
	return (Vector3.new(px, 0, pz) - Vector3.new(rbX, 0, rbZ)).Magnitude < C.RB_R + (margin or 0)
end

--------------------------------------------------------------------------------
-- 1) PLANIEREN (Stadt + Rennstrecke)
--------------------------------------------------------------------------------
do
	local cx = (C.FLAT_X0 + C.FLAT_X1) / 2
	local cz = (C.FLAT_Z0 + C.FLAT_Z1) / 2
	local sx = C.FLAT_X1 - C.FLAT_X0
	local sz = C.FLAT_Z1 - C.FLAT_Z0
	Terrain:FillBlock(CFrame.new(cx, PAD_TOP + 170, cz), Vector3.new(sx, 340, sz), Enum.Material.Air)
	Terrain:FillBlock(CFrame.new(cx, PAD_TOP - 40, cz), Vector3.new(sx, 80, sz), Enum.Material.Ground)
	-- Rennstrecke ebenfalls planieren
	Terrain:FillBlock(
		CFrame.new(C.TRACK_X, PAD_TOP + 170, C.TRACK_Z),
		Vector3.new(C.TRACK_RX * 2 + 80, 340, C.TRACK_RZ * 2 + 80),
		Enum.Material.Air)
	Terrain:FillBlock(
		CFrame.new(C.TRACK_X, PAD_TOP - 40, C.TRACK_Z),
		Vector3.new(C.TRACK_RX * 2 + 80, 80, C.TRACK_RZ * 2 + 80),
		Enum.Material.Ground)
end
print("[City] Planiert.")

--------------------------------------------------------------------------------
-- 2) STRASSEN
--------------------------------------------------------------------------------
local ASPHALT = rgb(46, 46, 50)
local WALKCOL = rgb(178, 174, 166)
local CURBCOL = rgb(206, 202, 194)
local LINE_W  = rgb(238, 236, 226)
local LINE_Y  = rgb(232, 190, 64)
local LAWN    = rgb(96, 132, 70)

local function sidewalkPairZ(x, len, cz, width)
	for _, s in ipairs({-1, 1}) do
		part({Name = "Curb", Size = Vector3.new(2.5, C.CURB_H + 5, len),
			Position = Vector3.new(x + s * (width / 2 + 1.25), Y - 2.5 + C.CURB_H / 2, cz),
			Color = CURBCOL}, F_WALKS)
		part({Name = "Walk", Size = Vector3.new(C.SIDEWALK_W, 5, len),
			Position = Vector3.new(x + s * (width / 2 + 2.5 + C.SIDEWALK_W / 2), Y - 1.6, cz),
			Color = WALKCOL, Material = Enum.Material.Pavement}, F_WALKS)
	end
end

local function sidewalkPairX(z, len, cx, width)
	for _, s in ipairs({-1, 1}) do
		part({Name = "Curb", Size = Vector3.new(len, C.CURB_H + 5, 2.5),
			Position = Vector3.new(cx, Y - 2.5 + C.CURB_H / 2, z + s * (width / 2 + 1.25)),
			Color = CURBCOL}, F_WALKS)
		part({Name = "Walk", Size = Vector3.new(len, 5, C.SIDEWALK_W),
			Position = Vector3.new(cx, Y - 1.6, z + s * (width / 2 + 2.5 + C.SIDEWALK_W / 2)),
			Color = WALKCOL, Material = Enum.Material.Pavement}, F_WALKS)
	end
end

local function roadZ(x, z0, z1, width, name, boulevard)
	local len = z1 - z0
	local cz = (z0 + z1) / 2
	part({Name = name, Size = Vector3.new(width, 5, len),
		Position = Vector3.new(x, Y - 2.5, cz), Color = ASPHALT,
		Material = Enum.Material.Asphalt}, F_ROADS)
	sidewalkPairZ(x, len, cz, width)

	if boulevard then
		part({Name = "Median", Size = Vector3.new(16, 5.6, len),
			Position = Vector3.new(x, Y - 2.2, cz), Color = LAWN,
			Material = Enum.Material.Grass}, F_ROADS)
		part({Name = "MedianCurb", Size = Vector3.new(18, 5.2, len),
			Position = Vector3.new(x, Y - 2.4, cz), Color = CURBCOL}, F_ROADS)
	end
end

local function roadX(z, x0, x1, width, name, boulevard)
	local len = x1 - x0
	local cx = (x0 + x1) / 2
	part({Name = name, Size = Vector3.new(len, 5, width),
		Position = Vector3.new(cx, Y - 2.5, z), Color = ASPHALT,
		Material = Enum.Material.Asphalt}, F_ROADS)
	sidewalkPairX(z, len, cx, width)

	if boulevard then
		part({Name = "Median", Size = Vector3.new(len, 5.6, 16),
			Position = Vector3.new(cx, Y - 2.2, z), Color = LAWN,
			Material = Enum.Material.Grass}, F_ROADS)
		part({Name = "MedianCurb", Size = Vector3.new(len, 5.2, 18),
			Position = Vector3.new(cx, Y - 2.4, z), Color = CURBCOL}, F_ROADS)
	end
end

-- Strassen in Segmente zerlegen, damit an der Diagonale Luecken entstehen
local function segmentsAlongZ(x, z0, z1, gap)
	local out, z = {}, z0
	while z < z1 do
		if distToDiag(x, z) >= gap and not onRoundabout(x, z, 24) then
			local s0 = z
			while z < z1 and distToDiag(x, z) >= gap and not onRoundabout(x, z, 24) do
				z = z + 6
			end
			if z - s0 > 24 then table.insert(out, {s0, math.min(z, z1)}) end
		else
			z = z + 6
		end
	end
	return out
end

local function segmentsAlongX(z, x0, x1, gap)
	local out, x = {}, x0
	while x < x1 do
		if distToDiag(x, z) >= gap and not onRoundabout(x, z, 24) then
			local s0 = x
			while x < x1 and distToDiag(x, z) >= gap and not onRoundabout(x, z, 24) do
				x = x + 6
			end
			if x - s0 > 24 then table.insert(out, {s0, math.min(x, x1)}) end
		else
			x = x + 6
		end
	end
	return out
end

local function roadZSegmented(x, z0, z1, width, name, boulevard)
	local gap = C.DIAG_W / 2 + width / 2 + C.ROAD_DIAG_GAP
	for _, seg in ipairs(segmentsAlongZ(x, z0, z1, gap)) do
		roadZ(x, seg[1], seg[2], width, name, boulevard)
	end
end

local function roadXSegmented(z, x0, x1, width, name, boulevard)
	local gap = C.DIAG_W / 2 + width / 2 + C.ROAD_DIAG_GAP
	for _, seg in ipairs(segmentsAlongX(z, x0, x1, gap)) do
		roadX(z, seg[1], seg[2], width, name, boulevard)
	end
end

local zA, zB = C.STREET_Z[1] - 60, C.STREET_Z[#C.STREET_Z] + 60
local xA, xB = C.AVENUE_X[1] - 60, C.AVENUE_X[#C.AVENUE_X] + 60

for i, ax in ipairs(C.AVENUE_X) do
	local w = C.AVENUE_W[i]
	roadZSegmented(ax, zA, zB, w, "Avenue" .. i, w >= 64)
end
for j, sz in ipairs(C.STREET_Z) do
	local w = C.STREET_W[j]
	roadXSegmented(sz, xA, xB, w, "Street" .. j, w >= 56)
end

-- Kuestenstrasse
roadZ(C.PROMENADE_X, C.FLAT_Z0 + 40, zB, C.PROM_W, "Promenade", false)
for j = 1, #C.STREET_Z, 2 do
	roadX(C.STREET_Z[j], C.PROMENADE_X - 30, C.AVENUE_X[1], C.STREET_W[j], "Link" .. j, false)
end
print("[City] Raster gebaut (Luecken an Diagonale, 2 Boulevards je Achse).")

--------------------------------------------------------------------------------
-- 3) DIAGONALER BOULEVARD (leicht erhoeht = Bruecke ueber Kreuzungen)
--------------------------------------------------------------------------------
local bridgeY = Y + C.DIAG_BRIDGE_H

do
	local segs = 40
	for k = 0, segs - 1 do
		local p0 = dA + dDir * (dLen * k / segs)
		local p1 = dA + dDir * (dLen * (k + 1) / segs)
		local mid = (p0 + p1) / 2
		local l = (p1 - p0).Magnitude + 1
		local cf = CFrame.lookAt(Vector3.new(mid.X, bridgeY, mid.Z), Vector3.new(p1.X, bridgeY, p1.Z))

		part({Name = "Diagonal", Size = Vector3.new(C.DIAG_W, 5, l),
			CFrame = cf * CFrame.new(0, -2.5, 0), Color = ASPHALT,
			Material = Enum.Material.Asphalt}, F_ROADS)
		for _, s in ipairs({-1, 1}) do
			part({Name = "DiagWalk", Size = Vector3.new(C.SIDEWALK_W, 5, l),
				CFrame = cf * CFrame.new(s * (C.DIAG_W / 2 + C.SIDEWALK_W / 2 + 1), -1.6, 0),
				Color = WALKCOL, Material = Enum.Material.Pavement}, F_WALKS)
		end
		if k % 2 == 0 then
			part({Name = "Mark", Size = Vector3.new(1.2, 0.2, l * 0.55),
				CFrame = cf * CFrame.new(0, 0.1, 0), Color = LINE_Y,
				Material = Enum.Material.SmoothPlastic, CanCollide = false}, F_MARKS)
		end
		-- Brueckenpfeiler an jedem 5. Segment
		if k % 5 == 0 then
			for _, side in ipairs({-1, 1}) do
				part({Name = "BridgePier", Size = Vector3.new(4, bridgeY - Y + 6, 4),
					CFrame = cf * CFrame.new(side * (C.DIAG_W / 2 + 2), -(bridgeY - Y) / 2 - 1, 0),
					Color = rgb(72, 74, 78), Material = Enum.Material.Concrete}, F_ROADS)
			end
		end
	end
end
print("[City] Diagonaler Boulevard als Bruecke gebaut.")

--------------------------------------------------------------------------------
-- 4) KREISVERKEHR
--------------------------------------------------------------------------------
local rbX = C.AVENUE_X[C.RB_I]
local rbZ = C.STREET_Z[C.RB_J]

do
	local R = C.RB_R
	-- Ringfahrbahn
	local n = 48
	for k = 0, n - 1 do
		local a0 = (k / n) * pi * 2
		local a1 = ((k + 1) / n) * pi * 2
		local p0 = Vector3.new(rbX + math.cos(a0) * R, Y, rbZ + math.sin(a0) * R)
		local p1 = Vector3.new(rbX + math.cos(a1) * R, Y, rbZ + math.sin(a1) * R)
		local mid = (p0 + p1) / 2
		local l = (p1 - p0).Magnitude + 1.5
		local cf = CFrame.lookAt(mid, p1)
		part({Name = "RingRoad", Size = Vector3.new(44, 5, l),
			CFrame = cf * CFrame.new(0, -2.5, 0), Color = ASPHALT,
			Material = Enum.Material.Asphalt}, F_ROADS)
	end
	-- Insel
	part({Name = "RBIsland", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, (R - 22) * 2, (R - 22) * 2),
		CFrame = CFrame.new(rbX, Y - 1.4, rbZ) * CFrame.Angles(0, 0, pi / 2),
		Color = LAWN, Material = Enum.Material.Grass}, F_ROADS)
	part({Name = "RBCurb", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(5.6, (R - 20) * 2, (R - 20) * 2),
		CFrame = CFrame.new(rbX, Y - 1.8, rbZ) * CFrame.Angles(0, 0, pi / 2),
		Color = CURBCOL}, F_ROADS)
	-- Denkmal in der Mitte
	part({Name = "Monument", Size = Vector3.new(22, 4, 22),
		Position = Vector3.new(rbX, Y + 3.5, rbZ), Color = rgb(206, 200, 188)}, F_ROADS)
	part({Name = "Obelisk", Size = Vector3.new(9, 56, 9),
		Position = Vector3.new(rbX, Y + 33, rbZ), Color = rgb(222, 216, 202)}, F_ROADS)
	part({Name = "ObeliskTip", Size = Vector3.new(5, 8, 5),
		Position = Vector3.new(rbX, Y + 65, rbZ), Color = rgb(0, 220, 170),
		Material = Enum.Material.Neon}, F_NEON)
end
print("[City] Kreisverkehr gebaut.")

--------------------------------------------------------------------------------
-- 5) FAHRBAHNMARKIERUNGEN
--------------------------------------------------------------------------------
local function blocked(px, pz)
	if distToDiag(px, pz) < C.DIAG_W / 2 + 22 then return true end
	if onRoundabout(px, pz, 30) then return true end
	for j, sz in ipairs(C.STREET_Z) do
		if math.abs(pz - sz) < C.STREET_W[j] / 2 + C.SIDEWALK_W + 14 then return true end
	end
	return false
end

local function blockedX(px, pz)
	if distToDiag(px, pz) < C.DIAG_W / 2 + 22 then return true end
	if onRoundabout(px, pz, 30) then return true end
	for i, ax in ipairs(C.AVENUE_X) do
		if math.abs(px - ax) < C.AVENUE_W[i] / 2 + C.SIDEWALK_W + 14 then return true end
	end
	return false
end

for i, ax in ipairs(C.AVENUE_X) do
	local isB = C.AVENUE_W[i] >= 64
	local z = zA + 12
	while z < zB - 12 do
		if not blocked(ax, z) then
			if isB then
				for _, o in ipairs({-14, 14}) do
					part({Name = "Mark", Size = Vector3.new(0.9, 0.2, 22),
						Position = Vector3.new(ax + o, Y + 0.06, z + 11), Color = LINE_W,
						Material = Enum.Material.SmoothPlastic, CanCollide = false}, F_MARKS)
				end
			else
				for _, o in ipairs({-1.4, 1.4}) do
					part({Name = "Mark", Size = Vector3.new(0.8, 0.2, 22),
						Position = Vector3.new(ax + o, Y + 0.06, z + 11), Color = LINE_Y,
						Material = Enum.Material.SmoothPlastic, CanCollide = false}, F_MARKS)
				end
			end
		end
		z = z + 26
	end
end

for j, sz in ipairs(C.STREET_Z) do
	local isB = C.STREET_W[j] >= 56
	local x = xA + 12
	while x < xB - 12 do
		if not blockedX(x, sz) then
			local col = isB and LINE_W or LINE_Y
			local off = isB and {-14, 14} or {-1.4, 1.4}
			for _, o in ipairs(off) do
				part({Name = "Mark", Size = Vector3.new(22, 0.2, 0.8),
					Position = Vector3.new(x + 11, Y + 0.06, sz + o), Color = col,
					Material = Enum.Material.SmoothPlastic, CanCollide = false}, F_MARKS)
			end
		end
		x = x + 26
	end
end

-- Zebrastreifen nur an den breiten Achsen
for i, ax in ipairs(C.AVENUE_X) do
	for j, sz in ipairs(C.STREET_Z) do
		if C.AVENUE_W[i] >= 42 and C.STREET_W[j] >= 36 then
			local d = (Vector3.new(ax, 0, sz) - Vector3.new(rbX, 0, rbZ)).Magnitude
			if d > C.RB_R + 40 and distToDiag(ax, sz) > 90 then
				local aw, sw = C.AVENUE_W[i], C.STREET_W[j]
				for _, s in ipairs({-1, 1}) do
					local zc = sz + s * (sw / 2 + 11)
					local cnt = math.floor(aw / 7)
					for k = -cnt, cnt do
						part({Name = "Zebra", Size = Vector3.new(4.4, 0.16, 13),
							Position = Vector3.new(ax + k * 6.6, Y + 0.07, zc), Color = LINE_W,
							Material = Enum.Material.SmoothPlastic, CanCollide = false}, F_MARKS)
					end
					part({Name = "StopLine", Size = Vector3.new(aw - 4, 0.16, 1.6),
						Position = Vector3.new(ax, Y + 0.07, zc + s * 9), Color = LINE_W,
						Material = Enum.Material.SmoothPlastic, CanCollide = false}, F_MARKS)
				end
			end
		end
	end
	task.wait()
end
print("[City] Markierungen fertig.")

--------------------------------------------------------------------------------
-- 6) STADTTEILE
--------------------------------------------------------------------------------
local DIST_BEACH, DIST_DOWN, DIST_RES, DIST_PORT = 1, 2, 3, 4

local function districtAt(x, z)
	if z < -740 then return DIST_PORT end
	if x < 260 then return DIST_BEACH end
	if x < 830 and z > -520 and z < 760 then return DIST_DOWN end
	return DIST_RES
end

local PALETTE = {
	[DIST_BEACH] = {rgb(246, 216, 216), rgb(214, 242, 234), rgb(250, 240, 208),
		rgb(228, 218, 246), rgb(252, 228, 204), rgb(212, 234, 248)},
	[DIST_DOWN] = {rgb(48, 66, 82), rgb(38, 52, 66), rgb(62, 86, 98),
		rgb(70, 92, 106), rgb(44, 62, 78), rgb(86, 104, 116)},
	[DIST_RES] = {rgb(198, 186, 168), rgb(176, 158, 138), rgb(212, 200, 184),
		rgb(158, 148, 138), rgb(190, 172, 150), rgb(166, 172, 168)},
	[DIST_PORT] = {rgb(138, 142, 146), rgb(112, 122, 130), rgb(154, 148, 138),
		rgb(96, 104, 110), rgb(170, 164, 152)},
}

local NEON_COLS = {rgb(255, 90, 170), rgb(70, 230, 235), rgb(150, 110, 255),
	rgb(255, 190, 60), rgb(60, 230, 150)}

local function heightFor(dist, x, z)
	if dist == DIST_BEACH then
		return rng:NextNumber(30, 82)
	elseif dist == DIST_PORT then
		return rng:NextNumber(22, 52)
	elseif dist == DIST_RES then
		return rng:NextNumber(42, 135)
	else
		local d = math.sqrt((x - 520) ^ 2 + (z - 140) ^ 2)
		local t = math.clamp(1 - d / 620, 0, 1) ^ 1.6
		return (90 + t * 350) * rng:NextNumber(0.55, 1.2)
	end
end

--------------------------------------------------------------------------------
-- 7) GEBAEUDE
--------------------------------------------------------------------------------
local function floorBands(cx, cz, sx, sz, h, col, baseY, par)
	local sc = col:Lerp(rgb(255, 255, 255), 0.32)
	local n = math.floor(h / C.FLOOR_H)
	for f = 1, n do
		local fy = baseY + f * C.FLOOR_H
		if fy < baseY + h - 3 then
			part({Name = "Slab", Size = Vector3.new(sx + 0.7, 1.1, sz + 0.7),
				Position = Vector3.new(cx, fy, cz), Color = sc}, par)
		end
	end
end

local function litWindows(cx, cz, sx, sz, h)
	for _ = 1, C.LIT_WINDOWS do
		local lv = rng:NextInteger(1, math.max(1, math.floor(h / C.FLOOR_H)))
		local fy = Y + lv * C.FLOOR_H - C.FLOOR_H / 2
		if fy > Y + 5 and fy < Y + h - 4 then
			local f = rng:NextInteger(1, 4)
			local px, pz, wx, wz = cx, cz, 7, 0.5
			if f == 1 then pz = cz + sz / 2 + 0.2
			elseif f == 2 then pz = cz - sz / 2 - 0.2
			elseif f == 3 then px = cx + sx / 2 + 0.2; wx = 0.5; wz = 7
			else px = cx - sx / 2 - 0.2; wx = 0.5; wz = 7 end
			part({Name = "LitWindow", Size = Vector3.new(wx, 5, wz),
				Position = Vector3.new(px, fy, pz), Color = rgb(30, 34, 42),
				Material = Enum.Material.Glass, CanCollide = false}, F_WINDOWS)
		end
	end
end

local function rooftop(cx, cz, sx, sz, topY, col, dist, par)
	part({Name = "Parapet", Size = Vector3.new(sx + 2, 2.4, sz + 2),
		Position = Vector3.new(cx, topY + 1.2, cz),
		Color = col:Lerp(rgb(0, 0, 0), 0.3)}, par)

	for _ = 1, rng:NextInteger(1, 3) do
		part({Name = "AC", Size = Vector3.new(rng:NextNumber(6, 13), 4, rng:NextNumber(6, 13)),
			Position = Vector3.new(cx + rng:NextNumber(-sx / 3, sx / 3), topY + 2,
				cz + rng:NextNumber(-sz / 3, sz / 3)),
			Color = rgb(150, 152, 155), Material = Enum.Material.Metal}, par)
	end

	if dist ~= DIST_DOWN and rng:NextNumber() < 0.4 then
		part({Name = "Tank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(11, 9, 9),
			CFrame = CFrame.new(cx + sx / 4, topY + 7, cz - sz / 4) * CFrame.Angles(0, 0, pi / 2),
			Color = rgb(120, 96, 74), Material = Enum.Material.Wood}, par)
	end
	if topY - Y > 300 then
		part({Name = "Helipad", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1, math.min(sx, sz) * 0.7, math.min(sx, sz) * 0.7),
			CFrame = CFrame.new(cx, topY + 2.6, cz) * CFrame.Angles(0, 0, pi / 2),
			Color = rgb(58, 62, 66)}, par)
	end
	if topY - Y > 200 and rng:NextNumber() < 0.55 then
		local ah = rng:NextNumber(30, 78)
		part({Name = "Antenna", Shape = Enum.PartType.Cylinder, Size = Vector3.new(ah, 2, 2),
			CFrame = CFrame.new(cx, topY + 2.4 + ah / 2, cz) * CFrame.Angles(0, 0, pi / 2),
			Color = rgb(80, 80, 84), Material = Enum.Material.Metal}, par)
		part({Name = "WarnLight", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3),
			Position = Vector3.new(cx, topY + 2.4 + ah, cz), Color = rgb(255, 40, 40),
			Material = Enum.Material.Neon, CanCollide = false}, F_NEON)
	end
end

local function building(cx, cz, sx, sz)
	if distToDiag(cx, cz) < C.DIAG_CLEAR + math.max(sx, sz) / 2 then return false end
	if onRoundabout(cx, cz, C.RB_R + 46) then return false end

	local dist = districtAt(cx, cz)
	local pal = PALETTE[dist]
	local col = pal[rng:NextInteger(1, #pal)]
	local h = heightFor(dist, cx, cz)
	local neon = NEON_COLS[rng:NextInteger(1, #NEON_COLS)]

	local mat, refl = Enum.Material.Concrete, 0
	if dist == DIST_DOWN and h > 150 then mat = Enum.Material.Glass; refl = 0.2 end
	if dist == DIST_PORT then mat = Enum.Material.Metal end

	-- Jedes Gebaeude ist ein eigenes Model. Script 07 kann es dadurch
	-- als Ganzes gegen ein echtes Modell aus dem Creator Store tauschen.
	local bm = Instance.new("Model")
	bm.Name = "Bldg"
	bm:SetAttribute("FootX", sx)
	bm:SetAttribute("FootZ", sz)
	bm:SetAttribute("Height", h)
	bm:SetAttribute("District", dist)
	bm:SetAttribute("CX", cx)
	bm:SetAttribute("CZ", cz)
	bm.Parent = F_BUILD

	part({Name = "Building", Size = Vector3.new(sx, h, sz),
		Position = Vector3.new(cx, Y + h / 2, cz), Color = col,
		Material = mat, Reflectance = refl}, bm)

	floorBands(cx, cz, sx, sz, h, col, Y, bm)
	litWindows(cx, cz, sx, sz, h)

	-- Ladenzeile nur wo Menschen laufen, nicht im Hafen
	if dist ~= DIST_PORT then
		part({Name = "Retail", Size = Vector3.new(sx + 1.2, 15, sz + 1.2),
			Position = Vector3.new(cx, Y + 7.5, cz), Color = rgb(38, 40, 44),
			Material = Enum.Material.Glass, Reflectance = 0.12}, bm)
		part({Name = "Canopy", Size = Vector3.new(sx + 7, 1.2, sz + 7),
			Position = Vector3.new(cx, Y + 15.6, cz), Color = rgb(52, 54, 58),
			Material = Enum.Material.Metal}, bm)
		part({Name = "NeonSign", Size = Vector3.new(sx * 0.5, 2.2, sz + 7.6),
			Position = Vector3.new(cx, Y + 13.2, cz), Color = neon,
			Material = Enum.Material.Neon, CanCollide = false}, F_NEON)
	end

	if dist == DIST_BEACH then
		local h2 = rng:NextNumber(8, 20)
		part({Name = "DecoStep", Size = Vector3.new(sx * 0.58, h2, sz * 0.58),
			Position = Vector3.new(cx, Y + h + h2 / 2, cz), Color = col}, bm)
		for k = 1, 2 do
			part({Name = "DecoNeon", Size = Vector3.new(sx + 1.4, 0.9, sz + 1.4),
				Position = Vector3.new(cx, Y + h - k * 9, cz), Color = neon,
				Material = Enum.Material.Neon, CanCollide = false}, F_NEON)
		end
		rooftop(cx, cz, sx * 0.58, sz * 0.58, Y + h + h2, col, dist, bm)
	elseif dist == DIST_DOWN and h > 190 then
		local h2 = h * rng:NextNumber(0.14, 0.36)
		part({Name = "Setback", Size = Vector3.new(sx * 0.62, h2, sz * 0.62),
			Position = Vector3.new(cx, Y + h + h2 / 2, cz), Color = col,
			Material = mat, Reflectance = refl}, bm)
		floorBands(cx, cz, sx * 0.62, sz * 0.62, h2, col, Y + h, bm)
		rooftop(cx, cz, sx * 0.62, sz * 0.62, Y + h + h2, col, dist, bm)
	else
		rooftop(cx, cz, sx, sz, Y + h, col, dist, bm)
	end
	return true
end

--------------------------------------------------------------------------------
-- 8) PARK
--------------------------------------------------------------------------------
local function park(cx, cz, sx, sz)
	part({Name = "ParkLawn", Size = Vector3.new(sx, 5, sz),
		Position = Vector3.new(cx, Y - 2.4, cz), Color = LAWN,
		Material = Enum.Material.Grass}, F_PARKS)
	-- geschwungener Weg
	local steps = 14
	for k = 0, steps do
		local t = k / steps
		local px = cx - sx / 2 + t * sx
		local pz = cz + math.sin(t * pi * 2) * (sz * 0.22)
		part({Name = "Path", Size = Vector3.new(sx / steps + 6, 0.4, 12),
			Position = Vector3.new(px, Y + 0.35, pz), Color = rgb(206, 196, 176),
			Material = Enum.Material.Sand, CanCollide = false}, F_PARKS)
	end
	-- Teich
	part({Name = "Pond", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, sz * 0.42, sz * 0.42),
		CFrame = CFrame.new(cx + sx * 0.22, Y + 0.3, cz - sz * 0.18) * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(52, 122, 148), Material = Enum.Material.Glass,
		Transparency = 0.35, Reflectance = 0.25, CanCollide = false}, F_PARKS)
end

--------------------------------------------------------------------------------
-- 9) BLOECKE BEBAUEN - sechs Muster, gewuerfelt
--------------------------------------------------------------------------------
local RESERVED = {["2,4"] = "police", ["5,8"] = "hospital", ["1,10"] = "fire",
	["6,3"] = "roadside", ["3,7"] = "dealer", ["3,6"] = "plaza"}

local count, parks = 0, 0

for i = 1, #C.AVENUE_X - 1 do
	local ix0 = C.AVENUE_X[i] + C.AVENUE_W[i] / 2 + C.SIDEWALK_W + 12
	local ix1 = C.AVENUE_X[i + 1] - C.AVENUE_W[i + 1] / 2 - C.SIDEWALK_W - 12
	for j = 1, #C.STREET_Z - 1 do
		local key = i .. "," .. j
		if not RESERVED[key] then
			local iz0 = C.STREET_Z[j] + C.STREET_W[j] / 2 + C.SIDEWALK_W + 12
			local iz1 = C.STREET_Z[j + 1] - C.STREET_W[j + 1] / 2 - C.SIDEWALK_W - 12
			local bw, bd = ix1 - ix0, iz1 - iz0
			local bcx, bcz = (ix0 + ix1) / 2, (iz0 + iz1) / 2

			if bw > 50 and bd > 50 then
				local roll = rng:NextNumber()
				local dist = districtAt(bcx, bcz)

				if roll < 0.1 then
					-- PARK
					park(bcx, bcz, bw, bd)
					parks = parks + 1

				elseif roll < 0.26 and dist == DIST_DOWN then
					-- EIN TURM auf dem ganzen Block
					if building(bcx, bcz, bw * 0.82, bd * 0.82) then count = count + 1 end

				elseif roll < 0.45 then
					-- KARREE 2x2 mit Versatz
					local lw, ld = bw / 2, bd / 2
					for a = 0, 1 do for b = 0, 1 do
						if rng:NextNumber() < 0.9 then
							local jx = rng:NextNumber(-lw * 0.08, lw * 0.08)
							local jz = rng:NextNumber(-ld * 0.08, ld * 0.08)
							if building(ix0 + lw * (a + 0.5) + jx, iz0 + ld * (b + 0.5) + jz,
								lw * rng:NextNumber(0.68, 0.9), ld * rng:NextNumber(0.68, 0.9)) then
								count = count + 1
							end
						end
					end end

				elseif roll < 0.62 then
					-- REIHE 3x2, kleinteilig
					local lw, ld = bw / 3, bd / 2
					for a = 0, 2 do for b = 0, 1 do
						if rng:NextNumber() < 0.88 then
							if building(ix0 + lw * (a + 0.5), iz0 + ld * (b + 0.5),
								lw * rng:NextNumber(0.72, 0.94), ld * rng:NextNumber(0.66, 0.88)) then
								count = count + 1
							end
						end
					end end

				elseif roll < 0.8 then
					-- INNENHOF: vier Riegel um eine Mitte
					local t = 0.26
					local combos = {
						{bcx, iz0 + bd * t / 2, bw * 0.9, bd * t},
						{bcx, iz1 - bd * t / 2, bw * 0.9, bd * t},
						{ix0 + bw * t / 2, bcz, bw * t, bd * 0.55},
						{ix1 - bw * t / 2, bcz, bw * t, bd * 0.55},
					}
					for _, cbo in ipairs(combos) do
						if building(cbo[1], cbo[2], cbo[3], cbo[4]) then count = count + 1 end
					end

				else
					-- GEMISCHT: ein grosses plus zwei kleine
					if building(ix0 + bw * 0.3, bcz, bw * 0.5, bd * 0.8) then count = count + 1 end
					if building(ix1 - bw * 0.18, iz0 + bd * 0.26, bw * 0.3, bd * 0.42) then count = count + 1 end
					if building(ix1 - bw * 0.18, iz1 - bd * 0.26, bw * 0.3, bd * 0.42) then count = count + 1 end
				end
			end
		end
		task.wait()
	end
end
print("[City] " .. count .. " Gebaeude, " .. parks .. " Parks.")

--------------------------------------------------------------------------------
-- 10) LANDMARKS
--------------------------------------------------------------------------------
local function blockBox(i, j)
	local ix0 = C.AVENUE_X[i] + C.AVENUE_W[i] / 2 + C.SIDEWALK_W + 12
	local ix1 = C.AVENUE_X[i + 1] - C.AVENUE_W[i + 1] / 2 - C.SIDEWALK_W - 12
	local iz0 = C.STREET_Z[j] + C.STREET_W[j] / 2 + C.SIDEWALK_W + 12
	local iz1 = C.STREET_Z[j + 1] - C.STREET_W[j + 1] / 2 - C.SIDEWALK_W - 12
	return (ix0 + ix1) / 2, (iz0 + iz1) / 2, ix1 - ix0, iz1 - iz0
end

local function landmark(i, j, name, col, height, text, accent)
	local bx, bz, sx, sz = blockBox(i, j)
	local d = sz * 0.62
	local fw, fd = sx * 0.8, d

	local lm = Instance.new("Model")
	lm.Name = "Landmark"
	lm:SetAttribute("IsLandmark", true)
	lm:SetAttribute("LandmarkType", name)
	lm:SetAttribute("CX", bx)
	lm:SetAttribute("CZ", bz)
	lm:SetAttribute("FootX", fw)
	lm:SetAttribute("FootZ", fd)
	lm:SetAttribute("Height", height)
	lm:SetAttribute("SignText", text)
	lm.Parent = F_LAND

	part({Name = name .. "_Lot", Size = Vector3.new(sx, 5, sz),
		Position = Vector3.new(bx, Y - 2.5, bz), Color = rgb(64, 64, 68),
		Material = Enum.Material.Asphalt}, lm)
	part({Name = name, Size = Vector3.new(fw, height, fd),
		Position = Vector3.new(bx, Y + height / 2, bz), Color = col}, lm)
	local n = math.floor(height / C.FLOOR_H)
	for f = 1, n do
		local fy = Y + f * C.FLOOR_H
		if fy < Y + height - 3 then
			part({Name = "Slab", Size = Vector3.new(fw + 0.7, 1.1, fd + 0.7),
				Position = Vector3.new(bx, fy, bz),
				Color = col:Lerp(rgb(255, 255, 255), 0.3)}, lm)
		end
	end
	part({Name = "Stripe", Size = Vector3.new(fw + 1, 4.5, fd + 1),
		Position = Vector3.new(bx, Y + height - 7, bz), Color = accent,
		Material = Enum.Material.Neon}, F_NEON)

	local s = part({Name = "SignBoard", Size = Vector3.new(56, 10, 1.2),
		Position = Vector3.new(bx, Y + height + 8, bz + fd / 2 + 2),
		Color = accent, Material = Enum.Material.Neon}, lm)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(1120, 200)
	gui.LightInfluence = 0
	gui.Parent = s
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextColor3 = rgb(255, 255, 255)
	lbl.Parent = gui

	local m = Instance.new("Part")
	m.Name = name .. "_SpawnPoint"
	m.Size = Vector3.new(20, 1, 34)
	m.Position = Vector3.new(bx, Y + 0.5, bz - sz * 0.4)
	m.Anchored = true m.CanCollide = false m.Transparency = 1
	m.Parent = lm
end

landmark(2, 4,  "Polizeirevier", rgb(34, 48, 88),   48, "POLICE DEPARTMENT", rgb(60, 130, 255))
landmark(5, 8,  "Klinikum",      rgb(240, 240, 240), 70, "HOSPITAL",         rgb(230, 40, 40))
landmark(1, 10, "Feuerwache",    rgb(136, 38, 32),  40, "FIRE DEPARTMENT",  rgb(255, 180, 30))
landmark(6, 3,  "Pannendienst",  rgb(236, 206, 56), 36, "ROADSIDE 24/7",    rgb(20, 20, 20))
landmark(3, 7,  "Autohaus",      rgb(26, 28, 32),   42, "PREMIUM MOTORS",   rgb(0, 220, 170))

do
	local px, pz, psx, psz = blockBox(3, 6)
	part({Name = "Plaza", Size = Vector3.new(psx, 5, psz),
		Position = Vector3.new(px, Y - 2.4, pz), Color = rgb(204, 198, 186),
		Material = Enum.Material.Pavement}, F_LAND)
	part({Name = "PlazaRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 50, 50),
		CFrame = CFrame.new(px, Y + 0.8, pz) * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(0, 220, 170), Material = Enum.Material.Neon, CanCollide = false}, F_NEON)
	local sp = Instance.new("SpawnLocation")
	sp.Name = "MainSpawn"
	sp.Size = Vector3.new(36, 1, 36)
	sp.Position = Vector3.new(px, Y + 1, pz)
	sp.Anchored = true sp.Transparency = 1 sp.CanCollide = false
	sp.Parent = F_LAND
end
print("[City] Landmarks fertig.")

--------------------------------------------------------------------------------
-- 10b) PERIPHERIE - leere Randzonen mit Inhalt fuellen
--------------------------------------------------------------------------------
local F_OUT = folder("Outskirts")
local outskirts = 0

-- Oestlicher Vorort: Lagerhallen
for k = 1, 6 do
	local cx = C.FLAT_X1 - 80 - k * 45
	local cz = C.STREET_Z[4] + rng:NextNumber(-120, 120)
	local sx, sz = rng:NextNumber(70, 110), rng:NextNumber(50, 80)
	part({Name = "Warehouse", Size = Vector3.new(sx, rng:NextNumber(18, 28), sz),
		Position = Vector3.new(cx, Y + 12, cz), Color = rgb(118, 122, 128),
		Material = Enum.Material.Metal}, F_OUT)
	outskirts = outskirts + 1
end

-- Suedlicher Park am Hafenrand
do
	local cx = (C.AVENUE_X[3] + C.AVENUE_X[5]) / 2
	local cz = C.FLAT_Z0 + 90
	local psx, psz = 280, 160
	park(cx, cz, psx, psz)
	outskirts = outskirts + 1
end

-- Nordoestlicher Parkplatz + Baeume
for k = 1, 8 do
	local cx = C.AVENUE_X[1] + rng:NextNumber(40, 180)
	local cz = C.STREET_Z[#C.STREET_Z] - rng:NextNumber(40, 160)
	part({Name = "Parking", Size = Vector3.new(rng:NextNumber(40, 70), 0.4, rng:NextNumber(30, 50)),
		Position = Vector3.new(cx, Y + 0.35, cz), Color = rgb(58, 58, 62),
		Material = Enum.Material.Asphalt}, F_OUT)
	outskirts = outskirts + 1
end

print("[City] " .. outskirts .. " Peripherie-Objekte gesetzt.")

--------------------------------------------------------------------------------
-- 11) RENNSTRECKE (suedlich am Hafen)
--------------------------------------------------------------------------------
do
	local N = C.TRACK_SEGS
	local pts = {}
	for k = 0, N do
		local t = (k / N) * pi * 2
		local wob = 1 + math.sin(t * 3) * 0.1
		pts[k] = Vector3.new(C.TRACK_X + math.cos(t) * C.TRACK_RX * wob, Y,
			C.TRACK_Z + math.sin(t) * C.TRACK_RZ * wob)
	end
	for k = 0, N - 1 do
		local a, b = pts[k], pts[k + 1]
		local mid = (a + b) / 2
		local len = (b - a).Magnitude + 1.5
		local cf = CFrame.lookAt(mid, b)
		part({Name = "TrackSeg", Size = Vector3.new(C.TRACK_W, 5, len),
			CFrame = cf * CFrame.new(0, -2.5, 0), Color = rgb(38, 38, 42),
			Material = Enum.Material.Asphalt}, F_TRACK)
		local kerb = (k % 2 == 0) and rgb(205, 40, 40) or rgb(235, 235, 235)
		for _, s in ipairs({-1, 1}) do
			part({Name = "Kerb", Size = Vector3.new(6, 5.2, len),
				CFrame = cf * CFrame.new(s * (C.TRACK_W / 2 + 3), -2.4, 0),
				Color = kerb}, F_TRACK)
			part({Name = "Barrier", Size = Vector3.new(2, 7, len),
				CFrame = cf * CFrame.new(s * (C.TRACK_W / 2 + 12), 3, 0),
				Color = rgb(184, 184, 190), Material = Enum.Material.Metal}, F_TRACK)
			if k % 4 == 0 then
				part({Name = "TrackLED", Size = Vector3.new(0.5, 1, len),
					CFrame = cf * CFrame.new(s * (C.TRACK_W / 2 + 13.2), 5.5, 0),
					Color = rgb(70, 200, 255), Material = Enum.Material.Neon,
					CanCollide = false}, F_NEON)
			end
		end
	end
	part({Name = "StartFinish", Size = Vector3.new(C.TRACK_W, 0.3, 12),
		Position = Vector3.new(pts[0].X, Y + 0.2, pts[0].Z), Color = rgb(245, 245, 245),
		Material = Enum.Material.SmoothPlastic, CanCollide = false}, F_TRACK)
end

print("[City] ---- FERTIG ---- Teile: " .. #root:GetDescendants())
print("[City] Naechster Schritt: 03_Traffic_v3.lua, dann 04, 05, optional 07_AssetPlacer.lua")
