--[[
================================================================================
  03_Traffic_v3.lua
  Ampeln nur an den Boulevard-Kreuzungen, LED-Laternen, Schilder.
  Liest das Layout aus den Attributen des CITY-Ordners - kein doppeltes
  Pflegen von Koordinaten mehr.
--------------------------------------------------------------------------------
  Voraussetzung: 02_City_v3.lua ist gelaufen.
  Ausfuehren ueber die BEFEHLSLEISTE. Dauer ca. 30-50 Sekunden.
================================================================================
]]

local root = workspace:FindFirstChild("CITY")
if not root then error("[Traffic] Ordner CITY fehlt. Zuerst 02_City_v3.lua ausfuehren.") end

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

local CFG = {
	-- Eine Ampel steht nur da, wo zwei breite Achsen aufeinandertreffen.
	MAJOR_AVENUE_W = 50,
	MAJOR_STREET_W = 42,

	LAMP_SPACING = 150,
	LAMP_LIGHT_EVERY = 4,
}

local pi = math.pi
local rng = Random.new(4242)

local function folder(name)
	local ex = root:FindFirstChild(name)
	if ex then ex:Destroy() end
	local f = Instance.new("Folder") f.Name = name f.Parent = root return f
end

local F_TL    = folder("TrafficLights")
local F_LAMPS = folder("StreetLamps")
local F_SIGNS = folder("Signs")

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Metal
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local POLE_COL, DARK = rgb(58, 60, 64), rgb(26, 27, 30)

--------------------------------------------------------------------------------
-- AMPELKOPF
--------------------------------------------------------------------------------
local function signalHead(parentModel, poleX, poleZ, dir, facing, armLen)
	local POLE_H = 30
	part({Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 6, 6),
		CFrame = CFrame.new(poleX, Y + 1.2, poleZ) * CFrame.Angles(0, 0, pi / 2),
		Color = DARK, CanCollide = true}, parentModel)
	part({Name = "Pole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(POLE_H, 2.6, 2.6),
		CFrame = CFrame.new(poleX, Y + POLE_H / 2, poleZ) * CFrame.Angles(0, 0, pi / 2),
		Color = POLE_COL, CanCollide = true}, parentModel)

	local armMid = Vector3.new(poleX, Y + POLE_H - 1.5, poleZ) + dir * (armLen / 2)
	part({Name = "Arm", Size = Vector3.new(1.8, 1.8, armLen),
		CFrame = CFrame.lookAt(armMid, armMid + dir), Color = POLE_COL}, parentModel)

	local headPos = Vector3.new(poleX, Y + POLE_H - 7, poleZ) + dir * (armLen - 2)
	part({Name = "Housing", Size = Vector3.new(5, 14, 4),
		CFrame = CFrame.lookAt(headPos, headPos + facing), Color = DARK,
		Material = Enum.Material.SmoothPlastic}, parentModel)
	part({Name = "Hanger", Size = Vector3.new(1.2, 6, 1.2),
		Position = headPos + Vector3.new(0, 10, 0), Color = POLE_COL}, parentModel)
	part({Name = "Visor", Size = Vector3.new(5.6, 1, 2.4),
		CFrame = CFrame.lookAt(headPos + Vector3.new(0, 7.2, 0),
			headPos + Vector3.new(0, 7.2, 0) + facing),
		Color = DARK, Material = Enum.Material.SmoothPlastic}, parentModel)

	for _, d in ipairs({{"Red", 4.4, rgb(255, 40, 40)}, {"Yellow", 0, rgb(255, 190, 30)},
		{"Green", -4.4, rgb(40, 240, 110)}}) do
		local lens = part({Name = d[1], Shape = Enum.PartType.Ball,
			Size = Vector3.new(3.2, 3.2, 3.2),
			Position = headPos + Vector3.new(0, d[2], 0) + facing * 2.1,
			Color = d[3], Material = Enum.Material.SmoothPlastic}, parentModel)
		lens:SetAttribute("OnColor", d[3])
		local pl = Instance.new("PointLight")
		pl.Name = "Glow" pl.Color = d[3] pl.Range = 18 pl.Brightness = 2.4
		pl.Enabled = false pl.Parent = lens
	end
end

local function intersection(ax, sz, aw, sw, id)
	local m = Instance.new("Model") m.Name = "TL_" .. id m.Parent = F_TL
	local ha, hs = aw / 2, sw / 2
	local off = SIDEWALK_W + 5
	local armA = ha + off + 4
	local armS = hs + off + 4

	local ns = Instance.new("Model") ns.Name = "NS" ns.Parent = m
	signalHead(ns, ax + ha + off, sz + hs + off, Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1), armA)
	signalHead(ns, ax - ha - off, sz - hs - off, Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), armA)

	local ew = Instance.new("Model") ew.Name = "EW" ew.Parent = m
	signalHead(ew, ax + ha + off, sz - hs - off, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), armS)
	signalHead(ew, ax - ha - off, sz + hs + off, Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0), armS)

	m:SetAttribute("PosX", ax)
	m:SetAttribute("PosZ", sz)
end

local majorA, majorS = {}, {}
for i, w in ipairs(AVENUE_W) do if w >= CFG.MAJOR_AVENUE_W then table.insert(majorA, i) end end
for j, w in ipairs(STREET_W) do if w >= CFG.MAJOR_STREET_W then table.insert(majorS, j) end end

local n = 0
for _, i in ipairs(majorA) do
	for _, j in ipairs(majorS) do
		n = n + 1
		intersection(AVENUE_X[i], STREET_Z[j], AVENUE_W[i], STREET_W[j], i .. "_" .. j)
	end
	task.wait()
end
print(("[Traffic] %d Ampelanlagen an den Boulevard-Kreuzungen (%d Achsen x %d Querachsen).")
	:format(n, #majorA, #majorS))

--------------------------------------------------------------------------------
-- LED-LATERNE
--------------------------------------------------------------------------------
local function streetLamp(x, z, dir, withLight)
	local m = Instance.new("Model") m.Name = "Lamp" m.Parent = F_LAMPS
	local H = 34
	part({Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 5, 5),
		CFrame = CFrame.new(x, Y + 1, z) * CFrame.Angles(0, 0, pi / 2),
		Color = DARK, CanCollide = true}, m)
	part({Name = "Pole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(H, 1.9, 1.9),
		CFrame = CFrame.new(x, Y + H / 2, z) * CFrame.Angles(0, 0, pi / 2),
		Color = POLE_COL, CanCollide = true}, m)

	local armLen = 13
	local armMid = Vector3.new(x, Y + H - 1, z) + dir * (armLen / 2)
	part({Name = "Arm", Size = Vector3.new(1.4, 1.4, armLen),
		CFrame = CFrame.lookAt(armMid, armMid + dir) * CFrame.Angles(math.rad(-6), 0, 0),
		Color = POLE_COL}, m)

	local headPos = Vector3.new(x, Y + H - 2.2, z) + dir * armLen
	part({Name = "Head", Size = Vector3.new(7, 1.6, 4),
		CFrame = CFrame.lookAt(headPos, headPos + dir), Color = rgb(72, 74, 78)}, m)
	local led = part({Name = "LED", Size = Vector3.new(6.2, 0.5, 3.4),
		Position = headPos - Vector3.new(0, 1.1, 0), Color = rgb(120, 122, 126),
		Material = Enum.Material.SmoothPlastic}, m)

	if withLight then
		local sl = Instance.new("SpotLight")
		sl.Name = "Beam" sl.Face = Enum.NormalId.Bottom sl.Angle = 105
		sl.Range = 60 sl.Brightness = 2.6 sl.Color = rgb(255, 244, 224)
		sl.Enabled = false sl.Parent = led
	end
end

local lamps = 0
local zA, zB = STREET_Z[1] - 40, STREET_Z[#STREET_Z] + 40
local xA, xB = AVENUE_X[1] - 40, AVENUE_X[#AVENUE_X] + 40

for i, ax in ipairs(AVENUE_X) do
	local off = AVENUE_W[i] / 2 + 9
	for _, s in ipairs({-1, 1}) do
		local z = zA + (s > 0 and 0 or CFG.LAMP_SPACING / 2)
		while z <= zB do
			lamps = lamps + 1
			streetLamp(ax + s * off, z, Vector3.new(-s, 0, 0), lamps % CFG.LAMP_LIGHT_EVERY == 0)
			z = z + CFG.LAMP_SPACING
		end
	end
	task.wait()
end

for j, sz in ipairs(STREET_Z) do
	local off = STREET_W[j] / 2 + 9
	for _, s in ipairs({-1, 1}) do
		local x = xA + (s > 0 and 0 or CFG.LAMP_SPACING / 2)
		while x <= xB do
			lamps = lamps + 1
			streetLamp(x, sz + s * off, Vector3.new(0, 0, -s), lamps % CFG.LAMP_LIGHT_EVERY == 0)
			x = x + CFG.LAMP_SPACING
		end
	end
end

-- Promenade nur landseitig
do
	local z = FLAT_Z0 + 80
	while z <= zB do
		lamps = lamps + 1
		streetLamp(PROMENADE_X + PROM_W / 2 + 9, z, Vector3.new(-1, 0, 0),
			lamps % CFG.LAMP_LIGHT_EVERY == 0)
		z = z + CFG.LAMP_SPACING
	end
end
print("[Traffic] " .. lamps .. " LED-Laternen.")

--------------------------------------------------------------------------------
-- SCHILDER
--------------------------------------------------------------------------------
local function signPost(x, z, h)
	part({Name = "SignPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 1.1, 1.1),
		CFrame = CFrame.new(x, Y + h / 2, z) * CFrame.Angles(0, 0, pi / 2),
		Color = rgb(140, 142, 146)}, F_SIGNS)
end

local function textOn(p, face, text, font, col, cw, ch)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face gui.CanvasSize = Vector2.new(cw, ch) gui.LightInfluence = 0
	gui.Parent = p
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1) lbl.BackgroundTransparency = 1
	lbl.Text = text lbl.Font = font lbl.TextScaled = true
	lbl.TextColor3 = col lbl.Parent = gui
end

local function stopSign(x, z, facing)
	signPost(x, z, 15)
	local p = part({Name = "Stop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 9, 9),
		CFrame = CFrame.lookAt(Vector3.new(x, Y + 16, z), Vector3.new(x, Y + 16, z) + facing)
			* CFrame.Angles(0, pi / 2, 0),
		Color = rgb(196, 30, 34), Material = Enum.Material.SmoothPlastic}, F_SIGNS)
	textOn(p, Enum.NormalId.Right, "STOP", Enum.Font.GothamBlack, rgb(255, 255, 255), 200, 200)
end

local function speedSign(x, z, facing, kmh)
	signPost(x, z, 14)
	local p = part({Name = "Speed", Size = Vector3.new(7, 9, 0.5),
		CFrame = CFrame.lookAt(Vector3.new(x, Y + 15, z), Vector3.new(x, Y + 15, z) + facing),
		Color = rgb(248, 248, 244), Material = Enum.Material.SmoothPlastic}, F_SIGNS)
	textOn(p, Enum.NormalId.Front, "SPEED\nLIMIT\n" .. kmh, Enum.Font.GothamBold,
		rgb(20, 20, 20), 160, 200)
end

local NAMES = {"OCEAN AVE", "COLLINS AVE", "PALM BLVD", "SUNSET AVE",
	"BAYSHORE BLVD", "HARBOR AVE", "MARINA AVE"}

local function streetNameSign(x, z, text)
	signPost(x, z, 32)
	local p = part({Name = "StreetName", Size = Vector3.new(32, 6, 0.6),
		Position = Vector3.new(x, Y + 30, z), Color = rgb(24, 96, 64),
		Material = Enum.Material.SmoothPlastic}, F_SIGNS)
	textOn(p, Enum.NormalId.Front, text, Enum.Font.GothamBold, rgb(255, 255, 255), 640, 120)
end

for _, i in ipairs(majorA) do
	for _, j in ipairs(majorS) do
		streetNameSign(AVENUE_X[i] - AVENUE_W[i] / 2 - SIDEWALK_W - 8,
			STREET_Z[j] + STREET_W[j] / 2 + 18, NAMES[i] .. "  /  " .. (j * 5) .. "TH ST")
	end
	speedSign(AVENUE_X[i] + AVENUE_W[i] / 2 + 11, STREET_Z[3] + 100, Vector3.new(0, 0, -1), 50)
end

-- Stoppschilder: nur wo eine schmale Strasse auf eine breite Achse trifft
local stops = 0
for _, i in ipairs(majorA) do
	for j, sz in ipairs(STREET_Z) do
		if STREET_W[j] < CFG.MAJOR_STREET_W then
			local ox = AVENUE_W[i] / 2 + 12
			stopSign(AVENUE_X[i] + ox, sz - STREET_W[j] / 2 - 12, Vector3.new(1, 0, 0))
			stopSign(AVENUE_X[i] - ox, sz + STREET_W[j] / 2 + 12, Vector3.new(-1, 0, 0))
			stops = stops + 2
		end
	end
end
print("[Traffic] " .. stops .. " Stoppschilder + Strassennamen + Tempolimits.")
print("[Traffic] ---- FERTIG ---- Naechster Schritt: 04_Props_v3.lua, dann 05, optional 07_AssetPlacer.lua")
