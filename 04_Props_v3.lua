--[[
================================================================================
  04_Props_v3.lua
  Begruenung, Strassenmoebel, Parks bepflanzen, Werbetafeln, Strand.
  Alle Abstaende sind bewusst unregelmaessig - gleichmaessige Reihen sind
  genau das, was eine Stadt kuenstlich wirken laesst.
--------------------------------------------------------------------------------
  Voraussetzung: 02_City_v3.lua und 03_Traffic_v3.lua sind gelaufen.
  Ausfuehren ueber die BEFEHLSLEISTE. Dauer ca. 40-70 Sekunden.
================================================================================
]]

local root = workspace:FindFirstChild("CITY")
if not root then error("[Props] Ordner CITY fehlt. Zuerst 02_City_v3.lua ausfuehren.") end

local function nums(attr)
	local t = {}
	for _, v in ipairs(string.split(root:GetAttribute(attr), ",")) do
		table.insert(t, tonumber(v))
	end
	return t
end

local AVENUE_X = nums("AvenueX")
local AVENUE_W = nums("AvenueW")
local STREET_Z = nums("StreetZ")
local STREET_W = nums("StreetW")
local Y = root:GetAttribute("CityLevel")
local SIDEWALK_W = root:GetAttribute("SidewalkW")
local PROMENADE_X = root:GetAttribute("PromenadeX")
local PROM_W = root:GetAttribute("PromW")
local FLAT_Z0 = root:GetAttribute("FlatZ0")
local FLAT_X0 = root:GetAttribute("FlatX0")

local pi = math.pi
local rng = Random.new(9001)

local function folder(name)
	local ex = root:FindFirstChild(name)
	if ex then ex:Destroy() end
	local f = Instance.new("Folder") f.Name = name f.Parent = root return f
end

local F_TREES  = folder("Trees")
local F_STREET = folder("StreetFurniture")
local F_BEACH  = folder("Beach")
local F_ADS    = folder("Billboards")

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {root}

local function groundAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 260, z), Vector3.new(0, -400, 0), rayParams)
	if hit then return hit.Position.Y end
	-- Fallback: Strand liegt auf CITY_LEVEL, Meer tiefer
	if x > FLAT_X0 + 40 then return Y end
	return math.max(4, Y - 4)
end

--------------------------------------------------------------------------------
-- PFLANZEN
--------------------------------------------------------------------------------
local function palm(x, y, z, scale)
	scale = scale or 1
	local m = Instance.new("Model") m.Name = "Palm" m.Parent = F_TREES
	local h = rng:NextNumber(22, 38) * scale
	local lean = CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), 0, math.rad(rng:NextNumber(-10, 10)))
	local trunk = part({Name = "Trunk", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(h, 2.6 * scale, 2.6 * scale),
		CFrame = CFrame.new(x, y + h / 2, z) * lean * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(112, 90, 64), Material = Enum.Material.Wood, CanCollide = true}, m)
	local top = trunk.Position + (lean * CFrame.new(0, h / 2, 0)).Position
	for k = 1, 7 do
		local ang = (k / 7) * pi * 2 + rng:NextNumber(-0.25, 0.25)
		part({Name = "Frond", Size = Vector3.new(3.4 * scale, 0.9, 19 * scale),
			CFrame = CFrame.new(top) * CFrame.Angles(0, ang, 0)
				* CFrame.new(0, 0, -9 * scale) * CFrame.Angles(math.rad(rng:NextNumber(12, 32)), 0, 0),
			Color = rgb(rng:NextInteger(46, 66), rng:NextInteger(100, 122), 54),
			Material = Enum.Material.Grass}, m)
	end
end

local function tree(x, y, z, scale)
	scale = scale or 1
	local m = Instance.new("Model") m.Name = "Tree" m.Parent = F_TREES
	local h = rng:NextNumber(16, 28) * scale
	part({Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 2.8, 2.8),
		CFrame = CFrame.new(x, y + h / 2, z) * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(96, 74, 54), Material = Enum.Material.Wood, CanCollide = true}, m)
	for _ = 1, 3 do
		local r = rng:NextNumber(11, 18) * scale
		part({Name = "Canopy", Shape = Enum.PartType.Ball, Size = Vector3.new(r, r * 0.82, r),
			Position = Vector3.new(x + rng:NextNumber(-4, 4), y + h + rng:NextNumber(-2, 5),
				z + rng:NextNumber(-4, 4)),
			Color = rgb(rng:NextInteger(44, 70), rng:NextInteger(94, 118), rng:NextInteger(46, 62)),
			Material = Enum.Material.LeafyGrass}, m)
	end
end

local function bush(x, y, z)
	local r = rng:NextNumber(6, 11)
	part({Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.new(r, r * 0.7, r),
		Position = Vector3.new(x, y + r * 0.3, z),
		Color = rgb(rng:NextInteger(56, 82), rng:NextInteger(104, 128), 58),
		Material = Enum.Material.LeafyGrass}, F_TREES)
end

--------------------------------------------------------------------------------
-- MOEBEL
--------------------------------------------------------------------------------
local function bench(x, z, rot)
	local m = Instance.new("Model") m.Name = "Bench" m.Parent = F_STREET
	local b = CFrame.new(x, Y + 0.9, z) * CFrame.Angles(0, rot, 0)
	part({Name = "Seat", Size = Vector3.new(14, 0.8, 4), CFrame = b * CFrame.new(0, 3, 0),
		Color = rgb(128, 96, 62), Material = Enum.Material.Wood, CanCollide = true}, m)
	part({Name = "Back", Size = Vector3.new(14, 4.5, 0.8), CFrame = b * CFrame.new(0, 5.2, -1.8),
		Color = rgb(128, 96, 62), Material = Enum.Material.Wood}, m)
	for _, s in ipairs({-5.5, 5.5}) do
		part({Name = "Leg", Size = Vector3.new(0.8, 3, 4), CFrame = b * CFrame.new(s, 1.5, 0),
			Color = rgb(52, 54, 58), Material = Enum.Material.Metal}, m)
	end
end

local function bin(x, z)
	local m = Instance.new("Model") m.Name = "Bin" m.Parent = F_STREET
	part({Name = "Body", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 4.4, 4.4),
		CFrame = CFrame.new(x, Y + 3.9, z) * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(44, 62, 52), Material = Enum.Material.Metal, CanCollide = true}, m)
	part({Name = "Lid", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 5, 5),
		CFrame = CFrame.new(x, Y + 7.2, z) * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(30, 44, 38), Material = Enum.Material.Metal}, m)
end

local function hydrant(x, z)
	local m = Instance.new("Model") m.Name = "Hydrant" m.Parent = F_STREET
	part({Name = "Body", Size = Vector3.new(2.4, 5, 2.4), Position = Vector3.new(x, Y + 3.4, z),
		Color = rgb(210, 46, 40), Material = Enum.Material.Metal, CanCollide = true}, m)
	part({Name = "Cap", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 2.2, 3),
		Position = Vector3.new(x, Y + 6.2, z), Color = rgb(210, 46, 40),
		Material = Enum.Material.Metal}, m)
end

local function busStop(x, z, rot)
	local m = Instance.new("Model") m.Name = "BusStop" m.Parent = F_STREET
	local b = CFrame.new(x, Y + 0.9, z) * CFrame.Angles(0, rot, 0)
	part({Name = "Roof", Size = Vector3.new(26, 0.9, 10), CFrame = b * CFrame.new(0, 12, 0),
		Color = rgb(48, 50, 54), Material = Enum.Material.Metal, CanCollide = true}, m)
	part({Name = "BackGlass", Size = Vector3.new(26, 11, 0.4), CFrame = b * CFrame.new(0, 6.5, -4.6),
		Color = rgb(180, 210, 220), Material = Enum.Material.Glass, Transparency = 0.55}, m)
	for _, s in ipairs({-12.5, 12.5}) do
		part({Name = "Post", Size = Vector3.new(0.9, 12, 0.9), CFrame = b * CFrame.new(s, 6, -4.6),
			Color = rgb(48, 50, 54), Material = Enum.Material.Metal, CanCollide = true}, m)
	end
	part({Name = "Bench", Size = Vector3.new(20, 0.8, 4), CFrame = b * CFrame.new(0, 3, -2.4),
		Color = rgb(120, 122, 126), Material = Enum.Material.Metal, CanCollide = true}, m)
	part({Name = "AdPanel", Size = Vector3.new(6, 10, 0.5), CFrame = b * CFrame.new(11, 6.5, 0),
		Color = rgb(70, 200, 255), Material = Enum.Material.Neon}, m)
end

--------------------------------------------------------------------------------
-- WERBETAFEL
--------------------------------------------------------------------------------
local AD_TEXTS = {"PREMIUM MOTORS", "SOUTH BEACH", "OCEAN DRIVE", "SUNSET RACING",
	"MIAMI NIGHTS", "PALM HOTEL", "HARBOR CLUB"}
local AD_COLS = {rgb(255, 70, 160), rgb(60, 220, 255), rgb(160, 90, 255),
	rgb(255, 170, 40), rgb(70, 255, 180)}

local function billboard(x, z, rot)
	local m = Instance.new("Model") m.Name = "Billboard" m.Parent = F_ADS
	local b = CFrame.new(x, Y, z) * CFrame.Angles(0, rot, 0)
	local col = AD_COLS[rng:NextInteger(1, #AD_COLS)]
	for _, s in ipairs({-14, 14}) do
		part({Name = "Leg", Shape = Enum.PartType.Cylinder, Size = Vector3.new(38, 2.4, 2.4),
			CFrame = b * CFrame.new(s, 19, 0) * CFrame.Angles(0, 0, pi / 2),
			Color = rgb(58, 60, 64), Material = Enum.Material.Metal, CanCollide = true}, m)
	end
	local board = part({Name = "Board", Size = Vector3.new(46, 20, 1.2),
		CFrame = b * CFrame.new(0, 48, 0), Color = rgb(22, 22, 26)}, m)
	for _, oy in ipairs({58.5, 37.5}) do
		part({Name = "Frame", Size = Vector3.new(48, 1.4, 2), CFrame = b * CFrame.new(0, oy, 0),
			Color = col, Material = Enum.Material.Neon}, m)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front gui.CanvasSize = Vector2.new(920, 400)
	gui.LightInfluence = 0 gui.Parent = board
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1) lbl.BackgroundTransparency = 1
	lbl.Text = AD_TEXTS[rng:NextInteger(1, #AD_TEXTS)]
	lbl.Font = Enum.Font.GothamBlack lbl.TextScaled = true
	lbl.TextColor3 = col lbl.Parent = gui
end

--------------------------------------------------------------------------------
-- BEGRUENUNG DER STRASSEN - unregelmaessig!
--------------------------------------------------------------------------------
local zA, zB = STREET_Z[1], STREET_Z[#STREET_Z]
local xA, xB = AVENUE_X[1], AVENUE_X[#AVENUE_X]

for i, ax in ipairs(AVENUE_X) do
	local off = AVENUE_W[i] / 2 + 2.5 + SIDEWALK_W / 2
	local isB = AVENUE_W[i] >= 64
	for _, s in ipairs({-1, 1}) do
		local z = zA + rng:NextNumber(0, 60)
		while z <= zB do
			-- Luecken lassen, sonst wirkt es wie eine Zaunreihe
			if rng:NextNumber() < 0.82 then
				local jitter = rng:NextNumber(-8, 8)
				if isB or i <= 2 then
					palm(ax + s * off + rng:NextNumber(-2, 2), Y + 0.9, z + jitter,
						rng:NextNumber(0.8, 1.1))
				else
					tree(ax + s * off + rng:NextNumber(-2, 2), Y + 0.9, z + jitter,
						rng:NextNumber(0.85, 1.15))
				end
			end
			z = z + rng:NextNumber(58, 105)
		end
	end
	-- Boulevard-Mittelstreifen bepflanzen
	if isB then
		local z = zA + 40
		while z <= zB do
			palm(ax + rng:NextNumber(-3, 3), Y + 1.2, z, rng:NextNumber(0.85, 1.15))
			z = z + rng:NextNumber(70, 120)
		end
	end
	task.wait()
end

for j, sz in ipairs(STREET_Z) do
	local off = STREET_W[j] / 2 + 2.5 + SIDEWALK_W / 2
	for _, s in ipairs({-1, 1}) do
		local x = xA + rng:NextNumber(0, 70)
		while x <= xB do
			if rng:NextNumber() < 0.7 then
				tree(x + rng:NextNumber(-8, 8), Y + 0.9, sz + s * off + rng:NextNumber(-2, 2),
					rng:NextNumber(0.8, 1.15))
			end
			x = x + rng:NextNumber(66, 120)
		end
	end
end
print("[Props] Strassenbegruenung (unregelmaessig) gesetzt.")

--------------------------------------------------------------------------------
-- PARKS BEPFLANZEN
--------------------------------------------------------------------------------
local parkFolder = root:FindFirstChild("Parks")
local plantedParks = 0
if parkFolder then
	for _, lawn in ipairs(parkFolder:GetChildren()) do
		if lawn:IsA("BasePart") and lawn.Name == "ParkLawn" then
			local cx, cz = lawn.Position.X, lawn.Position.Z
			local sx, sz = lawn.Size.X, lawn.Size.Z
			for _ = 1, math.floor(sx * sz / 2600) do
				local px = cx + rng:NextNumber(-sx / 2 + 14, sx / 2 - 14)
				local pz = cz + rng:NextNumber(-sz / 2 + 14, sz / 2 - 14)
				local r = rng:NextNumber()
				if r < 0.62 then tree(px, Y + 0.9, pz, rng:NextNumber(0.9, 1.4))
				elseif r < 0.82 then bush(px, Y + 0.9, pz)
				else palm(px, Y + 0.9, pz, rng:NextNumber(0.8, 1.1)) end
			end
			for _ = 1, 3 do
				bench(cx + rng:NextNumber(-sx / 2 + 20, sx / 2 - 20),
					cz + rng:NextNumber(-sz / 2 + 20, sz / 2 - 20), rng:NextNumber(0, pi * 2))
			end
			plantedParks = plantedParks + 1
		end
	end
end
print("[Props] " .. plantedParks .. " Parks bepflanzt.")

--------------------------------------------------------------------------------
-- MOEBEL AN DEN STRASSEN
--------------------------------------------------------------------------------
for i, ax in ipairs(AVENUE_X) do
	local off = AVENUE_W[i] / 2 + 2.5 + SIDEWALK_W / 2
	local z = zA + 50
	while z <= zB - 50 do
		local s = (rng:NextNumber() < 0.5) and -1 or 1
		local r = rng:NextNumber()
		if r < 0.34 then bench(ax + s * off, z, (s > 0) and pi / 2 or -pi / 2)
		elseif r < 0.6 then bin(ax + s * off, z) end
		z = z + rng:NextNumber(70, 150)
	end
end

for i, ax in ipairs(AVENUE_X) do
	for j, sz in ipairs(STREET_Z) do
		if rng:NextNumber() < 0.55 then
			hydrant(ax + AVENUE_W[i] / 2 + 2.5 + SIDEWALK_W / 2,
				sz + STREET_W[j] / 2 + 2.5 + SIDEWALK_W / 2)
		end
	end
end

for j, sz in ipairs(STREET_Z) do
	if j % 3 == 0 then
		busStop(AVENUE_X[2] + AVENUE_W[2] / 2 + SIDEWALK_W + 2, sz + 70, -pi / 2)
		busStop(AVENUE_X[5] - AVENUE_W[5] / 2 - SIDEWALK_W - 2, sz - 70, pi / 2)
	end
end

billboard(AVENUE_X[1] - 80, STREET_Z[4], 0)
billboard(AVENUE_X[#AVENUE_X] + 80, STREET_Z[7], pi)
billboard(PROMENADE_X - 70, STREET_Z[2], 0)
billboard(AVENUE_X[3], STREET_Z[#STREET_Z] + 100, pi / 2)
billboard(AVENUE_X[4] + 50, STREET_Z[1] - 100, -pi / 2)
billboard(AVENUE_X[6] - 60, STREET_Z[9], pi)
print("[Props] Moebel, Haltestellen und Werbung gesetzt.")

--------------------------------------------------------------------------------
-- STRAND
--------------------------------------------------------------------------------
local BOARD_X = PROMENADE_X - PROM_W / 2 - 36

do
	local cols = {rgb(168, 138, 100), rgb(156, 126, 92), rgb(178, 148, 110)}
	local z = FLAT_Z0 + 40
	while z <= zB + 60 do
		part({Name = "Plank", Size = Vector3.new(42, 5, 8),
			Position = Vector3.new(BOARD_X, Y - 2.4, z),
			Color = cols[rng:NextInteger(1, 3)], Material = Enum.Material.WoodPlanks,
			CanCollide = true}, F_BEACH)
		part({Name = "Rail", Size = Vector3.new(0.8, 4, 8.2),
			Position = Vector3.new(BOARD_X - 21, Y + 2.2, z),
			Color = rgb(228, 226, 220), Material = Enum.Material.Wood}, F_BEACH)
		z = z + 8.2
	end
end

local TOWER_PALS = {
	{rgb(255, 105, 160), rgb(70, 225, 235)}, {rgb(255, 190, 60), rgb(255, 90, 120)},
	{rgb(90, 220, 160), rgb(255, 240, 200)}, {rgb(120, 150, 255), rgb(255, 130, 90)},
}

local function lifeguardTower(x, y, z)
	local m = Instance.new("Model") m.Name = "LifeguardTower" m.Parent = F_BEACH
	local pal = TOWER_PALS[rng:NextInteger(1, #TOWER_PALS)]
	for _, o in ipairs({Vector3.new(-7, 0, -7), Vector3.new(7, 0, -7),
		Vector3.new(-7, 0, 7), Vector3.new(7, 0, 7)}) do
		part({Name = "Stilt", Size = Vector3.new(1.6, 12, 1.6),
			Position = Vector3.new(x, y + 6, z) + o, Color = rgb(140, 112, 80),
			Material = Enum.Material.Wood, CanCollide = true}, m)
	end
	part({Name = "Deck", Size = Vector3.new(18, 1.2, 18), Position = Vector3.new(x, y + 12.5, z),
		Color = rgb(168, 138, 100), Material = Enum.Material.WoodPlanks, CanCollide = true}, m)
	part({Name = "Cabin", Size = Vector3.new(15, 10, 15), Position = Vector3.new(x, y + 18, z),
		Color = pal[1], Material = Enum.Material.WoodPlanks, CanCollide = true}, m)
	part({Name = "Window", Size = Vector3.new(11, 5, 0.4), Position = Vector3.new(x, y + 19, z - 7.6),
		Color = rgb(180, 220, 230), Material = Enum.Material.Glass, Transparency = 0.4}, m)
	part({Name = "Roof", Size = Vector3.new(20, 1.4, 20), Position = Vector3.new(x, y + 23.5, z),
		Color = pal[2], Material = Enum.Material.Metal}, m)
	part({Name = "Trim", Size = Vector3.new(15.6, 1.2, 15.6), Position = Vector3.new(x, y + 13.6, z),
		Color = pal[2], Material = Enum.Material.Neon}, m)
	part({Name = "Ramp", Size = Vector3.new(6, 0.8, 20),
		CFrame = CFrame.new(x, y + 6.5, z + 17) * CFrame.Angles(math.rad(-32), 0, 0),
		Color = rgb(150, 122, 88), Material = Enum.Material.WoodPlanks, CanCollide = true}, m)
end

local UMB = {rgb(255, 110, 110), rgb(90, 200, 240), rgb(255, 200, 90),
	rgb(150, 230, 160), rgb(240, 150, 220)}

local function beachSet(x, y, z)
	local m = Instance.new("Model") m.Name = "BeachSet" m.Parent = F_BEACH
	local col = UMB[rng:NextInteger(1, #UMB)]
	part({Name = "Pole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 0.7, 0.7),
		CFrame = CFrame.new(x, y + 7, z) * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(220, 218, 212)}, m)
	part({Name = "Canopy", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 17, 17),
		CFrame = CFrame.new(x, y + 13.5, z) * CFrame.Angles(0, 0, pi / 2), Color = col}, m)
	for _, o in ipairs({-6, 6}) do
		part({Name = "Lounger", Size = Vector3.new(5, 0.7, 12),
			CFrame = CFrame.new(x + o, y + 1.8, z) * CFrame.Angles(math.rad(-8), 0, 0),
			Color = rgb(245, 243, 238), Material = Enum.Material.Fabric, CanCollide = true}, m)
	end
end

local towers, sets = 0, 0
local z = FLAT_Z0 + 200
while z <= zB do
	local gx = BOARD_X - rng:NextNumber(70, 110)
	local gy = groundAt(gx, z)
	lifeguardTower(gx, gy, z)
	towers = towers + 1
	z = z + rng:NextNumber(300, 420)
end

local tries = 0
while sets < 80 and tries < 900 do
	tries = tries + 1
	local gx = BOARD_X - rng:NextNumber(40, 230)
	local gz = rng:NextNumber(FLAT_Z0, zB)
	local gy = groundAt(gx, gz)
	beachSet(gx, gy, gz)
	sets = sets + 1
end

-- Seebruecke
do
	local zp = STREET_Z[5]
	local m = Instance.new("Model") m.Name = "Pier" m.Parent = F_BEACH
	local x = BOARD_X - 32
	while x > BOARD_X - 420 do
		part({Name = "Deck", Size = Vector3.new(10, 1.2, 34), Position = Vector3.new(x, Y + 4, zp),
			Color = rgb(162, 132, 96), Material = Enum.Material.WoodPlanks, CanCollide = true}, m)
		for _, s in ipairs({-15, 15}) do
			part({Name = "Piling", Shape = Enum.PartType.Cylinder, Size = Vector3.new(30, 2.4, 2.4),
				CFrame = CFrame.new(x, Y - 11, zp + s) * CFrame.Angles(0, 0, pi / 2),
				Color = rgb(96, 76, 56), Material = Enum.Material.Wood, CanCollide = true}, m)
			part({Name = "Rail", Size = Vector3.new(10, 3.5, 0.7),
				Position = Vector3.new(x, Y + 6.4, zp + s), Color = rgb(226, 224, 218),
				Material = Enum.Material.Wood}, m)
		end
		x = x - 10.2
	end
	part({Name = "Head", Size = Vector3.new(48, 1.2, 48),
		Position = Vector3.new(BOARD_X - 430, Y + 4, zp), Color = rgb(162, 132, 96),
		Material = Enum.Material.WoodPlanks, CanCollide = true}, m)
	part({Name = "HeadLED", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 46, 46),
		CFrame = CFrame.new(BOARD_X - 430, Y + 5, zp) * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(70, 210, 255), Material = Enum.Material.Neon}, m)
end

print("[Props] Strand: " .. towers .. " Tuerme, " .. sets .. " Liegengruppen, 1 Seebruecke.")
print("[Props] ---- FERTIG ---- Naechster Schritt: 05_Lighting_v2.lua, dann 06, optional 07_AssetPlacer.lua")
