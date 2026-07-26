--[[
================================================================================
  01_Terrain_flat.lua
  KOMPLETT EBENE Karte. Meer im Westen, Sandstrand, dahinter perfekt flaches
  Land auf Hoehe 16. Keine Huegel, keine Wellen im Boden.
--------------------------------------------------------------------------------
  Ersetzt 01_TerrainGenerator.lua.
  Ausfuehren ueber die BEFEHLSLEISTE. Dauer ca. 1-3 Minuten.

  Warum flach besser ist: Fahrzeuge auf Roblox verhalten sich auf welligem
  Terrain unberechenbar, und Gebaeude brauchen sonst ueberall Fundamente.
================================================================================
]]

local Terrain = workspace.Terrain

--------------------------------------------------------------------------------
-- KONFIGURATION
--------------------------------------------------------------------------------
local CONFIG = {
	SEED         = 1337,

	-- Auf Stadt-Raster zentriert (siehe FLAT_* in 02_City_v3.lua).
	-- Kein riesiges Leerland mehr ostlich/suedlich der bebaubaren Zone.
	MAP_SIZE     = 3584,
	MAP_CENTER_X = 300,
	MAP_CENTER_Z = -20,

	Y_MIN        = -96,
	Y_MAX        = 64,
	CHUNK        = 256,
	RES          = 4,

	COAST_X      = -700,   -- Kuestenlinie
	COAST_WIGGLE = 340,    -- Buchten und Landzungen bleiben - das ist Natur,
	                       -- kein Raster, und stoert das flache Land nicht
	WATER_LEVEL  = 0,

	SEA_DEPTH    = 62,
	SEA_RAMP     = 720,

	BEACH_WIDTH  = 210,    -- breiter Strand, sanfte Rampe
	LAND_HEIGHT  = 16,     -- das Plateau. Muss CITY_LEVEL in Script 02 sein.

	SAND_MAX     = 11,
}

--------------------------------------------------------------------------------
local floor, ceil, clamp = math.floor, math.ceil, math.clamp
local noise = math.noise
local M = Enum.Material

local function fnoise(x, z, octaves, scale, seedOffset)
	local total, amp, freq, maxAmp = 0, 1, 1 / scale, 0
	local s = CONFIG.SEED + seedOffset
	for i = 1, octaves do
		total = total + noise(x * freq, z * freq, s + i * 13.37) * amp
		maxAmp = maxAmp + amp
		amp = amp * 0.5
		freq = freq * 2
	end
	return (total / maxAmp) * 2
end

local function smoothstep(t)
	t = clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

--------------------------------------------------------------------------------
-- HOEHENFUNKTION - ab dem Strand exakt konstant
--------------------------------------------------------------------------------
local function heightAt(x, z)
	local C = CONFIG
	local coast = C.COAST_X + fnoise(0, z, 3, 850, 5) * C.COAST_WIGGLE
	local d = x - coast

	if d < 0 then
		-- Meeresboden
		local t = clamp(-d / C.SEA_RAMP, 0, 1)
		local h = 2 - (t * t) * (C.SEA_DEPTH + 2)
		return h + fnoise(x, z, 3, 240, 21) * 3.5 * (1 - t)
	end

	-- Strandrampe, danach absolut flach
	local beach = smoothstep(d / C.BEACH_WIDTH)
	return 2 + beach * (C.LAND_HEIGHT - 2)
end

local function materialFor(h)
	if h <= CONFIG.SAND_MAX then return M.Sand end
	return M.Grass
end

--------------------------------------------------------------------------------
-- GENERIERUNG
--------------------------------------------------------------------------------
local function snapDown(v) return floor(v / CONFIG.RES) * CONFIG.RES end
local function snapUp(v)   return ceil(v / CONFIG.RES) * CONFIG.RES end

local function generateChunk(chunkX, chunkZ)
	local C = CONFIG
	local RES = C.RES
	local cols = C.CHUNK / RES

	local hmap = {}
	local lo, hi = math.huge, -math.huge
	for xi = 1, cols do
		local row = {}
		local wx = chunkX + (xi - 1) * RES + RES / 2
		for zi = 1, cols do
			local wz = chunkZ + (zi - 1) * RES + RES / 2
			local h = heightAt(wx, wz)
			row[zi] = h
			if h < lo then lo = h end
			if h > hi then hi = h end
		end
		hmap[xi] = row
	end

	local bandLo = math.max(snapDown(math.min(lo, C.WATER_LEVEL) - RES * 2), C.Y_MIN)
	local bandHi = math.min(snapUp(math.max(hi, C.WATER_LEVEL) + RES * 2), C.Y_MAX)
	if bandHi <= bandLo then return end

	local ySize = (bandHi - bandLo) / RES
	local region = Region3.new(
		Vector3.new(chunkX, bandLo, chunkZ),
		Vector3.new(chunkX + C.CHUNK, bandHi, chunkZ + C.CHUNK)
	)

	local materials, occupancy = {}, {}
	for xi = 1, cols do
		local mX, oX = {}, {}
		local colMat = {}
		for zi = 1, cols do
			colMat[zi] = materialFor(hmap[xi][zi])
		end
		for yi = 1, ySize do
			local mY, oY = {}, {}
			local vb = bandLo + (yi - 1) * RES
			local vt = vb + RES
			for zi = 1, cols do
				local occ = clamp((hmap[xi][zi] - vb) / RES, 0, 1)
				if occ > 0 then
					mY[zi] = colMat[zi]
					oY[zi] = occ
				elseif vt <= C.WATER_LEVEL then
					mY[zi] = M.Water
					oY[zi] = 1
				else
					mY[zi] = M.Air
					oY[zi] = 0
				end
			end
			mX[yi] = mY
			oX[yi] = oY
		end
		materials[xi] = mX
		occupancy[xi] = oX
	end

	Terrain:WriteVoxels(region, RES, materials, occupancy)
end

--------------------------------------------------------------------------------
local C = CONFIG
local half = C.MAP_SIZE / 2
local perAxis = C.MAP_SIZE / C.CHUNK
local mapX0 = C.MAP_CENTER_X - half
local mapZ0 = C.MAP_CENTER_Z - half

print(("[MapGen] Ebene Karte: %d x %d Studs, Mittelpunkt (%.0f, %.0f), Landhoehe %d")
	:format(C.MAP_SIZE, C.MAP_SIZE, C.MAP_CENTER_X, C.MAP_CENTER_Z, C.LAND_HEIGHT))

Terrain:Clear()

local t0 = os.clock()
local done, total = 0, perAxis * perAxis
local lastYield = os.clock()

for cx = 0, perAxis - 1 do
	for cz = 0, perAxis - 1 do
		generateChunk(mapX0 + cx * C.CHUNK, mapZ0 + cz * C.CHUNK)
		done = done + 1
		if os.clock() - lastYield > 0.1 then
			lastYield = os.clock()
			task.wait()
		end
	end
	print("[MapGen] " .. done .. " / " .. total)
end

-- Tiefsee nur westlich der Kueste, innerhalb der Kartenbounds
local oceanEdge = C.COAST_X - C.COAST_WIGGLE - 150
local westWidth = oceanEdge - mapX0
if westWidth > 0 then
	Terrain:FillBlock(
		CFrame.new(mapX0 + westWidth / 2, C.Y_MIN / 2, C.MAP_CENTER_Z),
		Vector3.new(westWidth, math.abs(C.Y_MIN), C.MAP_SIZE),
		M.Water
	)
end

print(("[MapGen] FERTIG in %.0f Sekunden. Naechster Schritt: 02_City_v3.lua")
	:format(os.clock() - t0))
