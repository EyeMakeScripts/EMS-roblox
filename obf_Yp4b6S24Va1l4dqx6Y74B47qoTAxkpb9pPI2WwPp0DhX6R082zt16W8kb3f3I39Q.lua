if game.GameId ~= 10378493761 then return end
if not game:IsLoaded() then game.Loaded:Wait() end

local Library = (function()
-- WYVERN HUB LIBRARY v1
local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local LP = Players.LocalPlayer
-- the Wyvern Studio simulator provides its own typeof; in Roblox this is the normal one
local typeof = typeof
pcall(function() local env = getfenv and getfenv(1); if env and type(rawget(env, "__typeof")) == "function" then typeof = rawget(env, "__typeof") end end)
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")

local LANG = {
	en = { MenuSize = "Menu size", Search = "Search...", Settings = "Settings", ToggleKey = "Toggle key", Destroy = "Destroy hub", DestroyDesc = "Closes the hub and turns off every function", Loaded = "Loaded! Toggle key: ", Error = "Error: ", LoopError = "Loop error: ", Select = "Select...", Type = "Type...", Reset = "Reset saved settings", ResetDesc = "Next start uses the default values again", ResetDone = "Saved settings cleared", Update = "A new version is out – run the script again to get it." },
	bs = { MenuSize = "Veličina menija", Search = "Pretraga...", Settings = "Postavke", ToggleKey = "Taster za otvaranje", Destroy = "Ugasi hub", DestroyDesc = "Zatvara hub i gasi sve funkcije", Loaded = "Učitano! Taster: ", Error = "Greška: ", LoopError = "Greška u petlji: ", Select = "Izaberi...", Type = "Upiši...", Reset = "Obriši spremljene postavke", ResetDesc = "Sljedeće pokretanje koristi početne vrijednosti", ResetDone = "Spremljene postavke obrisane", Update = "Izašla je nova verzija – pokreni skriptu ponovo da je dobiješ." },
	tl = { MenuSize = "Laki ng menu", Search = "Maghanap...", Settings = "Mga Setting", ToggleKey = "Key para buksan", Destroy = "Isara ang hub", DestroyDesc = "Isinasara ang hub at pinapatay ang lahat ng function", Loaded = "Na-load na! Key: ", Error = "Error: ", LoopError = "Error sa loop: ", Select = "Pumili...", Type = "Mag-type..." },
	fi = { MenuSize = "Valikon koko", Search = "Haku...", Settings = "Asetukset", ToggleKey = "Avausnäppäin", Destroy = "Sulje hub", DestroyDesc = "Sulkee hubin ja sammuttaa kaikki toiminnot", Loaded = "Ladattu! Näppäin: ", Error = "Virhe: ", LoopError = "Silmukkavirhe: ", Select = "Valitse...", Type = "Kirjoita..." },
	es = { MenuSize = "Tamaño del menú", Search = "Buscar...", Settings = "Ajustes", ToggleKey = "Tecla para abrir", Destroy = "Cerrar hub", DestroyDesc = "Cierra el hub y apaga todas las funciones", Loaded = "¡Cargado! Tecla: ", Error = "Error: ", LoopError = "Error en bucle: ", Select = "Elegir...", Type = "Escribe..." },
	pt = { MenuSize = "Tamanho do menu", Search = "Pesquisar...", Settings = "Configurações", ToggleKey = "Tecla para abrir", Destroy = "Fechar hub", DestroyDesc = "Fecha o hub e desliga todas as funções", Loaded = "Carregado! Tecla: ", Error = "Erro: ", LoopError = "Erro no loop: ", Select = "Escolher...", Type = "Digite..." },
}

local function imageUrl(id)
	id = tostring(id or "")
	if tonumber(id) then return "rbxassetid://" .. id end
	return id
end
local function setImage(label, id)
	label.Image = imageUrl(id)
	if tonumber(id) then
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync({ label }, function(_, status)
					if status ~= Enum.AssetFetchStatus.Success then
						label.Image = "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150"
					end
				end)
			end)
		end)
	end
end
Library.setImage = setImage

local function hex(h, fallback)
	if typeof(h) == "Color3" then return h end
	local ok, c = pcall(function() return Color3.fromHex(h) end)
	if ok and c then return c end
	return fallback or Color3.new(1, 1, 1)
end

local BOLD = { Gotham = "GothamBold", SourceSans = "SourceSansBold", Roboto = "RobotoCondensed", Nunito = "Nunito", Ubuntu = "Ubuntu" }
local function font(name, bold)
	local n = name or "Gotham"
	if bold and BOLD[n] then n = BOLD[n] end
	local ok, f = pcall(function() return Enum.Font[n] end)
	if ok and f then return f end
	return bold and Enum.Font.GothamBold or Enum.Font.Gotham
end

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function make(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end

local function corner(r) return make("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function pad(l, r, t, b)
	return make("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r or l), PaddingTop = UDim.new(0, t or l), PaddingBottom = UDim.new(0, b or t or l) })
end

local function guiParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and cg then
		local test = pcall(function() local f = Instance.new("Folder"); f.Parent = cg; f:Destroy() end)
		if test then return cg end
	end
	return LP:WaitForChild("PlayerGui")
end

local STYLES = nil -- @@STYLES@@

function Library.new(cfg)
	local self = setmetatable({}, Library)
	cfg = cfg or {}
	self.Config = cfg
	self.Flags = {}
	self.Alive = true
	self.Visible = true
	self.Conns = {}
	self.Pages = {}
	self.TabButtons = {}
	self.Elements = {}
	self.AccentObjs = {}
	self.Setters = {}
	self.UserConns = {}
	self.RenderBinds = {}
	self.Restores = {}
	self.Cards = {}
	-- running this script again closes the previous hub first, so nothing is left running twice
	local G = _G
	pcall(function() if getgenv then G = getgenv() end end)
	self.G = G
	pcall(function()
		local old = rawget(G, "__WyvernHub")
		if old and old ~= self and old.Destroy then old:Destroy(true) end
	end)
	pcall(function() rawset(G, "__WyvernHub", self) end)
	-- hosted on wyvernstudio.app: remember id and version to tell players about updates
	pcall(function()
		local hs = rawget(G, "__WyvernScript")
		if type(hs) == "table" then self.Hosted = hs; rawset(G, "__WyvernScript", nil) end
	end)
	-- menu size the player chose in the game (remembered between runs when the executor allows files)
	local u = tonumber(rawget(G, "__WyvernMenuSize"))
	if not u then pcall(function() if isfile and readfile and isfile("WyvernHub_size.txt") then u = tonumber(readfile("WyvernHub_size.txt")) end end) end
	self.UserScale = math.clamp(u or 1, 0.5, 1.6)
	self.S = setmetatable(LANG[cfg.Language or "en"] or {}, { __index = LANG.en })

	local th = cfg.Theme or {}
	self.T = {
		Accent = hex(th.Accent, Color3.fromRGB(230, 30, 50)),
		Accent2 = hex(th.Accent2, Color3.fromRGB(140, 0, 20)),
		Background = hex(th.Background, Color3.fromRGB(12, 12, 14)),
		Surface = hex(th.Surface, Color3.fromRGB(22, 22, 26)),
		Surface2 = hex(th.Surface2, Color3.fromRGB(32, 32, 38)),
		Text = hex(th.Text, Color3.fromRGB(245, 245, 245)),
		SubText = hex(th.SubText, Color3.fromRGB(150, 150, 160)),
		Stroke = hex(th.Stroke, Color3.fromRGB(50, 50, 58)),
	}
	self.R = tonumber(cfg.Corner) or 10
	self.F = font(cfg.Font, false)
	self.FB = font(cfg.Font, true)
	self.TF = self.FB
	-- Premium design (only in Premium scripts)
	if STYLES and type(cfg.LayoutSpec) == "table" then
		local ok, h = pcall(STYLES.make, self, cfg.LayoutSpec)
		if ok then self.Sty = h else warn("[WyvernHub] design: " .. tostring(h)) end
	end
	self:_build()
	return self
end

function Library:_conn(sig, fn)
	local c = sig:Connect(fn)
	table.insert(self.Conns, c)
	return c
end

function Library:_icon(parent, name, size, col, props)
	local d = self.Config.IconData and self.Config.IconData[name]
	if not d then return nil end
	local im = make("ImageLabel", { Parent = parent, BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Image = "rbxassetid://" .. tostring(d[1]), ImageRectSize = Vector2.new(48, 48), ImageRectOffset = Vector2.new(d[2], d[3]), ImageColor3 = col or self.T.Text, ScaleType = Enum.ScaleType.Fit })
	for k, v in pairs(props or {}) do im[k] = v end
	return im
end

function Library:_glow(parent, radius)
	-- soft glow that follows the exact shape of its parent (same size, same corner)
	if self.Config.IconGlow == false then return end
	for i, t in ipairs({ 0.45, 0.7, 0.86 }) do
		local g = make("Frame", { Name = "IconGlow", Parent = parent, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = radius }) })
		self:_accent(make("UIStroke", { Parent = g, Thickness = i * 2, Transparency = t, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }), "Color")
	end
end

function Library:_letter(n)
	local cfg = self.Config
	local l = tostring(cfg.IconLetter or "")
	if l == "" then l = "W" end
	return string.upper(string.sub(l, 1, n or 2))
end

function Library:_brand(parent, size, textSize)
	local cfg = self.Config
	local mode = cfg.IconMode or "Letter"
	if mode == "None" then return nil end
	local radius = UDim.new(0, math.min(self.R, math.floor(size * 0.28)))
	-- holder keeps the glow outside the clipped icon box, so nothing is cut off
	local holder = make("Frame", { Name = "Brand", Parent = parent, Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, BorderSizePixel = 0 })
	self:_glow(holder, radius)
	local box = make("Frame", { Name = "Box", Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundColor3 = self.T.Surface2, BorderSizePixel = 0, ClipsDescendants = true }, { make("UICorner", { CornerRadius = radius }) })
	self:_accent(make("UIStroke", { Parent = box, Thickness = 1.5, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }), "Color")
	if mode == "Icon" and self:_symbol(box, math.floor(size * 0.62)) then
		-- a ready-made icon
	elseif mode == "Image" and cfg.Icon and tostring(cfg.Icon) ~= "" then
		local im = make("ImageLabel", { Parent = box, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop }, { make("UICorner", { CornerRadius = radius }) })
		setImage(im, cfg.Icon)
	else
		local l = make("TextLabel", { Parent = box, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = self:_letter(2), TextSize = textSize or 18, TextColor3 = Color3.new(1, 1, 1) })
		make("UIGradient", { Parent = l, Rotation = 90, Color = ColorSequence.new(self.T.Text, self.T.Accent) })
	end
	return holder
end

-- the ready-made icon chosen for the hub (IconMode "Icon"), centered in its parent
function Library:_symbol(parent, size)
	local im = self:_icon(parent, tostring(self.Config.IconName or ""), size, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	if not im then return nil end
	make("UIGradient", { Parent = im, Rotation = 90, Color = ColorSequence.new(self.T.Text, self.T.Accent) })
	return im
end

-- remembered values of toggles, sliders, dropdowns ... (when the executor can write files)
function Library:_loadSaved()
	self.Saved = {}
	if self.Config.SaveSettings == false then return end
	local name = string.gsub(tostring(self.Config.Title or "Hub"), "[^%w%-_ ]", "")
	if name == "" then name = "Hub" end
	self.SaveFile = "WyvernHub/" .. name .. ".json"
	pcall(function()
		if isfile and readfile and isfile(self.SaveFile) then
			local d = HttpService:JSONDecode(readfile(self.SaveFile))
			if type(d) == "table" then self.Saved = d end
		end
	end)
end

function Library:_save()
	if not self.Alive or self.Config.SaveSettings == false or not self.SaveFile or self.SavePending then return end
	self.SavePending = true
	task.delay(1, function()
		self.SavePending = false
		if not self.Alive then return end
		pcall(function()
			if not writefile then return end
			if makefolder and isfolder and not isfolder("WyvernHub") then makefolder("WyvernHub") end
			local out = {}
			for k, v in pairs(self.Flags) do local ty = type(v); if ty == "boolean" or ty == "number" or ty == "string" then out[k] = v end end
			writefile(self.SaveFile, HttpService:JSONEncode(out))
		end)
	end)
end

function Library:_click()
	if self.ClickSnd then pcall(function() self.ClickSnd:Play() end) end
end

function Library:_accent(obj, prop)
	table.insert(self.AccentObjs, { obj, prop })
	obj[prop] = self.T.Accent
	return obj
end

function Library:_safe(name, fn, ...)
	if type(fn) ~= "function" then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(fn, table.unpack(args, 1, args.n))
		if not ok then
			warn("[" .. tostring(self.Config.Title) .. "] " .. name .. ": " .. tostring(err))
			if self.Alive then self:Notify(self.S.Error .. name, tostring(err), 5) end
		end
	end)
end

-- special designs: animated background, particles and decorations
local FX = {
	Water = { p = "ring", move = "up", size = { 4, 11 }, speed = { 16, 38 }, sway = 6, anim = "wave" },
	Lava = { p = "blob", move = "up", size = { 6, 16 }, speed = { 6, 14 }, sway = 3, anim = "pulse", bottom = true },
	Fire = { p = "square", move = "up", size = { 2, 5 }, speed = { 40, 85 }, sway = 10, anim = "flicker", bottom = true, fade = true },
	Winter = { p = "text", chars = { "❄", "❅", "❆", "•" }, move = "down", size = { 8, 16 }, speed = { 14, 34 }, sway = 12, anim = "none", snow = true, over = true },
	Galaxy = { p = "dot", move = "twinkle", size = { 1, 3 }, anim = "spin" },
	Neon = { p = "dot", move = "up", size = { 1, 2 }, speed = { 8, 18 }, sway = 2, anim = "pulse", scan = true },
	Matrix = { p = "text", chars = { "0", "1", "Z", "7", "X", "$", "#", "%" }, move = "down", size = { 10, 14 }, speed = { 50, 110 }, sway = 0, anim = "none", mono = true },
	Sakura = { p = "petal", move = "diag", size = { 5, 9 }, speed = { 14, 28 }, sway = 18, anim = "wave", over = true },
	Storm = { p = "rain", move = "rain", size = { 1, 1 }, speed = { 160, 240 }, sway = 0, anim = "none", flash = true },
	Gold = { p = "text", chars = { "✦", "✧", "·" }, move = "twinkle", size = { 8, 14 }, anim = "sweep" },
	Halloween = { p = "text", chars = { "🦇" }, move = "float", size = { 14, 20 }, speed = { 10, 22 }, sway = 14, anim = "pulse", over = true },
}

function Library:_special(main)
	local cfg = self.Config
	local st = FX[tostring(cfg.Special or "")]
	if not st then return end
	local fx = type(cfg.Fx) == "table" and cfg.Fx or {}
	local T, R = self.T, self.R
	local c1 = hex(fx.Color1, T.Accent)
	local c2 = hex(fx.Color2, T.Accent2)
	local amount = math.clamp(tonumber(fx.Amount) or 50, 0, 100)
	local speed = math.clamp(tonumber(fx.Speed) or 100, 10, 300) / 100
	self.FxOn = true
	local layer = make("Frame", { Name = "Special", Parent = main, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true }, { corner(R) })
	local bg = make("Frame", { Parent = layer, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, BorderSizePixel = 0 }, { corner(R) })
	local grad = make("UIGradient", { Parent = bg, Rotation = 90,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(0.5, T.Background), ColorSequenceKeypoint.new(1, c2) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.5, 0.88), NumberSequenceKeypoint.new(1, 0.6) }) })
	local fxo = { layer = layer, bg = bg, grad = grad, parts = {} }
	-- snow, petals and bats drift over the whole menu (they never block clicks)
	local host = layer
	if st.over then
		host = make("Frame", { Name = "SpecialOver", Parent = main, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Active = false, ZIndex = 40 }, { corner(R) })
		fxo.over = host
	end
	self.Fx = fxo
	if st.bottom then
		fxo.bottom = make("Frame", { Parent = layer, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.45), BackgroundColor3 = c1, BorderSizePixel = 0 })
		make("UIGradient", { Parent = fxo.bottom, Rotation = -90, Color = ColorSequence.new(c1, c2), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }) })
	end
	if st.anim == "sweep" then
		fxo.shine = make("Frame", { Parent = layer, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 })
		fxo.shineG = make("UIGradient", { Parent = fxo.shine, Rotation = 25, Color = ColorSequence.new(c1, c2),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 1), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }) })
	end
	if st.scan then fxo.scan = make("Frame", { Parent = layer, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = c1, BackgroundTransparency = 0.4, BorderSizePixel = 0 }) end
	if st.flash then fxo.flash = make("Frame", { Parent = layer, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(220, 230, 255), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 }) end
	-- animated border in the design's colors
	if fx.Animated ~= false and self.MainStroke then
		self.MainStroke.Color = Color3.new(1, 1, 1)
		for i, a in ipairs(self.AccentObjs) do if a[1] == self.MainStroke then table.remove(self.AccentObjs, i) break end end
		fxo.border = make("UIGradient", { Parent = self.MainStroke, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(0.5, c2), ColorSequenceKeypoint.new(1, c1) }) })
	end
	-- particles
	local n = (fx.Particles ~= false) and math.floor(4 + amount * 0.3) or 0
	if st.move == "twinkle" then n = math.floor(n * 1.4) end
	local function place(p, initial)
		p.x = math.random()
		if st.move == "up" then p.y = initial and math.random() or 1.05
		elseif st.move == "down" or st.move == "diag" or st.move == "rain" then p.y = initial and math.random() or -0.05
		else p.y = math.random() end
		local sp = st.speed or { 0, 0 }
		p.v = sp[1] + math.random() * (sp[2] - sp[1])
		p.ph = math.random() * 6.28
		p.dir = math.random() < 0.5 and -1 or 1
	end
	for i = 1, n do
		local s = st.size[1] + math.random() * (st.size[2] - st.size[1])
		local col = (i % 2 == 0) and c2 or c1
		local o
		if st.p == "text" then
			o = make("TextLabel", { Parent = host, BackgroundTransparency = 1, Size = UDim2.fromOffset(s + 4, s + 4), Text = st.chars[(i % #st.chars) + 1], Font = st.mono and Enum.Font.Code or Enum.Font.GothamBold, TextSize = s, TextColor3 = st.snow and Color3.new(1, 1, 1) or col, TextTransparency = 0.15 })
		elseif st.p == "ring" then
			o = make("Frame", { Parent = host, BackgroundTransparency = 1, Size = UDim2.fromOffset(s, s), BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }), make("UIStroke", { Color = col, Thickness = 1.2, Transparency = 0.25 }) })
		elseif st.p == "rain" then
			o = make("Frame", { Parent = host, BackgroundColor3 = c1, BackgroundTransparency = 0.45, Size = UDim2.fromOffset(1, 8 + math.random() * 8), Rotation = 12, BorderSizePixel = 0 })
		elseif st.p == "petal" then
			o = make("Frame", { Parent = host, BackgroundColor3 = col, BackgroundTransparency = 0.15, Size = UDim2.fromOffset(s, s * 0.6), Rotation = math.random(0, 360), BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
		else
			o = make("Frame", { Parent = host, BackgroundColor3 = st.p == "dot" and Color3.new(1, 1, 1) or col, BackgroundTransparency = st.p == "blob" and 0.35 or 0.1, Size = UDim2.fromOffset(s, s), BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(st.p == "square" and 0 or 1, 0) }) })
		end
		o.AnchorPoint = Vector2.new(0.5, 0.5)
		o.ZIndex = st.over and 40 or 1
		if st.over and o:IsA("GuiObject") then o.Active = false end
		local p = { o = o, s = s }
		place(p, true)
		table.insert(fxo.parts, p)
	end
	local tt = 0
	self:_conn(RunService.Heartbeat, function(dt)
		if not self.Alive or not self.Visible then return end
		dt = math.min(tonumber(dt) or 0.016, 0.1) * speed
		tt += dt
		local w, h = math.max(layer.AbsoluteSize.X, 1), math.max(layer.AbsoluteSize.Y, 1)
		for _, p in ipairs(fxo.parts) do
			local sx = 0
			if st.move == "up" then
				p.y -= p.v * dt / h
				if p.y < -0.05 then place(p) end
				sx = math.sin(tt * 1.6 + p.ph) * (st.sway or 0)
				if st.fade then p.o.BackgroundTransparency = 0.1 + 0.9 * math.clamp(1 - p.y, 0, 1) end
			elseif st.move == "down" or st.move == "diag" or st.move == "rain" then
				p.y += p.v * dt / h
				if st.move == "diag" then p.x += p.v * 0.35 * dt / w; p.o.Rotation += 40 * dt * p.dir end
				if st.move == "rain" then p.x += p.v * 0.2 * dt / w end
				if p.x > 1.05 then p.x -= 1.1 end
				if p.y > 1.05 then place(p) end
				sx = math.sin(tt * 1.2 + p.ph) * (st.sway or 0)
			elseif st.move == "twinkle" then
				local a = 0.15 + 0.8 * (0.5 + 0.5 * math.sin(tt * 2.2 + p.ph))
				if p.o:IsA("TextLabel") then p.o.TextTransparency = a else p.o.BackgroundTransparency = a end
			elseif st.move == "float" then
				p.x += p.v * p.dir * dt / w
				if p.x > 1.08 then p.x = -0.06 elseif p.x < -0.08 then p.x = 1.06 end
				sx = 0
				p.o.Position = UDim2.new(p.x, 0, p.y + math.sin(tt * 1.4 + p.ph) * 0.03, 0)
			end
			if st.move ~= "float" then p.o.Position = UDim2.new(p.x, sx, p.y, 0) end
		end
		if st.anim == "wave" then grad.Offset = Vector2.new(0, math.sin(tt * 0.8) * 0.15)
		elseif st.anim == "spin" then grad.Rotation = (tt * 10) % 360
		elseif st.anim == "pulse" then bg.BackgroundTransparency = 0.15 + 0.15 * math.sin(tt * 1.5)
		elseif st.anim == "flicker" and fxo.bottom then fxo.bottom.BackgroundTransparency = 0.05 + 0.25 * math.abs(math.sin(tt * 7) * math.sin(tt * 3.1)) end
		if st.bottom and st.anim ~= "flicker" then fxo.bottom.BackgroundTransparency = 0.1 + 0.2 * math.sin(tt * 1.1) end
		if fxo.shineG then fxo.shineG.Offset = Vector2.new((tt * 0.35) % 2 - 1, 0) end
		if fxo.scan then fxo.scan.Position = UDim2.new(0, 0, (tt * 0.22) % 1, 0) end
		if fxo.flash and math.random() < dt * 0.25 then
			fxo.flash.BackgroundTransparency = 0.55
			tween(fxo.flash, 0.35, { BackgroundTransparency = 1 })
		end
		if fxo.border then fxo.border.Rotation = (tt * 60) % 360 end
	end)
end

function Library:_build()
	local cfg, T, R = self.Config, self.T, self.R
	local gui = make("ScreenGui", { Name = "WyvernHub_" .. tostring(math.random(1000, 9999)), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 999 })
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	gui.Parent = guiParent()
	self.Gui = gui

	-- keep the hub below Roblox's own top bar (menu / chat buttons)
	local inset = 0
	pcall(function() inset = tonumber(game:GetService("GuiService"):GetGuiInset().Y) or 0 end)
	if type(inset) ~= "number" then inset = 0 end
	self.Inset = inset
	local sx = (cfg.Size and tonumber(cfg.Size.X)) or 580
	local sy = (cfg.Size and tonumber(cfg.Size.Y)) or 400
	local main = make("Frame", {
		Name = "Main", Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, math.floor(inset / 2)),
		Size = UDim2.fromOffset(sx, sy), BackgroundColor3 = T.Background, BackgroundTransparency = tonumber(cfg.Transparency) or 0,
		BorderSizePixel = 0, ClipsDescendants = false,
	}, { corner(R) })
	self.Main = main
	local scale = make("UIScale", { Parent = main })
	self.Scale = scale
	self.DesignW, self.DesignH = sx, sy
	self.BaseScale = 1
	if workspace.CurrentCamera then self:_conn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function() self:_layout() end) end

	local stroke = make("UIStroke", { Parent = main, Thickness = 1.5, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	self:_accent(stroke, "Color")
	self.MainStroke = stroke
	if cfg.Glow ~= false then
		for i = 1, 3 do
			local g = make("Frame", { Parent = main, Size = UDim2.new(1, i * 6, 1, i * 6), Position = UDim2.fromOffset(-i * 3, -i * 3), BackgroundTransparency = 1, ZIndex = 0 }, { corner(R + i * 3) })
			local gs = make("UIStroke", { Parent = g, Thickness = 3, Transparency = 0.55 + i * 0.13 })
			self:_accent(gs, "Color")
		end
	end

	local Sty = self.Sty
	if Sty then Sty.main(self, main) else self:_special(main) end
	local panelT = self.FxOn and math.max(tonumber(cfg.Transparency) or 0, 0.18) or (tonumber(cfg.Transparency) or 0)
	self.CardT = self.FxOn and 0.22 or 0
	if Sty then panelT = Sty.panelT; self.CardT = Sty.cardT end

	-- header
	local header = make("Frame", { Parent = main, Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = T.Surface, BackgroundTransparency = panelT, BorderSizePixel = 0, ZIndex = 2 }, { corner(R) })
	make("Frame", { Parent = header, Size = UDim2.new(1, 0, 0, R), Position = UDim2.new(0, 0, 1, -R), BackgroundColor3 = T.Surface, BackgroundTransparency = panelT, BorderSizePixel = 0, ZIndex = 2 })
	local line = make("Frame", { Parent = header, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, ZIndex = 3, BackgroundColor3 = Color3.new(1, 1, 1) })
	local lineGrad = make("UIGradient", { Parent = line })
	self.LineGrad = lineGrad
	local brand = self:_brand(header, 34, 17)
	local tx = 16
	if brand then brand.Position = UDim2.fromOffset(10, 8); brand.ZIndex = 3; for _, d in ipairs(brand:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = 3 end end; tx = 56 end
	local title = make("TextLabel", { Parent = header, BackgroundTransparency = 1, Position = UDim2.fromOffset(tx, 7), Size = UDim2.new(1, -120 - tx, 0, 22), Font = self.TF, Text = cfg.Title or "Wyvern Hub", TextSize = 19, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3 })
	local titleGrad = make("UIGradient", { Parent = title })
	self.TitleGrad = titleGrad
	local subL = make("TextLabel", { Parent = header, BackgroundTransparency = 1, Position = UDim2.fromOffset(tx, 28), Size = UDim2.new(1, -120 - tx, 0, 16), Font = self.F, Text = cfg.Subtitle or "", TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3 })
	self:_paintGradients()
	if Sty then Sty.header(self, header, title, subL, brand) end

	local function hbtn(txt, x, icon)
		if Sty then
			local sb = Sty.hbtn(self, header, x, icon)
			if sb then return sb end
		end
		local b = make("TextButton", { Parent = header, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = T.Surface2, Text = txt, Font = self.FB, TextSize = 16, TextColor3 = T.Text, AutoButtonColor = false, ZIndex = 4 }, { corner(math.min(R, 8)) })
		if self:_icon(b, icon, 16, T.Text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 5 }) then b.Text = "" end
		b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = T.Accent }) end)
		b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundColor3 = T.Surface2 }) end)
		return b
	end
	local closeB = hbtn("×", -10, "x")
	local minB = hbtn("–", -46, "minus")
	closeB.MouseButton1Click:Connect(function() self:Destroy() end)
	minB.MouseButton1Click:Connect(function() self:SetVisible(false) end)

	-- drag
	do
		local dragging, start, startPos
		self:_conn(header.InputBegan, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging, start, startPos = true, i.Position, main.Position
				i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
			end
		end)
		self:_conn(UIS.InputChanged, function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = (i.Position - start) / math.max(scale.Scale, 0.01)
				main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X * scale.Scale, startPos.Y.Scale, startPos.Y.Offset + d.Y * scale.Scale)
			end
		end)
	end

	-- body ("Made with Wyvern Studio" takes a thin line at the bottom)
	local brandH = cfg.Brand and 16 or 0
	local top = cfg.TabStyle == "Top"
	local tabBar, content
	if top then
		tabBar = make("ScrollingFrame", { Parent = main, Position = UDim2.fromOffset(10, 58), Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, BorderSizePixel = 0 }, {
			make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		content = make("Frame", { Parent = main, Position = UDim2.fromOffset(10, cfg.SearchBar ~= false and 136 or 100), Size = UDim2.new(1, -20, 1, (cfg.SearchBar ~= false and -146 or -110) - brandH), BackgroundTransparency = 1 })
	else
		local side = make("Frame", { Parent = main, Position = UDim2.fromOffset(10, 60), Size = UDim2.new(0, 150, 1, -70 - brandH), BackgroundColor3 = T.Surface, BackgroundTransparency = math.min(1, panelT + 0.2), BorderSizePixel = 0 }, { corner(R) })
		tabBar = make("ScrollingFrame", { Parent = side, Position = UDim2.fromOffset(0, cfg.SearchBar ~= false and 44 or 6), Size = UDim2.new(1, 0, 1, cfg.SearchBar ~= false and -50 or -12), BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0 }, {
			make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
			pad(6, 6, 2, 2),
		})
		self.Side = side
		if Sty then Sty.side(self, side) end
		content = make("Frame", { Parent = main, Position = UDim2.fromOffset(170, 60), Size = UDim2.new(1, -180, 1, -70 - brandH), BackgroundTransparency = 1 })
		self.SideW = 150
	end
	self.TabBar, self.Content, self.TopTabs = tabBar, content, top
	if cfg.Brand then
		make("TextLabel", { Parent = main, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 1, -24), Size = UDim2.new(1, -20, 0, 16), Font = self.F, Text = "Made with Wyvern Studio", TextSize = 11, TextColor3 = T.SubText, TextTransparency = 0.2, ZIndex = 3 })
	end

	if cfg.SearchBar ~= false then
		local holder = top and make("Frame", { Parent = main, Position = UDim2.fromOffset(10, 98), Size = UDim2.new(1, -20, 0, 30), BackgroundColor3 = T.Surface2, BorderSizePixel = 0 }, { corner(math.min(R, 8)) })
			or make("Frame", { Parent = self.Side, Position = UDim2.fromOffset(6, 8), Size = UDim2.new(1, -12, 0, 30), BackgroundColor3 = T.Surface2, BorderSizePixel = 0 }, { corner(math.min(R, 8)) })
		if not self:_icon(holder, "search", 14, T.SubText, { Position = UDim2.fromOffset(8, 8) }) then
			make("TextLabel", { Parent = holder, BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 30), Text = "⌕", Font = self.FB, TextSize = 16, TextColor3 = T.SubText })
		end
		local sb = make("TextBox", { Parent = holder, BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -32, 1, 0), Font = self.F, Text = "", PlaceholderText = self.S.Search, PlaceholderColor3 = T.SubText, TextColor3 = T.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false })
		self.SearchBox = sb
		sb:GetPropertyChangedSignal("Text"):Connect(function() self:_filter() end)
	end

	-- resize grip (bottom right): drag to make the whole menu bigger or smaller
	do
		local grip = make("TextButton", { Name = "Resize", Parent = main, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20 })
		local gi = self:_icon(grip, "move-diagonal-2", 14, T.SubText, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ImageTransparency = 0.35, ZIndex = 21 })
		if not gi then grip.Text = "◢"; grip.TextColor3 = T.SubText; grip.TextTransparency = 0.4; grip.TextSize = 14; grip.Font = Enum.Font.GothamBold end
		self.Grip = grip
		local dragging, start, startU, startPhys
		self:_conn(grip.InputBegan, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging, start, startU = true, i.Position, self.UserScale
				startPhys = (main.Size.X.Offset + main.Size.Y.Offset) / 2 * self.BaseScale
			end
		end)
		self:_conn(UIS.InputChanged, function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - start
				local grow = (d.X + d.Y) -- the corner moves half of the size change (menu grows around its centre)
				self:SetMenuSize(startU * math.max(startPhys + grow, 40) / math.max(startPhys, 1), true)
			end
		end)
		self:_conn(UIS.InputEnded, function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				self:SetMenuSize(self.UserScale)
			end
		end)
	end
	self:_layout()

	-- notifications
	local np = tostring(cfg.NotifyPosition or "BottomRight")
	local nTop, nx = string.find(np, "Top") ~= nil, (np == "BottomLeft" and 0) or (np == "TopCenter" and 0.5) or 1
	self.NotifFrom = (nx == 0 and -320) or (nx == 0.5 and 0) or 320
	self.NotifHolder = make("Frame", { Parent = gui, AnchorPoint = Vector2.new(nx, nTop and 0 or 1), Position = UDim2.new(nx, (nx == 1 and -16) or (nx == 0 and 16) or 0, nTop and 0 or 1, nTop and (inset + 12) or -16), Size = UDim2.fromOffset(290, 500), BackgroundTransparency = 1 }, {
		make("UIListLayout", { VerticalAlignment = nTop and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	-- click sound
	local snd = tostring(cfg.ClickSound or "None")
	local sid = (snd == "Click" and "rbxasset://sounds/clickfast.wav") or (snd == "Ping" and "rbxasset://sounds/electronicpingshort.wav") or (snd == "Custom" and imageUrl(cfg.SoundId)) or nil
	if sid and sid ~= "" then
		pcall(function()
			self.ClickSnd = make("Sound", { Name = "WyvernClick", SoundId = sid, Volume = math.clamp(tonumber(cfg.SoundVolume) or 50, 0, 100) / 100, Parent = game:GetService("SoundService") })
		end)
	end

	-- toggle key
	self.ToggleKey = cfg.ToggleKey or "RightShift"
	self:_conn(UIS.InputBegan, function(i, gp)
		if gp then return end
		if i.KeyCode.Name == self.ToggleKey then self:SetVisible(not self.Visible) end
	end)

	-- mobile button
	if cfg.MobileButton ~= false and UIS.TouchEnabled then
		local mr = cfg.ButtonShape == "Round" and UDim.new(1, 0) or UDim.new(0, 12)
		local mb = make("TextButton", { Name = "OpenButton", Parent = gui, Position = UDim2.new(0, 20, 0.35, 0), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = T.Background, Text = "", AutoButtonColor = false, ClipsDescendants = false, ZIndex = 50 }, { make("UICorner", { CornerRadius = mr }) })
		self:_glow(mb, mr)
		self:_accent(make("UIStroke", { Parent = mb, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }), "Color")
		local sym = cfg.IconMode == "Icon" and self:_symbol(mb, 28)
		if sym then
			sym.ZIndex = 51
		elseif cfg.IconMode == "Image" and cfg.Icon and tostring(cfg.Icon) ~= "" then
			local im = make("ImageLabel", { Parent = mb, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop, ZIndex = 51 }, { make("UICorner", { CornerRadius = mr }) })
			setImage(im, cfg.Icon)
		else
			local l = make("TextLabel", { Parent = mb, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = self:_letter(cfg.IconMode == "None" and 1 or 2), TextSize = 22, TextColor3 = Color3.new(1, 1, 1), ZIndex = 51 })
			make("UIGradient", { Parent = l, Rotation = 90, Color = ColorSequence.new(T.Text, T.Accent) })
		end
		for _, d in ipairs(mb:GetDescendants()) do if d:IsA("GuiObject") and d.Name == "IconGlow" then d.ZIndex = 49 end end
		self.OpenButton = mb
		local moved, st, sp = false, nil, nil
		mb.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then moved, st, sp = false, i.Position, mb.Position end
		end)
		mb.InputChanged:Connect(function(i)
			if st and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
				local d = i.Position - st
				if d.Magnitude > 6 then moved = true end
				if moved then mb.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end
			end
		end)
		mb.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				if not moved and st then self:SetVisible(not self.Visible) end
				st = nil
			end
		end)
	end

	-- watermark
	if cfg.Watermark then
		local wm = make("TextLabel", { Parent = gui, Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(10, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Background, BackgroundTransparency = 0.1, Font = self.FB, TextSize = 13, TextColor3 = T.Text, Text = "" }, { corner(6), pad(10, 10, 0, 0) })
		self:_accent(make("UIStroke", { Parent = wm, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }), "Color")
		local frames, last = 0, os.clock()
		self:_conn(RunService.RenderStepped, function()
			frames += 1
			local now = os.clock()
			if now - last >= 0.5 then
				wm.Text = (cfg.Title or "Hub") .. "  •  " .. math.floor(frames / (now - last)) .. " FPS  •  " .. os.date("%H:%M")
				frames, last = 0, now
			end
		end)
	end

	-- rainbow
	if cfg.Rainbow then
		self:_conn(RunService.Heartbeat, function()
			local c = Color3.fromHSV((os.clock() * 0.12) % 1, 0.85, 1)
			self.T.Accent = c
			self.T.Accent2 = Color3.fromHSV((os.clock() * 0.12 + 0.15) % 1, 0.9, 0.8)
			for _, a in ipairs(self.AccentObjs) do
				if a[1].Parent then a[1][a[2]] = c end
			end
			self:_paintGradients()
		end)
	end

	if cfg.Blur then
		self.BlurFx = make("BlurEffect", { Parent = Lighting, Size = 0 })
	end
end

function Library:_paintGradients()
	local seq = ColorSequence.new({ ColorSequenceKeypoint.new(0, self.T.Accent), ColorSequenceKeypoint.new(1, self.Config.Gradient == false and self.T.Accent or self.T.Accent2) })
	if self.LineGrad then self.LineGrad.Color = seq end
	if self.TitleGrad then
		self.TitleGrad.Color = self.Config.Gradient == false and ColorSequence.new(self.T.Text) or ColorSequence.new({ ColorSequenceKeypoint.new(0, self.T.Text), ColorSequenceKeypoint.new(1, self.T.Accent) })
	end
end

local MIN_SCALE = 0.62 -- below this the text is too small to read
local MIN_W, MIN_H = 360, 250 -- smallest menu (in design pixels)

function Library:_layout()
	if not self.Main then return end
	local vx, vy = 1280, 720
	pcall(function()
		local vp = workspace.CurrentCamera.ViewportSize
		if tonumber(vp.X) and tonumber(vp.Y) and vp.X > 0 then vx, vy = vp.X, vp.Y end
	end)
	local ax, ay = math.max(vx - 24, 200), math.max(vy - (self.Inset or 0) - 24, 150)
	local W, H = self.DesignW or 580, self.DesignH or 400
	local fit = math.min(ax / W, ay / H)
	local e = math.max((self.UserScale or 1) * math.min(fit, 1), MIN_SCALE)
	-- when the screen is too small for this size, the menu gets narrower / lower instead of unreadable
	local w, h = W, H
	if w * e > ax then w = math.max(MIN_W, ax / e) end
	if h * e > ay then h = math.max(MIN_H, ay / e) end
	e = math.min(e, ax / w, ay / h)
	w, h = math.floor(w), math.floor(h)
	self.Main.Size = UDim2.fromOffset(w, h)
	self.W, self.H = w, h
	if self.Side then
		local sw = w < 500 and 120 or 150
		self.SideW = sw
		self.Side.Size = UDim2.new(0, sw, 1, -70)
		self.Content.Position = UDim2.fromOffset(sw + 20, 60)
		self.Content.Size = UDim2.new(1, -(sw + 30), 1, -70)
	end
	self.BaseScale = e
	if self.Visible and self.Scale then self.Scale.Scale = e end
	for _, c in ipairs(self.Cards) do self:_fitCard(c) end
end

function Library:SetMenuSize(u, live)
	u = math.clamp(tonumber(u) or 1, 0.5, 1.6)
	self.UserScale = u
	self:_layout()
	local s = self.Setters and self.Setters[self.S.MenuSize]
	if s then s(math.floor(u * 100 + 0.5), false) end
	pcall(function() rawset(self.G, "__WyvernMenuSize", u) end)
	if not live then
		self._saveToken = (self._saveToken or 0) + 1
		local my = self._saveToken
		task.delay(0.6, function()
			if my ~= self._saveToken then return end
			pcall(function() if writefile then writefile("WyvernHub_size.txt", tostring(self.UserScale)) end end)
		end)
	end
end

function Library:SetVisible(v)
	if not self.Alive then return end
	self.Visible = v
	local main, anim = self.Main, self.Config.Animation or "Pop"
	if v then
		main.Visible = true
		if anim == "Slide" then
			local p = main.Position
			main.Position = p + UDim2.fromOffset(0, 40)
			self.Scale.Scale = self.BaseScale
			tween(main, 0.35, { Position = p }, Enum.EasingStyle.Back)
		elseif anim == "Fade" then
			self.Scale.Scale = self.BaseScale
			self:_cover(true)
		else
			self.Scale.Scale = self.BaseScale * 0.85
			tween(self.Scale, 0.35, { Scale = self.BaseScale }, Enum.EasingStyle.Back)
		end
		if self.BlurFx then tween(self.BlurFx, 0.3, { Size = 14 }) end
	else
		if self.BlurFx then tween(self.BlurFx, 0.3, { Size = 0 }) end
		local tw = tween(self.Scale, 0.2, { Scale = self.BaseScale * 0.85 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tw.Completed:Connect(function() if not self.Visible and self.Main then self.Main.Visible = false end end)
	end
end

function Library:_cover(fadeOut)
	local cv = make("Frame", { Parent = self.Main, Size = UDim2.fromScale(1, 1), BackgroundColor3 = self.T.Background, BackgroundTransparency = fadeOut and 0 or 1, ZIndex = 50, BorderSizePixel = 0 }, { corner(self.R) })
	local tw = tween(cv, 0.45, { BackgroundTransparency = fadeOut and 1 or 0 })
	tw.Completed:Connect(function() cv:Destroy() end)
end

function Library:Notify(title, text, dur)
	if not self.Alive then return end
	dur = dur or 3.5
	local T, R = self.T, math.min(self.R, 10)
	local card = make("Frame", { Parent = self.NotifHolder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	local from = self.NotifFrom or 320
	local inner = make("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(from, from == 0 and -40 or 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0 }, { corner(R), pad(14, 12, 10, 12) })
	self:_accent(make("UIStroke", { Parent = inner, Thickness = 1, Transparency = 0.3 }), "Color")
	if self.Sty then self.Sty.notify(self, inner) end
	local bar = make("Frame", { Parent = inner, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, 10), BorderSizePixel = 0 })
	self:_accent(bar, "BackgroundColor3")
	make("UIListLayout", { Parent = inner, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder })
	local tl = make("TextLabel", { Parent = inner, LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = self.FB, Text = tostring(title or ""), TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left })
	local bi = self:_icon(tl, "bell", 14, T.Accent, { Position = UDim2.fromOffset(-20, 2) })
	if bi then pad(20, 0, 0, 0).Parent = tl; table.insert(self.AccentObjs, { bi, "ImageColor3" }) end
	make("TextLabel", { Parent = inner, LayoutOrder = 2, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = self.F, Text = tostring(text or ""), TextSize = 13, TextWrapped = true, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left })
	bar.Parent = card
	bar.Position = UDim2.new(0, 0, 1, -2)
	tween(inner, 0.4, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	tween(bar, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	task.delay(dur, function()
		if not card.Parent then return end
		local tw = tween(inner, 0.3, { Position = UDim2.fromOffset(from, from == 0 and -40 or 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tw.Completed:Connect(function() card:Destroy() end)
	end)
end

function Library:_tab(name)
	if self.Pages[name] then return self.Pages[name] end
	local T, R = self.T, self.R
	local order = 0
	for _ in pairs(self.Pages) do order += 1 end
	local page = make("ScrollingFrame", { Parent = self.Content, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, {
		make("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }),
		pad(2, 8, 2, 8),
	})
	local btn, icon
	local iconName = self.Config.TabIcons and self.Config.TabIcons[name]
	if self.TopTabs then
		btn = make("TextButton", { Parent = self.TabBar, LayoutOrder = order, Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Surface, Text = name, Font = self.FB, TextSize = 13, TextColor3 = T.SubText, AutoButtonColor = false }, { corner(math.min(R, 8)) })
		icon = iconName and self:_icon(btn, iconName, 15, T.SubText, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -22, 0.5, 0) })
		pad(icon and 36 or 14, 14, 0, 0).Parent = btn
	else
		btn = make("TextButton", { Parent = self.TabBar, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.Surface2, BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, { corner(math.min(R, 8)) })
		icon = iconName and self:_icon(btn, iconName, 16, T.SubText, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0) })
		make("TextLabel", { Name = "L", Parent = btn, BackgroundTransparency = 1, Position = UDim2.fromOffset(icon and 38 or 16, 0), Size = UDim2.new(1, icon and -44 or -22, 1, 0), Text = name, Font = self.FB, TextSize = 13, TextScaled = true, TextWrapped = true, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left }, { make("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 10 }) })
		local ind = make("Frame", { Name = "I", Parent = btn, Position = UDim2.new(0, 4, 0.5, -8), Size = UDim2.fromOffset(3, 16), BorderSizePixel = 0, BackgroundTransparency = 1 }, { corner(2) })
		self:_accent(ind, "BackgroundColor3")
	end
	local entry = { Page = page, Button = btn, Order = order, Icon = icon }
	self.Pages[name] = entry
	if self.Sty then self.Sty.tab(self, entry, name) end
	btn.MouseButton1Click:Connect(function() self:_click(); self:SelectTab(name) end)
	if not self.Current then self:SelectTab(name) end
	return entry
end

function Library:SelectTab(name)
	local T = self.T
	for n, e in pairs(self.Pages) do
		local on = n == name
		e.Page.Visible = on
		if self.Sty and self.Sty.select(self, e, on) then
			-- drawn by the design
		elseif self.TopTabs then
			tween(e.Button, 0.2, { BackgroundColor3 = on and T.Accent or T.Surface, TextColor3 = on and Color3.new(1, 1, 1) or T.SubText })
			if e.Icon then tween(e.Icon, 0.2, { ImageColor3 = on and Color3.new(1, 1, 1) or T.SubText }) end
		else
			local base = e.Icon and 38 or 14
			tween(e.Button, 0.2, { BackgroundTransparency = on and 0 or 1 })
			tween(e.Button.L, 0.2, { TextColor3 = on and T.Text or T.SubText, Position = UDim2.fromOffset(on and base + 4 or base, 0) })
			tween(e.Button.I, 0.2, { BackgroundTransparency = on and 0 or 1 })
			if e.Icon then tween(e.Icon, 0.2, { ImageColor3 = on and T.Accent or T.SubText, Position = UDim2.new(0, on and 16 or 14, 0.5, 0) }) end
		end
	end
	if self.Pages[name] then
		local p = self.Pages[name].Page
		p.Position = UDim2.fromOffset(0, 12)
		tween(p, 0.3, { Position = UDim2.fromOffset(0, 0) })
	end
	self.Current = name
	self:_filter()
end

function Library:_filter()
	local q = self.SearchBox and string.lower(self.SearchBox.Text) or ""
	for _, el in ipairs(self.Elements) do
		if el.Tab == self.Current then
			el.Frame.Visible = q == "" or string.find(string.lower(el.Name), q, 1, true) ~= nil
		end
	end
end

local function textHeight(text, size, fnt, width)
	local h
	pcall(function()
		local v = TextService:GetTextSize(text, size, fnt, Vector2.new(width, 10000))
		h = tonumber(v.Y)
	end)
	if not h or h <= 0 then
		-- fallback estimate (about 0.55 x font size per character)
		local per = math.max(1, math.floor(width / (size * 0.55)))
		h = math.ceil(math.max(#text, 1) / per) * math.ceil(size * 1.2)
	end
	return math.ceil(h)
end

-- Cards grow to fit their text: long names wrap to a new line instead of being cut off.
function Library:_card(page, name, desc, opts)
	opts = opts or {}
	local T, R = self.T, self.R
	local hasDesc = desc and desc ~= ""
	local f = make("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, hasDesc and 52 or 40), BackgroundColor3 = T.Surface, BackgroundTransparency = self.CardT or 0, BorderSizePixel = 0, ClipsDescendants = true }, { corner(math.min(R, 10)) })
	local st = make("UIStroke", { Parent = f, Color = T.Stroke, Thickness = 1, Transparency = 0.3 })
	if self.Sty then self.Sty.card(self, f, st) end
	local stC, stT = st.Color, st.Transparency
	f.MouseEnter:Connect(function() tween(st, 0.2, { Color = T.Accent, Transparency = 0.4 }) end)
	f.MouseLeave:Connect(function() tween(st, 0.2, { Color = stC, Transparency = stT }) end)
	local title = make("TextLabel", { Name = "Title", Parent = f, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 11), Size = UDim2.new(1, -(14 + (opts.reserve or 70)), 0, 18), Font = self.FB, Text = name, TextSize = 14, TextWrapped = true, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center })
	local d
	if hasDesc then
		d = make("TextLabel", { Name = "Desc", Parent = f, BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 31), Size = UDim2.new(1, -(14 + (opts.descReserve or opts.reserve or 70)), 0, 15), Font = self.F, Text = desc, TextSize = 12, TextWrapped = true, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
	end
	local c = { Frame = f, Title = title, Desc = d, Name = name, DescText = desc, Reserve = opts.reserve or 70, DescReserve = opts.descReserve or opts.reserve or 70, Bottom = opts.bottom or 0, OnFit = opts.onFit,
		-- a wide control (text box, dropdown, key) moves under the text when the menu is narrow
		Stack = opts.stack, OnStack = opts.onStack }
	table.insert(self.Cards, c)
	self:_fitCard(c)
	return f, c
end

function Library:_fitCard(c)
	local cw
	if self.TopTabs then cw = (self.W or 580) - 20 else cw = (self.W or 580) - (self.SideW or 150) - 30 end
	cw = cw - 10 -- page padding
	-- narrow menu: put the control under the text instead of squeezing the text into a thin column
	local stacked = c.Stack ~= nil and (cw - 14 - c.Reserve) < 150
	local reserve = stacked and 14 or c.Reserve
	local descReserve = stacked and 14 or c.DescReserve
	local tw = math.max(cw - 14 - reserve, 60)
	-- very narrow: slightly smaller letters, so words stay whole
	local ts = tw < 110 and 13 or 14
	c.Title.TextSize = ts
	local th = textHeight(c.Name, ts, self.FB, tw)
	c.Title.Size = UDim2.new(1, -(14 + reserve), 0, th)
	local y = 11 + th
	if c.Desc then
		local dw = math.max(cw - 14 - descReserve, 60)
		local ds = dw < 110 and 11 or 12
		c.Desc.TextSize = ds
		local dh = textHeight(c.DescText, ds, self.F, dw)
		c.Desc.Position = UDim2.fromOffset(14, y + 3)
		c.Desc.Size = UDim2.new(1, -(14 + descReserve), 0, dh)
		y = y + 3 + dh
	end
	local sy
	if stacked then
		sy = y + 8
		y = sy + c.Stack
	end
	local h = math.max(y + 11 + c.Bottom, c.Desc and 52 or 40)
	if th <= 18 and not c.Desc and not stacked then
		-- single line, no description: keep the title centred like before
		c.Title.Position = UDim2.fromOffset(14, 0)
		c.Title.Size = UDim2.new(1, -(14 + reserve), 0, h - c.Bottom)
	else
		c.Title.Position = UDim2.fromOffset(14, 11)
	end
	c.Height = h
	c.Stacked, c.StackY = stacked, sy
	if c.OnStack then c.OnStack(stacked, sy) end
	if c.OnFit then c.OnFit(h, c) else c.Frame.Size = UDim2.new(1, 0, 0, h) end
end

function Library:_ripple(parent, x, y)
	local r = make("Frame", { Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x - parent.AbsolutePosition.X, y - parent.AbsolutePosition.Y), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = self.T.Accent, BackgroundTransparency = 0.6, ZIndex = parent.ZIndex + 1 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local s = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
	local tw = tween(r, 0.55, { Size = UDim2.fromOffset(s, s), BackgroundTransparency = 1 })
	tw.Completed:Connect(function() r:Destroy() end)
end

local function keyName(k)
	if typeof(k) == "EnumItem" then return k.Name end
	return tostring(k or "None")
end

function Library:_element(e)
	local T, R = self.T, self.R
	local tabName = e.Tab or "Main"
	local page = self:_tab(tabName).Page
	local name = e.Name or e.Type
	local f
	if e.Type == "Section" then
		f = make("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
		local l = make("TextLabel", { Parent = f, BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 6), Size = UDim2.new(1, -8, 0, 18), Font = self.FB, Text = string.upper(name), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
		self:_accent(l, "TextColor3")
		if self.Sty then self.Sty.section(self, f, l, name) end
	elseif e.Type == "Label" then
		f = make("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Surface, BackgroundTransparency = 0.4, BorderSizePixel = 0 }, { corner(math.min(R, 10)), pad(14, 14, 10, 10) })
		make("TextLabel", { Parent = f, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = self.F, Text = name, TextSize = 13, TextWrapped = true, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left })
	elseif e.Type == "Button" then
		f = self:_card(page, name, e.Desc, { reserve = 44 })
		local icon = make("TextLabel", { Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = "›", Font = self.FB, TextSize = 22 })
		self:_accent(icon, "TextColor3")
		local b = make("TextButton", { Parent = f, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3 })
		b.MouseButton1Down:Connect(function(x, y) self:_ripple(f, x, y) end)
		b.MouseButton1Click:Connect(function()
			self:_click()
			tween(icon, 0.1, { Position = UDim2.new(1, -8, 0.5, 0) }).Completed:Connect(function() tween(icon, 0.2, { Position = UDim2.new(1, -14, 0.5, 0) }) end)
			self:_safe(name, e.Callback)
		end)
	elseif e.Type == "Toggle" then
		f = self:_card(page, name, e.Desc, { reserve = 70 })
		local sw = make("Frame", { Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(42, 22), BackgroundColor3 = T.Surface2, BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local swStroke = make("UIStroke", { Parent = sw, Color = T.Stroke, Thickness = 1 })
		local knob = make("Frame", { Parent = sw, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = T.SubText, BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local state, token = false, 0
		local look = self.Sty and self.Sty.toggle(self, sw, knob, swStroke)
		if look then look(false) end
		local function set(v, silent)
			state = v and true or false
			self.Flags[name] = state
			self:_save()
			if look then look(state) else
				tween(sw, 0.25, { BackgroundColor3 = state and T.Accent or T.Surface2 })
				tween(swStroke, 0.25, { Color = state and T.Accent or T.Stroke })
				tween(knob, 0.3, { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = state and Color3.new(1, 1, 1) or T.SubText }, Enum.EasingStyle.Back)
			end
			if silent then return end
			token += 1
			local my = token
			if state then
				self:_safe(name, e.On)
				if type(e.Loop) == "function" then
					task.spawn(function()
						while self.Alive and state and token == my do
							local ok, err = pcall(e.Loop)
							if not ok then
								warn("[Loop] " .. name .. ": " .. tostring(err))
								self:Notify(self.S.LoopError .. name, tostring(err), 4)
								set(false)
								break
							end
							task.wait(tonumber(e.Interval) or 0.1)
						end
					end)
				end
			else
				self:_safe(name, e.Off)
			end
		end
		self.Setters[name] = set
		local b = make("TextButton", { Parent = f, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3 })
		b.MouseButton1Click:Connect(function() self:_click(); set(not state) end)
		self.Flags[name] = false
		local sv = self.Saved and self.Saved[name]
		if sv == nil then sv = e.Default end
		if sv then task.defer(set, true) end
	elseif e.Type == "Slider" then
		local hasDesc = e.Desc and e.Desc ~= ""
		f = self:_card(page, name, e.Desc, { reserve = 84, descReserve = 14, bottom = 20 })
		local mn, mx = tonumber(e.Min) or 0, tonumber(e.Max) or 100
		if mx <= mn then mx = mn + 1 end
		local dec = tonumber(e.Decimals) or 0
		local valL = make("TextLabel", { Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, hasDesc and 8 or 8), Size = UDim2.fromOffset(70, 20), BackgroundTransparency = 1, Font = self.FB, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
		self:_accent(valL, "TextColor3")
		local track = make("Frame", { Parent = f, Position = UDim2.new(0, 14, 1, -16), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = T.Surface2, BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local fill = make("Frame", { Parent = track, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		self:_accent(fill, "BackgroundColor3")
		local dot = make("Frame", { Parent = fill, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local look = self.Sty and self.Sty.slider(self, track, fill, dot)
		local value
		local function set(v, fire)
			local m = 10 ^ dec
			v = math.clamp(math.floor(v * m + 0.5) / m, mn, mx)
			if v == value then return end
			value = v
			self.Flags[name] = v
			valL.Text = tostring(v)
			if fire ~= false then self:_save() end
			tween(fill, 0.08, { Size = UDim2.fromScale((v - mn) / (mx - mn), 1) }, Enum.EasingStyle.Linear)
			if look then look((v - mn) / (mx - mn)) end
			if fire ~= false then self:_safe(name, e.Callback, v) end
		end
		self.Setters[name] = set
		local startV = tonumber(e.Default) or mn
		local saved = not e.Internal and self.Saved and tonumber(self.Saved[name])
		set(startV, false)
		if saved and saved ~= startV then task.defer(set, saved) end
		if not e.Internal then
			-- when the hub is closed, put the value back to where it started (e.g. WalkSpeed 16)
			table.insert(self.Restores, function() if value ~= startV then self:_safe(name, e.Callback, startV) end end)
		end
		local dragging = false
		local function upd(x)
			local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			set(mn + (mx - mn) * rel)
		end
		local hit = make("TextButton", { Parent = f, Position = UDim2.new(0, 8, 1, -28), Size = UDim2.new(1, -16, 0, 28), BackgroundTransparency = 1, Text = "", ZIndex = 3 })
		hit.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				tween(dot, 0.15, { Size = UDim2.fromOffset(18, 18) })
				upd(i.Position.X)
			end
		end)
		self:_conn(UIS.InputChanged, function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end
		end)
		self:_conn(UIS.InputEnded, function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				tween(dot, 0.15, { Size = UDim2.fromOffset(14, 14) })
			end
		end)
	elseif e.Type == "Keybind" then
		local kb
		local card
		f, card = self:_card(page, name, e.Desc, { reserve = 100, stack = 26, onStack = function(st, y)
			if not kb then return end
			if st then kb.AnchorPoint = Vector2.new(0, 0); kb.Position = UDim2.fromOffset(14, y)
			else kb.AnchorPoint = Vector2.new(1, 0.5); kb.Position = UDim2.new(1, -12, 0.5, 0) end
		end })
		local key = (self.Saved and type(self.Saved[name]) == "string" and self.Saved[name]) or e.Key or "E"
		if key ~= e.Key and e.OnChange and key ~= "None" then e.OnChange(key) end
		kb = make("TextButton", { Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Surface2, Font = self.FB, TextSize = 12, TextColor3 = T.Text, Text = key, AutoButtonColor = false, ZIndex = 3 }, { corner(6), pad(10, 10, 0, 0) })
		self:_accent(make("UIStroke", { Parent = kb, Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }), "Color")
		self:_fitCard(card)
		local waiting = false
		self.Flags[name] = key
		kb.MouseButton1Click:Connect(function() waiting = true; kb.Text = "..." end)
		self:_conn(UIS.InputBegan, function(i, gp)
			if waiting then
				if i.UserInputType == Enum.UserInputType.Keyboard then
					waiting = false
					if i.KeyCode == Enum.KeyCode.Escape or i.KeyCode == Enum.KeyCode.Backspace then key = "None" else key = i.KeyCode.Name end
					kb.Text = key
					self.Flags[name] = key
					self:_save()
					if e.OnChange then e.OnChange(key) end
				end
				return
			end
			if gp or key == "None" then return end
			if i.KeyCode.Name == key then
				tween(kb, 0.1, { BackgroundColor3 = T.Accent }).Completed:Connect(function() tween(kb, 0.3, { BackgroundColor3 = T.Surface2 }) end)
				self:_safe(name, e.Callback)
			end
		end)
	elseif e.Type == "Textbox" then
		local tb
		local card
		f, card = self:_card(page, name, e.Desc, { reserve = 186, stack = 28, onStack = function(st, y)
			if not tb then return end
			if st then tb.AnchorPoint = Vector2.new(0, 0); tb.Position = UDim2.fromOffset(14, y); tb.Size = UDim2.new(1, -28, 0, 28)
			else tb.AnchorPoint = Vector2.new(1, 0.5); tb.Position = UDim2.new(1, -12, 0.5, 0); tb.Size = UDim2.fromOffset(160, 26) end
		end })
		tb = make("TextBox", { Parent = f, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(160, 26), BackgroundColor3 = T.Surface2, Font = self.F, TextSize = 12, TextColor3 = T.Text, PlaceholderText = e.Placeholder or self.S.Type, PlaceholderColor3 = T.SubText, Text = "", ClearTextOnFocus = false, ZIndex = 3 }, { corner(6), pad(8, 8, 0, 0) })
		local st = make("UIStroke", { Parent = tb, Color = T.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		self:_fitCard(card)
		if self.Saved and type(self.Saved[name]) == "string" then tb.Text = self.Saved[name]; self.Flags[name] = tb.Text end
		tb.Focused:Connect(function() tween(st, 0.2, { Color = T.Accent }) end)
		tb.FocusLost:Connect(function(enter)
			tween(st, 0.2, { Color = T.Stroke })
			self.Flags[name] = tb.Text
			self:_save()
			if enter or e.FireOnLeave then self:_safe(name, e.Callback, tb.Text) end
		end)
	elseif e.Type == "Dropdown" then
		local opts = e.Options or {}
		local baseH, cur, arrow, list, hb = 40, nil, nil, nil, nil
		local open = false
		local sY -- set when the menu is narrow: the choice sits under the name
		local function apply(h, c)
			baseH = h
			if cur then
				if sY then
					cur.AnchorPoint = Vector2.new(0, 0); cur.Position = UDim2.fromOffset(14, sY); cur.Size = UDim2.new(1, -50, 0, 26); cur.TextXAlignment = Enum.TextXAlignment.Left
					arrow.Position = UDim2.new(1, -12, 0, sY); arrow.Size = UDim2.fromOffset(18, 26)
				else
					cur.AnchorPoint = Vector2.new(1, 0); cur.Position = UDim2.new(1, -34, 0, 0); cur.Size = UDim2.fromOffset(140, h); cur.TextXAlignment = Enum.TextXAlignment.Right
					arrow.Position = UDim2.new(1, -12, 0, 0); arrow.Size = UDim2.fromOffset(18, h)
				end
				list.Position = UDim2.fromOffset(8, h)
				hb.Size = UDim2.new(1, 0, 0, h)
			end
			local fr = (c and c.Frame) or f
			if fr then fr.Size = UDim2.new(1, 0, 0, h + (open and (#opts * 30 + 8) or 0)) end
		end
		local card
		f, card = self:_card(page, name, e.Desc, { reserve = 170, onFit = apply, stack = 26, onStack = function(st, y) sY = st and y or nil end })
		cur = make("TextLabel", { Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -34, 0, 0), Size = UDim2.fromOffset(140, baseH), BackgroundTransparency = 1, Font = self.F, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" })
		arrow = make("TextLabel", { Parent = f, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.fromOffset(18, baseH), BackgroundTransparency = 1, Font = self.FB, TextSize = 14, Text = "▾" })
		self:_accent(arrow, "TextColor3")
		list = make("Frame", { Parent = f, Position = UDim2.fromOffset(8, baseH), Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, { make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }), pad(0, 0, 0, 8) })
		local btns = {}
		local function set(o, fire)
			cur.Text = tostring(o)
			self.Flags[name] = o
			if fire ~= false then self:_save() end
			for k, b in pairs(btns) do tween(b, 0.15, { BackgroundColor3 = k == o and T.Accent or T.Surface2 }) end
			if fire ~= false then self:_safe(name, e.Callback, o) end
		end
		self.Setters[name] = set
		local function toggle()
			open = not open
			local h = baseH + (open and (#opts * 30 + 8) or 0)
			tween(f, 0.3, { Size = UDim2.new(1, 0, 0, h) })
			tween(arrow, 0.3, { Rotation = open and 180 or 0 })
		end
		for idx, o in ipairs(opts) do
			local b = make("TextButton", { Parent = list, LayoutOrder = idx, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = T.Surface2, Font = self.F, TextSize = 12, TextColor3 = T.Text, Text = tostring(o), AutoButtonColor = false }, { corner(6) })
			btns[o] = b
			b.MouseButton1Click:Connect(function() self:_click(); set(o); toggle() end)
		end
		hb = make("TextButton", { Parent = f, Size = UDim2.new(1, 0, 0, baseH), BackgroundTransparency = 1, Text = "", ZIndex = 3 })
		hb.MouseButton1Click:Connect(toggle)
		self:_fitCard(card)
		local sv = self.Saved and self.Saved[name]
		if sv ~= nil and table.find(opts, sv) then task.defer(set, sv)
		elseif e.Default and e.Default ~= "" then set(e.Default, false) else cur.Text = self.S.Select end
	else
		return
	end
	table.insert(self.Elements, { Name = name, Tab = tabName, Frame = f })
	f.LayoutOrder = #self.Elements
end

function Library:Build(elements, tabsOrder)
	self:_loadSaved()
	for _, t in ipairs(tabsOrder or {}) do self:_tab(t) end
	for _, e in ipairs(elements or {}) do
		local ok, err = pcall(function() self:_element(e) end)
		if not ok then warn("[WyvernHub] element " .. tostring(e.Name) .. ": " .. tostring(err)) end
	end
	if self.Config.SettingsTab ~= false then
		local st = (self.Config.SettingsTabName and self.Config.SettingsTabName ~= "") and self.Config.SettingsTabName or self.S.Settings
		if self.Config.TabIcons and not self.Config.TabIcons[st] then self.Config.TabIcons[st] = "settings" end
		self:_element({ Type = "Section", Name = "Hub", Tab = st })
		self:_element({ Type = "Slider", Name = self.S.MenuSize, Desc = "", Tab = st, Min = 50, Max = 160, Default = math.floor(self.UserScale * 100 + 0.5), Internal = true, Callback = function(v) self:SetMenuSize(v / 100) end })
		self:_element({ Type = "Keybind", Name = self.S.ToggleKey, Tab = st, Key = self.ToggleKey, Callback = function() end, OnChange = function(k) if k ~= "None" then self.ToggleKey = k end end })
		if self.Config.SaveSettings ~= false then
			self:_element({ Type = "Button", Name = self.S.Reset, Desc = self.S.ResetDesc, Tab = st, Callback = function()
				pcall(function() if delfile and self.SaveFile and isfile and isfile(self.SaveFile) then delfile(self.SaveFile) end end)
				self.SaveFile = nil
				self:Notify(self.Config.Title or "Hub", self.S.ResetDone, 3)
			end })
		end
		self:_element({ Type = "Button", Name = self.S.Destroy, Desc = self.S.DestroyDesc, Tab = st, Callback = function() self:Destroy() end })
	end
	local first = (tabsOrder and tabsOrder[1])
	if first and self.Pages[first] then self:SelectTab(first) end
	self:_intro()
	self:_watchUpdates()
end

-- hosted scripts: every few minutes ask whether a newer version was published
function Library:_watchUpdates()
	local hs = self.Hosted
	if type(hs) ~= "table" or type(hs.Url) ~= "string" then return end
	task.spawn(function()
		while self.Alive do
			task.wait(180)
			if not self.Alive then break end
			local ok, v = pcall(function() return game:HttpGet(hs.Url .. "/v") end)
			v = ok and tonumber(v) or nil
			if v and v > (tonumber(hs.Ver) or 0) then
				self:Notify(self.Config.Title or "Hub", self.S.Update, 10)
				break
			end
		end
	end)
end

function Library:_intro()
	local cfg = self.Config
	self.Main.Visible = false
	local function show()
		self.Visible = false
		self:SetVisible(true)
		if cfg.LoadNotify ~= false then
			self:Notify(cfg.Title or "Hub", (cfg.LoadText and cfg.LoadText ~= "") and cfg.LoadText or (self.S.Loaded .. self.ToggleKey), 4)
		end
		if cfg.Brand then
			task.delay(1, function() if self.Alive then self:Notify("Wyvern Studio", "This hub was made with Wyvern Studio.", 4) end end)
		end
	end
	if cfg.Intro == false then show() return end
	local T = self.T
	local ov = make("Frame", { Parent = self.Gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 100 })
	local ib = self:_brand(ov, 84, 38)
	if ib then
		ib.AnchorPoint = Vector2.new(0.5, 0.5)
		ib.Position = UDim2.fromScale(0.5, 0.33)
		ib.ZIndex = 101
		for _, d in ipairs(ib:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex = 102 end end
		local sc = make("UIScale", { Parent = ib, Scale = 0 })
		tween(sc, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(1.4, function() tween(sc, 0.35, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In) end)
	end
	local t = make("TextLabel", { Parent = ov, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromOffset(600, 60), BackgroundTransparency = 1, Font = self.TF, Text = cfg.IntroText ~= "" and cfg.IntroText or cfg.Title or "Hub", TextSize = 44, TextColor3 = Color3.new(1, 1, 1), TextTransparency = 1, ZIndex = 101 })
	make("UIGradient", { Parent = t, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, T.Text), ColorSequenceKeypoint.new(1, T.Accent) }) })
	local barBg = make("Frame", { Parent = ov, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.54), Size = UDim2.fromOffset(220, 3), BackgroundColor3 = T.Surface2, BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 101 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local bar = make("Frame", { Parent = barBg, Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 102 }, { make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	tween(ov, 0.4, { BackgroundTransparency = 0.35 })
	tween(t, 0.6, { TextTransparency = 0, Position = UDim2.fromScale(0.5, 0.45) })
	tween(barBg, 0.4, { BackgroundTransparency = 0 })
	tween(bar, 1.3, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Quad)
	task.delay(1.5, function()
		tween(t, 0.35, { TextTransparency = 1 })
		tween(barBg, 0.35, { BackgroundTransparency = 1 })
		tween(bar, 0.35, { BackgroundTransparency = 1 })
		tween(ov, 0.45, { BackgroundTransparency = 1 }).Completed:Connect(function() ov:Destroy() end)
		show()
	end)
end

function Library:Set(name, value)
	local s = self.Setters[name]
	if s then s(value) end
end

-- Helper objects that functions create and must not stay in the game after closing
local HELPERS = { BodyVelocity = true, BodyGyro = true, BodyPosition = true, BodyForce = true, BodyThrust = true, BodyAngularVelocity = true, LinearVelocity = true, AngularVelocity = true, AlignPosition = true, AlignOrientation = true, VectorForce = true, Highlight = true, SelectionBox = true, BoxHandleAdornment = true, BillboardGui = true }
local function sweep(t, seen)
	if type(t) ~= "table" or seen[t] then return end
	seen[t] = true
	for k, v in pairs(t) do
		local ty = typeof(v)
		if ty == "RBXScriptConnection" then
			pcall(function() v:Disconnect() end)
			t[k] = nil
		elseif ty == "thread" then
			pcall(task.cancel, v)
			t[k] = nil
		elseif ty == "Instance" then
			local ok, cls = pcall(function() return v.ClassName end)
			if ok and HELPERS[cls] then pcall(function() v:Destroy() end); t[k] = nil end
		elseif ty == "table" then
			sweep(v, seen)
		end
	end
end

-- Wraps a service so that every connection made through it is closed with the hub.
function Library:Track(svc)
	local hub, cache, proxy = self, {}, nil
	local function track(c) table.insert(hub.UserConns, c) return c end
	proxy = setmetatable({}, {
		__index = function(_, k)
			local v = svc[k]
			if typeof(v) == "RBXScriptSignal" then
				if not cache[k] then
					cache[k] = {
						Connect = function(_, fn) return track(v:Connect(fn)) end,
						Once = function(_, fn) return track(v:Once(fn)) end,
						ConnectParallel = function(_, fn) return track(v:ConnectParallel(fn)) end,
						Wait = function(_) return v:Wait() end,
					}
				end
				return cache[k]
			elseif type(v) == "function" then
				if k == "BindToRenderStep" then
					return function(_, name, ...) table.insert(hub.RenderBinds, name) return v(svc, name, ...) end
				end
				return function(me, ...) if me == proxy then return v(svc, ...) end return v(me, ...) end
			end
			return v
		end,
		__newindex = function(_, k, v) svc[k] = v end,
		__tostring = function() return tostring(svc) end,
	})
	return proxy
end

-- Closes the hub completely: every function is switched off and nothing keeps running.
function Library:Destroy(instant)
	if not self.Alive then return end
	self.Alive = false
	-- 1. every toggle that is on runs its "off" code
	for n, v in pairs(self.Flags) do if v == true and self.Setters[n] then pcall(self.Setters[n], false) end end
	-- 2. sliders go back to their start value (WalkSpeed, gravity, FOV ...)
	for _, r in ipairs(self.Restores) do pcall(r) end
	-- 3. stop everything the functions connected
	local function cleanup()
		for _, c in ipairs(self.UserConns) do pcall(function() c:Disconnect() end) end
		table.clear(self.UserConns)
		for _, n in ipairs(self.RenderBinds) do pcall(function() RunService:UnbindFromRenderStep(n) end) end
		if self.Store then sweep(self.Store, {}) end
	end
	cleanup()
	task.delay(0.5, cleanup) -- again, after "off" code that waited for something
	for _, c in ipairs(self.Conns) do pcall(function() c:Disconnect() end) end
	if self.BlurFx then self.BlurFx:Destroy() end
	if self.ClickSnd then pcall(function() self.ClickSnd:Destroy() end) end
	pcall(function() if rawget(self.G, "__WyvernHub") == self then rawset(self.G, "__WyvernHub", nil) end end)
	if self.Gui then
		if instant then
			self.Gui:Destroy()
		else
			local tw = tween(self.Scale, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			tw.Completed:Connect(function() if self.Gui then self.Gui:Destroy() end end)
		end
	end
	if self.OnDestroy then pcall(self.OnDestroy) end
end

return Library

end)()

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local HUI = (gethui and gethui()) or game:GetService("CoreGui")

local DM = RS:WaitForChild("DodgeMatch")
local Remotes = RS:WaitForChild("DodgeGame"):WaitForChild("Remotes")
local Action = Remotes:FindFirstChild("Action")
local Progress = Remotes:FindFirstChild("Progress")
local Offer = Remotes:FindFirstChild("Offer")
local CrateR = Remotes:FindFirstChild("Crate")
local LockV = LP:WaitForChild("LockOnTarget", 10)
local warnGui = LP:WaitForChild("PlayerGui"):WaitForChild("IncomingWarningGui", 30)

local function now() return workspace:GetServerTimeNow() end
local function la(k) return LP:GetAttribute(k) end
local function json(s) local ok, t = pcall(Http.JSONDecode, Http, s or "") return ok and t or nil end
local function myChar() return LP.Character end
local function myRoot() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function playing() return la("InMatch") == true and DM:GetAttribute("Phase") == "Playing" end
local function isOut(c) return not c or c:GetAttribute("DodgeOut") == true end

local function press(setting, default)
	local k = Enum.KeyCode[tostring(la(setting) or default)] or Enum.KeyCode[default]
	if not k then return end
	VIM:SendKeyEvent(true, k, false, game)
	task.wait(0.03 + math.random() * 0.03)
	VIM:SendKeyEvent(false, k, false, game)
end

-- ===== CONFIG =====
local Config = {
	Animation = "Pop",
	Blur = false,
	Brand = false,
	ButtonShape = "Square",
	ClickSound = "Click",
	Corner = 9,
	Font = "GothamBold",
	Fx = { Amount = 60, Animated = true, Color1 = "#ff4a5a", Color2 = "#3c8dff", Particles = true, Speed = 150 },
	Glow = true,
	Gradient = true,
	IconData = {
		bell = { 16898612819, 820, 257 },
		minus = { 16898613613, 771, 196 },
		["move-diagonal-2"] = { 16898613613, 967, 49 },
		search = { 16898613699, 918, 857 },
		settings = { 16898613777, 771, 257 },
		sparkles = { 16898613777, 918, 49 },
		wrench = { 16898613869, 820, 906 },
		x = { 16898613869, 869, 906 },
		eye = { 16898613353, 771, 563 },
	},
	IconGlow = true,
	IconLetter = "PD",
	IconMode = "Letter",
	Intro = true,
	IntroText = "Prison Dodgeball Hub",
	Language = "en",
	LoadNotify = true,
	LoadText = "RightShift to toggle · F6 to pause",
	MobileButton = true,
	NotifyPosition = "BottomRight",
	Rainbow = false,
	SaveSettings = true,
	SearchBar = true,
	SettingsTab = true,
	Size = { X = 670, Y = 440 },
	Special = "Galaxy",
	Subtitle = "by Stizzyyy · always free",
	TabIcons = {
		Match = "sparkles",
		Aim = "eye",
		Visuals = "eye",
		Rewards = "bell",
		Extras = "wrench",
	},
	TabStyle = "Sidebar",
	Theme = {
		Accent = "#ff4a5a",
		Accent2 = "#3c8dff",
		Background = "#0b0b0e",
		Stroke = "#2d2d38",
		SubText = "#a0a0b0",
		Surface = "#16161e",
		Surface2 = "#20202c",
		Text = "#f2f2f5",
	},
	Title = "Prison Dodgeball Hub",
	ToggleKey = "RightShift",
	Transparency = 0.08,
	Watermark = true,
}

-- ===== HUB =====
local Hub = Library.new(Config)
Hub.Store = {}
local RunService = Hub:Track(game:GetService("RunService"))
local UIS = Hub:Track(game:GetService("UserInputService"))
local Flags = Hub.Flags
local Store = Hub.Store

-- ===== STATE =====
local paused = false
local busy = false
local alive = true
local cur = nil
local aimT = nil
local rmb = false
local lastThrow, throwing = 0, false
local fpsWas = nil
local litWas = nil
local crateN = 0
local staffSeen = {}
local why = "idle"

local function F(name) return Flags[name] end

-- ===== EXTRA GUIS =====
local extraGuis = {}
local function makeGui(name, order)
	local g = Instance.new("ScreenGui")
	g.Name = name .. math.random(100000, 1000000)
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = order or 40
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(g) end end)
	g.Parent = HUI
	table.insert(extraGuis, g)
	return g
end

local ESPF = Instance.new("Folder")
ESPF.Name = "PDH_ESP"
ESPF.Parent = HUI
table.insert(extraGuis, ESPF)

local Ov = makeGui("PDH_OV", 40)

-- ===== LINE POOL =====
local linePool, lineUsed = {}, 0
local function line(a, b, col, thick)
	lineUsed += 1
	local f = linePool[lineUsed]
	if not f then
		f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BorderSizePixel = 0
		f.Parent = Ov
		linePool[lineUsed] = f
	end
	local d = b - a
	f.Visible = true
	f.BackgroundColor3 = col
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	f.Size = UDim2.fromOffset(math.max(d.Magnitude, 1), thick or 1.5)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
end

local function onScreen(pos)
	local v, vis = workspace.CurrentCamera:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), vis and v.Z > 0
end

-- ===== HUD =====
local Hud = Instance.new("TextLabel")
Hud.Position = UDim2.new(1, -16, 0.5, -60)
Hud.AnchorPoint = Vector2.new(1, 0)
Hud.Size = UDim2.fromOffset(0, 0)
Hud.AutomaticSize = Enum.AutomaticSize.XY
Hud.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
Hud.BackgroundTransparency = 0.15
Hud.Font = Enum.Font.Gotham
Hud.TextSize = 13
Hud.TextColor3 = Color3.new(1, 1, 1)
Hud.RichText = true
Hud.TextXAlignment = Enum.TextXAlignment.Left
Hud.TextYAlignment = Enum.TextYAlignment.Top
Hud.Active = true
local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = Hud
local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Color3.fromRGB(50, 50, 58)
hudStroke.Parent = Hud
local hudPad = Instance.new("UIPadding")
hudPad.Parent = Hud
hudPad.PaddingTop = UDim.new(0, 8)
hudPad.PaddingBottom = UDim.new(0, 8)
hudPad.PaddingLeft = UDim.new(0, 10)
hudPad.PaddingRight = UDim.new(0, 12)
do
	local drag, start, pos2
	Hud.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag, start, pos2 = true, i.Position, Hud.Position
		end
	end)
	game:GetService("UserInputService").InputChanged:Connect(function(i)
		if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - start
			Hud.Position = UDim2.new(pos2.X.Scale, pos2.X.Offset + d.X, pos2.Y.Scale, pos2.Y.Offset + d.Y)
		end
	end)
	game:GetService("UserInputService").InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
	end)
end

-- ===== QUEUE PANEL =====
local Queue = Instance.new("TextLabel")
Queue.Position = UDim2.new(0, 16, 0.5, -60)
Queue.Size = UDim2.fromOffset(0, 0)
Queue.AutomaticSize = Enum.AutomaticSize.XY
Queue.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
Queue.BackgroundTransparency = 0.15
Queue.Font = Enum.Font.Gotham
Queue.TextSize = 13
Queue.TextColor3 = Color3.new(1, 1, 1)
Queue.RichText = true
Queue.TextXAlignment = Enum.TextXAlignment.Left
Queue.TextYAlignment = Enum.TextYAlignment.Top
Queue.Active = true
Queue.Visible = false
local qCorner = Instance.new("UICorner")
qCorner.CornerRadius = UDim.new(0, 8)
qCorner.Parent = Queue
local qStroke = Instance.new("UIStroke")
qStroke.Color = Color3.fromRGB(50, 50, 58)
qStroke.Parent = Queue
local qPad = Instance.new("UIPadding")
qPad.Parent = Queue
qPad.PaddingTop = UDim.new(0, 8)
qPad.PaddingBottom = UDim.new(0, 8)
qPad.PaddingLeft = UDim.new(0, 10)
qPad.PaddingRight = UDim.new(0, 12)

-- ===== WARN BANNER =====
local Warn = Instance.new("TextLabel")
Warn.AnchorPoint = Vector2.new(0.5, 0)
Warn.Position = UDim2.new(0.5, 0, 0, 110)
Warn.Size = UDim2.fromOffset(460, 34)
Warn.BackgroundTransparency = 1
Warn.Font = Enum.Font.GothamBold
Warn.TextSize = 22
Warn.TextColor3 = Color3.fromRGB(255, 74, 90)
Warn.TextStrokeTransparency = 0.3
Warn.Text = ""
Warn.Visible = false

-- Parent all to Hub's gui so they're cleaned up with the hub
local hubGui = Hub.Gui
Hud.Parent = hubGui
Queue.Parent = hubGui
Warn.Parent = hubGui

Hub.OnDestroy = function()
	alive = false
	for _, g in ipairs(extraGuis) do pcall(function() g:Destroy() end) end
end

-- ===== COLORS =====
local RED    = Color3.fromRGB(255, 74, 90)
local BLUE   = Color3.fromRGB(60, 141, 255)
local GREEN  = Color3.fromRGB(110, 235, 140)
local ORANGE = Color3.fromRGB(255, 150, 50)
local WHITE  = Color3.new(1, 1, 1)
local PURPLE = Color3.fromRGB(190, 120, 255)
local GREY   = Color3.fromRGB(150, 150, 150)
local CROSS  = { White = WHITE, Red = RED, Green = GREEN, Cyan = Color3.fromRGB(80, 220, 255), Yellow = Color3.fromRGB(245, 200, 70) }

-- ===== ESP =====
local esp = {}
local function tag(key, adornee, model, col, text, sz)
	local o = esp[key]
	if not o then
		o = {}
		if model then
			o.hl = Instance.new("Highlight")
			o.hl.FillTransparency = 0.8
			o.hl.OutlineTransparency = 0
			o.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			o.hl.Parent = ESPF
		end
		o.bb = Instance.new("BillboardGui")
		o.bb.Size = UDim2.fromOffset(200, 38)
		o.bb.StudsOffset = Vector3.new(0, model and 3.4 or 1.6, 0)
		o.bb.AlwaysOnTop = true
		o.bb.LightInfluence = 0
		o.bb.Parent = ESPF
		o.tx = Instance.new("TextLabel")
		o.tx.Size = UDim2.fromScale(1, 1)
		o.tx.BackgroundTransparency = 1
		o.tx.Font = Enum.Font.GothamBold
		o.tx.TextSize = sz or 13
		o.tx.TextStrokeTransparency = 0.4
		o.tx.RichText = true
		o.tx.Parent = o.bb
		esp[key] = o
	end
	o.seen = true
	if o.hl then
		o.hl.Enabled = F("Outline") or false
		o.hl.Adornee = model
		o.hl.FillColor = col
		o.hl.OutlineColor = col
	end
	o.bb.Adornee = adornee
	o.tx.TextColor3 = col
	o.tx.Text = text
end

-- ===== HELPERS =====
local function chars()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then t[#t + 1] = { c = p.Character, p = p } end
	end
	local bots = workspace:FindFirstChild("DodgeBots")
	for _, m in ipairs(bots and bots:GetChildren() or {}) do
		if m:IsA("Model") then t[#t + 1] = { c = m, bot = true } end
	end
	return t
end

local function teamCol(c)
	return c and c:GetAttribute("Team") == "Red" and RED or BLUE
end

local function hearts(c)
	local n = tonumber(c:GetAttribute("Lives")) or 0
	local mx = tonumber(c:GetAttribute("MaxLives")) or 3
	return string.rep("♥", math.max(n, 0)) .. string.rep("♡", math.max(mx - n, 0))
end

local function holderOf(ball)
	for _, w in ipairs(ball:GetChildren()) do
		if w:IsA("Weld") or w:IsA("WeldConstraint") or w:IsA("Motor6D") then
			for _, part in ipairs({ w.Part0, w.Part1 }) do
				local plr = part and part ~= ball and Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model"))
				if plr then return plr end
			end
		end
	end
end

local function threat()
	local w = warnGui and warnGui:FindFirstChild("Warning")
	local badge = w and w:FindFirstChild("Badge")
	if not (w and badge and w.Visible and badge.BackgroundTransparency < 0.4) then return nil end
	local scale = w:FindFirstChild("Approach") and w.Approach:FindFirstChild("Scale")
	local tti = scale and (scale.Scale - 1) / (warnGui:GetAttribute("ApproachGrow") or 0.7) * (warnGui:GetAttribute("Horizon") or 1) or 1
	local green = warnGui:GetAttribute("CatchColor") or Color3.fromHex("8cff3a")
	local c3 = badge.BackgroundColor3
	local canCatch = math.abs(c3.R - green.R) + math.abs(c3.G - green.G) + math.abs(c3.B - green.B) < 0.08
	return tti, canCatch
end

local function incomingBall()
	local r = myRoot()
	local f = workspace:FindFirstChild("DodgeBalls")
	local best, bd
	for _, b in ipairs(f and r and f:GetChildren() or {}) do
		local v = b:IsA("BasePart") and b.AssemblyLinearVelocity
		local to = v and r.Position - b.Position
		if v and v.Magnitude > 20 and to.Magnitude > 0.5 and not b:FindFirstChildWhichIsA("Weld") and v.Unit:Dot(to.Unit) > 0.6 and (not bd or to.Magnitude < bd) then
			best, bd = b, to.Magnitude
		end
	end
	return best
end

local rayP = RaycastParams.new()
rayP.FilterType = Enum.RaycastFilterType.Exclude

local function visible(root)
	local cam = workspace.CurrentCamera
	local ign = {}
	for _, e in ipairs(chars()) do ign[#ign + 1] = e.c end
	local f = workspace:FindFirstChild("DodgeBalls")
	if f then ign[#ign + 1] = f end
	for _ = 1, 6 do
		rayP.FilterDescendantsInstances = ign
		local hit = workspace:Raycast(cam.CFrame.Position, root.Position - cam.CFrame.Position, rayP)
		if not hit then return true end
		if hit.Instance.Transparency < 0.9 then return false end
		ign[#ign + 1] = hit.Instance
	end
	return false
end

local function aimCenter()
	local cam = workspace.CurrentCamera
	if game:GetService("UserInputService").MouseBehavior == Enum.MouseBehavior.LockCenter then
		return cam.ViewportSize / 2
	end
	return game:GetService("UserInputService"):GetMouseLocation()
end

local function pickTarget()
	local r = myRoot()
	if not r then return nil end
	local team = la("Team")
	local ctr = aimCenter()
	local best, bestScore
	for _, e in ipairs(chars()) do
		local c = e.c
		local root = c:FindFirstChild("HumanoidRootPart")
		if root and (F("Aim Bots") or not e.bot) and c ~= myChar() and c:GetAttribute("InMatch") and not isOut(c) and c:GetAttribute("Team") ~= nil and c:GetAttribute("Team") ~= team and not c:GetAttribute("InPrison") then
			local sp, on = onScreen(root.Position)
			local px = (sp - ctr).Magnitude
			if on and px <= (F("Aim FOV") or 300) and (not F("Visible Only") or visible(root)) then
				local score
				if F("Aim Priority") == "Closest to me" then
					score = (root.Position - r.Position).Magnitude
				elseif F("Aim Priority") == "Fewest lives" then
					score = (tonumber(c:GetAttribute("Lives")) or 9) * 1000 + px
				elseif F("Aim Priority") == "Holding a ball" then
					score = (c:GetAttribute("HasBall") and 0 or 1000) + px
				else
					score = px
				end
				if not bestScore or score < bestScore then best, bestScore = c, score end
			end
		end
	end
	return best
end

local function jailedMate()
	local r, team = myRoot(), la("Team")
	local best, bd
	for _, e in ipairs(chars()) do
		local c = e.c
		local root = c:FindFirstChild("HumanoidRootPart")
		if root and c ~= myChar() and c:GetAttribute("InPrison") and c:GetAttribute("InMatch") and not isOut(c) and c:GetAttribute("Team") == team and not c:GetAttribute("HasBall") then
			local d = (root.Position - r.Position).Magnitude
			if not bd or d < bd then best, bd = c, d end
		end
	end
	return best
end

local function throwKey()
	local k = tostring(la("SettingKeyThrow") or "MouseButton1")
	if k:find("^MouseButton") then
		local m = game:GetService("UserInputService"):GetMouseLocation()
		VIM:SendMouseButtonEvent(m.X, m.Y, k == "MouseButton2" and 1 or 0, true, game, 0)
		task.wait(0.03 + math.random() * 0.03)
		VIM:SendMouseButtonEvent(m.X, m.Y, k == "MouseButton2" and 1 or 0, false, game, 0)
	else
		press("SettingKeyThrow", "F")
	end
end

-- ===== FPS BOOST =====
local function fpsBoost(on)
	if on and not fpsWas then
		fpsWas = {
			Potato = la("SettingPotato") == true,
			LiteLighting = la("SettingLiteLighting") == true,
			OthersFX = la("SettingOthersFX") ~= false,
		}
	end
	local want = on and { Potato = true, LiteLighting = true, OthersFX = false } or fpsWas
	if not want then return end
	for k, v in pairs(want) do
		if la("Setting" .. k) ~= v then
			LP:SetAttribute("Setting" .. k, v)
			if Action then Action:FireServer("Setting", k, v) end
		end
	end
	if not on then fpsWas = nil end
end

-- ===== STAFF =====
local function newServer()
	local ok, body = pcall(game.HttpGet, game, "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
	local ok2, t = pcall(Http.JSONDecode, Http, ok and body or "")
	local list = {}
	for _, sv in ipairs(ok2 and type(t) == "table" and t.data or {}) do
		if sv.id ~= game.JobId and (sv.playing or 0) < (sv.maxPlayers or 0) - 1 then
			list[#list + 1] = sv.id
		end
	end
	return #list > 0 and list[math.random(#list)] or nil
end

local function staffRole(p)
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(p.GetRankInGroup, p, game.CreatorId)
		if ok and rank and rank > 1 then
			local ok2, role = pcall(p.GetRoleInGroup, p, game.CreatorId)
			return ok2 and role or ("rank " .. rank)
		end
	elseif p.UserId == game.CreatorId then
		return "game owner"
	end
end

local function checkStaff(p)
	if p == LP or staffSeen[p] or not F("Staff Detector") then return end
	local role = staffRole(p)
	if not role then return end
	staffSeen[p] = true
	Hub:Notify("Staff in your server", p.DisplayName .. " · " .. role, 6)
	local action = F("Staff Action") or "Just warn"
	if action == "Pause assists" then
		paused = true
	elseif action == "Join a new server" then
		paused = true
		local TP = game:GetService("TeleportService")
		local id = newServer()
		if not (id and pcall(TP.TeleportToPlaceInstance, TP, game.PlaceId, id, LP)) then
			pcall(TP.Teleport, TP, game.PlaceId, LP)
		end
	elseif action == "Leave the game" then
		LP:Kick("Left: staff member in the server (" .. p.DisplayName .. ", " .. role .. ")")
	end
end

-- ===== CRATES =====
local CRATES = { ["Ball skins"] = "Crate_Skin", Trails = "Crate_Throw", ["Death FX"] = "Crate_Death", Abilities = "Crate_Ability" }
local PROMPT = { ["1x"] = "OpenPrompt", ["3x"] = "Open3Prompt", ["10x"] = "Open10Prompt" }

if CrateR then
	CrateR.OnClientEvent:Connect(function(k, t)
		if k == "Opened" and type(t) == "table" then
			crateN += 1
			if t.rarity == "Legendary" or t.rarity == "Mythic" then
				Hub:Notify("Crate", t.rarity .. " pull!", 4)
			end
		end
	end)
end

local function cratePrompt()
	local lobby = workspace:FindFirstChild("PrisonDodgeballMap") and workspace.PrisonDodgeballMap:FindFirstChild("Lobby")
	local crates = lobby and lobby:FindFirstChild("Crates")
	local m = crates and crates:FindFirstChild(CRATES[F("Crate Type") or "Ball skins"] or "")
	return m and m:FindFirstChild(PROMPT[F("Crate Count") or "1x"] or "OpenPrompt", true)
end

local function OpenCrate(loud)
	local pr, r = cratePrompt(), myRoot()
	if not (pr and r) then
		if loud then Hub:Notify("Crate", "Crate not found", 3) end
		return false
	end
	if la("InMatch") or la("Rolling") then
		if loud then Hub:Notify("Crate", "Only in lobby, after last roll", 3) end
		return false
	end
	local price = tonumber(pr:GetAttribute("Price")) or math.huge
	local reserve = tonumber(F("Coin Reserve")) or 0
	if (la("Coins") or 0) - price < (loud and 0 or reserve) then
		if loud then Hub:Notify("Crate", "Not enough coins", 3) end
		return false
	end
	local spot = pr.Parent:IsA("Attachment") and pr.Parent.WorldPosition or pr.Parent.Position
	local back = r.CFrame
	local dir = (r.Position - spot) * Vector3.new(1, 0, 1)
	dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, 1)
	r.CFrame = CFrame.lookAt(spot + dir * 5 + Vector3.new(0, 1, 0), spot)
	task.wait(0.35)
	local before = crateN
	fireproximityprompt(pr)
	local t0 = os.clock()
	while crateN == before and os.clock() - t0 < 4 do task.wait(0.1) end
	task.wait(0.2)
	r.CFrame = back
	t0 = os.clock()
	while la("Rolling") and os.clock() - t0 < 15 do task.wait(0.25) end
	if la("Rolling") and CrateR then CrateR:FireServer("Done") end
	return crateN > before
end

-- ===== CLAIM REWARDS =====
local lastPassXP = nil
local function Claim()
	if not Progress then return end
	if F("Auto Daily") and la("DailyClaimed") == false then
		local ok = Progress:InvokeServer("ClaimDaily")
		if ok then Hub:Notify("Daily reward", "Claimed day " .. tostring(la("DailyDay")), 4) end
	end
	if F("Auto Quests") then
		local q = json(la("QuestsJSON")) or {}
		for _, list in ipairs({ q.daily or {}, q.weekly or {} }) do
			for _, it in ipairs(list) do
				if not it.claimed and (tonumber(it.prog) or 0) >= (tonumber(it.goal) or 1) then
					local ok = Progress:InvokeServer("ClaimQuest", it.id)
					if ok then Hub:Notify("Quest", "Claimed: " .. tostring(it.text), 3) end
					task.wait(0.5)
				end
			end
		end
	end
	local pass = json(la("PassJSON")) or {}
	if F("Auto Season Pass") and pass.xp and pass.xp ~= lastPassXP then
		lastPassXP = pass.xp
		Progress:InvokeServer("ClaimPassAll")
	end
end

-- ===== ELEMENTS =====
local Elements = {}

-- MATCH TAB
table.insert(Elements, { Type = "Section", Name = "Reactions", Tab = "Match" })
table.insert(Elements, { Type = "Toggle", Name = "Auto Catch", Tab = "Match", Desc = "Presses your catch key when a ball is about to hit you.", Default = false })
table.insert(Elements, { Type = "Toggle", Name = "Auto Dodge", Tab = "Match", Desc = "Presses your dodge key at the last moment when you can't catch.", Default = false })
table.insert(Elements, { Type = "Dropdown", Name = "Catch Mode", Tab = "Match", Desc = "When to prefer catching vs dodging.", Options = { "Catch, else dodge", "Catch only", "Dodge only" }, Default = "Catch, else dodge" })
table.insert(Elements, { Type = "Slider", Name = "Miss Rate", Tab = "Match", Desc = "Lets this % of balls through on purpose.", Min = 0, Max = 40, Default = 5, Decimals = 0 })
table.insert(Elements, { Type = "Toggle", Name = "Face Ball", Tab = "Match", Desc = "Turns toward the ball before catching (widens the 120 catch angle).", Default = true })
table.insert(Elements, { Type = "Slider", Name = "Catch Timing", Tab = "Match", Desc = "0 = early and safe, 100 = late and risky.", Min = 0, Max = 100, Default = 50, Decimals = 0 })
table.insert(Elements, { Type = "Section", Name = "Ability", Tab = "Match" })
table.insert(Elements, { Type = "Toggle", Name = "Auto Ability", Tab = "Match", Desc = "Uses your ability as soon as it is off cooldown.", Default = false })
table.insert(Elements, { Type = "Dropdown", Name = "Ability When", Tab = "Match", Options = { "Ball coming", "When ready" }, Default = "Ball coming" })
table.insert(Elements, { Type = "Section", Name = "Prison", Tab = "Match" })
table.insert(Elements, { Type = "Toggle", Name = "Auto Break Out", Tab = "Match", Desc = "Uses the game free break out or a saved token. Never the Robux one.", Default = false })
table.insert(Elements, { Type = "Toggle", Name = "Auto Rejoin", Tab = "Match", Desc = "Joins the next match if you got sat out.", Default = false })
table.insert(Elements, { Type = "Toggle", Name = "Call Pass", Tab = "Match", Desc = "While jailed and a teammate holds a ball, calls for the pass.", Default = false })
table.insert(Elements, { Type = "Toggle", Name = "Release Order", Tab = "Match", Desc = "Everyone in prison, sorted by release time. Drag anywhere.", Default = false })

-- AIM TAB
table.insert(Elements, { Type = "Section", Name = "Targeting", Tab = "Aim" })
table.insert(Elements, { Type = "Toggle", Name = "Silent Aim", Tab = "Aim", Desc = "Throws go to the best enemy inside the circle, via the game lock-on.", Default = false })
table.insert(Elements, { Type = "Dropdown", Name = "Aim Mode", Tab = "Aim", Options = { "Always", "Hold right mouse" }, Default = "Always" })
table.insert(Elements, { Type = "Dropdown", Name = "Aim Priority", Tab = "Aim", Desc = "Which enemy wins when several are in the circle.", Options = { "Closest to crosshair", "Closest to me", "Fewest lives", "Holding a ball" }, Default = "Closest to crosshair" })
table.insert(Elements, { Type = "Toggle", Name = "Aim Bots", Tab = "Aim", Desc = "Include AI bots in aim targets.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Visible Only", Tab = "Aim", Desc = "Skip enemies behind walls.", Default = false })
table.insert(Elements, { Type = "Slider", Name = "Aim FOV", Tab = "Aim", Desc = "Circle radius in pixels. Only enemies inside count.", Min = 40, Max = 600, Default = 300, Decimals = 0 })
table.insert(Elements, { Type = "Toggle", Name = "Show Circle", Tab = "Aim", Desc = "Draws the aim circle. Red when it has a target.", Default = true })
table.insert(Elements, { Type = "Section", Name = "Camera", Tab = "Aim" })
table.insert(Elements, { Type = "Toggle", Name = "Camera Aim", Tab = "Aim", Desc = "Turns your camera toward the target while you hold a ball.", Default = false })
table.insert(Elements, { Type = "Slider", Name = "Cam Smooth", Tab = "Aim", Desc = "Higher = slower camera turning.", Min = 0, Max = 95, Default = 70, Decimals = 0 })
table.insert(Elements, { Type = "Section", Name = "Throwing", Tab = "Aim" })
table.insert(Elements, { Type = "Toggle", Name = "Auto Throw", Tab = "Aim", Desc = "Throws as soon as you hold a ball and have a target.", Default = false })
table.insert(Elements, { Type = "Slider", Name = "Throw Delay", Tab = "Aim", Desc = "Milliseconds to wait before auto throw.", Min = 0, Max = 600, Default = 150, Decimals = 0 })
table.insert(Elements, { Type = "Toggle", Name = "Rescue Pass", Tab = "Aim", Desc = "Holding a ball and a teammate is jailed: passes it to them.", Default = false })
table.insert(Elements, { Type = "Toggle", Name = "Prison Throw", Tab = "Aim", Desc = "In prison with a ball: aims and throws at an enemy.", Default = false })

-- VISUALS TAB
table.insert(Elements, { Type = "Section", Name = "ESP", Tab = "Visuals" })
table.insert(Elements, { Type = "Toggle", Name = "Ball ESP", Tab = "Visuals", Desc = "Tags every ball: who holds it, loose, or in flight.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Enemy ESP", Tab = "Visuals", Desc = "Enemy tags: lives, ball, prison status, ability cooldown.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Team ESP", Tab = "Visuals", Desc = "Teammate tags including prison timer.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Bot ESP", Tab = "Visuals", Desc = "AI bots in purple with a BOT tag.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Tracers", Tab = "Visuals", Desc = "Lines from your screen to every enemy.", Default = false })
table.insert(Elements, { Type = "Slider", Name = "ESP Distance", Tab = "Visuals", Desc = "Nobody further gets a tag.", Min = 50, Max = 600, Default = 250, Decimals = 0 })
table.insert(Elements, { Type = "Toggle", Name = "Outline", Tab = "Visuals", Desc = "Highlight outline through walls.", Default = true })
table.insert(Elements, { Type = "Section", Name = "Warnings", Tab = "Visuals" })
table.insert(Elements, { Type = "Toggle", Name = "Aim Warning", Tab = "Visuals", Desc = "Warning when an enemy holding a ball faces you.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Incoming Ball", Tab = "Visuals", Desc = "BALL INCOMING banner with seconds left.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Ball Path", Tab = "Visuals", Desc = "Shows where thrown balls are heading. Red when aimed at you.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Match Panel", Tab = "Visuals", Desc = "Score, round, time, your stats. Drag anywhere.", Default = true })

-- SCREEN TAB
table.insert(Elements, { Type = "Section", Name = "Crosshair", Tab = "Screen" })
table.insert(Elements, { Type = "Toggle", Name = "Crosshair", Tab = "Screen", Default = false })
table.insert(Elements, { Type = "Slider", Name = "Cross Size", Tab = "Screen", Min = 4, Max = 30, Default = 9, Decimals = 0 })
table.insert(Elements, { Type = "Dropdown", Name = "Cross Color", Tab = "Screen", Options = { "White", "Red", "Green", "Cyan", "Yellow" }, Default = "White" })
table.insert(Elements, { Type = "Section", Name = "View", Tab = "Screen" })
table.insert(Elements, {
	Type = "Toggle", Name = "Custom FOV", Tab = "Screen", Desc = "Wider or narrower view.", Default = false,
	Off = function() workspace.CurrentCamera.FieldOfView = 70 end,
})
table.insert(Elements, {
	Type = "Slider", Name = "Field of View", Tab = "Screen", Min = 50, Max = 120, Default = 70, Decimals = 0,
	Callback = function(v) if F("Custom FOV") then workspace.CurrentCamera.FieldOfView = v end end,
})
table.insert(Elements, {
	Type = "Toggle", Name = "Fullbright", Tab = "Screen", Desc = "Lights up the whole map.", Default = false,
	On = function()
		litWas = {
			Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
			Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
		}
		Lighting.Ambient = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.Brightness = 2
		Lighting.FogEnd = 1000000
		Lighting.GlobalShadows = false
	end,
	Off = function()
		if litWas then
			for k, v in pairs(litWas) do Lighting[k] = v end
			litWas = nil
		end
	end,
})

-- REWARDS TAB
table.insert(Elements, { Type = "Section", Name = "Rewards", Tab = "Rewards" })
table.insert(Elements, { Type = "Toggle", Name = "Auto Daily", Tab = "Rewards", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Auto Quests", Tab = "Rewards", Desc = "Claims daily and weekly quests the moment they complete.", Default = true })
table.insert(Elements, { Type = "Toggle", Name = "Auto Season Pass", Tab = "Rewards", Desc = "Claims all free tier rewards.", Default = true })
table.insert(Elements, { Type = "Button", Name = "Claim Now", Tab = "Rewards", Desc = "Runs all three right away.", Callback = function() task.spawn(Claim) Hub:Notify("Rewards", "Claiming...", 2) end })
table.insert(Elements, { Type = "Section", Name = "Crates", Tab = "Rewards" })
table.insert(Elements, { Type = "Toggle", Name = "Auto Crates", Tab = "Rewards", Desc = "Steps to the crate, opens it with coins, steps back. Never Robux.", Default = false })
table.insert(Elements, { Type = "Dropdown", Name = "Crate Type", Tab = "Rewards", Options = { "Ball skins", "Trails", "Death FX", "Abilities" }, Default = "Ball skins" })
table.insert(Elements, { Type = "Dropdown", Name = "Crate Count", Tab = "Rewards", Options = { "1x", "3x", "10x" }, Default = "1x" })
table.insert(Elements, { Type = "Slider", Name = "Coin Reserve", Tab = "Rewards", Desc = "Stop auto crates before coins drop below this.", Min = 0, Max = 20000, Default = 1000, Decimals = 0 })
table.insert(Elements, { Type = "Button", Name = "Open Crate Now", Tab = "Rewards", Desc = "Opens selected crate once (need to be in lobby).", Callback = function() task.spawn(OpenCrate, true) end })

-- EXTRAS TAB
table.insert(Elements, { Type = "Section", Name = "Performance", Tab = "Extras" })
table.insert(Elements, {
	Type = "Toggle", Name = "FPS Boost", Tab = "Extras",
	Desc = "Game own Potato graphics + hides other players effects.",
	On = function() fpsBoost(true) end,
	Off = function() fpsBoost(false) end,
	Default = false,
})
table.insert(Elements, {
	Type = "Toggle", Name = "Anti AFK", Tab = "Extras",
	Desc = "Stops the idle kick.",
	Default = true,
	On = function()
		Store.afkConn = LP.Idled:Connect(function()
			local VU = game:GetService("VirtualUser")
			VU:CaptureController()
			VU:ClickButton2(Vector2.new())
		end)
	end,
	Off = function()
		if Store.afkConn then Store.afkConn:Disconnect() Store.afkConn = nil end
	end,
})
table.insert(Elements, { Type = "Section", Name = "Staff", Tab = "Extras" })
table.insert(Elements, { Type = "Toggle", Name = "Staff Detector", Tab = "Extras", Desc = "Warns when group staff is in your server.", Default = true })
table.insert(Elements, { Type = "Dropdown", Name = "Staff Action", Tab = "Extras", Options = { "Just warn", "Pause assists", "Join a new server", "Leave the game" }, Default = "Just warn" })

-- ===== BUILD =====
Hub:Build(Elements, { "Match", "Aim", "Visuals", "Screen", "Rewards", "Extras" })

-- ===== MOUSE TRACKING =====
UIS.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 then rmb = true end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 then rmb = false end
end)

-- ===== F6 PAUSE =====
game:GetService("UserInputService").InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.F6 then
		paused = not paused
		Hub:Notify("Prison Dodgeball Hub", paused and "Paused every assist (F6 to resume)" or "Assists back on", 3)
	end
end)

-- ===== AUTO CATCH / DODGE (RenderStepped) =====
RunService.RenderStepped:Connect(function()
	if busy or paused or not playing() or la("InPrison") or isOut(myChar()) then cur = nil return end
	local tti, canCatch = threat()
	if not tti then cur = nil return end
	if not cur then
		local win = (myChar() and myChar():GetAttribute("CatchWin")) or 0.42
		local at = math.clamp(0.8 - (F("Catch Timing") or 50) / 100 * 0.6 + (math.random() - 0.5) * 0.2, 0.1, 0.95)
		cur = { catchAt = win * at, dodgeAt = 0.16 + math.random() * 0.1, miss = math.random(100) <= (F("Miss Rate") or 5), done = false }
	end
	if cur.done or cur.miss then return end
	local mode = F("Catch Mode") or "Catch, else dodge"
	local catchOk = F("Auto Catch") and mode ~= "Dodge only" and canCatch
	local dodgeOk = F("Auto Dodge") and mode ~= "Catch only" and now() >= (la("DashReadyAt") or 0) and (mode == "Dodge only" or not canCatch or not F("Auto Catch"))
	if catchOk and tti <= cur.catchAt then
		cur.done = true
		busy = true
		why = "catching"
		task.spawn(function()
			if F("Face Ball") then
				local b = incomingBall()
				local r = myRoot()
				if b and r then
					local look = CFrame.lookAt(r.Position, Vector3.new(b.Position.X, r.Position.Y, b.Position.Z))
					r.CFrame = look
					local t0 = os.clock()
					local c2
					c2 = game:GetService("RunService").RenderStepped:Connect(function()
						if os.clock() - t0 > 0.35 or not r.Parent then c2:Disconnect()
						else r.CFrame = CFrame.new(r.Position) * look.Rotation end
					end)
				end
			end
			press("SettingKeyCatch", "F")
			busy = false
		end)
	elseif dodgeOk and tti <= cur.dodgeAt then
		cur.done = true
		busy = true
		why = "dodging"
		task.spawn(function() press("SettingKeyDodge", "Q") busy = false end)
	end
end)

-- ===== BACKGROUND LOOPS =====
task.spawn(function()
	while alive do
		task.wait(0.1)
		if not (F("Auto Ability") and not paused and playing() and not la("InPrison") and not isOut(myChar())) then continue end
		if now() >= (la("AbilityReadyAt") or 0) + 0.3 then
			if F("Ability When") == "Ball coming" and not threat() then continue end
			press("SettingKeyAbility", "E")
			task.wait(1)
		end
	end
end)

local brokeAt = nil
task.spawn(function()
	while alive do
		task.wait(0.5)
		if not (F("Auto Break Out") and not paused and Offer and playing() and la("InPrison") == true and DM:GetAttribute("Mode") == nil and not la("BreakOutLock")) then continue end
		local left = (la("PrisonFreeAt") or 0) - now()
		if left >= 6 and brokeAt ~= la("PrisonFreeAt") then
			brokeAt = la("PrisonFreeAt")
			task.wait(0.5 + math.random())
			Offer:FireServer("BreakOut")
			Hub:Notify("Prison", "Used the free break out", 3)
		end
	end
end)

task.spawn(function()
	while alive do
		task.wait(0.5)
		if not (F("Call Pass") and not paused and Action and playing() and la("InPrison") == true) then continue end
		local team = la("Team")
		for _, e in ipairs(chars()) do
			if e.c ~= myChar() and e.c:GetAttribute("Team") == team and e.c:GetAttribute("HasBall") and not e.c:GetAttribute("InPrison") then
				Action:FireServer("CallPass")
				task.wait(3 + math.random())
				break
			end
		end
	end
end)

task.spawn(function()
	while alive do
		task.wait(3)
		if F("Auto Rejoin") and not paused and Action and la("SitOut") == true and la("AfkMode") ~= true then
			Action:FireServer("JoinMatch")
		end
	end
end)

task.spawn(function()
	while alive do
		task.wait(20)
		if not paused then task.spawn(Claim) end
	end
end)

task.spawn(function()
	while alive do
		task.wait(1.5)
		if F("Auto Crates") and not paused then OpenCrate(false) end
	end
end)

Players.PlayerAdded:Connect(function(p) task.wait(1) checkStaff(p) end)
task.spawn(function()
	while alive do
		task.wait(10)
		for _, p in ipairs(Players:GetPlayers()) do checkStaff(p) end
	end
end)

-- ===== AIM LOOP (RenderStepped) =====
RunService.RenderStepped:Connect(function()
	local base = not paused and playing() and not isOut(myChar()) and la("HasBall") == true
	local jailed = la("InPrison") == true
	local tgt, isPass
	if base and F("Rescue Pass") and not jailed then
		tgt = jailedMate()
		isPass = tgt ~= nil
	end
	if base and not tgt and ((F("Silent Aim") and (F("Aim Mode") == "Always" or rmb)) or (jailed and F("Prison Throw"))) then
		tgt = pickTarget()
	end
	if LockV then
		if tgt then LockV.Value = tgt
		elseif aimT and LockV.Value == aimT then LockV.Value = nil end
	end
	aimT = tgt
	if tgt and not isPass and F("Camera Aim") then
		local hrp = tgt:FindFirstChild("HumanoidRootPart")
		local cam = workspace.CurrentCamera
		if hrp then
			cam.CFrame = cam.CFrame:Lerp(
				CFrame.lookAt(cam.CFrame.Position, hrp.Position + Vector3.new(0, 1, 0)),
				math.clamp(1 - (F("Cam Smooth") or 70) / 100, 0.03, 1)
			)
		end
	end
	local fire = tgt and (isPass or F("Auto Throw") or (jailed and F("Prison Throw")))
	if fire and not throwing and os.clock() - lastThrow > 0.8 then
		throwing = true
		task.spawn(function()
			task.wait((F("Throw Delay") or 150) / 1000 * (0.7 + math.random() * 0.6))
			if aimT == tgt and la("HasBall") == true then
				lastThrow = os.clock()
				why = isPass and "rescue pass" or "throwing"
				throwKey()
			end
			throwing = false
		end)
	end
end)

-- ===== ESP + OVERLAY + HUD (RenderStepped) =====
local espTracers = {}
RunService.RenderStepped:Connect(function()
	for _, o in pairs(esp) do o.seen = false end
	espTracers = {}

	local r = myRoot()
	local myTeam = la("Team")
	local cam = workspace.CurrentCamera
	local vp = cam.ViewportSize
	local aimer = nil

	local function distTo(pos)
		return r and math.floor((pos - r.Position).Magnitude) or 0
	end

	-- player/bot ESP
	for _, e in ipairs(chars()) do
		local c, p = e.c, e.p
		local root = c ~= myChar() and c:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		if not c:GetAttribute("InMatch") then continue end
		if isOut(c) then continue end
		if distTo(root.Position) > (F("ESP Distance") or 250) then continue end

		local mate = c:GetAttribute("Team") == myTeam
		local show = (e.bot and F("Bot ESP")) or (not e.bot and ((mate and F("Team ESP")) or (not mate and F("Enemy ESP"))))
		local jail = c:GetAttribute("InPrison") or (p and p:GetAttribute("InPrison"))

		if show then
			local bits = {}
			if c:GetAttribute("HasBall") then bits[#bits + 1] = "HAS BALL" end
			if c:GetAttribute("LastStanding") then bits[#bits + 1] = "LAST STANDING" end
			if jail then
				local free = tonumber((p and p:GetAttribute("PrisonFreeAt")) or c:GetAttribute("PrisonFreeAt"))
				bits[#bits + 1] = free and string.format("PRISON %ds", math.max(0, math.floor(free - now()))) or "PRISON"
			end
			if not e.bot then
				local cd = (tonumber(c:GetAttribute("AbilityReadyAt")) or 0) - now()
				bits[#bits + 1] = cd > 0 and string.format("ability %ds", math.ceil(cd)) or "ability ready"
			end
			local col = jail and GREY or (e.bot and PURPLE) or teamCol(c)
			local name = e.bot and ("BOT · " .. c.Name .. (mate and " (team)" or "")) or p.DisplayName
			local subline = (#bits > 0 and table.concat(bits, " · ") or "") .. " · " .. distTo(root.Position)
			tag(c, root, c, col, string.format("%s  %s\n<font size=\"11\">%s</font>", name, hearts(c), subline))
			if not mate and not jail then espTracers[#espTracers + 1] = { root.Position, col } end
		end

		-- aim warning check
		if r and not mate and c:GetAttribute("HasBall") and not jail then
			local to = r.Position - root.Position
			local d = to.Magnitude
			if d < 90 and root.CFrame.LookVector:Dot(to.Unit) > 0.94 then
				if not aimer or d < aimer[2] then
					aimer = { e.bot and ("BOT " .. c.Name) or p.DisplayName, d }
				end
			end
		end
	end

	-- ball ESP
	if F("Ball ESP") then
		local bf = workspace:FindFirstChild("DodgeBalls")
		for _, b in ipairs(bf and bf:GetChildren() or {}) do
			if b:IsA("BasePart") then
				local who = holderOf(b)
				local speed = b.AssemblyLinearVelocity.Magnitude
				if who then
					if who ~= LP then
						tag(b, b, nil, teamCol(who.Character), string.format("ball · %s", who.DisplayName), 11)
					end
				elseif speed > 25 and not b.Anchored then
					tag(b, b, nil, ORANGE, string.format("BALL IN FLIGHT · %d", distTo(b.Position)), 13)
				else
					tag(b, b, nil, WHITE, string.format("LOOSE BALL · %d", distTo(b.Position)), 13)
				end
			end
		end
	end

	-- purge stale ESP
	for key, o in pairs(esp) do
		if not o.seen or (typeof(key) == "Instance" and not key.Parent) then
			if o.hl then o.hl:Destroy() end
			o.bb:Destroy()
			esp[key] = nil
		end
	end

	-- warn banner
	local tti = F("Incoming Ball") and playing() and not la("InPrison") and threat()
	if tti then
		Warn.Visible = true
		Warn.TextColor3 = ORANGE
		Warn.Text = string.format("BALL INCOMING · %.1fs", math.max(tti, 0))
	elseif F("Aim Warning") and aimer and playing() and not la("InPrison") then
		Warn.Visible = true
		Warn.TextColor3 = RED
		Warn.Text = string.format("%s IS AIMING AT YOU · %d", aimer[1]:upper(), math.floor(aimer[2]))
	else
		Warn.Visible = false
	end

	-- overlay lines
	lineUsed = 0

	if F("Tracers") then
		for _, t in ipairs(espTracers) do
			local pp, vis = onScreen(t[1])
			if vis then line(Vector2.new(vp.X / 2, vp.Y - 2), pp, t[2], 1.2) end
		end
	end

	if F("Ball Path") then
		local bf2 = workspace:FindFirstChild("DodgeBalls")
		for _, b in ipairs(bf2 and bf2:GetChildren() or {}) do
			local v = b:IsA("BasePart") and b.AssemblyLinearVelocity
			if v and v.Magnitude > 25 and not b:FindFirstChildWhichIsA("Weld") then
				local col = ORANGE
				if r and (r.Position - b.Position).Magnitude > 1 and v.Unit:Dot((r.Position - b.Position).Unit) > 0.85 then
					col = RED
				end
				local lp2, lv = onScreen(b.Position)
				for i = 1, 6 do
					local np2, nv = onScreen(b.Position + v * (i * 0.08))
					if nv and lv then line(lp2, np2, col, 2.5) end
					lp2, lv = np2, nv
				end
			end
		end
	end

	if F("Crosshair") then
		local c2 = vp / 2
		local n = F("Cross Size") or 9
		local col = CROSS[F("Cross Color") or "White"] or WHITE
		line(c2 - Vector2.new(n, 0), c2 - Vector2.new(3, 0), col, 2)
		line(c2 + Vector2.new(3, 0), c2 + Vector2.new(n, 0), col, 2)
		line(c2 - Vector2.new(0, n), c2 - Vector2.new(0, 3), col, 2)
		line(c2 + Vector2.new(0, 3), c2 + Vector2.new(0, n), col, 2)
	end

	if F("Silent Aim") and F("Show Circle") then
		local ctr = aimCenter()
		local rad = F("Aim FOV") or 300
		local col2 = aimT and RED or WHITE
		local nn = 40
		local last3 = ctr + Vector2.new(rad, 0)
		for i = 1, nn do
			local a = i / nn * math.pi * 2
			local np3 = ctr + Vector2.new(math.cos(a) * rad, math.sin(a) * rad)
			line(last3, np3, col2, 1.2)
			last3 = np3
		end
	end

	if F("Custom FOV") then cam.FieldOfView = F("Field of View") or 70 end

	for i = lineUsed + 1, #linePool do linePool[i].Visible = false end
end)

-- ===== HUD LOOP =====
task.spawn(function()
	while alive do
		task.wait(0.5)
		Hud.Visible = F("Match Panel") or false
		if not Hud.Visible then continue end
		local lines = {
			string.format("<b>Prison Dodgeball Hub</b>%s", paused and "  <font color=\"#ff4a5a\">PAUSED (F6)</font>" or ""),
		}
		if la("InMatch") then
			local tl = tonumber(DM:GetAttribute("TimeLeft")) or 0
			lines[#lines + 1] = string.format(
				"<font color=\"#ff4a5a\">RED %s</font> – <font color=\"#3c8dff\">%s BLUE</font> · round %s · %d:%02d",
				tostring(DM:GetAttribute("RedScore") or 0),
				tostring(DM:GetAttribute("BlueScore") or 0),
				tostring(DM:GetAttribute("Round") or "?"),
				tl // 60, tl % 60
			)
			lines[#lines + 1] = string.format(
				"Alive: red %s/%s · blue %s/%s",
				tostring(DM:GetAttribute("RedAlive") or "?"), tostring(DM:GetAttribute("RedTotal") or "?"),
				tostring(DM:GetAttribute("BlueAlive") or "?"), tostring(DM:GetAttribute("BlueTotal") or "?")
			)
			local c = myChar()
			lines[#lines + 1] = string.format(
				"You (%s): %s · %s outs · %s catches",
				tostring(la("Team") or "?"), tostring(la("Lives") or "?"),
				tostring(c and c:GetAttribute("MatchOuts") or la("MatchOuts") or 0),
				tostring(c and c:GetAttribute("MatchCatches") or la("MatchCatches") or 0)
			)
			if la("InPrison") then
				local left = (la("PrisonFreeAt") or now()) - now()
				lines[#lines + 1] = string.format("<font color=\"#f5c846\">In prison · free in %ds</font>", math.max(0, math.floor(left)))
			end
		else
			lines[#lines + 1] = string.format(
				"Lobby · %s · countdown %ss",
				tostring(DM:GetAttribute("Phase") or "—"),
				tostring(DM:GetAttribute("Countdown") or "?")
			)
		end
		local q = json(la("QuestsJSON")) or {}
		for _, it in ipairs(q.daily or {}) do
			if not it.claimed then
				lines[#lines + 1] = string.format("· %s %d/%d", tostring(it.text):lower(), tonumber(it.prog) or 0, tonumber(it.goal) or 0)
			end
		end
		lines[#lines + 1] = "doing: " .. why
		Hud.Text = table.concat(lines, "\n")
	end
end)

-- ===== RELEASE ORDER LOOP =====
task.spawn(function()
	while alive do
		task.wait(0.25)
		local list = {}
		if F("Release Order") and la("InMatch") then
			for _, e in ipairs(chars()) do
				local c = e.c
				local inPrison = c:GetAttribute("InPrison") or (e.p and e.p:GetAttribute("InPrison"))
				if inPrison and not isOut(c) then
					local free = tonumber((e.p and e.p:GetAttribute("PrisonFreeAt")) or c:GetAttribute("PrisonFreeAt"))
					list[#list + 1] = {
						name = e.bot and ("BOT " .. c.Name) or e.p.DisplayName,
						team = c:GetAttribute("Team"),
						left = free and free - now() or math.huge,
						me = c == myChar(),
					}
				end
			end
			table.sort(list, function(a, b) return a.left < b.left end)
		end
		Queue.Visible = #list > 0
		if #list == 0 then continue end
		local qlines = { "<b>Release order</b>" }
		for i, q2 in ipairs(list) do
			local hex = q2.team == "Red" and "#ff4a5a" or "#3c8dff"
			local timeStr = q2.left == math.huge and "?" or (math.max(0, math.floor(q2.left)) .. "s")
			qlines[#qlines + 1] = string.format(
				"%d. <font color=\"%s\">%s</font>%s · %s",
				i, hex, q2.name, q2.me and " (you)" or "", timeStr
			)
		end
		Queue.Text = table.concat(qlines, "\n")
	end
end)

-- ===== WHY TRACKER =====
task.spawn(function()
	while alive do
		task.wait(1)
		if why ~= "idle" and why ~= "watching" and not busy then
			task.wait(1.5)
			why = playing() and "watching" or "idle"
		end
	end
end)

print("[Prison Dodgeball Hub] by Stizzyyy · always free & keyless")