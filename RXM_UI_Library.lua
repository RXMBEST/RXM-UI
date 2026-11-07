-- RXM UI OPEN SOURCE --
local function svc(name)
	local service = game:GetService(name)
	if cloneref then
		local ok, cloned = pcall(cloneref, service)
		if ok and cloned then
			return cloned
		end
	end
	return service
end
local Players = svc("Players")
local TweenService = svc("TweenService")
local UserInputService = svc("UserInputService")
local RunService = svc("RunService")
local CoreGui = svc("CoreGui")
local HttpService = svc("HttpService")
local ContentProvider = svc("ContentProvider")
local TextService = svc("TextService")
local LocalPlayer = Players.LocalPlayer
local ES, ED = Enum.EasingStyle, Enum.EasingDirection
local isTouch = UserInputService.TouchEnabled
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local GLOW = "rbxassetid://5028857484"
local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local genv = (getgenv and getgenv()) or _G
local Library = {
	Version = "2.1.0",
	Transparency = 0.2,
	Flags = {},
	Windows = {},
	Intros = {},
	IntroStyles = {},
	ActiveIntro = "Default",
	Presets = {
		Monochrome = Color3.fromRGB(235, 235, 235),
		Crimson = Color3.fromRGB(240, 56, 76),
		Ocean = Color3.fromRGB(58, 160, 255),
		Violet = Color3.fromRGB(150, 104, 255),
		Emerald = Color3.fromRGB(46, 214, 140),
		Sunset = Color3.fromRGB(255, 132, 60),
		Sakura = Color3.fromRGB(255, 122, 172),
		Gold = Color3.fromRGB(255, 200, 64),
	},
	_intros = {},
}
if genv.RXM_UI_LIBRARY and type(genv.RXM_UI_LIBRARY.Unload) == "function" then
	pcall(genv.RXM_UI_LIBRARY.Unload, genv.RXM_UI_LIBRARY)
end
genv.RXM_UI_LIBRARY = Library
local fontTrack
local TEXT_CLASSES = {TextLabel = true, TextButton = true, TextBox = true}
local function new(class, props)
	local inst = Instance.new(class)
	local parent
	if props then
		for key, value in pairs(props) do
			if key == "Parent" then
				parent = value
			else
				inst[key] = value
			end
		end
	end
	if parent then
		inst.Parent = parent
	end
	if fontTrack and TEXT_CLASSES[class] then
		fontTrack(inst)
	end
	return inst
end
local function corner(inst, radius)
	return new("UICorner", {CornerRadius = UDim.new(0, radius), Parent = inst})
end
local function round(inst)
	return new("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = inst})
end
local function stroke(inst, color, thickness, transparency)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
end
local function tween(inst, time, props, style, direction, delay)
	local info = TweenInfo.new(time, style or ES.Quint, direction or ED.Out, 0, false, delay or 0)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end
local function kp(t, v)
	return NumberSequenceKeypoint.new(t, v)
end
local function ck(t, c)
	return ColorSequenceKeypoint.new(t, c)
end
local function lighten(c, a)
	return c:Lerp(WHITE, a)
end
local function darken(c, a)
	return c:Lerp(BLACK, a)
end
local function luminance(c)
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end
local function onColor(c)
	if luminance(c) > 0.62 then
		return Color3.fromRGB(18, 18, 18)
	end
	return WHITE
end
local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end
local function viewportSize()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end
local function copy(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = copy(v)
	end
	return out
end
local function merge(dst, src)
	for k, v in pairs(src) do
		if k == "Colors" then
			if type(v) == "table" then
				dst.Colors = dst.Colors or {}
				for ck2, cv in pairs(v) do
					dst.Colors[ck2] = cv
				end
			elseif v == false then
				dst.Colors = {}
			end
		else
			dst[k] = v
		end
	end
	return dst
end
local function mountGui(gui)
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	end
	local parents = {}
	if gethui then
		table.insert(parents, function()
			return gethui()
		end)
	end
	table.insert(parents, function()
		return CoreGui
	end)
	table.insert(parents, function()
		return LocalPlayer:WaitForChild("PlayerGui")
	end)
	for _, getParent in ipairs(parents) do
		local ok = pcall(function()
			gui.Parent = getParent()
		end)
		if ok and gui.Parent ~= nil then
			return true
		end
	end
	return false
end
local function newSpring(value, k, ratio)
	return {x = value, v = 0, t = value, k = k, d = 2 * ratio * math.sqrt(k)}
end
local function tuneSpring(s, k, ratio)
	s.k = k
	s.d = 2 * math.clamp(ratio, 0.25, 1) * math.sqrt(k)
end
local function stepSpring(s, dt)
	local n = math.max(1, math.ceil(dt * 120))
	local h = dt / n
	for _ = 1, n do
		s.v = s.v + (s.k * (s.t - s.x) - s.d * s.v) * h
		s.x = s.x + s.v * h
	end
end
local function settled(s)
	return math.abs(s.t - s.x) < 0.02 and math.abs(s.v) < 0.02
end
local function drawGlyph(parent, kind, color)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end
	local function bar(x, y, bw, bh, rot)
		local b = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(bw, bh),
			Rotation = rot,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = parent,
		})
		round(b)
	end
	if kind == "success" then
		bar(0.36, 0.58, 0.11, 0.27, -45)
		bar(0.60, 0.51, 0.11, 0.47, 45)
	elseif kind == "error" then
		bar(0.5, 0.5, 0.11, 0.5, 45)
		bar(0.5, 0.5, 0.11, 0.5, -45)
	elseif kind == "warn" then
		bar(0.5, 0.40, 0.12, 0.34, 0)
		bar(0.5, 0.72, 0.13, 0.13, 0)
	else
		bar(0.5, 0.27, 0.13, 0.13, 0)
		bar(0.5, 0.58, 0.12, 0.34, 0)
	end
end
local Theme = {
	Accent = Color3.fromRGB(235, 235, 235),
	Accent2 = Color3.fromRGB(118, 118, 118),
	Background = Color3.fromRGB(0, 0, 0),
	Card = Color3.fromRGB(18, 18, 18),
	CardHover = Color3.fromRGB(32, 32, 32),
	Stroke = Color3.fromRGB(60, 60, 60),
	Track = Color3.fromRGB(44, 44, 44),
	Off = Color3.fromRGB(64, 64, 64),
	Text = Color3.fromRGB(245, 245, 245),
	Muted = Color3.fromRGB(160, 160, 160),
	Input = Color3.fromRGB(12, 12, 12),
	Button = Color3.fromRGB(32, 32, 32),
	Dark = Color3.fromRGB(22, 22, 22),
}
Library.Theme = Theme
local binds = {}
local themeListeners = {}
local function bindTheme(inst, fn)
	table.insert(binds, {inst = inst, fn = fn})
	pcall(fn, Theme, inst)
end
local function applyTheme()
	local i = 1
	while i <= #binds do
		local b = binds[i]
		if b.inst.Parent == nil then
			table.remove(binds, i)
		else
			pcall(b.fn, Theme, b.inst)
			i = i + 1
		end
	end
	for _, cb in ipairs(themeListeners) do
		pcall(cb, Theme)
	end
end
function Library:SetTheme(t)
	if type(t) ~= "table" then
		return
	end
	for key, value in pairs(t) do
		if Theme[key] ~= nil and typeof(value) == "Color3" then
			Theme[key] = value
		end
	end
	if t.Accent and not t.Accent2 then
		Theme.Accent2 = darken(t.Accent, 0.5)
	end
	applyTheme()
end
function Library:SetAccent(color, secondary)
	if typeof(color) ~= "Color3" then
		return
	end
	self:SetTheme({Accent = color, Accent2 = secondary})
end
Library.SetUIColor = Library.SetAccent
function Library:SetPreset(name)
	local color = self.Presets[name]
	if color then
		self:SetAccent(color)
		return true
	end
	return false
end
function Library:GetAccent()
	return Theme.Accent
end
function Library:OnThemeChanged(fn)
	table.insert(themeListeners, fn)
end

function Library:SetTransparency(value)
	value = tonumber(value)
	if not value then
		return
	end
	self.Transparency = math.clamp(value, 0, 0.9)
	applyTheme()
end
local CLICK_IDS = {
	"rbxasset://sounds/button.mp3",
	"rbxasset://sounds/switch.mp3",
	"rbxasset://sounds/clickfast.mp3",
	"rbxasset://sounds/SWITCH3.mp3",
	"rbxasset://sounds/button.wav",
	"rbxasset://sounds/switch.wav",
}
local function makeClicker(parent, isEnabled)
	local volume = 0.7
	local pool, nextIndex = {}, 0
	for i = 1, 4 do
		pool[i] = new("Sound", {Name = "Click" .. i, SoundId = CLICK_IDS[1], Volume = volume, Parent = parent})
	end
	task.spawn(function()
		local probe = pool[1]
		for _, id in ipairs(CLICK_IDS) do
			probe.SoundId = id
			local loaded = false
			pcall(function()
				ContentProvider:PreloadAsync({probe}, function(_, status)
					if status == Enum.AssetFetchStatus.Success then
						loaded = true
					end
				end)
			end)
			if loaded or (probe.IsLoaded and probe.TimeLength > 0) then
				for _, snd in ipairs(pool) do
					snd.SoundId = id
				end
				return
			end
		end
	end)
	return function(speed, vol)
		if not isEnabled() then
			return
		end
		nextIndex = nextIndex % #pool + 1
		local snd = pool[nextIndex]
		snd.PlaybackSpeed = (speed or 1) * (0.96 + math.random() * 0.08)
		snd.Volume = volume * (vol or 1)
		snd.TimePosition = 0
		snd:Play()
	end
end
local function resolveImage(spec, onResolved)
	if spec == nil or spec == "" or spec == false then
		return nil
	end
	if type(spec) == "number" then
		spec = "rbxassetid://" .. tostring(spec)
	end
	spec = tostring(spec)
	if spec:find("^rbxthumb://") or spec:find("^rbxasset://") or spec:find("^rbxgameasset://") then
		return spec
	end
	local makeAsset = getcustomasset or getsynasset
	if makeAsset and isfile and not spec:find("^https?://") then
		local okFile, exists = pcall(isfile, spec)
		if okFile and exists then
			local okAsset, asset = pcall(makeAsset, spec)
			if okAsset and type(asset) == "string" then
				return asset
			end
		end
	end
	local id = spec:match("^rbxassetid://(%d+)") or spec:match("^(%d+)$") or spec:match("[%?&]id=(%d+)")
	local done = false
	local probeGui = new("ScreenGui", {Name = "RXMUI_Probe", ResetOnSpawn = false, DisplayOrder = -1})
	if not mountGui(probeGui) then
		if id and onResolved then
			task.defer(onResolved, "rbxassetid://" .. id)
		end
		return nil
	end
	local function finish(url)
		if done then
			return
		end
		done = true
		pcall(function()
			probeGui:Destroy()
		end)
		if onResolved then
			pcall(onResolved, url)
		end
	end
	local function attempt(url, timeout)
		if done or type(url) ~= "string" or url == "" then
			return
		end
		task.spawn(function()
			local probe = new("ImageLabel", {
				Size = UDim2.fromOffset(4, 4),
				BackgroundTransparency = 1,
				Image = url,
				ImageTransparency = 0.99,
				Parent = probeGui,
			})
			pcall(function()
				ContentProvider:PreloadAsync({probe})
			end)
			local t0 = os.clock()
			while not done and os.clock() - t0 < (timeout or 6) do
				local ok, loaded = pcall(function()
					return probe.IsLoaded
				end)
				if ok and loaded == true then
					finish(url)
					break
				end
				task.wait(0.1)
			end
			pcall(function()
				probe:Destroy()
			end)
		end)
	end
	local function attemptId(imageId)
		attempt("rbxassetid://" .. imageId, 6)
		attempt("http://www.roblox.com/asset/?id=" .. imageId, 6)
	end
	if id then
		attemptId(id)
		attempt("rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420", 6)
		task.spawn(function()
			local okObj, objs = pcall(function()
				return game:GetObjects("rbxassetid://" .. id)
			end)
			if not (okObj and type(objs) == "table") then
				return
			end
			for _, obj in ipairs(objs) do
				local tex
				pcall(function()
					if obj:IsA("Decal") or obj:IsA("Texture") then
						tex = obj.Texture
					elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
						tex = obj.Image
					else
						local d = obj:FindFirstChildWhichIsA("Decal", true) or obj:FindFirstChildWhichIsA("Texture", true)
						tex = d and d.Texture
					end
				end)
				pcall(function()
					obj:Destroy()
				end)
				if tex and tex ~= "" then
					attempt(tex, 6)
					local texId = tex:match("(%d%d%d+)")
					if texId then
						attemptId(texId)
					end
				end
			end
		end)
	elseif spec:find("^https?://") then
		task.spawn(function()
			if not (requestFunc and writefile and makeAsset) then
				return
			end
			local ok, res = pcall(requestFunc, {Url = spec, Method = "GET"})
			if not (ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 100) then
				return
			end
			if res.StatusCode and res.StatusCode ~= 200 then
				return
			end
			local body = res.Body
			local ext = string.sub(body, 2, 4) == "PNG" and ".png" or ".jpg"
			local hash = 0
			for i = 1, #spec do
				hash = (hash * 31 + string.byte(spec, i)) % 1000000007
			end
			local fileName = "RXMUI_img_" .. hash .. ext
			if not pcall(writefile, fileName, body) then
				return
			end
			local okAsset, asset = pcall(makeAsset, fileName)
			if okAsset and type(asset) == "string" then
				attempt(asset, 6)
			end
		end)
	end
	task.delay(14, function()
		if not done then
			done = true
			pcall(function()
				probeGui:Destroy()
			end)
		end
	end)
	return nil
end
local function soundId(spec)
	if type(spec) == "number" then
		return "rbxassetid://" .. tostring(spec)
	end
	spec = tostring(spec or "")
	if spec:match("^%d+$") then
		return "rbxassetid://" .. spec
	end
	return spec
end
local SFX = {
	Open = {id = "rbxassetid://77120543307812", volume = 0.8, flag = "Sounds"},
	Toggle = {id = "rbxassetid://12222183", volume = 0.8, flag = "SwitchSounds"},
	Notify = {id = "rbxassetid://71450094482101", volume = 0.9, flag = "NotifySounds"},
	Slider = {id = "rbxassetid://15675032796", volume = 0.7, flag = "SliderSounds"},
}
local SLIDER_TICK = 0.1
local function makeSfx(parent, isEnabled)
	local pools, cursor, warm = {}, {}, {}
	for name, info in pairs(SFX) do
		local pool = {}
		for i = 1, 3 do
			pool[i] = new("Sound", {
				Name = "Sfx" .. name .. i,
				SoundId = info.id,
				Volume = info.volume,
				Parent = parent,
			})
		end
		pools[name] = pool
		cursor[name] = 0
		table.insert(warm, pool[1])
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(warm)
		end)
	end)
	return function(name, speed, vol)
		local pool = pools[name]
		if not pool or not isEnabled(SFX[name].flag) then
			return
		end
		cursor[name] = cursor[name] % #pool + 1
		local snd = pool[cursor[name]]
		snd.PlaybackSpeed = speed or 1
		snd.Volume = SFX[name].volume * (vol or 1)
		snd.TimePosition = 0
		snd:Play()
	end
end
local FontList, FontByName = {}, {}
Library.Fonts = FontList
local function addFontEntry(entry)
	if FontByName[entry.Name] then
		for i, e in ipairs(FontList) do
			if e.Name == entry.Name then
				FontList[i] = entry
			end
		end
	else
		table.insert(FontList, entry)
	end
	FontByName[entry.Name] = entry
end
local STORE_FONTS = {
	{"Silkscreen", 12187371840},
	{"Damion", 12187607722},
	{"Bungee Inline", 12187370000},
	{"Finger Paint", 12187375716},
	{"Mulish", 12187372629},
	{"Cairo", 12187377099},
	{"Montserrat", 11702779517},
	{"Eater", 12187372382},
	{"Fuzzy Bubbles", 11322590111},
	{"Nosifer", 12187377325},
	{"Tangerine", 12187376545},
	{"Audiowide", 12187360881},
	{"Builder Sans", 16658221428},
	{"Caesar Dressing", 12187368843},
	{"Faster One", 12187370928},
	{"Mukta", 12187365559},
	{"Rubik Burned", 12187363148},
	{"Rubik Marker Hatch", 12187367066},
	{"Bungee Shade", 12187367666},
	{"Dancing Script", 8764312106},
	{"Frijole", 12187375194},
	{"Noto Serif SC", 12187376739},
	{"Prompt", 12187607287},
	{"Rubik", 12187365977},
	{"Barrio", 12187371991},
	{"Builder Extended", 16658237174},
	{"M PLUS Rounded 1c", 12188570269},
	{"Nothing You Could Do", 12187367901},
	{"Roboto Slab", 12187368625},
	{"Sedgwick Ave Display", 12187376357},
	{"Are You Serious", 12187363616},
	{"Builder Mono", 16658246179},
	{"Codystar", 12187363887},
	{"Great Vibes", 12187375958},
	{"Inter", 12187365364},
	{"Irish Grover", 12187376910},
	{"Italianno", 12187374273},
	{"Lobster", 8836875837},
	{"Marhey", 12187364648},
	{"Monofett", 12187606783},
	{"Poppins", 11702779409},
	{"Rajdhani", 12187375422},
	{"Shadows Into Light", 12187607493},
	{"Teko", 12187376174},
	{"Unica One", 12187364842},
	{"Blaka", 12187365104},
	{"Caveat", 12187369802},
	{"IBM Plex Sans JP", 12187364147},
	{"Kanit", 12187373592},
	{"Kings", 12187371622},
	{"Libre Baskerville", 12187365769},
	{"Monoton", 12187374098},
	{"Nanum Gothic", 12187361718},
	{"Noto Sans", 12187370747},
	{"Noto Serif HK", 12187366846},
	{"Noto Serif JP", 12187369639},
	{"Pacifico", 12187367362},
	{"Parisienne", 12187361943},
	{"Quicksand", 12187371324},
	{"Raleway", 11702779240},
	{"Rubik Iso", 12187362120},
	{"Rubik Maze", 12187366475},
	{"Rubik Wet Paint", 12187369046},
	{"Rye", 12187372175},
	{"Sono", 12187374537},
	{"Sono Monospace", 12187362578},
	{"Work Sans", 12187373327},
	{"Akronim", 12187368317},
	{"Arimo", 16658254058},
	{"Barlow", 12187372847},
	{"Fira Sans", 12187374954},
	{"Hind", 12187361116},
	{"Hind Siliguri", 12187361378},
	{"La Belle Aurore", 12187607116},
	{"Lato", 11598289817},
	{"Lora", 12187366657},
	{"Noto Sans HK", 12187362892},
	{"Noto Serif TC", 12187368093},
	{"Nunito Sans", 12187363368},
	{"Open Sans", 11598121416},
	{"Playfair Display", 12187374765},
	{"PT Sans", 12187606934},
	{"PT Serif", 12187606624},
	{"Tajawal", 12187377588},
	{"Yellowtail", 12187373881}
}
for _, f in ipairs(STORE_FONTS) do
	addFontEntry({Name = f[1], Id = f[2]})
end
local function same(enumName)
	return {Regular = enumName, Medium = enumName, Bold = enumName, Black = enumName}
end
local BUILTIN_FONTS = {
	{"Gotham", {Regular = "Gotham", Medium = "GothamMedium", Bold = "GothamBold", Black = "GothamBlack"}},
	{"Source Sans", {Regular = "SourceSans", Medium = "SourceSansSemibold", Bold = "SourceSansBold", Black = "SourceSansBold"}},
	{"Arial", {Regular = "Arial", Medium = "Arial", Bold = "ArialBold", Black = "ArialBold"}},
	{"Code", same("Code")},
	{"Roboto", same("Roboto")},
	{"Roboto Condensed", same("RobotoCondensed")},
	{"Roboto Mono", same("RobotoMono")},
	{"Ubuntu", same("Ubuntu")},
	{"Nunito", same("Nunito")},
	{"Oswald", same("Oswald")},
	{"Jura", same("Jura")},
	{"Michroma", same("Michroma")},
	{"Merriweather", same("Merriweather")},
	{"Fredoka One", same("FredokaOne")},
	{"Titillium Web", same("TitilliumWeb")},
	{"Josefin Sans", same("JosefinSans")},
	{"Sarpanch", same("Sarpanch")},
	{"Arcade", same("Arcade")},
	{"SciFi", same("SciFi")},
	{"Cartoon", same("Cartoon")},
	{"Fantasy", same("Fantasy")},
	{"Antique", same("Antique")},
	{"Bodoni", same("Bodoni")},
	{"Garamond", same("Garamond")},
	{"Highway", same("Highway")},
	{"Bangers", same("Bangers")},
	{"Luckiest Guy", same("LuckiestGuy")},
	{"Permanent Marker", same("PermanentMarker")},
	{"Indie Flower", same("IndieFlower")},
	{"Kalam", same("Kalam")},
	{"Patrick Hand", same("PatrickHand")},
	{"Special Elite", same("SpecialElite")},
	{"Creepster", same("Creepster")},
	{"Amatic SC", same("AmaticSC")},
	{"Denk One", same("DenkOne")},
	{"Fondamento", same("Fondamento")},
	{"Grenze Gotisch", same("GrenzeGotisch")},
}
for _, f in ipairs(BUILTIN_FONTS) do
	addFontEntry({Name = f[1], Roles = f[2], BuiltIn = true})
end
local ROLE_WEIGHT = {
	Regular = Enum.FontWeight.Regular,
	Medium = Enum.FontWeight.Medium,
	Bold = Enum.FontWeight.Bold,
	Black = Enum.FontWeight.Heavy,
}
local function roleOf(enumFont)
	if enumFont == Enum.Font.GothamBold or enumFont == Enum.Font.SourceSansBold or enumFont == Enum.Font.ArialBold then
		return "Bold"
	elseif enumFont == Enum.Font.GothamBlack then
		return "Black"
	elseif enumFont == Enum.Font.GothamMedium or enumFont == Enum.Font.SourceSansSemibold then
		return "Medium"
	end
	return "Regular"
end
local function applyFont(inst, role, entry)
	pcall(function()
		if entry.Id then
			inst.FontFace = Font.fromId(entry.Id, ROLE_WEIGHT[role], Enum.FontStyle.Normal)
		else
			inst.Font = Enum.Font[entry.Roles[role] or entry.Roles.Regular]
		end
	end)
end
Library.FontName = "Silkscreen"
Library.DefaultFont = "Silkscreen"
local fontItems = {}
local function currentFontEntry(override)
	return FontByName[override or Library.FontName] or FontByName[Library.DefaultFont] or FontByName["Gotham"]
end
local function pruneFonts()
	local keep = 0
	for i = 1, #fontItems do
		local item = fontItems[i]
		local alive = true
		if item.inst.Parent ~= nil then
			item.seen = true
		elseif item.seen then
			alive = false
		end
		if alive then
			keep = keep + 1
			fontItems[keep] = item
		end
	end
	for i = #fontItems, keep + 1, -1 do
		fontItems[i] = nil
	end
end
fontTrack = function(inst, override)
	local role = roleOf(inst.Font)
	table.insert(fontItems, {inst = inst, role = role, override = override, seen = inst.Parent ~= nil})
	applyFont(inst, role, currentFontEntry(override))
	if #fontItems > 600 and #fontItems % 100 == 0 then
		pruneFonts()
	end
end
function Library:SetFont(which)
	local entry
	if type(which) == "number" then
		for _, e in ipairs(FontList) do
			if e.Id == which then
				entry = e
			end
		end
		if not entry then
			entry = {Name = "Font " .. tostring(which), Id = which}
			addFontEntry(entry)
		end
	else
		entry = FontByName[which]
	end
	if not entry then
		return false
	end
	self.FontName = entry.Name
	pruneFonts()
	for _, item in ipairs(fontItems) do
		if not item.override then
			applyFont(item.inst, item.role, entry)
		end
	end
	return true
end
function Library:GetFont()
	return self.FontName
end
function Library:AddFont(name, assetId)
	assert(type(name) == "string" and type(assetId) == "number", "AddFont: butuh (nama string, id angka)")
	addFontEntry({Name = name, Id = assetId})
end
function Library:GetFontNames()
	local out = {}
	for _, e in ipairs(FontList) do
		table.insert(out, e.Name)
	end
	table.sort(out, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	return out
end
function Library:GetFontInfo(name)
	local e = FontByName[name]
	if e then
		return {Name = e.Name, Id = e.Id, BuiltIn = e.BuiltIn and true or false}
	end
	return nil
end
local Icons = {}
Library.Icons = Icons
local function I(name, ...)
	Icons[name] = {...}
end
I("activity", {"p",2.5,12,7,12,9.5,4.5,14,19.5,16.5,12,21.5,12})
I("alert", {"P",12,3.8,21.5,20,2.5,20}, {"l",12,10,12,14.5}, {"C",12,17.3,1.3})
I("anchor", {"c",12,5,2.2}, {"l",12,7.2,12,21}, {"l",8,11,16,11}, {"a",12,13,8,0,180}, {"l",4,13,4,10.5}, {"l",20,13,20,10.5})
I("arrow-down", {"l",12,5,12,19}, {"p",7.4,14.4,12,19,16.6,14.4})
I("arrow-left", {"l",19,12,5,12}, {"p",9.6,7.4,5,12,9.6,16.6})
I("arrow-right", {"l",5,12,19,12}, {"p",14.4,16.6,19,12,14.4,7.4})
I("arrow-up", {"l",12,19,12,5}, {"p",16.6,9.6,12,5,7.4,9.6})
I("asterisk", {"l",12,4,12,20}, {"l",5.1,8,18.9,16}, {"l",5.1,16,18.9,8})
I("award", {"c",12,9.5,6}, {"p",8.5,14.5,7,21.5,12,18.5,17,21.5,15.5,14.5})
I("ban", {"c",12,12,9}, {"l",5.6,5.6,18.4,18.4})
I("bar-chart", {"l",6,20,6,13}, {"l",12,20,12,5}, {"l",18,20,18,10})
I("battery", {"r",2.5,7,17,10,2.5}, {"l",21.5,10.5,21.5,13.5}, {"l",6,12,11,12})
I("bell", {"a",12,10,6,180,360}, {"l",6,10,6,15}, {"l",18,10,18,15}, {"p",6,15,4.5,17.5,19.5,17.5,18,15}, {"a",12,19.8,2,0,180}, {"l",12,3,12,4})
I("bomb", {"c",11,14,7}, {"l",15.8,9,19,5.8}, {"l",19.5,3,19.5,4.6}, {"l",21.4,5,22.2,5})
I("bookmark", {"P",6,3.5,18,3.5,18,20.5,12,16,6,20.5})
I("box", {"P",12,3,20.5,7.5,20.5,16.5,12,21,3.5,16.5,3.5,7.5}, {"p",3.5,7.5,12,12,20.5,7.5}, {"l",12,12,12,21})
I("bug", {"P",16.5,13.5,16.05,16.23,14.81,18.43,13,19.64,11,19.64,9.19,18.43,7.95,16.23,7.5,13.5,7.95,10.77,9.19,8.57,11,7.36,13,7.36,14.81,8.57,16.05,10.77}, {"c",12,5.6,2.2}, {"l",7.5,10,4,8}, {"l",7.5,14,3.5,14}, {"l",8,18,5,20.5}, {"l",16.5,10,20,8}, {"l",16.5,14,20.5,14}, {"l",16,18,19,20.5}, {"l",12,8,12,19.8})
I("calendar", {"r",4,5,16,15.5,2.5}, {"l",4,10,20,10}, {"l",8,3,8,7}, {"l",16,3,16,7})
I("camera", {"P",3.5,8,8,8,9.5,5.5,14.5,5.5,16,8,20.5,8,20.5,19,3.5,19}, {"c",12,13,3.5})
I("cart", {"p",2.5,3.5,5,3.5,7,15.5,18,15.5,20,7.5,6,7.5}, {"c",9.5,19.5,1.5}, {"c",16.5,19.5,1.5})
I("check", {"p",4.5,12.5,9.8,17.8,19.5,7})
I("check-circle", {"c",12,12,9}, {"p",8,12.3,11,15.3,16.5,9})
I("chevron-down", {"p",6,9,12,15,18,9})
I("chevron-left", {"p",15,6,9,12,15,18})
I("chevron-right", {"p",9,6,15,12,9,18})
I("chevron-up", {"p",6,15,12,9,18,15})
I("circle", {"c",12,12,9})
I("circle-dot", {"c",12,12,9}, {"C",12,12,3.2})
I("clipboard", {"r",5,4.5,14,16.5,2.5}, {"r",9,2.5,6,4,1.5}, {"l",8.5,12,15.5,12}, {"l",8.5,16,13,16})
I("clock", {"c",12,12,9}, {"p",12,7,12,12,15.5,14})
I("cloud", {"l",6.2,19,16.7,19}, {"a",6.2,15,4,90,270}, {"a",11.7,11,5.3,180,335}, {"a",16.7,13.8,5.2,270,450})
I("code", {"p",8.5,7,3.5,12,8.5,17}, {"p",15.5,7,20.5,12,15.5,17}, {"l",13.5,5,10.5,19})
I("coin", {"c",12,12,9}, {"p",14.5,9,10.2,9,9.5,10,9.8,11.2,14.2,12.8,14.5,14,13.8,15,9.5,15}, {"l",12,7,12,9}, {"l",12,15,12,17})
I("compass", {"c",12,12,9}, {"P",15.5,8.5,13.5,13.5,8.5,15.5,10.5,10.5})
I("copy", {"r",9,9,11,11,2.5}, {"p",9,15,6.5,15,4,12.5,4,6.5,6.5,4,12.5,4,15,6.5,15,9})
I("cpu", {"r",6.5,6.5,11,11,1.5}, {"r",9.5,9.5,5,5,0.5}, {"l",9.5,3.5,9.5,6.5}, {"l",14.5,3.5,14.5,6.5}, {"l",9.5,17.5,9.5,20.5}, {"l",14.5,17.5,14.5,20.5}, {"l",3.5,9.5,6.5,9.5}, {"l",3.5,14.5,6.5,14.5}, {"l",17.5,9.5,20.5,9.5}, {"l",17.5,14.5,20.5,14.5})
I("crosshair", {"c",12,12,8}, {"l",12,2.5,12,7}, {"l",12,17,12,21.5}, {"l",2.5,12,7,12}, {"l",17,12,21.5,12})
I("crown", {"p",3.5,18,3.5,8,8.5,13,12,6,15.5,13,20.5,8,20.5,18,3.5,18}, {"l",3.5,20.8,20.5,20.8})
I("cursor", {"P",5.5,3,5.5,18.5,9.5,15,12.5,21,15,19.8,12.2,14,17.5,14})
I("database", {"P",20,6.5,19.39,7.65,17.66,8.62,15.06,9.27,12,9.5,8.94,9.27,6.34,8.62,4.61,7.65,4,6.5,4.61,5.35,6.34,4.38,8.94,3.73,12,3.5,15.06,3.73,17.66,4.38,19.39,5.35}, {"l",4,6.5,4,17.5}, {"l",20,6.5,20,17.5}, {"p",20,12,19.39,13.15,17.66,14.12,15.06,14.77,12,15,8.94,14.77,6.34,14.12,4.61,13.15,4,12}, {"p",20,17.5,19.39,18.65,17.66,19.62,15.06,20.27,12,20.5,8.94,20.27,6.34,19.62,4.61,18.65,4,17.5})
I("diamond", {"P",12,3,21,12,12,21,3,12})
I("dice", {"r",4,4,16,16,3}, {"C",8.5,8.5,1.3}, {"C",15.5,8.5,1.3}, {"C",8.5,15.5,1.3}, {"C",15.5,15.5,1.3}, {"C",12,12,1.3})
I("download", {"l",12,4,12,15}, {"p",7,10.5,12,15.5,17,10.5}, {"l",4,20,20,20})
I("droplet", {"a",12,15,6,200,-20}, {"p",6.36,12.95,12,3,17.64,12.95})
I("edit", {"P",4,20,5.5,14.5,16,4,20,8,9.5,18.5}, {"l",13.5,6.5,17.5,10.5})
I("external-link", {"p",14,4,20,4,20,10}, {"l",20,4,11,13}, {"p",18,14.5,18,19,5,19,5,6,9.5,6})
I("eye", {"p",2.5,12,6,8,12,6,18,8,21.5,12,18,16,12,18,6,16,2.5,12}, {"c",12,12,3})
I("eye-off", {"p",2.5,12,6,8,12,6,18,8,21.5,12,18,16,12,18,6,16,2.5,12}, {"c",12,12,3}, {"l",4,20,20,4})
I("file", {"P",6,3,14,3,19,8,19,21,6,21}, {"p",14,3,14,8,19,8})
I("filter", {"P",3.5,4.5,20.5,4.5,14,12.5,14,19.5,10,17.5,10,12.5})
I("flag", {"l",5,3.5,5,21}, {"p",5,4.5,19,4.5,15.5,9,19,13.5,5,13.5})
I("flame", {"P",12,2.8,16.2,8,18.5,13,17,18,12,21,7,18,5.5,13,8,10,10,12.5})
I("flask", {"p",9.5,3,9.5,9.5,4.5,18.5,5,20,19,20,19.5,18.5,14.5,9.5,14.5,3}, {"l",8,3,16,3}, {"l",7.5,14.5,16.5,14.5})
I("folder", {"P",3,6,9,6,11,8.5,21,8.5,21,19.5,3,19.5})
I("frown", {"c",12,12,9}, {"a",12,17.5,4.5,205,335}, {"C",9,9.3,1.2}, {"C",15,9.3,1.2})
I("gamepad", {"r",2.5,7,19,10,5}, {"l",7,10.5,7,13.5}, {"l",5.5,12,8.5,12}, {"C",16,10.8,1.3}, {"C",18.2,13.2,1.3})
I("gauge", {"a",12,15,8.5,180,360}, {"l",12,15,16,9.5}, {"l",3.5,15,5.5,15}, {"l",18.5,15,20.5,15}, {"C",12,15,1.4})
I("gem", {"P",7,4,17,4,21.5,9.5,12,20.5,2.5,9.5}, {"l",2.5,9.5,21.5,9.5}, {"p",8.3,9.5,12,20.5,15.7,9.5}, {"p",10,4,8.3,9.5}, {"p",14,4,15.7,9.5})
I("ghost", {"a",12,10,7,180,360}, {"l",5,10,5,20.5}, {"l",19,10,19,20.5}, {"p",5,20.5,8.5,17.5,12,20.5,15.5,17.5,19,20.5}, {"C",9.5,10,1.4}, {"C",14.5,10,1.4})
I("gift", {"r",4,10,16,10.5,1.5}, {"r",3,7,18,3.5,1}, {"l",12,7,12,20.5}, {"c",9,5,2.2}, {"c",15,5,2.2})
I("globe", {"c",12,12,9}, {"l",3,12,21,12}, {"P",16,12,15.6,15.9,14.49,19.04,12.89,20.77,11.11,20.77,9.51,19.04,8.4,15.9,8,12,8.4,8.1,9.51,4.96,11.11,3.23,12.89,3.23,14.49,4.96,15.6,8.1})
I("grid", {"r",4,4,6.5,6.5,1.5}, {"r",13.5,4,6.5,6.5,1.5}, {"r",4,13.5,6.5,6.5,1.5}, {"r",13.5,13.5,6.5,6.5,1.5})
I("hammer", {"l",4.5,19.5,13,11}, {"P",14.07,3.21,20.79,9.93,17.53,13.19,10.81,6.47})
I("hash", {"l",9,4,7,20}, {"l",17,4,15,20}, {"l",4,9,20,9}, {"l",3.5,15,19.5,15})
I("headphones", {"a",12,13,8.5,180,360}, {"r",3.5,13,4,6.5,1.5}, {"r",16.5,13,4,6.5,1.5})
I("heart", {"a",7.6,8.4,4.6,-16.94,-220}, {"a",16.4,8.4,4.6,196.94,400}, {"l",4.08,11.36,12,20.8}, {"l",19.92,11.36,12,20.8})
I("help", {"c",12,12,9}, {"a",12,9.8,2.8,180,450}, {"l",12,12.6,12,14.2}, {"C",12,17.2,1.3})
I("hexagon", {"P",12,3,19.8,7.5,19.8,16.5,12,21,4.2,16.5,4.2,7.5})
I("home", {"p",3,11,12,3,21,11}, {"p",5,9.5,5,20.5,19,20.5,19,9.5}, {"p",10,20.5,10,14,14,14,20.5})
I("hourglass", {"P",6.5,3.5,17.5,3.5,12,12}, {"P",12,12,17.5,20.5,6.5,20.5})
I("image", {"r",3.5,4.5,17,15,2.5}, {"c",9,10,1.8}, {"p",3.5,17,9,12.5,14,17,16.5,15,20.5,18.5})
I("info", {"c",12,12,9}, {"l",12,11,12,16.5}, {"C",12,7.8,1.3})
I("key", {"c",8,15.5,4.5}, {"l",11.3,12.2,20.5,3.5}, {"l",16.5,7.5,19,10}, {"l",14,10,16,12})
I("keyboard", {"r",2.5,6.5,19,11,2.5}, {"C",6.5,10,1}, {"C",10,10,1}, {"C",14,10,1}, {"C",17.5,10,1}, {"l",7,14,17,14})
I("laptop", {"r",5,5.5,14,10,1.5}, {"l",2.5,19,21.5,19})
I("layers", {"P",12,3.5,21,8.5,12,13.5,3,8.5}, {"p",3,12.5,12,17.5,21,12.5}, {"p",3,16.5,12,21.5,21,16.5})
I("layout", {"r",3.5,3.5,17,17,2.5}, {"l",10,3.5,10,20.5}, {"l",10,10,20.5,10})
I("leaf", {"P",5,19,5.5,11,11,5.5,19.5,4.5,18.5,13,13,18.5}, {"l",5,19,12,12})
I("lightbulb", {"a",12,9.5,6,135,405}, {"p",7.76,13.74,9.5,16,9.5,18}, {"p",16.24,13.74,14.5,16,14.5,18}, {"l",9.5,18,14.5,18}, {"l",10,20.5,14,20.5})
I("link", {"P",7.92,12.26,9.13,11.57,10.53,11.57,11.74,12.26,12.43,13.47,12.43,14.87,11.74,16.08,8.48,19.34,7.27,20.03,5.87,20.03,4.66,19.34,3.97,18.13,3.97,16.73,4.66,15.52}, {"P",15.52,4.66,16.73,3.97,18.13,3.97,19.34,4.66,20.03,5.87,20.03,7.27,19.34,8.48,16.08,11.74,14.87,12.43,13.47,12.43,12.26,11.74,11.57,10.53,11.57,9.13,12.26,7.92}, {"l",9.6,14.4,14.4,9.6})
I("list", {"l",8,6,20,6}, {"l",8,12,20,12}, {"l",8,18,20,18}, {"C",4,6,1.2}, {"C",4,12,1.2}, {"C",4,18,1.2})
I("lock", {"r",5,11,14,10,2.5}, {"a",12,9,4.5,180,360}, {"l",7.5,9,7.5,11}, {"l",16.5,9,16.5,11}, {"C",12,16,1.3})
I("log-out", {"p",9,4,5,4,5,20,9,20}, {"l",10,12,20,12}, {"p",16.46,15.54,20,12,16.46,8.46})
I("magnet", {"a",12,11,6.5,0,180}, {"l",5.5,11,5.5,4}, {"l",18.5,11,18.5,4}, {"l",3.5,4,7.5,4}, {"l",16.5,4,20.5,4}, {"l",3.5,7,7.5,7}, {"l",16.5,7,20.5,7})
I("mail", {"r",3,5.5,18,13,2.5}, {"p",3.5,7,12,13.5,20.5,7})
I("map", {"P",3,6.5,9,4,15,6.5,21,4,21,17.5,15,20,9,17.5,3,20}, {"l",9,4,9,17.5}, {"l",15,6.5,15,20})
I("map-pin", {"a",12,9.5,6.5,150,390}, {"p",6.4,12.75,12,21,17.6,12.75}, {"c",12,9.5,2.3})
I("maximize", {"p",4,9.5,4,4,9.5,4}, {"p",14.5,4,20,4,20,9.5}, {"p",20,14.5,20,20,14.5,20}, {"p",9.5,20,4,20,4,14.5})
I("menu", {"l",4,6,20,6}, {"l",4,12,20,12}, {"l",4,18,20,18})
I("message", {"P",4,5,20,5,20,16,11,16,6.5,20,6.5,16,4,16})
I("mic", {"r",9,3,6,11,3}, {"a",12,11,7,0,180}, {"l",12,18,12,21.5}, {"l",8.5,21.5,15.5,21.5})
I("minimize", {"p",9.5,4,9.5,9.5,4,9.5}, {"p",20,9.5,14.5,9.5,14.5,4}, {"p",14.5,20,14.5,14.5,20,14.5}, {"p",4,14.5,9.5,14.5,9.5,20})
I("minus", {"l",5,12,19,12})
I("monitor", {"r",3,4,18,12.5,2}, {"l",8,20.5,16,20.5}, {"l",12,16.5,12,20.5})
I("moon", {"a",12,12,9,0,270}, {"a",16.5,7.5,6.36,225,45})
I("move", {"l",12,3,12,21}, {"l",3,12,21,12}, {"p",9,6,12,3,15,6}, {"p",9,18,12,21,15,18}, {"p",6,9,3,12,6,15}, {"p",18,9,21,12,18,15})
I("music", {"p",9,18,9,5.5,19,3.5,19,16}, {"c",6.5,18,2.7}, {"c",16.5,16,2.7})
I("navigation", {"P",12,3,19.5,20.5,12,16.5,4.5,20.5})
I("pause", {"r",6,5,4,14,1}, {"r",14,5,4,14,1})
I("percent", {"l",19,5,5,19}, {"c",7,7,2.3}, {"c",17,17,2.3})
I("phone", {"r",7,2.5,10,19,2.5}, {"l",10.5,18.5,13.5,18.5})
I("pie-chart", {"c",12,12,9}, {"l",12,3,12,12}, {"l",12,12,19.8,16.4})
I("play", {"P",7,4,19,12,7,20})
I("plug", {"l",9,3.5,9,8}, {"l",15,3.5,15,8}, {"P",6.5,8,17.5,8,17.5,12,14.5,15,9.5,15,6.5,12}, {"l",12,15,12,20.5})
I("plus", {"l",12,5,12,19}, {"l",5,12,19,12})
I("plus-circle", {"c",12,12,9}, {"l",12,8,12,16}, {"l",8,12,16,12})
I("power", {"a",12,13,8,300,600}, {"l",12,3,12,12})
I("redo", {"p",20,9,10,9}, {"p",16.46,12.54,20,9,16.46,5.46}, {"a",10,14,5,270,90}, {"l",10,19,15,19})
I("refresh", {"a",12,12,7.5,40,330}, {"p",14.12,6.83,18.5,8.25,19.45,3.75})
I("rocket", {"P",12,3,16.5,8,16.5,15,7.5,15,7.5,8}, {"c",12,9.5,1.8}, {"p",7.5,12.5,4.5,16.5,7.5,15}, {"p",16.5,12.5,19.5,16.5,16.5,15}, {"p",10,17.5,12,21.5,14,17.5})
I("save", {"P",4,4,17,4,20,7,20,20,4,20}, {"p",8,4,8,9,15,9,15,4}, {"p",7,20,7,14,17,14,17,20})
I("search", {"c",10.5,10.5,6.5}, {"l",15.5,15.5,20.5,20.5})
I("send", {"P",21,3,3,10.5,10.5,13.5,13.5,21}, {"l",10.5,13.5,21,3})
I("server", {"r",3,4,18,6.5,2}, {"r",3,13.5,18,6.5,2}, {"C",7,7.25,1.1}, {"C",7,16.75,1.1})
I("settings", {"c",12,12,3}, {"c",12,12,6.8}, {"l",18.8,12,21.6,12}, {"l",16.81,16.81,18.79,18.79}, {"l",12,18.8,12,21.6}, {"l",7.19,16.81,5.21,18.79}, {"l",5.2,12,2.4,12}, {"l",7.19,7.19,5.21,5.21}, {"l",12,5.2,12,2.4}, {"l",16.81,7.19,18.79,5.21})
I("share", {"c",18,5.5,2.5}, {"c",6,12,2.5}, {"c",18,18.5,2.5}, {"l",8.2,10.8,15.8,6.7}, {"l",8.2,13.2,15.8,17.3})
I("shield", {"P",12,3,19.5,6,19.5,12,16,18,12,21,8,18,4.5,12,4.5,6})
I("shield-check", {"P",12,3,19.5,6,19.5,12,16,18,12,21,8,18,4.5,12,4.5,6}, {"p",8.5,11.8,11,14.3,15.5,9.3})
I("signal", {"l",5,19,5,17}, {"l",10,19,10,13}, {"l",15,19,15,9}, {"l",20,19,20,5})
I("skip-back", {"P",19,5,9,12,19,19}, {"l",5,5,5,19})
I("skip-forward", {"P",5,5,15,12,5,19}, {"l",19,5,19,19})
I("skull", {"a",12,10.5,7.5,180,360}, {"p",4.5,10.5,4.5,13.5,8,16,8,20.5,16,20.5,16,16,19.5,13.5,19.5,10.5}, {"C",9,11.6,1.5}, {"C",15,11.6,1.5}, {"l",11.2,17.5,11.2,20.5}, {"l",12.8,17.5,12.8,20.5})
I("sliders", {"l",4,7,20,7}, {"l",4,17,20,17}, {"c",9,7,2.4}, {"c",15,17,2.4})
I("smile", {"c",12,12,9}, {"a",12,11.5,5,25,155}, {"C",9,9.3,1.2}, {"C",15,9.3,1.2})
I("snowflake", {"l",12,3,12,21}, {"l",4.2,7.5,19.8,16.5}, {"l",4.2,16.5,19.8,7.5}, {"p",9.5,4.5,12,7,14.5,4.5}, {"p",9.5,19.5,12,17,14.5,19.5})
I("sparkles", {"P",12,2.5,13.84,10.16,21.5,12,13.84,13.84,12,21.5,10.16,13.84,2.5,12,10.16,10.16}, {"l",19.5,3,19.5,7}, {"l",17.5,5,21.5,5})
I("square", {"r",4,4,16,16,3})
I("star", {"P",12,3.2,14.59,9.24,21.13,9.83,16.18,14.16,17.64,20.57,12,17.2,6.36,20.57,7.82,14.16,2.87,9.83,9.41,9.24})
I("stop", {"r",5.5,5.5,13,13,2})
I("sun", {"c",12,12,4}, {"l",19,12,21.8,12}, {"l",16.95,16.95,18.93,18.93}, {"l",12,19,12,21.8}, {"l",7.05,16.95,5.07,18.93}, {"l",5,12,2.2,12}, {"l",7.05,7.05,5.07,5.07}, {"l",12,5,12,2.2}, {"l",16.95,7.05,18.93,5.07})
I("sword", {"l",6,18,18.5,5.5}, {"p",14.5,4.5,19.5,4.5,19.5,9.5}, {"l",7.5,12.5,11.5,16.5}, {"l",5.2,18.8,3.5,20.5})
I("tag", {"P",3,12.5,12.5,3,21,3,21,11.5,11.5,21}, {"c",16.5,7.5,1.4})
I("target", {"c",12,12,9}, {"c",12,12,5}, {"C",12,12,1.4})
I("terminal", {"r",3,4.5,18,15,2.5}, {"p",7,9.5,10.5,12.5,7,15.5}, {"l",12.5,15.5,17,15.5})
I("timer", {"c",12,13.5,7.5}, {"l",12,13.5,15,10.5}, {"l",10,2.8,14,2.8}, {"l",12,2.8,12,6})
I("toggle", {"r",2.5,7.5,19,9,4.5}, {"c",8,12,2.2})
I("trash", {"l",4,6,20,6}, {"p",8,6,8,4,16,4,16,6}, {"p",6,6,7,20.5,17,20.5,18,6}, {"l",10,10,10,17}, {"l",14,10,14,17})
I("trending-down", {"p",3,7,9,13,13,9,21,17}, {"p",15,17,21,17,21,11})
I("trending-up", {"p",3,17,9,11,13,15,21,7}, {"p",15,7,21,7,21,13})
I("triangle", {"P",12,4,21,20,3,20})
I("trophy", {"p",7,4,17,4,17,10,14.5,13,9.5,13,7,10,7,4}, {"p",7,6,3.5,6,3.5,8,5,10.5,7.5,11}, {"p",17,6,20.5,6,20.5,8,19,10.5,16.5,11}, {"l",12,13,12,17.5}, {"l",9,17.5,15,17.5}, {"l",8,20.5,16,20.5})
I("undo", {"p",4,9,14,9}, {"p",7.54,5.46,4,9,7.54,12.54}, {"a",14,14,5,270,450}, {"l",14,19,9,19})
I("unlock", {"r",5,11,14,10,2.5}, {"a",12,7.5,4.5,180,360}, {"l",7.5,7.5,7.5,11}, {"C",12,16,1.3})
I("upload", {"l",12,16,12,5}, {"p",7,9.5,12,4.5,17,9.5}, {"l",4,20,20,20})
I("user", {"c",12,8,4}, {"a",12,20.5,7.5,180,360}, {"l",4.5,20.5,19.5,20.5})
I("users", {"c",9,8,3.5}, {"a",9,20,6.5,180,360}, {"l",2.5,20,15.5,20}, {"c",17,8.5,2.8}, {"a",17,20,4.5,200,340})
I("video", {"r",3,6.5,13,11,2.5}, {"p",16,10.5,21,7.5,21,16.5,16,13.5})
I("volume", {"P",4,9.5,8,9.5,13,5,13,19,8,14.5,4,14.5}, {"a",13,12,4.5,-50,50}, {"a",13,12,8.5,-50,50})
I("volume-x", {"P",4,9.5,8,9.5,13,5,13,19,8,14.5,4,14.5}, {"l",16.5,9.5,21,14.5}, {"l",21,9.5,16.5,14.5})
I("wand", {"l",4,20,15,9}, {"P",17.5,2.7,18.35,5.65,21.3,6.5,18.35,7.35,17.5,10.3,16.65,7.35,13.7,6.5,16.65,5.65}, {"l",7,3.5,7,6.5}, {"l",5.5,5,8.5,5})
I("wifi", {"a",12,19,14,227,313}, {"a",12,19,9,227,313}, {"a",12,19,4.2,227,313}, {"C",12,19.2,1.2})
I("x", {"l",6,6,18,18}, {"l",18,6,6,18})
I("x-circle", {"c",12,12,9}, {"l",9,9,15,15}, {"l",15,9,9,15})
I("zap", {"P",13,2.5,5,13.5,11.5,13.5,10.5,21.5,19,10.5,12.5,10.5})
I("zoom-in", {"c",10.5,10.5,6.5}, {"l",15.5,15.5,20.5,20.5}, {"l",7.8,10.5,13.2,10.5}, {"l",10.5,7.8,10.5,13.2})
I("zoom-out", {"c",10.5,10.5,6.5}, {"l",15.5,15.5,20.5,20.5}, {"l",7.8,10.5,13.2,10.5})
local IconAliases = {["about"] = "info", ["aim"] = "crosshair", ["aimbot"] = "crosshair", ["anti-lag"] = "gauge", ["antilag"] = "gauge", ["audio"] = "volume", ["autofarm"] = "leaf", ["boss"] = "skull", ["chat"] = "message", ["color"] = "droplet", ["combat"] = "sword", ["config"] = "sliders", ["credits"] = "heart", ["dashboard"] = "layout", ["debug"] = "bug", ["defense"] = "shield", ["discord"] = "message", ["esp"] = "eye", ["exit"] = "log-out", ["farm"] = "leaf", ["fly"] = "navigation", ["fps"] = "gauge", ["fun"] = "dice", ["game"] = "gamepad", ["games"] = "gamepad", ["gun"] = "crosshair", ["interface"] = "layout", ["inventory"] = "box", ["items"] = "box", ["keybinds"] = "keyboard", ["keys"] = "keyboard", ["lag"] = "gauge", ["logout"] = "log-out", ["magic"] = "wand", ["main"] = "home", ["misc"] = "box", ["movement"] = "move", ["network"] = "wifi", ["noclip"] = "ghost", ["notification"] = "bell", ["notifications"] = "bell", ["performance"] = "gauge", ["ping"] = "signal", ["player"] = "user", ["players"] = "users", ["premium"] = "crown", ["protection"] = "shield", ["quest"] = "flag", ["quests"] = "flag", ["reset"] = "refresh", ["rewards"] = "gift", ["script"] = "code", ["scripts"] = "code", ["security"] = "lock", ["shop"] = "cart", ["sound"] = "volume", ["speed"] = "zap", ["stats"] = "bar-chart", ["store"] = "cart", ["teleport"] = "map-pin", ["theme"] = "sun", ["tools"] = "hammer", ["tp"] = "map-pin", ["ui"] = "layout", ["update"] = "refresh", ["utility"] = "hammer", ["vip"] = "crown", ["visual"] = "eye", ["visuals"] = "eye", ["weapon"] = "sword", ["weapons"] = "sword", ["webhook"] = "link", ["world"] = "globe"}
function Library:AddIconAlias(alias, target)
	IconAliases[string.lower(alias)] = target
end
function Library:GetIconAliases()
	return copy(IconAliases)
end
local iconProxy = {}
setmetatable(iconProxy, {
	__index = function(_, key)
		return function(a, b)
			local arg = a
			if a == iconProxy then
				arg = b
			end
			if type(arg) == "table" then
				local out = {}
				for k, v in pairs(arg) do
					out[k] = v
				end
				out.Icon = key
				return out
			end
			return {Icon = key, Text = arg, Name = arg}
		end
	end,
})
Library.icon = iconProxy
local ICON_STROKE = 2
local function iconDef(name)
	if type(name) == "number" then
		return {Image = "rbxassetid://" .. tostring(name)}
	end
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local def = Icons[name]
	if def == nil then
		local lowered = string.lower(name)
		def = Icons[IconAliases[lowered] or lowered]
	end
	if def ~= nil then
		if type(def) == "string" then
			return {Image = def}
		end
		return def
	end
	if name:find("^rbx") or name:find("^https?://") then
		return {Image = name}
	end
	if name:match("^%d+$") then
		return {Image = "rbxassetid://" .. name}
	end
	return nil
end
local function createIcon(name, parent, size, color, props)
	size = size or 18
	local holder = new("Frame", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	})
	if props then
		for key, value in pairs(props) do
			holder[key] = value
		end
	end
	local obj = {Frame = holder, Size = size, Name = name, _parts = {}}
	if typeof(color) == "Color3" then
		obj.Color = color
	elseif type(color) == "string" and Theme[color] then
		obj._themeKey = color
		obj.Color = Theme[color]
	else
		obj._themeKey = "Text"
		obj.Color = Theme.Text
	end
	local function paint(c, animTime)
		for _, part in ipairs(obj._parts) do
			local prop = "ImageColor3"
			if part.kind == "fill" then
				prop = "BackgroundColor3"
			elseif part.kind == "stroke" then
				prop = "Color"
			end
			if animTime then
				tween(part.inst, animTime, {[prop] = c}, ES.Quad)
			else
				part.inst[prop] = c
			end
		end
	end
	local function draw()
		for _, child in ipairs(holder:GetChildren()) do
			child:Destroy()
		end
		obj._parts = {}
		local parts = obj._parts
		local def = iconDef(obj.Name) or iconDef("help")
		local c = obj.Color
		if def.Image ~= nil then
			local img = new("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ImageColor3 = c,
				ScaleType = Enum.ScaleType.Fit,
				Parent = holder,
			})
			if def.Offset then
				img.ImageRectOffset = def.Offset
				img.ImageRectSize = def.Size or Vector2.new(0, 0)
			end
			parts[#parts + 1] = {inst = img, kind = "image"}
			local direct = resolveImage(def.Image, function(url)
				if img.Parent then
					img.Image = url
				end
			end)
			if direct then
				img.Image = direct
			end
			return
		end
		local k = size / 24
		local t = math.max(ICON_STROKE * k, 1.4)
		local function seg(x1, y1, x2, y2)
			local dx, dy = (x2 - x1) * k, (y2 - y1) * k
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset((x1 + x2) / 2 * k, (y1 + y2) / 2 * k),
				Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + t, t),
				Rotation = math.deg(math.atan2(dy, dx)),
				BackgroundColor3 = c,
				BorderSizePixel = 0,
				Parent = holder,
			})
			round(f)
			parts[#parts + 1] = {inst = f, kind = "fill"}
		end
		for _, p in ipairs(def) do
			local kind = p[1]
			if kind == "l" then
				seg(p[2], p[3], p[4], p[5])
			elseif kind == "p" or kind == "P" then
				local n = #p
				for i = 2, n - 3, 2 do
					seg(p[i], p[i + 1], p[i + 2], p[i + 3])
				end
				if kind == "P" then
					seg(p[n - 1], p[n], p[2], p[3])
				end
			elseif kind == "a" then
				local cx, cy, r, a0, a1 = p[2], p[3], p[4], p[5], p[6]
				local steps = math.max(2, math.ceil(math.abs(a1 - a0) / 22))
				local px, py = cx + r * math.cos(math.rad(a0)), cy + r * math.sin(math.rad(a0))
				for i = 1, steps do
					local a = math.rad(a0 + (a1 - a0) * i / steps)
					local nx, ny = cx + r * math.cos(a), cy + r * math.sin(a)
					seg(px, py, nx, ny)
					px, py = nx, ny
				end
			elseif kind == "c" then
				local d = math.max(2 * p[4] * k - t, 1)
				local f = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(p[2] * k, p[3] * k),
					Size = UDim2.fromOffset(d, d),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Parent = holder,
				})
				round(f)
				local st = new("UIStroke", {Color = c, Thickness = t, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f})
				parts[#parts + 1] = {inst = st, kind = "stroke"}
			elseif kind == "C" then
				local d = math.max(2 * p[4] * k, t)
				local f = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(p[2] * k, p[3] * k),
					Size = UDim2.fromOffset(d, d),
					BackgroundColor3 = c,
					BorderSizePixel = 0,
					Parent = holder,
				})
				round(f)
				parts[#parts + 1] = {inst = f, kind = "fill"}
			elseif kind == "r" then
				local f = new("Frame", {
					Position = UDim2.fromOffset(p[2] * k + t / 2, p[3] * k + t / 2),
					Size = UDim2.fromOffset(math.max(p[4] * k - t, 1), math.max(p[5] * k - t, 1)),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Parent = holder,
				})
				local cr = math.max(p[6] * k - t / 2, 0)
				if cr > 0 then
					corner(f, cr)
				end
				local st = new("UIStroke", {Color = c, Thickness = t, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f})
				parts[#parts + 1] = {inst = st, kind = "stroke"}
			end
		end
	end
	function obj:SetColor(spec)
		if typeof(spec) == "Color3" then
			self._themeKey = nil
			self.Color = spec
		elseif type(spec) == "string" and Theme[spec] then
			self._themeKey = spec
			self.Color = Theme[spec]
		else
			return
		end
		paint(self.Color)
	end
	function obj:TweenColor(c, time)
		self._themeKey = nil
		self.Color = c
		paint(c, time or 0.3)
	end
	function obj:SetIcon(newName)
		self.Name = newName
		draw()
	end
	function obj:Destroy()
		holder:Destroy()
	end
	draw()
	bindTheme(holder, function(T)
		if obj._themeKey and T[obj._themeKey] then
			obj.Color = T[obj._themeKey]
			paint(obj.Color)
		end
	end)
	return obj
end
function Library:CreateIcon(name, parent, size, color, props)
	return createIcon(name, parent, size, color, props)
end
function Library:AddIcon(name, def)
	assert(type(name) == "string", "AddIcon: nama harus string")
	if type(def) == "string" or type(def) == "number" then
		def = {Image = type(def) == "number" and ("rbxassetid://" .. def) or def}
	end
	Icons[name] = def
end
function Library:GetIconNames()
	local out = {}
	for key in pairs(Icons) do
		table.insert(out, key)
	end
	table.sort(out)
	return out
end
function Library:HasIcon(name)
	return iconDef(name) ~= nil
end
local IntroDefaults = {
	Style = "Emblem",
	Text = "R X M   H U B",
	Subtitle = "W E L C O M E",
	ImageSpin = true,
	Volume = 1.5,
	Duration = 5,
	Skippable = true,
	TypeSpeed = 0.055,
	Particles = true,
	Shockwaves = true,
	Glitch = true,
	Statuses = {
		{0, "Initializing core"},
		{0.16, "Loading modules"},
		{0.4, "Building interface"},
		{0.64, "Applying theme"},
		{0.88, "Finalizing"},
	},
	Colors = {},
}
Library.IntroDefaults = IntroDefaults
Library.Intros.Default = {Style = "Emblem"}
Library.IntroEnabled = true
function Library:SetIntroEnabled(on)
	self.IntroEnabled = on and true or false
end
function Library:AddIntro(name, config)
	assert(type(name) == "string", "AddIntro: nama intro harus string")
	if type(config) == "function" then
		config = {Style = config}
	end
	self.Intros[name] = config or {}
	return name
end
function Library:AddIntroStyle(name, builder)
	assert(type(name) == "string" and type(builder) == "function", "AddIntroStyle: butuh nama dan function")
	self.IntroStyles[name] = builder
end
function Library:SetIntro(arg)
	if type(arg) == "string" then
		if self.Intros[arg] then
			self.ActiveIntro = arg
			return true
		end
		return false
	elseif type(arg) == "table" then
		local current = self.Intros[self.ActiveIntro] or {}
		merge(current, arg)
		self.Intros[self.ActiveIntro] = current
		return true
	end
	return false
end
function Library:SetIntroText(text, subtitle)
	self:SetIntro({Text = text, Subtitle = subtitle})
end
function Library:SetIntroImage(image)
	self:SetIntro({Image = image or false})
end
function Library:SetIntroSound(sound, volume)
	self:SetIntro({Sound = sound or false, Volume = volume})
end
function Library:SetIntroStyle(style)
	self:SetIntro({Style = style})
end
function Library:SetIntroDuration(seconds)
	self:SetIntro({Duration = seconds})
end
function Library:SetIntroColor(primary, secondary, pale)
	if primary == nil then
		self:SetIntro({Colors = false})
		return
	end
	self:SetIntro({Colors = {Primary = primary, Secondary = secondary or darken(primary, 0.5), Pale = pale}})
end
function Library:GetIntroConfig(which)
	local cfg = copy(IntroDefaults)
	local src
	if type(which) == "string" then
		src = self.Intros[which]
	elseif type(which) == "table" then
		src = which
	else
		src = self.Intros[self.ActiveIntro]
	end
	if type(src) == "table" then
		if type(src.Base) == "string" and self.Intros[src.Base] and self.Intros[src.Base] ~= src then
			merge(cfg, self.Intros[src.Base])
		end
		merge(cfg, src)
	end
	local c = cfg.Colors or {}
	local primary = c.Primary or Theme.Accent
	cfg.ResolvedColors = {
		Primary = primary,
		Secondary = c.Secondary or (c.Primary and darken(c.Primary, 0.5)) or Theme.Accent2,
		Pale = c.Pale or lighten(primary, 0.3),
		Background = c.Background or BLACK,
		Text = c.Text or WHITE,
	}
	cfg.Text = tostring(cfg.Text or "")
	cfg.Subtitle = tostring(cfg.Subtitle or "")
	cfg.Letter = cfg.Letter or string.upper(cfg.Text:match("%w") or "R")
	return cfg
end
local function runIntro(cfg, onDone)
	local handle = {}
	local finished = false
	local function complete()
		if finished then
			return
		end
		finished = true
		if onDone then
			task.spawn(onDone)
		end
	end
	local gui = new("ScreenGui", {
		Name = "RXMUI_Intro",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 999999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)
	if not mountGui(gui) then
		complete()
		return handle
	end
	Library._intros[gui] = true
	local conn
	local function cleanup()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		Library._intros[gui] = nil
		pcall(function()
			gui:Destroy()
		end)
		complete()
	end
	handle.Destroy = cleanup
	task.delay((cfg.Duration or 5) + 12, function()
		if gui.Parent then
			cleanup()
		end
	end)
	local ok, err = pcall(function()
		local C = cfg.ResolvedColors
		local viewport = viewportSize()
		local compact = isTouch or viewport.X < 700
		local rng = Random.new()
		local function make(class, props, parent)
			local inst = Instance.new(class)
			for key, value in pairs(props) do
				inst[key] = value
			end
			inst.Parent = parent
			if TEXT_CLASSES[class] then
				fontTrack(inst, cfg.Font)
			end
			return inst
		end
		local stage = make("CanvasGroup", {
			Name = "Stage",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Background,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			GroupTransparency = 1,
		}, gui)
		local stageScale = make("UIScale", {Scale = 1}, stage)
		tween(stage, 0.55, {GroupTransparency = 0}, ES.Sine)
		local sound
		if cfg.Sound and cfg.Sound ~= "" then
			sound = make("Sound", {SoundId = soundId(cfg.Sound), Volume = cfg.Volume or 1.5}, gui)
			task.spawn(function()
				pcall(function()
					ContentProvider:PreloadAsync({sound})
				end)
				pcall(function()
					sound:Play()
				end)
			end)
		end
		local ctx = {
			Gui = gui,
			Stage = stage,
			Config = cfg,
			Colors = C,
			Viewport = viewport,
			Compact = compact,
			Rng = rng,
			Make = make,
			Tween = tween,
			Circle = round,
			Exiting = false,
			Time = 0,
		}
		function ctx.Icon(parent, size, colorSpec, props)
			if cfg.Icon and cfg.Icon ~= "" then
				return createIcon(cfg.Icon, parent, size, colorSpec, props)
			end
			return nil
		end
		local imgUrl, imgListeners = nil, {}
		function ctx.OnImage(fn)
			if imgUrl then
				fn(imgUrl, true)
			else
				table.insert(imgListeners, fn)
			end
		end
		local direct = resolveImage(cfg.Image, function(url)
			imgUrl = url
			for _, fn in ipairs(imgListeners) do
				pcall(fn, url, false)
			end
		end)
		if direct then
			imgUrl = direct
		end
		function ctx.StatusAt(prog)
			local idx = 1
			for i, s in ipairs(cfg.Statuses) do
				if prog >= s[1] then
					idx = i
				end
			end
			return cfg.Statuses[idx] and cfg.Statuses[idx][2] or ""
		end
		local builder = cfg.Style
		if type(builder) ~= "function" then
			builder = Library.IntroStyles[builder] or Library.IntroStyles.Emblem
		end
		local styleObj = builder(ctx) or {}
		local LEAD = 0.35
		local dur = math.max(cfg.Duration or 5, 1.2)
		local t = 0
		local exiting, faded, exitAt = false, false, 0
		local hold = styleObj.ExitHold or 0.5
		local flash = make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = lighten(C.Primary, 0.6),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 30,
		}, stage)
		local function skip()
			if not exiting then
				t = math.max(t, dur)
			end
		end
		handle.Skip = skip
		if cfg.Skippable then
			local hit = make("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 40,
			}, stage)
			hit.MouseButton1Click:Connect(skip)
		end
		local function step(dt)
			t = t + dt
			ctx.Time = t
			local u = math.clamp((t - LEAD) / math.max(dur - LEAD, 0.1), 0, 1)
			local prog = u * u * (3 - 2 * u)
			if styleObj.Step then
				styleObj.Step(t, dt, u, prog)
			end
			if not exiting and u >= 1 then
				exiting, exitAt = true, t
				ctx.Exiting = true
				local f1 = tween(flash, 0.12, {BackgroundTransparency = 0.45}, ES.Quad)
				f1.Completed:Connect(function()
					tween(flash, 0.6, {BackgroundTransparency = 1}, ES.Quad)
				end)
				if styleObj.OnComplete then
					pcall(styleObj.OnComplete)
				end
			end
			if exiting then
				local e = t - exitAt
				if not faded and e >= hold then
					faded = true
					tween(stageScale, 0.95, {Scale = 1.25}, ES.Quint, ED.In)
					tween(stage, 0.95, {GroupTransparency = 1}, ES.Sine, ED.InOut)
					if sound then
						tween(sound, 0.95, {Volume = 0}, ES.Linear)
					end
					complete()
				end
				if faded and e >= hold + 1.05 then
					cleanup()
				end
			end
		end
		local fails = 0
		conn = RunService.Heartbeat:Connect(function(rawDt)
			local okStep, stepErr = pcall(step, math.min(rawDt, 0.05))
			if not okStep then
				fails = fails + 1
				if fails >= 3 then
					warn("[RXM UI] intro error: " .. tostring(stepErr))
					cleanup()
				end
			end
		end)
	end)
	if not ok then
		warn("[RXM UI] gagal membuat intro: " .. tostring(err))
		cleanup()
	end
	return handle
end
function Library:PlayIntro(which, onDone)
	if type(which) == "function" and onDone == nil then
		onDone, which = which, nil
	end
	return runIntro(self:GetIntroConfig(which), onDone)
end
Library.IntroStyles.Emblem = function(ctx)
	local cfg, C, stage = ctx.Config, ctx.Colors, ctx.Stage
	local make, tw, circle = ctx.Make, ctx.Tween, ctx.Circle
	local viewport, compact, rng = ctx.Viewport, ctx.Compact, ctx.Rng
	local P, D, L, TXT, BG = C.Primary, C.Secondary, C.Pale, C.Text, C.Background
	local titleText = cfg.Text
	local fog = {
		{size = 980, color = P, base = 0.74, sx = 0.38, sy = 0.31, ax = 0.20, ay = 0.14, ph = 0},
		{size = 760, color = D, base = 0.62, sx = 0.27, sy = 0.44, ax = 0.26, ay = 0.18, ph = 2.1},
		{size = 640, color = P, base = 0.84, sx = 0.52, sy = 0.36, ax = 0.30, ay = 0.12, ph = 4.2},
	}
	for _, f in ipairs(fog) do
		f.img = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(f.size, f.size),
			BackgroundTransparency = 1,
			Image = GLOW,
			ImageColor3 = f.color,
			ImageTransparency = f.base,
			ZIndex = 1,
		}, stage)
	end
	local streaks = {}
	for i = 1, compact and 4 or 6 do
		local frame = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(rng:NextInteger(2, 4), math.floor(viewport.Y * 1.7)),
			Rotation = 18,
			BackgroundColor3 = i % 2 == 0 and P or D,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, stage)
		make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.55), kp(1, 1)})}, frame)
		streaks[i] = {frame = frame, speed = rng:NextNumber(0.05, 0.12), phase = rng:NextNumber(0, 1)}
	end
	local beamHalo = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, 0, 0, 130),
		BackgroundColor3 = P,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, stage)
	make("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.88), kp(1, 1)})}, beamHalo)
	local beam = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = P,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, stage)
	make("UIGradient", {Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.2), kp(1, 1)})}, beam)
	local particles = {}
	local function resetParticle(p, initial)
		p.x = rng:NextNumber(0.02, 0.98)
		p.y = initial and rng:NextNumber(0.05, 1.05) or rng:NextNumber(1.04, 1.2)
		p.vy = rng:NextNumber(0.06, 0.2)
		p.amp = rng:NextNumber(0.004, 0.022)
		p.freq = rng:NextNumber(0.8, 2.4)
		p.phase = rng:NextNumber(0, 6.28)
		p.alpha = rng:NextNumber(0.55, 0.95)
		local s = rng:NextInteger(2, 5)
		p.frame.Size = UDim2.fromOffset(s, s)
		p.frame.BackgroundColor3 = P:Lerp(L, rng:NextNumber(0, 0.5))
	end
	if cfg.Particles then
		for i = 1, compact and 28 or 46 do
			local frame = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = P,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 4,
			}, stage)
			circle(frame)
			local glow = make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(5, 5),
				BackgroundTransparency = 1,
				Image = GLOW,
				ImageColor3 = P,
				ImageTransparency = 1,
			}, frame)
			local p = {frame = frame, glow = glow}
			resetParticle(p, true)
			particles[i] = p
		end
	end
	local function edge(anchor, pos, size, rot)
		local f = make("Frame", {
			AnchorPoint = anchor,
			Position = pos,
			Size = size,
			BackgroundColor3 = BG,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, stage)
		make("UIGradient", {Rotation = rot, Transparency = NumberSequence.new({kp(0, 0), kp(1, 1)})}, f)
	end
	edge(Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, 0.3), 90)
	edge(Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.3), -90)
	edge(Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromScale(0.22, 1), 0)
	edge(Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.fromScale(0.22, 1), 180)
	local brackets = {}
	local function bracket(ax, ay)
		local m, len, th = 18, 34, 2
		for k = 1, 2 do
			local f = make("Frame", {
				AnchorPoint = Vector2.new(ax, ay),
				Position = UDim2.new(ax, ax == 0 and m or -m, ay, ay == 0 and m or -m),
				Size = k == 1 and UDim2.fromOffset(len, th) or UDim2.fromOffset(th, len),
				BackgroundColor3 = P,
				BorderSizePixel = 0,
				ZIndex = 10,
			}, stage)
			table.insert(brackets, f)
		end
	end
	bracket(0, 0)
	bracket(1, 0)
	bracket(0, 1)
	bracket(1, 1)
	local E = compact and 112 or 180
	local EY = 0.36
	local emblem = make("Frame", {
		Name = "Emblem",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, EY, 0),
		Size = UDim2.fromOffset(E, E),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, stage)
	local emblemScale = make("UIScale", {Scale = 0.3}, emblem)
	tw(emblemScale, 0.95, {Scale = 1}, ES.Back, ED.Out)
	local coreGlow = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(E * 2.2, E * 2.2),
		BackgroundTransparency = 1,
		Image = GLOW,
		ImageColor3 = P,
		ImageTransparency = 0.55,
		ZIndex = 1,
	}, emblem)
	local ticks = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(E * 1.24, E * 1.24),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, emblem)
	for i = 0, 23 do
		local a = math.rad(i * 15)
		local major = i % 6 == 0
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a)),
			Size = UDim2.fromOffset(major and 3 or 2, major and 12 or 7),
			Rotation = i * 15 + 90,
			BackgroundColor3 = P,
			BackgroundTransparency = major and 0.1 or 0.55,
			BorderSizePixel = 0,
		}, ticks)
	end
	local function ring(size, thickness, trans, colors)
		local f = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
			ZIndex = 3,
		}, emblem)
		circle(f)
		local st = make("UIStroke", {Thickness = thickness, Color = WHITE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f)
		local grad = make("UIGradient", {Color = colors, Transparency = trans}, st)
		return f, st, grad
	end
	local _, _, outerGrad = ring(E, 3,
		NumberSequence.new({kp(0, 1), kp(0.12, 0.1), kp(0.42, 0), kp(0.58, 1), kp(1, 1)}),
		ColorSequence.new({ck(0, P), ck(0.5, L), ck(1, D)}))
	local _, _, midGrad = ring(E * 0.8, 2,
		NumberSequence.new({kp(0, 1), kp(0.1, 0.15), kp(0.22, 1), kp(0.4, 1), kp(0.5, 0.15), kp(0.62, 1), kp(0.8, 1), kp(0.9, 0.25), kp(1, 1)}),
		ColorSequence.new({ck(0, D), ck(0.5, P), ck(1, D)}))
	local _, innerStroke = ring(E * 0.6, 1.5,
		NumberSequence.new({kp(0, 0), kp(1, 0)}),
		ColorSequence.new({ck(0, P), ck(1, P)}))
	local core = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(E * 0.5, E * 0.5),
		BackgroundColor3 = darken(BG, 0.2):Lerp(Color3.fromRGB(14, 14, 14), 0.8),
		BorderSizePixel = 0,
		ZIndex = 4,
	}, emblem)
	circle(core)
	make("UIStroke", {Color = P, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, core)
	local coreScale = make("UIScale", {Scale = 1}, core)
	local letter = make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = cfg.Letter,
		Font = Enum.Font.GothamBlack,
		TextSize = math.floor(E * 0.26),
		TextColor3 = TXT,
		ZIndex = 4,
	}, core)
	local iconObj = ctx.Icon(core, math.floor(E * 0.3), TXT, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 5})
	if iconObj then
		letter.Visible = false
	end
	local profile = make("ImageLabel", {
		Name = "Profile",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 5,
	}, core)
	circle(profile)
	ctx.OnImage(function(url, instant)
		if not profile.Parent then
			return
		end
		profile.Image = url
		letter.Visible = false
		if iconObj then
			iconObj.Frame.Visible = false
		end
		if instant then
			profile.ImageTransparency = 0
		else
			tw(profile, 0.45, {ImageTransparency = 0}, ES.Sine)
		end
	end)
	local orbits = {}
	for i = 1, 3 do
		local frame = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = i == 1 and TXT or P,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, emblem)
		circle(frame)
		make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(6, 6),
			BackgroundTransparency = 1,
			Image = GLOW,
			ImageColor3 = P,
			ImageTransparency = 0.35,
		}, frame)
		orbits[i] = {frame = frame, speed = 1.3 + i * 0.55, phase = i * 2.09}
	end
	local function shockwave(fromSize, toSize, life, thick)
		if not cfg.Shockwaves then
			return
		end
		local f = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(fromSize, fromSize),
			BackgroundTransparency = 1,
			ZIndex = 4,
		}, emblem)
		circle(f)
		local st = make("UIStroke", {
			Color = P,
			Thickness = thick or 3,
			Transparency = 0.15,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, f)
		tw(f, life, {Size = UDim2.fromOffset(toSize, toSize)}, ES.Quart, ED.Out)
		tw(st, life, {Transparency = 1, Thickness = 0.5}, ES.Quad, ED.In)
		task.delay(life + 0.1, function()
			f:Destroy()
		end)
	end
	local titleOff = E / 2 + (compact and 34 or 48)
	local titleHolder = make("Frame", {
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, EY, titleOff),
		Size = UDim2.new(0.94, 0, 0, 48),
		BackgroundTransparency = 1,
		ZIndex = 7,
	}, stage)
	local function titleLabel(color, z)
		local label = make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Font = Enum.Font.GothamBlack,
			TextScaled = true,
			TextColor3 = color,
			ZIndex = z,
		}, titleHolder)
		make("UITextSizeConstraint", {MaxTextSize = compact and 18 or 26, MinTextSize = 8}, label)
		return label
	end
	local ghostA = titleLabel(P, 6)
	local ghostB = titleLabel(L, 6)
	local titleMain = titleLabel(TXT, 7)
	ghostA.TextTransparency = 1
	ghostB.TextTransparency = 1
	make("UIStroke", {Color = Color3.fromRGB(10, 10, 10), Thickness = 2.5, Transparency = 0.1}, titleMain)
	local titleGrad = make("UIGradient", {
		Color = ColorSequence.new({ck(0, TXT:Lerp(P, 0.35)), ck(0.5, TXT), ck(1, TXT:Lerp(D, 0.5))}),
	}, titleMain)
	local subtitle = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, EY, titleOff + (compact and 28 or 36)),
		Size = UDim2.new(0.94, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = cfg.Subtitle,
		Font = Enum.Font.GothamMedium,
		TextSize = compact and 9 or 11,
		TextColor3 = TXT:Lerp(D, 0.35),
		TextTransparency = 1,
		ZIndex = 7,
	}, stage)
	local barW = math.clamp(viewport.X * 0.6, 240, 460)
	local bar = make("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, compact and 0.93 or 0.9, 0),
		Size = UDim2.fromOffset(barW, 44),
		BackgroundTransparency = 1,
		ZIndex = 8,
	}, stage)
	local statusLabel = make("TextLabel", {
		Size = UDim2.new(0.75, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = ctx.StatusAt(0),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = TXT:Lerp(D, 0.4),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 8,
	}, bar)
	local percent = make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.25, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = "0%",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = TXT,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 8,
	}, bar)
	local track = make("Frame", {
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = Color3.fromRGB(28, 28, 28),
		BorderSizePixel = 0,
		ZIndex = 8,
	}, bar)
	circle(track)
	make("UIStroke", {Color = P, Thickness = 1, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, track)
	local barGlow = make("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -7, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 34),
		BackgroundTransparency = 1,
		Image = GLOW,
		ImageColor3 = P,
		ImageTransparency = 0.55,
		ZIndex = 8,
	}, track)
	local fill = make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 9,
	}, track)
	circle(fill)
	make("UIGradient", {Color = ColorSequence.new({ck(0, D), ck(0.7, P), ck(1, lighten(P, 0.3))})}, fill)
	local sweep = make("Frame", {
		Size = UDim2.fromScale(0.3, 1),
		Position = UDim2.fromScale(-0.4, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, fill)
	make("UIGradient", {Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.35), kp(1, 1)})}, sweep)
	local head = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(46, 46),
		BackgroundTransparency = 1,
		Image = GLOW,
		ImageColor3 = P,
		ImageTransparency = 0.3,
		ZIndex = 11,
	}, track)
	local TYPE_START, TYPE_RATE = 0.7, math.max(cfg.TypeSpeed or 0.055, 0.005)
	local len = utf8.len(titleText) or #titleText
	local lastShown, statusIdx = -1, 0
	local glitchUntil, nextGlitch, nextWave = 0, 2.6, 0.9
	local subShown = false
	local lastStatus = ""
	local function step(t, dt, u, prog)
		for _, f in ipairs(fog) do
			f.img.Position = UDim2.fromScale(0.5 + f.ax * math.sin(t * f.sx + f.ph), 0.5 + f.ay * math.cos(t * f.sy + f.ph))
			f.img.ImageTransparency = f.base + 0.06 * math.sin(t * 1.3 + f.ph)
		end
		for _, s in ipairs(streaks) do
			s.frame.Position = UDim2.fromScale(((t * s.speed + s.phase) % 1) * 1.5 - 0.25, 0.5)
		end
		local by = ((t * 0.2) % 1.25) - 0.12
		beam.Position = UDim2.fromScale(0.5, by)
		beamHalo.Position = UDim2.fromScale(0.5, by)
		for _, p in ipairs(particles) do
			p.y = p.y - p.vy * dt
			if p.y < -0.06 then
				resetParticle(p, false)
			end
			p.frame.Position = UDim2.fromScale(p.x + math.sin(t * p.freq + p.phase) * p.amp, p.y)
			local vis = math.clamp(math.min((1.04 - p.y) / 0.1, (p.y + 0.02) / 0.3), 0, 1)
			p.frame.BackgroundTransparency = 1 - vis * p.alpha
			p.glow.ImageTransparency = 1 - vis * 0.5
		end
		local ba = 0.25 + 0.2 * math.sin(t * 2.4)
		for _, f in ipairs(brackets) do
			f.BackgroundTransparency = ba
		end
		outerGrad.Rotation = (t * 150) % 360
		midGrad.Rotation = 360 - (t * 95) % 360
		ticks.Rotation = (t * 14) % 360
		if cfg.ImageSpin then
			profile.Rotation = (t * 90) % 360
		end
		local pulse = 0.5 + 0.5 * math.sin(t * 3.2)
		coreScale.Scale = 1 + 0.07 * pulse
		coreGlow.ImageTransparency = 0.55 - 0.18 * pulse
		local gs = E * (2.2 + 0.25 * pulse)
		coreGlow.Size = UDim2.fromOffset(gs, gs)
		innerStroke.Transparency = 0.45 + 0.3 * pulse
		for _, o in ipairs(orbits) do
			local a = t * o.speed + o.phase
			o.frame.Position = UDim2.new(0.5, math.cos(a) * E * 0.41, 0.5, math.sin(a) * E * 0.41)
		end
		if t >= nextWave and not ctx.Exiting then
			nextWave = t + 1.5
			shockwave(E * 0.55, E * 2.6, 1.35, 3)
		end
		local shown = math.clamp(math.floor((t - TYPE_START) / TYPE_RATE), 0, len)
		if shown ~= lastShown then
			lastShown = shown
			local txt = titleText
			if shown < len then
				local off = utf8.offset(titleText, shown + 1)
				if off then
					txt = string.sub(titleText, 1, off - 1)
				end
			end
			titleMain.Text = txt
			ghostA.Text = txt
			ghostB.Text = txt
		end
		titleGrad.Rotation = (titleGrad.Rotation + dt * 200) % 360
		if cfg.Glitch then
			if t >= nextGlitch and shown >= len then
				glitchUntil = t + 0.16
				nextGlitch = t + rng:NextNumber(1.1, 2.4)
			end
			if t < glitchUntil then
				local j = rng:NextInteger(3, 7)
				ghostA.Position = UDim2.new(0.5, -j, 0.5, rng:NextInteger(-2, 2))
				ghostB.Position = UDim2.new(0.5, j, 0.5, rng:NextInteger(-2, 2))
				ghostA.TextTransparency = 0.3
				ghostB.TextTransparency = 0.5
				titleMain.Position = UDim2.new(0.5, rng:NextInteger(-2, 2), 0.5, 0)
			else
				ghostA.TextTransparency = 1
				ghostB.TextTransparency = 1
				titleMain.Position = UDim2.fromScale(0.5, 0.5)
			end
		end
		if not subShown and t > 2.0 then
			subShown = true
			tw(subtitle, 0.8, {TextTransparency = 0.15}, ES.Quad)
		end
		fill.Size = UDim2.fromScale(prog, 1)
		head.Position = UDim2.new(prog, 0, 0.5, 0)
		head.ImageTransparency = 0.25 + 0.15 * math.sin(t * 11)
		barGlow.Size = UDim2.new(prog, 14, 0, 34)
		sweep.Position = UDim2.fromScale((t * 0.9) % 1.6 - 0.4, 0)
		if not ctx.Exiting then
			percent.Text = math.floor(prog * 100 + 0.5) .. "%"
			local s = ctx.StatusAt(prog)
			if s ~= lastStatus then
				lastStatus = s
				statusLabel.Text = s
			end
		end
	end
	local function onComplete()
		percent.Text = "100%"
		statusLabel.Text = "Ready"
		tw(emblemScale, 0.4, {Scale = 1.2}, ES.Back, ED.Out)
		shockwave(E * 0.6, E * 8, 0.95, 6)
	end
	return {Step = step, OnComplete = onComplete}
end
Library.IntroStyles.Minimal = function(ctx)
	local cfg, C, stage = ctx.Config, ctx.Colors, ctx.Stage
	local make, tw, circle = ctx.Make, ctx.Tween, ctx.Circle
	local viewport, compact = ctx.Viewport, ctx.Compact
	local P, D, L, TXT = C.Primary, C.Secondary, C.Pale, C.Text
	local titleText = cfg.Text
	local glow = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(760, 760),
		BackgroundTransparency = 1,
		Image = GLOW,
		ImageColor3 = P,
		ImageTransparency = 0.82,
		ZIndex = 1,
	}, stage)
	local R = compact and 86 or 112
	local logo = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(R, R),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, stage)
	local logoScale = make("UIScale", {Scale = 0.4}, logo)
	tw(logoScale, 0.9, {Scale = 1}, ES.Back, ED.Out)
	local ringFrame = make("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3}, logo)
	circle(ringFrame)
	local ringStroke = make("UIStroke", {Thickness = 2.5, Color = WHITE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, ringFrame)
	local ringGrad = make("UIGradient", {
		Color = ColorSequence.new({ck(0, P), ck(0.5, L), ck(1, D)}),
		Transparency = NumberSequence.new({kp(0, 1), kp(0.15, 0.1), kp(0.5, 0), kp(0.7, 0.6), kp(1, 1)}),
	}, ringStroke)
	local faint = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, logo)
	circle(faint)
	make("UIStroke", {Thickness = 1, Color = P, Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, faint)
	local core = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.76, 0.76),
		BackgroundColor3 = Color3.fromRGB(14, 14, 14),
		BorderSizePixel = 0,
		ZIndex = 4,
	}, logo)
	circle(core)
	local letter = make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = cfg.Letter,
		Font = Enum.Font.GothamBlack,
		TextSize = math.floor(R * 0.3),
		TextColor3 = TXT,
		ZIndex = 5,
	}, core)
	local iconObj = ctx.Icon(core, math.floor(R * 0.34), TXT, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 5})
	if iconObj then
		letter.Visible = false
	end
	local profile = make("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 6,
	}, core)
	circle(profile)
	ctx.OnImage(function(url, instant)
		if not profile.Parent then
			return
		end
		profile.Image = url
		letter.Visible = false
		if iconObj then
			iconObj.Frame.Visible = false
		end
		if instant then
			profile.ImageTransparency = 0
		else
			tw(profile, 0.45, {ImageTransparency = 0}, ES.Sine)
		end
	end)
	local titleY = 0.38
	local titleOff = R / 2 + 38
	local title = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, titleY, titleOff),
		Size = UDim2.new(0.9, 0, 0, 40),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = TXT,
		ZIndex = 6,
	}, stage)
	make("UITextSizeConstraint", {MaxTextSize = compact and 22 or 32, MinTextSize = 8}, title)
	local titleGrad = make("UIGradient", {
		Color = ColorSequence.new({ck(0, TXT:Lerp(P, 0.4)), ck(0.5, TXT), ck(1, TXT:Lerp(P, 0.4))}),
	}, title)
	local lineMax = math.clamp(viewport.X * 0.34, 120, 260)
	local line = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, titleY, titleOff + 30),
		Size = UDim2.fromOffset(0, 2),
		BackgroundColor3 = P,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, stage)
	circle(line)
	make("UIGradient", {Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0), kp(1, 1)})}, line)
	local subtitle = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, titleY, titleOff + 52),
		Size = UDim2.new(0.9, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = cfg.Subtitle,
		Font = Enum.Font.GothamMedium,
		TextSize = compact and 9 or 11,
		TextColor3 = TXT:Lerp(D, 0.4),
		TextTransparency = 1,
		ZIndex = 6,
	}, stage)
	local barW = math.clamp(viewport.X * 0.5, 200, 380)
	local bar = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, compact and 0.93 or 0.9, 0),
		Size = UDim2.fromOffset(barW, 34),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, stage)
	local statusLabel = make("TextLabel", {
		Size = UDim2.new(0.75, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = ctx.StatusAt(0),
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = TXT:Lerp(D, 0.4),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, bar)
	local percent = make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.25, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = "0%",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = TXT,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
	}, bar)
	local track = make("Frame", {
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Color3.fromRGB(32, 32, 32),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, bar)
	circle(track)
	local fill = make("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = P, BorderSizePixel = 0, ZIndex = 7}, track)
	circle(fill)
	make("UIGradient", {Color = ColorSequence.new({ck(0, D), ck(1, lighten(P, 0.25))})}, fill)
	local len = utf8.len(titleText) or #titleText
	local rate = math.max(cfg.TypeSpeed or 0.055, 0.005)
	local lastShown, lastStatus, subShown = -1, "", false
	local function step(t, dt, u, prog)
		glow.ImageTransparency = 0.82 + 0.05 * math.sin(t * 1.8)
		local gs = 760 + 30 * math.sin(t * 1.3)
		glow.Size = UDim2.fromOffset(gs, gs)
		ringGrad.Rotation = (t * 160) % 360
		logo.Rotation = math.sin(t * 0.9) * 2
		local shown = math.clamp(math.floor((t - 0.6) / rate), 0, len)
		if shown ~= lastShown then
			lastShown = shown
			local txt = titleText
			if shown < len then
				local off = utf8.offset(titleText, shown + 1)
				if off then
					txt = string.sub(titleText, 1, off - 1)
				end
			end
			title.Text = txt
		end
		titleGrad.Offset = Vector2.new(((t * 0.35) % 2) - 1, 0)
		local lineP = len > 0 and shown / len or 1
		line.Size = UDim2.fromOffset(lineMax * lineP, 2)
		if not subShown and shown >= len and t > 1.2 then
			subShown = true
			tw(subtitle, 0.7, {TextTransparency = 0.2}, ES.Quad)
		end
		fill.Size = UDim2.fromScale(prog, 1)
		if not ctx.Exiting then
			percent.Text = math.floor(prog * 100 + 0.5) .. "%"
			local s = ctx.StatusAt(prog)
			if s ~= lastStatus then
				lastStatus = s
				statusLabel.Text = s
			end
		end
	end
	local function onComplete()
		percent.Text = "100%"
		statusLabel.Text = "Ready"
		tw(logoScale, 0.4, {Scale = 1.15}, ES.Back, ED.Out)
	end
	return {Step = step, OnComplete = onComplete}
end
Library.IntroStyles.Cinematic = function(ctx)
	local cfg, C, stage = ctx.Config, ctx.Colors, ctx.Stage
	local make, tw, circle = ctx.Make, ctx.Tween, ctx.Circle
	local viewport, compact, rng = ctx.Viewport, ctx.Compact, ctx.Rng
	local P, D, L, TXT, BG = C.Primary, C.Secondary, C.Pale, C.Text, C.Background
	local glow = make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(900, 420),
		BackgroundTransparency = 1,
		Image = GLOW,
		ImageColor3 = P,
		ImageTransparency = 0.8,
		ZIndex = 1,
	}, stage)
	local dust = {}
	for i = 1, compact and 14 or 24 do
		local f = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(rng:NextInteger(2, 3), rng:NextInteger(2, 3)),
			BackgroundColor3 = P:Lerp(L, rng:NextNumber(0, 1)),
			BackgroundTransparency = rng:NextNumber(0.5, 0.85),
			BorderSizePixel = 0,
			ZIndex = 2,
		}, stage)
		circle(f)
		dust[i] = {f = f, x = rng:NextNumber(0, 1), y = rng:NextNumber(0, 1), vx = rng:NextNumber(-0.01, 0.015), vy = rng:NextNumber(-0.03, -0.008), ph = rng:NextNumber(0, 6.28)}
	end
	local logoSize = compact and 58 or 72
	local logo = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, compact and -76 or -92),
		Size = UDim2.fromOffset(logoSize, logoSize),
		BackgroundColor3 = Color3.fromRGB(14, 14, 14),
		BorderSizePixel = 0,
		ZIndex = 4,
	}, stage)
	circle(logo)
	make("UIStroke", {Thickness = 2, Color = P, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, logo)
	local logoScale = make("UIScale", {Scale = 0}, logo)
	local letter = make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = cfg.Letter,
		Font = Enum.Font.GothamBlack,
		TextSize = math.floor(logoSize * 0.42),
		TextColor3 = TXT,
		ZIndex = 5,
	}, logo)
	local iconObj = ctx.Icon(logo, math.floor(logoSize * 0.46), TXT, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 5})
	if iconObj then
		letter.Visible = false
	end
	local profile = make("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 6,
	}, logo)
	circle(profile)
	ctx.OnImage(function(url, instant)
		if not profile.Parent then
			return
		end
		profile.Image = url
		letter.Visible = false
		if iconObj then
			iconObj.Frame.Visible = false
		end
		if instant then
			profile.ImageTransparency = 0
		else
			tw(profile, 0.45, {ImageTransparency = 0}, ES.Sine)
		end
	end)
	tw(logoScale, 0.9, {Scale = 1}, ES.Back, ED.Out, 0.5)
	local titleHolder = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0, compact and 40 or 56),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, stage)
	local titleScale = make("UIScale", {Scale = 1.4}, titleHolder)
	tw(titleScale, 1.5, {Scale = 1}, ES.Quint, ED.Out, 0.3)
	local title = make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = cfg.Text,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = WHITE,
		TextTransparency = 1,
		ZIndex = 6,
	}, titleHolder)
	make("UITextSizeConstraint", {MaxTextSize = compact and 28 or 46, MinTextSize = 8}, title)
	tw(title, 1.1, {TextTransparency = 0}, ES.Quad, ED.Out, 0.3)
	local sheen = make("UIGradient", {
		Color = ColorSequence.new({ck(0, TXT:Lerp(D, 0.55)), ck(0.5, WHITE), ck(1, TXT:Lerp(D, 0.55))}),
	}, title)
	local lineW = math.clamp(viewport.X * 0.5, 200, 420)
	local function hline(yOff)
		local f = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, yOff),
			Size = UDim2.fromOffset(0, 2),
			BackgroundColor3 = P,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, stage)
		make("UIGradient", {Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0), kp(1, 1)})}, f)
		tw(f, 1.3, {Size = UDim2.fromOffset(lineW, 2)}, ES.Quint, ED.Out, 0.2)
		return f
	end
	hline(compact and -34 or -44)
	hline(compact and 34 or 44)
	local subtitle = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, compact and 58 or 72),
		Size = UDim2.new(0.9, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = cfg.Subtitle,
		Font = Enum.Font.GothamMedium,
		TextSize = compact and 10 or 12,
		TextColor3 = TXT:Lerp(D, 0.35),
		TextTransparency = 1,
		ZIndex = 6,
	}, stage)
	tw(subtitle, 1.0, {TextTransparency = 0.15}, ES.Quad, ED.Out, 1.4)
	local function barFrame(top)
		local f = make("Frame", {
			AnchorPoint = Vector2.new(0.5, top and 0 or 1),
			Position = UDim2.fromScale(0.5, top and 0 or 1),
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = BG:Lerp(BLACK, 0.5),
			BorderSizePixel = 0,
			ZIndex = 20,
		}, stage)
		tw(f, 1.1, {Size = UDim2.new(1, 0, 0.17, 0)}, ES.Quint, ED.Out)
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, top and 1 or 0),
			Position = UDim2.fromScale(0.5, top and 1 or 0),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = P,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 21,
		}, f)
		return f
	end
	barFrame(true)
	local bottom = barFrame(false)
	local barW = math.clamp(viewport.X * 0.4, 180, 340)
	local track = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 4),
		Size = UDim2.fromOffset(barW, 2),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0,
		ZIndex = 22,
	}, bottom)
	local fill = make("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = P, BorderSizePixel = 0, ZIndex = 23}, track)
	make("UIGradient", {Color = ColorSequence.new({ck(0, D), ck(1, lighten(P, 0.3))})}, fill)
	local percent = make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -14),
		Size = UDim2.fromOffset(barW, 14),
		BackgroundTransparency = 1,
		Text = ctx.StatusAt(0) .. "  0%",
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		TextColor3 = TXT:Lerp(D, 0.35),
		ZIndex = 22,
	}, bottom)
	local lastText = ""
	local function step(t, dt, u, prog)
		glow.ImageTransparency = 0.8 + 0.05 * math.sin(t * 1.6)
		sheen.Offset = Vector2.new(((t * 0.45) % 1) * 2.6 - 1.3, 0)
		for _, d in ipairs(dust) do
			d.x = d.x + d.vx * dt
			d.y = d.y + d.vy * dt
			if d.y < -0.05 then
				d.y = 1.05
				d.x = rng:NextNumber(0, 1)
			end
			if d.x < -0.05 then
				d.x = 1.05
			elseif d.x > 1.05 then
				d.x = -0.05
			end
			d.f.Position = UDim2.fromScale(d.x + math.sin(t * 0.8 + d.ph) * 0.004, d.y)
		end
		fill.Size = UDim2.fromScale(prog, 1)
		if not ctx.Exiting then
			local txt = ctx.StatusAt(prog) .. "  " .. math.floor(prog * 100 + 0.5) .. "%"
			if txt ~= lastText then
				lastText = txt
				percent.Text = txt
			end
		end
	end
	local function onComplete()
		percent.Text = "Ready  100%"
		tw(titleScale, 0.5, {Scale = 1.08}, ES.Back, ED.Out)
	end
	return {Step = step, OnComplete = onComplete, ExitHold = 0.6}
end
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local TAB_POSITION_ALIAS = {
	up = "Up",
	top = "Up",
	atas = "Up",
	down = "Down",
	bottom = "Down",
	bawah = "Down",
	left = "Left",
	kiri = "Left",
	right = "Right",
	kanan = "Right",
}
local function normalizeTabPosition(value)
	if type(value) ~= "string" then
		return nil
	end
	local cleaned = string.gsub(value, "%s", "")
	return TAB_POSITION_ALIAS[string.lower(cleaned)]
end
local function kindColor(kind)
	if kind == "success" then
		return Color3.fromRGB(64, 222, 140)
	elseif kind == "error" then
		return Color3.fromRGB(246, 78, 88)
	elseif kind == "warn" then
		return Color3.fromRGB(255, 192, 64)
	end
	return Theme.Accent
end
function Window:_connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self.Connections, c)
	return c
end
function Window:_fire(callback, ...)
	if not callback then
		return
	end
	local ok, err = pcall(callback, ...)
	if not ok then
		self:Notify({Title = "Callback error", Content = tostring(err), Type = "error", Duration = 5})
	end
end
function Window:_build(opts)
	local W = self
	local IDLE_H = 36
	local baseW = math.clamp(tonumber(W.IslandWidth) or 142, 90, 420)
	W.IslandWidth = baseW
	local function fitIslandWidth()
		local ok, size = pcall(function()
			return TextService:GetTextSize(tostring(W.Name), 12, Enum.Font.GothamBold, Vector2.new(2000, 20))
		end)
		if not ok or typeof(size) ~= "Vector2" then
			return baseW
		end
		local need = math.ceil(size.X) + 72
		local cap = math.max(baseW, viewportSize().X - 40)
		return math.clamp(math.max(baseW, need), baseW, cap)
	end
	local idleW = fitIslandWidth()
	local NOTIFY_H = 64
	local function notifyWidth()
		return math.max(300, idleW + 40)
	end
	local PAD_Y = 8
	local PANEL_R = 30
	local HEADER_H, TABBAR_H = 46, 34
	local PAGE_TOP = HEADER_H + TABBAR_H + 8
	local PW, PH = 450, 360
	if typeof(opts.Size) == "Vector2" then
		PW, PH = opts.Size.X, opts.Size.Y
	end
	local viewport = viewportSize()
	if isTouch or viewport.X < 700 then
		PW = math.clamp(viewport.X - 24, 290, 410)
		PH = math.clamp(viewport.Y - 70, 236, 320)
	end
	W.PW, W.PH = PW, PH
	local TP = {
		pos = normalizeTabPosition(W.TabPosition) or "Up",
		side = math.clamp(math.floor(PW * 0.24), 80, 120),
		top = HEADER_H + 4,
		shift = {
			Up = Vector2.new(0, -8),
			Down = Vector2.new(0, 8),
			Left = Vector2.new(-8, 0),
			Right = Vector2.new(8, 0),
		},
	}
	TP.vertical = TP.pos == "Left" or TP.pos == "Right"
	W.TabPosition = TP.pos
	W.PageWidth = PW - 24
	W._layoutHooks = {}
	function TP.slide(d)
		if TP.vertical then
			return UDim2.fromScale(0, d)
		end
		return UDim2.fromScale(d, 0)
	end
	function TP.itemSize(count)
		local barH = PH - (TP.top + 12)
		return math.clamp(math.floor((barH - 12) / math.max(count, 1)), 24, 36)
	end
	local gui = new("ScreenGui", {
		Name = "RXMUI_Window",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		IgnoreGuiInset = true,
	})
	if not mountGui(gui) then
		error("RXM UI: GUI tidak bisa dipasang (gethui / CoreGui / PlayerGui gagal)")
	end
	W.Gui = gui
	W.Click = makeClicker(gui, function()
		return W.Alive and W.FX.Sounds
	end)
	W.Sfx = makeSfx(gui, function(flag)
		return W.Alive and W.FX[flag]
	end)
	local PROFILES = {
		open = {w = {175, 0.64}, h = {150, 0.66}, r = {210, 0.72}},
		close = {w = {250, 0.82}, h = {270, 0.86}, r = {270, 0.86}},
		pop = {w = {235, 0.58}, h = {265, 0.62}, r = {270, 0.70}},
		swap = {w = {225, 0.70}, h = {245, 0.74}, r = {260, 0.80}},
	}
	local sp = {
		w = newSpring(idleW, 190, 0.7),
		h = newSpring(IDLE_H, 210, 0.7),
		r = newSpring(IDLE_H / 2, 220, 0.7),
		ox = newSpring(0, 150, 0.85),
		oy = newSpring(0, 150, 0.85),
		press = newSpring(1, 380, 0.5),
		show = newSpring(0, 170, 0.72),
	}
	local function applyProfile(p)
		tuneSpring(sp.w, p.w[1], p.w[2])
		tuneSpring(sp.h, p.h[1], p.h[2])
		tuneSpring(sp.r, p.r[1], p.r[2])
	end
	applyProfile(PROFILES.pop)
	local state, hover = "idle", false
	local clock, glowKick = 0, 0
	local visible = true
	local panelPos = {x = 0, y = math.floor(IDLE_H * W.Scale + 8)}
	local shell = new("Frame", {
		Name = "Island",
		ZIndex = 5,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, PAD_Y),
		Size = UDim2.fromOffset(idleW, IDLE_H),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	local shellScale = new("UIScale", {Scale = 0.001, Parent = shell})
	W._shell, W._shellScale = shell, shellScale
	local backdrop = new("TextButton", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 1,
		Visible = false,
		Parent = gui,
	})
	local halos = {}
	do
		local count, spread, total = 10, 54, 0.30
		local weights, sum = {}, 0
		for i = 1, count do
			local k = (i - 0.5) / count
			weights[i] = 6 * k * (1 - k)
			sum = sum + weights[i]
		end
		for i = 1, count do
			local grow = spread * i / count
			local frame = new("Frame", {
				Name = "Glow" .. i,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, grow, 1, grow),
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 1,
				Parent = shell,
			})
			halos[i] = {frame = frame, corner = corner(frame, 20), grow = grow, alpha = 1 - (1 - total) ^ (weights[i] / sum)}
			bindTheme(frame, function(T, f)
				f.BackgroundColor3 = T.Accent
			end)
		end
	end
	local island = new("CanvasGroup", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ZIndex = 2,
		Active = true,
		Parent = shell,
	})
	local islandCorner = corner(island, IDLE_H / 2)
	bindTheme(island, function(T, f)
		f.BackgroundColor3 = T.Background
		f.BackgroundTransparency = math.clamp(Library.Transparency, 0, 0.85)
	end)
	local sheen = new("Frame", {
		Name = "Sheen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = island,
	})
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({kp(0, 0.92), kp(0.45, 0.985), kp(1, 1)}),
		Parent = sheen,
	})
	local borderFrame = new("Frame", {
		Name = "Border",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = shell,
	})
	local borderCorner = corner(borderFrame, IDLE_H / 2)
	local border = stroke(borderFrame, WHITE, 1.6, 0.2)
	local borderGrad = new("UIGradient", {
		Transparency = NumberSequence.new({kp(0, 0), kp(0.3, 0.78), kp(0.7, 0.78), kp(1, 0)}),
		Parent = border,
	})
	bindTheme(borderFrame, function(T)
		borderGrad.Color = ColorSequence.new({ck(0, T.Accent), ck(0.5, T.Accent2), ck(1, T.Accent)})
	end)
	local function makeGroup(name, w, h)
		local frame = new("CanvasGroup", {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, h / 2),
			Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 3,
			Parent = island,
		})
		local scale = new("UIScale", {Scale = 0.85, Parent = frame})
		return {frame = frame, scale = scale, tok = 0}
	end
	local function showGroup(g, on, delay, dur)
		g.tok = g.tok + 1
		local tok = g.tok
		local function apply()
			if g.tok ~= tok or not W.Alive then
				return
			end
			if on then
				g.frame.Visible = true
				tween(g.frame, dur or 0.3, {GroupTransparency = 0}, ES.Quad, ED.Out)
				tween(g.scale, 0.5, {Scale = 1}, ES.Back, ED.Out)
			else
				tween(g.frame, dur or 0.12, {GroupTransparency = 1}, ES.Quad, ED.In)
				tween(g.scale, 0.2, {Scale = 0.88}, ES.Quad, ED.In)
				task.delay((dur or 0.12) + 0.03, function()
					if g.tok == tok then
						g.frame.Visible = false
					end
				end)
			end
		end
		if (delay or 0) > 0 then
			task.delay(delay, apply)
		else
			apply()
		end
	end
	local idleG = makeGroup("Idle", idleW, IDLE_H)
	local notifyG = makeGroup("Notify", notifyWidth(), NOTIFY_H)
	local panelG = makeGroup("Panel", PW, PH)
	corner(panelG.frame, PANEL_R)
	local panel = panelG.frame
	local idleHalo = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = idleG.frame,
	})
	round(idleHalo)
	local idleDot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = idleG.frame,
	})
	round(idleDot)
	local idleLabel = new("TextLabel", {
		Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -66, 1, 0),
		BackgroundTransparency = 1,
		Text = W.Name,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextScaled = true,
		TextColor3 = WHITE,
		Parent = idleG.frame,
	})
	new("UITextSizeConstraint", {MaxTextSize = 12, MinTextSize = 8, Parent = idleLabel})
	local idleGrad = new("UIGradient", {Offset = Vector2.new(-1, 0), Parent = idleLabel})
	local barBox = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(19, 14),
		BackgroundTransparency = 1,
		Parent = idleG.frame,
	})
	local idleBars = {}
	for i = 1, 4 do
		local b = new("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, (i - 1) * 5, 1, 0),
			Size = UDim2.fromOffset(3, 4),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Parent = barBox,
		})
		round(b)
		idleBars[i] = b
	end
	bindTheme(idleDot, function(T)
		idleHalo.BackgroundColor3 = T.Accent
		idleDot.BackgroundColor3 = T.Accent
		for _, b in ipairs(idleBars) do
			b.BackgroundColor3 = T.Accent
		end
		local base = lighten(T.Accent, 0.55)
		idleGrad.Color = ColorSequence.new({ck(0, base), ck(0.5, WHITE), ck(1, base)})
	end)
	local idleRest = {dot = idleDot.Position, halo = idleHalo.Position, bars = barBox.Position}
	local idleTok = 0
	local function idleIntro(delay)
		idleTok = idleTok + 1
		local tok = idleTok
		idleDot.Position = idleRest.dot + UDim2.fromOffset(12, 0)
		idleHalo.Position = idleRest.halo + UDim2.fromOffset(12, 0)
		barBox.Position = idleRest.bars + UDim2.fromOffset(-12, 0)
		idleLabel.TextTransparency = 1
		task.delay(delay or 0, function()
			if tok ~= idleTok or not W.Alive then
				return
			end
			tween(idleDot, 0.55, {Position = idleRest.dot}, ES.Back, ED.Out)
			tween(idleHalo, 0.55, {Position = idleRest.halo}, ES.Back, ED.Out)
			tween(barBox, 0.55, {Position = idleRest.bars}, ES.Back, ED.Out)
			tween(idleLabel, 0.4, {TextTransparency = 0}, ES.Quad, ED.Out, 0.04)
		end)
	end
	local idleHit = new("TextButton", {
		Name = "Hit",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 10,
		Parent = idleG.frame,
	})
	local noteIcon = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		Parent = notifyG.frame,
	})
	round(noteIcon)
	local noteStroke = stroke(noteIcon, Theme.Accent, 1.5, 0.3)
	local noteTitle = new("TextLabel", {
		Position = UDim2.new(0, 60, 0.5, -17),
		Size = UDim2.new(1, -76, 0, 17),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = notifyG.frame,
	})
	local noteMsg = new("TextLabel", {
		Position = UDim2.new(0, 60, 0.5, 1),
		Size = UDim2.new(1, -76, 0, 16),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = notifyG.frame,
	})
	local noteBar = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -6),
		Size = UDim2.new(1, -32, 0, 2),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = notifyG.frame,
	})
	round(noteBar)
	local noteHit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 10,
		Parent = notifyG.frame,
	})
	local aurora = {}
	do
		local cfgs = {
			{size = 340, ax = 0.30, ay = 0.18, sx = 0.31, sy = 0.23, ph = 0, base = 0.9, cx = 0.2, cy = 0.15},
			{size = 300, ax = 0.28, ay = 0.20, sx = 0.22, sy = 0.37, ph = 2.2, base = 0.92, cx = 0.85, cy = 0.55},
			{size = 380, ax = 0.24, ay = 0.16, sx = 0.27, sy = 0.19, ph = 4.1, base = 0.93, cx = 0.45, cy = 0.95},
		}
		for _, cfg in ipairs(cfgs) do
			cfg.frame = new("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(cfg.cx, cfg.cy),
				Size = UDim2.fromOffset(cfg.size, cfg.size),
				BackgroundTransparency = 1,
				Image = GLOW,
				ImageColor3 = Theme.Accent,
				ImageTransparency = cfg.base,
				ZIndex = 1,
				Parent = panel,
			})
			bindTheme(cfg.frame, function(T, f)
				f.ImageColor3 = T.Accent
			end)
			table.insert(aurora, cfg)
		end
	end
	local header = new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = panel,
	})
	local logoHalo = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 28, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = header,
	})
	round(logoHalo)
	local logoDot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 28, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = header,
	})
	round(logoDot)
	local title = new("TextLabel", {
		Position = UDim2.new(0, 48, 0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		BackgroundTransparency = 1,
		Text = W.Name,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = header,
	})
	local titleGrad = new("UIGradient", {Offset = Vector2.new(-1, 0), Parent = title})
	bindTheme(logoDot, function(T)
		logoHalo.BackgroundColor3 = T.Accent
		logoDot.BackgroundColor3 = T.Accent
		local base = lighten(T.Accent, 0.55)
		titleGrad.Color = ColorSequence.new({ck(0, base), ck(0.5, WHITE), ck(1, base)})
	end)
	local headerIcon = createIcon(W.Icon or "circle", header, 18, "Accent", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 28, 0.5, 0),
		ZIndex = 4,
		Visible = false,
	})
	local idleIcon = createIcon(W.Icon or "circle", idleG.frame, 14, "Accent", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Visible = false,
	})
	function W:SetIcon(name)
		if name == "" or name == false then
			name = nil
		end
		W.Icon = name
		local has = name ~= nil
		logoDot.Visible = not has
		logoHalo.Visible = not has
		idleDot.Visible = not has
		idleHalo.Visible = not has
		headerIcon.Frame.Visible = has
		idleIcon.Frame.Visible = has
		if has then
			headerIcon:SetIcon(name)
			idleIcon:SetIcon(name)
		end
	end
	W:SetIcon(W.Icon)
	local tabBar = new("Frame", {
		Name = "Tabs",
		Position = UDim2.new(0, 12, 0, HEADER_H),
		Size = UDim2.new(1, -24, 0, TABBAR_H),
		BackgroundColor3 = Theme.Input,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = panel,
	})
	local tabCorner = round(tabBar)
	local tabBarStroke = stroke(tabBar, Theme.Stroke, 1, 0.3)
	bindTheme(tabBar, function()
		tabBar.BackgroundTransparency = math.clamp(0.1 + Library.Transparency * 0.6, 0, 0.9)
	end)
	local highlight = new("Frame", {
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = tabBar,
	})
	round(highlight)
	local highlightStroke = stroke(highlight, Theme.Accent, 1, 0.4)
	bindTheme(highlight, function(T)
		highlight.BackgroundColor3 = T.Accent
		highlightStroke.Color = T.Accent
	end)
	TP.divider = new("Frame", {
		Position = UDim2.new(0, 14, 0, PAGE_TOP - 5),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = panel,
	})
	local neonLine = new("Frame", {
		Position = UDim2.new(0, 14, 0, PAGE_TOP - 6),
		Size = UDim2.new(1, -28, 0, 2),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = panel,
	})
	local neonGrad = new("UIGradient", {
		Offset = Vector2.new(-1, 0),
		Transparency = NumberSequence.new({kp(0, 1), kp(0.35, 0.6), kp(0.5, 0), kp(0.65, 0.6), kp(1, 1)}),
		Parent = neonLine,
	})
	bindTheme(neonLine, function(T)
		neonGrad.Color = ColorSequence.new({ck(0, T.Accent), ck(0.5, lighten(T.Accent, 0.65)), ck(1, T.Accent)})
	end)
	local pageHost = new("Frame", {
		Name = "Pages",
		Position = UDim2.new(0, 12, 0, PAGE_TOP),
		Size = UDim2.new(1, -24, 1, -(PAGE_TOP + 12)),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = panel,
	})
	local fadeBottom = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ZIndex = 8,
		Parent = pageHost,
	})
	local fadeGrad = new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({kp(0, 1), kp(1, 0)}), Parent = fadeBottom})
	bindTheme(fadeBottom, function(T, f)
		f.BackgroundColor3 = T.Background
		fadeGrad.Transparency = NumberSequence.new({kp(0, 1), kp(1, math.clamp(Library.Transparency, 0, 0.85))})
	end)
	W._tabBar, W._pageHost = tabBar, pageHost
	local chromeRest = {header = header.Position, tabs = tabBar.Position, pages = pageHost.Position}
	function TP.geometry(pos)
		local side, top = TP.side, TP.top
		local line = TP.divider
		TP.pos = pos
		TP.vertical = pos == "Left" or pos == "Right"
		neonGrad.Rotation = TP.vertical and 90 or 0
		tabCorner.CornerRadius = TP.vertical and UDim.new(0, 16) or UDim.new(0.5, 0)
		if pos == "Up" then
			tabBar.AnchorPoint = Vector2.new(0, 0)
			tabBar.Position = UDim2.new(0, 12, 0, HEADER_H)
			tabBar.Size = UDim2.new(1, -24, 0, TABBAR_H)
			line.Position = UDim2.new(0, 14, 0, PAGE_TOP - 5)
			line.Size = UDim2.new(1, -28, 0, 1)
			neonLine.Position = UDim2.new(0, 14, 0, PAGE_TOP - 6)
			neonLine.Size = UDim2.new(1, -28, 0, 2)
			pageHost.Position = UDim2.new(0, 12, 0, PAGE_TOP)
			pageHost.Size = UDim2.new(1, -24, 1, -(PAGE_TOP + 12))
			W.PageWidth = PW - 24
		elseif pos == "Down" then
			tabBar.AnchorPoint = Vector2.new(0, 1)
			tabBar.Position = UDim2.new(0, 12, 1, -12)
			tabBar.Size = UDim2.new(1, -24, 0, TABBAR_H)
			line.Position = UDim2.new(0, 14, 1, -(12 + TABBAR_H + 4))
			line.Size = UDim2.new(1, -28, 0, 1)
			neonLine.Position = UDim2.new(0, 14, 1, -(12 + TABBAR_H + 4))
			neonLine.Size = UDim2.new(1, -28, 0, 2)
			pageHost.Position = UDim2.new(0, 12, 0, top)
			pageHost.Size = UDim2.new(1, -24, 1, -(top + 12 + TABBAR_H + 8))
			W.PageWidth = PW - 24
		elseif pos == "Left" then
			local edge = 12 + side
			tabBar.AnchorPoint = Vector2.new(0, 0)
			tabBar.Position = UDim2.new(0, 12, 0, top)
			tabBar.Size = UDim2.new(0, side, 1, -(top + 12))
			line.Position = UDim2.new(0, edge + 7, 0, top + 8)
			line.Size = UDim2.new(0, 1, 1, -(top + 28))
			neonLine.Position = UDim2.new(0, edge + 6, 0, top + 8)
			neonLine.Size = UDim2.new(0, 2, 1, -(top + 28))
			pageHost.Position = UDim2.new(0, edge + 14, 0, top)
			pageHost.Size = UDim2.new(1, -(edge + 26), 1, -(top + 12))
			W.PageWidth = PW - (edge + 26)
		else
			local edge = 12 + side
			tabBar.AnchorPoint = Vector2.new(1, 0)
			tabBar.Position = UDim2.new(1, -12, 0, top)
			tabBar.Size = UDim2.new(0, side, 1, -(top + 12))
			line.Position = UDim2.new(1, -(edge + 7), 0, top + 8)
			line.Size = UDim2.new(0, 1, 1, -(top + 28))
			neonLine.Position = UDim2.new(1, -(edge + 8), 0, top + 8)
			neonLine.Size = UDim2.new(0, 2, 1, -(top + 28))
			pageHost.Position = UDim2.new(0, 12, 0, top)
			pageHost.Size = UDim2.new(1, -(edge + 26), 1, -(top + 12))
			W.PageWidth = PW - (edge + 26)
		end
		chromeRest.tabs = tabBar.Position
		chromeRest.pages = pageHost.Position
	end
	TP.geometry(TP.pos)
	local function revealChrome(delay)
		local sh = TP.shift[TP.pos]
		header.Position = chromeRest.header + UDim2.fromOffset(0, -10)
		tabBar.Position = chromeRest.tabs + UDim2.fromOffset(sh.X, sh.Y)
		pageHost.Position = chromeRest.pages + UDim2.fromOffset(0, 10)
		tween(header, 0.65, {Position = chromeRest.header}, ES.Quint, ED.Out, delay)
		tween(tabBar, 0.65, {Position = chromeRest.tabs}, ES.Quint, ED.Out, delay + 0.04)
		tween(pageHost, 0.65, {Position = chromeRest.pages}, ES.Quint, ED.Out, delay + 0.08)
	end
	local function hideChrome()
		local sh = TP.shift[TP.pos]
		tween(header, 0.22, {Position = chromeRest.header + UDim2.fromOffset(0, -6)}, ES.Quad, ED.In)
		tween(tabBar, 0.22, {Position = chromeRest.tabs + UDim2.fromOffset(sh.X / 2, sh.Y / 2)}, ES.Quad, ED.In)
		tween(pageHost, 0.22, {Position = chromeRest.pages + UDim2.fromOffset(0, 6)}, ES.Quad, ED.In)
	end
	local embers = new("Frame", {
		Name = "Embers",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 6,
		Parent = panel,
	})
	do
		local haze = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = embers})
		local hazeGrad = new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({kp(0, 1), kp(0.7, 1), kp(1, 0.88)}),
			Parent = haze,
		})
		bindTheme(haze, function(T)
			hazeGrad.Color = ColorSequence.new(T.Accent)
		end)
		local function spawnSpark()
			if not embers.Parent then
				return
			end
			local size = math.random(2, 4)
			local x = math.random()
			local drift = (math.random() - 0.5) * 0.14
			local travel = 0.4 + math.random() * 0.5
			local life = 3 + math.random() * 3
			local spark = new("Frame", {
				BackgroundColor3 = Theme.Accent:Lerp(Color3.new(1, 0.9, 0.7), math.random() * 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(size, size),
				Position = UDim2.new(x, 0, 1.02, 0),
				Parent = embers,
			})
			round(spark)
			tween(spark, life, {Position = UDim2.new(x + drift, 0, 1.02 - travel, 0)}, ES.Sine, ED.Out)
			tween(spark, 0.6, {BackgroundTransparency = 0.3}, ES.Quad, ED.Out)
			task.delay(life * 0.55, function()
				if spark.Parent then
					tween(spark, life * 0.45, {BackgroundTransparency = 1}, ES.Linear, ED.In)
				end
			end)
			task.delay(life + 0.1, function()
				spark:Destroy()
			end)
		end
		task.spawn(function()
			while W.Alive do
				if W.FX.Embers and state == "expanded" then
					spawnSpark()
				end
				task.wait(isTouch and 0.7 or 0.4)
			end
		end)
	end
	local function applyFX()
		local fx = W.FX
		border.Color = fx.Border and WHITE or Theme.Stroke
		border.Transparency = fx.Border and 0.2 or 0.35
		borderGrad.Enabled = fx.Border
		neonLine.BackgroundTransparency = fx.Neon and 0 or 1
		titleGrad.Enabled = fx.Shimmer
		idleGrad.Enabled = fx.Shimmer
		embers.Visible = fx.Embers
		for _, a in ipairs(aurora) do
			a.frame.Visible = fx.Aurora
		end
	end
	applyFX()
	function W:SetEffect(name, on)
		if self.FX[name] ~= nil then
			self.FX[name] = on and true or false
			applyFX()
		end
	end
	local function limits()
		local vp = viewportSize()
		local maxX = math.max(0, vp.X / 2 - PW * W.Scale / 2 - 4)
		local minY = 4 - PAD_Y
		local maxY = math.max(minY, vp.Y - 4 - PAD_Y - PH * W.Scale)
		return maxX, minY, maxY
	end
	local function applyTargets()
		if state == "expanded" then
			local maxX, minY, maxY = limits()
			panelPos.x = math.clamp(panelPos.x, -maxX, maxX)
			panelPos.y = math.clamp(panelPos.y, minY, maxY)
			sp.w.t, sp.h.t, sp.r.t = PW, PH, PANEL_R
			sp.ox.t, sp.oy.t = panelPos.x, panelPos.y
		elseif state == "notify" then
			sp.w.t, sp.h.t, sp.r.t = notifyWidth(), NOTIFY_H, NOTIFY_H / 2
			sp.ox.t, sp.oy.t = 0, 0
		else
			sp.w.t = idleW + (hover and 10 or 0)
			sp.h.t = IDLE_H + (hover and 2 or 0)
			sp.r.t = sp.h.t / 2
			sp.ox.t, sp.oy.t = 0, 0
		end
	end
	local function updateBackdrop()
		backdrop.Visible = state == "expanded" and visible
	end

	local function setState(newState)
		if not W.Alive or newState == state then
			return
		end
		local old = state
		state = newState
		W.State = newState
		if newState ~= "expanded" and W._closeSearch then
			W._closeSearch(true)
		end
		updateBackdrop()
		glowKick = 1
		if newState == "expanded" then
			W.Sfx("Open")
			applyProfile(PROFILES.open)
			applyTargets()
			showGroup(idleG, false, 0, 0.1)
			showGroup(notifyG, false, 0, 0.1)
			showGroup(panelG, true, 0.1, 0.32)
			revealChrome(0.12)
			if W._selectFirst then
				W._selectFirst()
			end
		elseif newState == "notify" then
			applyProfile(PROFILES.swap)
			applyTargets()
			showGroup(idleG, false, 0, 0.1)
			showGroup(panelG, false, 0, 0.1)
			showGroup(notifyG, true, 0.08, 0.3)
		else
			applyProfile(old == "expanded" and PROFILES.close or PROFILES.swap)
			applyTargets()
			showGroup(panelG, false, 0, 0.12)
			showGroup(notifyG, false, 0, 0.1)
			showGroup(idleG, true, 0.12, 0.3)
			idleIntro(0.14)
			if old == "expanded" then
				W.Sfx("Open")
				hideChrome()
			end
		end
	end
	function W:SetState(s)
		setState(s)
	end
	function W:Open()
		setState("expanded")
	end
	function W:Close()
		setState("idle")
	end
	function W:Toggle()
		setState(state == "expanded" and "idle" or "expanded")
	end
	function W:SetVisible(on)
		visible = on and true or false
		updateBackdrop()
		sp.show.t = visible and 1 or 0
		if visible then
			applyProfile(PROFILES.pop)
		end
	end
	function W:IsOpen()
		return state == "expanded"
	end
	local function refitIsland()
		idleW = fitIslandWidth()
		idleG.frame.Size = UDim2.fromOffset(idleW, IDLE_H)
		notifyG.frame.Size = UDim2.fromOffset(notifyWidth(), NOTIFY_H)
		if state ~= "expanded" then
			applyProfile(PROFILES.swap)
		end
		applyTargets()
	end
	function W:SetIslandWidth(width)
		width = tonumber(width)
		if not width then
			return
		end
		baseW = math.clamp(width, 90, 420)
		W.IslandWidth = baseW
		refitIsland()
	end
	function W:GetIslandWidth()
		return baseW
	end
	function W:SetScale(scale)
		self.Scale = math.clamp(scale, 0.6, 1.4)
		applyTargets()
	end
	function W:SetToggleKey(key)
		self.ToggleKey = key
	end
	function W:SetTitle(text)
		self.Name = tostring(text)
		title.Text = self.Name
		idleLabel.Text = self.Name
		refitIsland()
	end
	idleHit.MouseEnter:Connect(function()
		hover = true
		if state == "idle" then
			applyTargets()
		end
	end)
	idleHit.MouseLeave:Connect(function()
		hover = false
		sp.press.t = 1
		if state == "idle" then
			applyTargets()
		end
	end)
	idleHit.InputBegan:Connect(function(input)
		if isPress(input) then
			sp.press.t = 0.92
		end
	end)
	idleHit.InputEnded:Connect(function(input)
		if isPress(input) then
			sp.press.t = 1
		end
	end)
	idleHit.MouseButton1Click:Connect(function()
		setState("expanded")
	end)
	noteHit.MouseButton1Click:Connect(function()
		setState("expanded")
	end)
	backdrop.MouseButton1Click:Connect(function()
		if state == "expanded" then
			setState("idle")
		end
	end)
	local dragging, dragStart, dragOrigin = false, nil, nil
	header.InputBegan:Connect(function(input)
		if state == "expanded" and isPress(input) then
			dragging = true
			dragStart = input.Position
			dragOrigin = Vector2.new(panelPos.x, panelPos.y)
		end
	end)
	W:_connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			local d = (input.Position - dragStart) / math.max(W.Scale, 0.1)
			local maxX, minY, maxY = limits()
			panelPos.x = math.clamp(dragOrigin.X + d.X, -maxX, maxX)
			panelPos.y = math.clamp(dragOrigin.Y + d.Y, minY, maxY)
			sp.ox.t, sp.oy.t = panelPos.x, panelPos.y
		end
	end)
	W:_connect(UserInputService.InputEnded, function(input)
		if isPress(input) then
			dragging = false
		end
	end)
	W:_connect(UserInputService.InputBegan, function(input, processed)
		if processed or W.Capturing then
			return
		end
		if input.KeyCode == W.ToggleKey and W.ToggleKey ~= Enum.KeyCode.Unknown then
			W:SetVisible(not visible)
		end
	end)
	W:_connect(RunService.Heartbeat, function(rawDt)
		if not W.Alive then
			return
		end
		local dt = math.min(rawDt, 0.05)
		clock = clock + dt
		for _, s in pairs(sp) do
			stepSpring(s, dt)
		end
		local show = sp.show.x > 0.01 or sp.show.t > 0
		shell.Visible = show
		if not show then
			return
		end
		local w, h = math.max(sp.w.x, 8), math.max(sp.h.x, 8)
		shell.Size = UDim2.fromOffset(w, h)
		shell.Position = UDim2.new(0.5, sp.ox.x, 0, PAD_Y + sp.oy.x)
		shellScale.Scale = math.max(W.Scale * sp.show.x * sp.press.x, 0.001)
		local r = math.clamp(sp.r.x, 4, math.max(math.min(w, h) / 2, 4))
		islandCorner.CornerRadius = UDim.new(0, r)
		borderCorner.CornerRadius = UDim.new(0, r)
		glowKick = math.max(glowKick - dt * 1.4, 0)
		local mult = W.FX.Glow and (0.7 + 0.3 * math.sin(clock * 1.7) + glowKick * 0.9) or 0
		for _, hl in ipairs(halos) do
			hl.frame.BackgroundTransparency = 1 - math.clamp(hl.alpha * mult, 0, 0.95)
			hl.corner.CornerRadius = UDim.new(0, r + hl.grow * 0.5)
		end
		if W.FX.Border then
			borderGrad.Rotation = (clock * W.BorderSpeed) % 360
		end
		if state ~= "expanded" then
			for i, b in ipairs(idleBars) do
				b.Size = UDim2.fromOffset(3, 4 + 9 * math.abs(math.sin(clock * (1.9 + i * 0.65) + i * 1.3)))
			end
			if W.FX.Shimmer then
				idleGrad.Offset = Vector2.new(((clock * 0.5) % 2) - 1, 0)
			end
			local pulse = 0.5 + 0.5 * math.sin(clock * 3)
			idleHalo.Size = UDim2.fromOffset(8 + pulse * 7, 8 + pulse * 7)
			idleHalo.BackgroundTransparency = 0.5 + pulse * 0.4
		end
		if panelG.frame.Visible then
			if W.FX.Neon then
				local sweep = ((clock * 0.35) % 2) - 1
				neonGrad.Offset = Vector2.new(sweep, TP.vertical and sweep or 0)
			end
			if W.FX.Shimmer then
				titleGrad.Offset = Vector2.new(((clock * 0.4) % 2) - 1, 0)
			end
			local pulse = 0.5 + 0.5 * math.sin(clock * 3)
			logoHalo.Size = UDim2.fromOffset(10 + pulse * 8, 10 + pulse * 8)
			logoHalo.BackgroundTransparency = 0.5 + pulse * 0.4
			if W.FX.Aurora then
				for _, a in ipairs(aurora) do
					a.frame.Position = UDim2.fromScale(a.cx + a.ax * 0.4 * math.sin(clock * a.sx + a.ph), a.cy + a.ay * 0.4 * math.cos(clock * a.sy + a.ph))
					a.frame.ImageTransparency = a.base + 0.03 * math.sin(clock * 1.1 + a.ph)
				end
			end
		end
	end)
	local queueBusy, noticeTok = false, 0
	local function showIslandNotice(item)
		queueBusy = true
		noticeTok = noticeTok + 1
		local tok = noticeTok
		local color = kindColor(item.kind)
		noteIcon.BackgroundColor3 = color
		noteStroke.Color = color
		if item.icon then
			for _, ch in ipairs(noteIcon:GetChildren()) do
				if not ch:IsA("UICorner") and not ch:IsA("UIStroke") then
					ch:Destroy()
				end
			end
			createIcon(item.icon, noteIcon, 18, color, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
		else
			drawGlyph(noteIcon, item.kind, color)
		end
		noteTitle.Text = item.title
		noteMsg.Text = item.content
		noteBar.BackgroundColor3 = color
		noteBar.Size = UDim2.new(1, -32, 0, 2)
		tween(noteBar, item.duration, {Size = UDim2.new(0, 0, 0, 2)}, ES.Linear)
		noteIcon.Size = UDim2.fromOffset(18, 18)
		tween(noteIcon, 0.6, {Size = UDim2.fromOffset(34, 34)}, ES.Back, ED.Out, 0.1)
		setState("notify")
		task.delay(item.duration, function()
			if tok ~= noticeTok or not W.Alive then
				return
			end
			queueBusy = false
			if state == "notify" then
				setState("idle")
			end
		end)
	end
	local TOAST = {
		w = math.min(300, viewport.X - 28),
		h = 58,
		gap = 8,
		max = 4,
		edgeX = 14,
		edgeY = isTouch and 108 or 16,
	}
	local toastHolder = new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -TOAST.edgeX, 1, -TOAST.edgeY),
		Size = UDim2.new(0, TOAST.w, 1, -(TOAST.edgeY + 12)),
		BackgroundTransparency = 1,
		ZIndex = 60,
		Parent = gui,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, TOAST.gap),
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = toastHolder,
	})
	local toastSeq = 0
	local function floatToast(item)
		local TW, TH = TOAST.w, TOAST.h
		local existing = {}
		for _, child in ipairs(toastHolder:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(existing, child)
			end
		end
		if #existing >= TOAST.max then
			existing[1]:Destroy()
		end
		toastSeq = toastSeq + 1
		local color = kindColor(item.kind)
		local slot = new("Frame", {Size = UDim2.fromOffset(TW, TH), BackgroundTransparency = 1, LayoutOrder = toastSeq, Parent = toastHolder})
		local pill = new("CanvasGroup", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, TW + 40, 0, 0),
			Size = UDim2.fromOffset(TW, TH),
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = math.clamp(Library.Transparency, 0, 0.6),
			BorderSizePixel = 0,
			GroupTransparency = 1,
			Parent = slot,
		})
		corner(pill, 18)
		local pillStroke = stroke(pill, WHITE, 1.4, 0.2)
		new("UIGradient", {
			Color = ColorSequence.new({ck(0, color), ck(0.5, darken(color, 0.55)), ck(1, color)}),
			Rotation = 25,
			Parent = pillStroke,
		})
		local icon = new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, -1),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			Parent = pill,
		})
		round(icon)
		stroke(icon, color, 1.4, 0.35)
		if item.icon then
			createIcon(item.icon, icon, 16, color, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)})
		else
			drawGlyph(icon, item.kind, color)
		end
		new("TextLabel", {
			Position = UDim2.new(0, 52, 0.5, -19),
			Size = UDim2.new(1, -64, 0, 17),
			BackgroundTransparency = 1,
			Text = item.title,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = pill,
		})
		new("TextLabel", {
			Position = UDim2.new(0, 52, 0.5, -2),
			Size = UDim2.new(1, -64, 0, 16),
			BackgroundTransparency = 1,
			Text = item.content,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = pill,
		})
		local timeBar = new("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Parent = pill,
		})
		tween(timeBar, item.duration, {Size = UDim2.new(0, 0, 0, 3)}, ES.Linear)
		tween(pill, 0.6, {Position = UDim2.new(1, 0, 0, 0)}, ES.Back, ED.Out)
		tween(pill, 0.3, {GroupTransparency = 0}, ES.Quad, ED.Out)
		local dismissed = false
		local function dismiss()
			if dismissed or not slot.Parent then
				return
			end
			dismissed = true
			tween(pill, 0.3, {Position = UDim2.new(1, TW + 40, 0, 0)}, ES.Quint, ED.In)
			tween(pill, 0.25, {GroupTransparency = 1}, ES.Quad, ED.In)
			tween(slot, 0.3, {Size = UDim2.fromOffset(TW, 0)}, ES.Quint, ED.InOut, 0.2)
			task.delay(0.6, function()
				slot:Destroy()
			end)
		end
		local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = pill})
		hit.MouseButton1Click:Connect(dismiss)
		task.delay(item.duration, dismiss)
	end
	function W:Notify(data)
		if type(data) ~= "table" then
			data = {Title = tostring(data)}
		end
		local item = {
			title = tostring(data.Title or data.title or "Notice"),
			content = tostring(data.Content or data.content or data.Text or ""),
			duration = tonumber(data.Duration or data.duration) or 3.5,
			kind = data.Type or data.type or "info",
			icon = data.Icon or data.icon,
		}
		if not W.Alive then
			return
		end
		if not W.Ready then
			table.insert(W._pending, data)
			return
		end
		W.Sfx("Notify")
		if state == "idle" and not queueBusy then
			showIslandNotice(item)
		else
			floatToast(item)
		end
	end
	local tabs = W.Tabs
	local currentTab
	local hlToken = 0
	local function paintTab(tab, color, dur)
		tween(tab.label, dur or 0.3, {TextColor3 = color})
		if tab.icon then
			tab.icon:TweenColor(color, dur or 0.3)
		end
	end
	local function moveHighlight(index, instant)
		local n = math.max(#tabs, 1)
		if instant then
			hlToken = hlToken + 1
		end
		if TP.vertical then
			local h = TP.itemSize(n)
			local toY = 4 + (index - 1) * h + 3
			local restSize = UDim2.new(1, -6, 0, h - 6)
			if instant then
				highlight.Position = UDim2.new(0, 3, 0, toY)
				highlight.Size = restSize
				return
			end
			hlToken = hlToken + 1
			local token = hlToken
			local fromY = highlight.Position.Y.Offset
			local dist = math.abs(toY - fromY)
			tween(highlight, 0.16, {
				Position = UDim2.new(0, 3, 0, math.min(fromY, toY)),
				Size = UDim2.new(1, -6, 0, h - 6 + dist),
			}, ES.Quad, ED.Out)
			task.delay(0.15, function()
				if token ~= hlToken or not W.Alive then
					return
				end
				tween(highlight, 0.45, {Position = UDim2.new(0, 3, 0, toY), Size = restSize}, ES.Back, ED.Out)
			end)
			return
		end
		local toX = (index - 1) / n
		local restSize = UDim2.new(1 / n, -6, 1, -6)
		if instant then
			highlight.Position = UDim2.new(toX, 3, 0, 3)
			highlight.Size = restSize
			return
		end
		hlToken = hlToken + 1
		local token = hlToken
		local fromX = highlight.Position.X.Scale
		local dist = math.abs(toX - fromX)
		tween(highlight, 0.16, {
			Position = UDim2.new(math.min(fromX, toX), 3, 0, 3),
			Size = UDim2.new(1 / n + dist, -6, 1, -6),
		}, ES.Quad, ED.Out)
		task.delay(0.15, function()
			if token ~= hlToken or not W.Alive then
				return
			end
			tween(highlight, 0.45, {Position = UDim2.new(toX, 3, 0, 3), Size = restSize}, ES.Back, ED.Out)
		end)
	end
	local function layoutTabs()
		local n = #tabs
		local vertical = TP.vertical
		local h = TP.itemSize(n)
		local avail = vertical and TP.side or (PW - 24) / math.max(n, 1)
		for i, tab in ipairs(tabs) do
			if vertical then
				tab.button.Position = UDim2.new(0, 0, 0, 4 + (i - 1) * h)
				tab.button.Size = UDim2.new(1, 0, 0, h)
			else
				tab.button.Position = UDim2.new((i - 1) / n, 0, 0, 0)
				tab.button.Size = UDim2.new(1 / n, 0, 1, 0)
			end
			if tab.icon then
				-- the label stays centered in the button; the icon only shows when it fits beside it
				local room = avail >= (tab.textW + 40)
				tab.icon.Frame.Visible = room
				tab.label.Position = UDim2.fromOffset(room and 22 or 4, 0)
				tab.label.Size = UDim2.new(1, room and -44 or -8, 1, 0)
			end
			if tab.pad then
				tab.pad.PaddingLeft = UDim.new(0, 0)
				tab.button.TextXAlignment = Enum.TextXAlignment.Center
			end
		end
		if currentTab then
			moveHighlight(currentTab.index, true)
		end
	end
	local SLIDE_T = 0.42
	local function slideOut(tab, dir)
		tab.slideTok = tab.slideTok + 1
		local tok = tab.slideTok
		tab.page.ZIndex = 2
		tween(tab.page, SLIDE_T, {Position = TP.slide(-dir)}, ES.Quint, ED.Out)
		task.delay(SLIDE_T + 0.04, function()
			if tab.slideTok == tok and W.Alive and currentTab ~= tab then
				tab.page.Visible = false
				tab.page.Position = UDim2.new()
			end
		end)
	end
	local function slideIn(tab, dir)
		tab.slideTok = tab.slideTok + 1
		tab.page.ZIndex = 3
		if dir == 0 then
			tab.page.Position = UDim2.new()
			tab.page.Visible = true
		else
			if not tab.page.Visible then
				tab.page.Position = TP.slide(dir)
				tab.page.Visible = true
			end
			tween(tab.page, SLIDE_T, {Position = UDim2.new()}, ES.Quint, ED.Out)
		end
		for i, entry in ipairs(tab.Cards) do
			local d = 0.08 + math.min(i, 10) * 0.04
			entry.frame.Position = entry.rest + UDim2.fromOffset(0, 16)
			tween(entry.frame, 0.55, {Position = entry.rest}, ES.Quint, ED.Out, d)
			task.delay(d + 0.05, entry.sweep)
		end
	end
	local function selectTab(tab)
		if currentTab == tab then
			return
		end
		local old = currentTab
		currentTab = tab
		W.CurrentTab = tab
		local dir = 0
		if old then
			dir = tab.index > old.index and 1 or -1
			paintTab(old, Theme.Muted, 0.3)
			slideOut(old, dir)
		end
		paintTab(tab, Theme.Text, 0.3)
		moveHighlight(tab.index, old == nil)
		slideIn(tab, dir)
		if W._onTabChanged then
			W._onTabChanged(tab)
		end
	end
	W._selectFirst = function()
		if not currentTab and tabs[1] then
			selectTab(tabs[1])
		end
	end
	function W:SelectTab(which)
		if type(which) == "number" then
			which = tabs[which]
		elseif type(which) == "string" then
			for _, t in ipairs(tabs) do
				if t.Name == which then
					which = t
					break
				end
			end
		end
		if type(which) == "table" and which.page then
			selectTab(which)
		end
	end
	function W:GetTabPosition()
		return TP.pos
	end
	function W:SetTabPosition(position, instant)
		local pos = normalizeTabPosition(position)
		if not pos then
			return false
		end
		if pos == TP.pos then
			return pos
		end
		TP.geometry(pos)
		W.TabPosition = pos
		layoutTabs()
		for _, hook in ipairs(W._layoutHooks) do
			pcall(hook)
		end
		if not instant and W.Alive then
			local sh = TP.shift[pos]
			local tabRest, pageRest = tabBar.Position, pageHost.Position
			tabBar.Position = tabRest + UDim2.fromOffset(sh.X * 3, sh.Y * 3)
			pageHost.Position = pageRest + UDim2.fromOffset(0, 10)
			tween(tabBar, 0.5, {Position = tabRest}, ES.Quint, ED.Out)
			tween(pageHost, 0.5, {Position = pageRest}, ES.Quint, ED.Out, 0.05)
		end
		return pos
	end
	function W:AddTab(name, icon)
		if type(name) == "table" then
			icon = icon or name.Icon
			name = name.Text or name.Name
		end
		name = tostring(name or "Tab")
		local tab = setmetatable({Name = name, Window = W, Cards = {}, n = 0, index = #tabs + 1, slideTok = 0}, Tab)
		local button = new("TextButton", {
			Name = name,
			BackgroundTransparency = 1,
			Text = name,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Theme.Muted,
			AutoButtonColor = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 4,
			Parent = tabBar,
		})
		local label, iconObj, textW = button, nil, 0
		if icon and icon ~= "" then
			button.Text = ""
			-- the label is centered in the whole tab button; the icon is pinned to the left edge
			local row = new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 4,
				Parent = button,
			})
			iconObj = createIcon(icon, row, 14, Theme.Muted, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				ZIndex = 4,
			})
			label = new("TextLabel", {
				Position = UDim2.fromOffset(22, 0),
				Size = UDim2.new(1, -44, 1, 0),
				BackgroundTransparency = 1,
				Text = name,
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextColor3 = Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 4,
				Parent = row,
			})
			local okSize, size = pcall(function()
				return TextService:GetTextSize(name, 12, Enum.Font.GothamMedium, Vector2.new(1000, 20))
			end)
			textW = (okSize and size.X or (#name * 7)) * 1.2
			tab.row = row
		end
		tab.label, tab.icon, tab.textW = label, iconObj, textW
		if not iconObj then
			tab.pad = new("UIPadding", {Parent = button})
		end
		local page = new("Frame", {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = pageHost})
		local scroll = new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = page,
		})
		new("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll})
		new("UIPadding", {PaddingLeft = UDim.new(0, 1), PaddingTop = UDim.new(0, 2), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 26), Parent = scroll})
		bindTheme(scroll, function(T, s)
			s.ScrollBarImageColor3 = T.Accent
		end)
		button.MouseEnter:Connect(function()
			if currentTab ~= tab then
				paintTab(tab, Theme.Text, 0.25)
			end
		end)
		button.MouseLeave:Connect(function()
			if currentTab ~= tab then
				paintTab(tab, Theme.Muted, 0.35)
			end
		end)
		button.MouseButton1Click:Connect(function()
			W.Click(1.05, 0.8)
			selectTab(tab)
		end)
		tab.button, tab.page, tab.scroll = button, page, scroll
		table.insert(tabs, tab)
		layoutTabs()
		return tab
	end
	-- ====================================================================
	-- Header buttons (Search + Settings) and the search sheet
	-- ====================================================================
	;(function()
		local function esc(text)
			return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
		end
		local function safeIcon(name, fallback)
			if type(name) == "string" and name ~= "" and iconDef(name) then
				return name
			end
			return fallback
		end
		local KIND_ICON = {
			Tab = "layout", Toggle = "toggle", Slider = "sliders", Dropdown = "list", Button = "cursor",
			Input = "edit", Keybind = "keyboard", Color = "droplet", Group = "folder", Icons = "grid", Font = "star",
		}

		------------------------------------------------------------------
		-- header buttons
		------------------------------------------------------------------
		local function headerButton(iconName, rightOffset)
			local hb = {active = false, hover = false}
			local btn = new("TextButton", {
				Name = "HeaderButton",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, rightOffset, 0.5, 0),
				Size = UDim2.fromOffset(30, 30),
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				ZIndex = 5,
				Parent = header,
			})
			round(btn)
			local ring = stroke(btn, Theme.Accent, 1, 0.65)
			local pop = new("UIScale", {Scale = 1, Parent = btn})
			createIcon(iconName, btn, 16, "Accent", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				ZIndex = 6,
			})
			bindTheme(btn, function(T)
				btn.BackgroundColor3 = T.Accent
				ring.Color = T.Accent
			end)
			hb.Button = btn
			function hb.paint()
				tween(btn, 0.25, {BackgroundTransparency = hb.active and 0.62 or (hb.hover and 0.78 or 0.88)}, ES.Quad)
				tween(ring, 0.25, {Transparency = hb.active and 0.05 or (hb.hover and 0.35 or 0.65)}, ES.Quad)
			end
			btn.MouseEnter:Connect(function()
				hb.hover = true
				hb.paint()
			end)
			btn.MouseLeave:Connect(function()
				hb.hover = false
				hb.paint()
				tween(pop, 0.3, {Scale = 1}, ES.Back)
			end)
			btn.InputBegan:Connect(function(input)
				if isPress(input) then
					tween(pop, 0.1, {Scale = 0.88}, ES.Quad)
				end
			end)
			btn.InputEnded:Connect(function(input)
				if isPress(input) then
					tween(pop, 0.4, {Scale = 1}, ES.Back)
				end
			end)
			return hb
		end
		local searchBtn = headerButton("search", -52)
		local gearBtn = headerButton("settings", -14)

		------------------------------------------------------------------
		-- search sheet (covers everything below the header)
		------------------------------------------------------------------
		local sheet = new("CanvasGroup", {
			Name = "SearchSheet",
			Position = UDim2.fromOffset(0, HEADER_H),
			Size = UDim2.new(1, 0, 1, -HEADER_H),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 9,
			Parent = panel,
		})
		local veil = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 1,
			Parent = sheet,
		})
		bindTheme(veil, function(T)
			veil.BackgroundColor3 = T.Background
			veil.BackgroundTransparency = math.clamp(0.02 + Library.Transparency * 0.3, 0, 0.6)
		end)
		local body = new("Frame", {
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, -10),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = sheet,
		})

		-- search bar
		local bar = new("Frame", {
			Position = UDim2.fromOffset(0, 6),
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundColor3 = Theme.Input,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = body,
		})
		round(bar)
		local barRing = stroke(bar, Theme.Accent, 1.5, 0.6)
		bindTheme(bar, function(T)
			bar.BackgroundColor3 = T.Input
			barRing.Color = T.Accent
		end)
		createIcon("search", bar, 18, "Accent", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 13, 0.5, 0),
			ZIndex = 3,
		})
		local box = new("TextBox", {
			Position = UDim2.fromOffset(40, 0),
			Size = UDim2.new(1, -(40 + 76), 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			PlaceholderText = "Search features...",
			PlaceholderColor3 = Theme.Muted,
			TextColor3 = Theme.Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			ZIndex = 3,
			Parent = bar,
		})
		bindTheme(box, function(T)
			box.TextColor3 = T.Text
			box.PlaceholderColor3 = T.Muted
		end)
		local countLabel = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -40, 0.5, 0),
			Size = UDim2.fromOffset(32, 16),
			BackgroundTransparency = 1,
			Text = "",
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = Theme.Accent,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 3,
			Parent = bar,
		})
		bindTheme(countLabel, function(T)
			countLabel.TextColor3 = T.Accent
		end)
		local clearBtn = new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -7, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 4,
			Parent = bar,
		})
		round(clearBtn)
		bindTheme(clearBtn, function(T)
			clearBtn.BackgroundColor3 = T.Accent
		end)
		createIcon("x", clearBtn, 12, "Muted", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 5,
		})

		-- tab filter chips
		local chipRow = new("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 50),
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ZIndex = 2,
			Parent = body,
		})
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = chipRow,
		})

		-- results list
		local results = new("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 84),
			Size = UDim2.new(1, 0, 1, -84),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
			Parent = body,
		})
		bindTheme(results, function(T)
			results.ScrollBarImageColor3 = T.Accent
		end)
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = results,
		})
		new("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 4),
			Parent = results,
		})

		-- empty state
		local empty = new("Frame", {
			Position = UDim2.fromOffset(0, 100),
			Size = UDim2.new(1, 0, 0, 100),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 2,
			Parent = body,
		})
		createIcon("search", empty, 34, "Muted", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			ZIndex = 3,
		})
		local emptyTitle = new("TextLabel", {
			Position = UDim2.fromOffset(0, 46),
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = "No results",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 3,
			Parent = empty,
		})
		local emptySub = new("TextLabel", {
			Position = UDim2.fromOffset(0, 66),
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = "Try another word or pick a different tab.",
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = Theme.Muted,
			ZIndex = 3,
			Parent = empty,
		})
		bindTheme(empty, function(T)
			emptyTitle.TextColor3 = T.Text
			emptySub.TextColor3 = T.Muted
		end)

		------------------------------------------------------------------
		-- search logic
		------------------------------------------------------------------
		local searchOpen, searchTok = false, 0
		local filterTab = nil
		local shown, chipRefs, lastTokens = {}, {}, {}
		local go

		local function collect()
			local list = {}
			for _, t in ipairs(tabs) do
				table.insert(list, {
					Name = t.Name, Tab = t, Kind = "Tab", IsTab = true, Order = 0,
					Icon = (t.icon and t.icon.Name) or "layout",
				})
			end
			for _, e in ipairs(W._search or {}) do
				if e.Slot and e.Slot.Parent then
					table.insert(list, e)
				end
			end
			return list
		end

		local function scoreEntry(e, tokens)
			local nameL = string.lower(e.Name)
			local tabL = string.lower(e.Tab.Name)
			local kindL = string.lower(e.Kind or "")
			local total = 0
			for _, tk in ipairs(tokens) do
				local s = string.find(nameL, tk, 1, true)
				if s then
					local base = 60
					if s == 1 then
						base = 100
					elseif string.sub(nameL, s - 1, s - 1) == " " then
						base = 80
					end
					total = total + base - math.min(s, 20)
				elseif string.find(tabL, tk, 1, true) then
					total = total + 25
				elseif string.find(kindL, tk, 1, true) then
					total = total + 15
				else
					return nil
				end
			end
			if nameL == table.concat(tokens, " ") then
				total = total + 100
			end
			if e.IsTab then
				total = total + 10
			end
			return total
		end

		local function highlightText(name, tokens)
			local lower = string.lower(name)
			local ranges = {}
			for _, tk in ipairs(tokens) do
				local s, e = string.find(lower, tk, 1, true)
				if s then
					table.insert(ranges, {s, e})
				end
			end
			if #ranges == 0 then
				return esc(name)
			end
			table.sort(ranges, function(a, b)
				return a[1] < b[1]
			end)
			local merged = {ranges[1]}
			for i = 2, #ranges do
				local last = merged[#merged]
				if ranges[i][1] <= last[2] + 1 then
					last[2] = math.max(last[2], ranges[i][2])
				else
					table.insert(merged, ranges[i])
				end
			end
			local hex = Theme.Accent:ToHex()
			local out, pos = {}, 1
			for _, r in ipairs(merged) do
				if r[1] > pos then
					table.insert(out, esc(string.sub(name, pos, r[1] - 1)))
				end
				table.insert(out, '<font color="#' .. hex .. '"><b>' .. esc(string.sub(name, r[1], r[2])) .. "</b></font>")
				pos = r[2] + 1
			end
			if pos <= #name then
				table.insert(out, esc(string.sub(name, pos)))
			end
			return table.concat(out)
		end

		local function makeResult(entry, order, animate, delay)
			local item = new("CanvasGroup", {
				Name = "Result",
				Size = UDim2.new(1, 0, 0, 46),
				BackgroundColor3 = Theme.Card,
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				GroupTransparency = animate and 1 or 0,
				LayoutOrder = order,
				ZIndex = 3,
				Parent = results,
			})
			corner(item, 12)
			local ring = stroke(item, Theme.Stroke, 1, 0.2)
			local pop = new("UIScale", {Scale = animate and 0.95 or 1, Parent = item})
			bindTheme(item, function(T)
				item.BackgroundColor3 = T.Card
				ring.Color = T.Stroke
			end)

			local tile = new("Frame", {
				Position = UDim2.fromOffset(9, 8),
				Size = UDim2.fromOffset(30, 30),
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 0.86,
				BorderSizePixel = 0,
				ZIndex = 4,
				Parent = item,
			})
			corner(tile, 9)
			local tileRing = stroke(tile, Theme.Accent, 1, 0.7)
			bindTheme(tile, function(T)
				tile.BackgroundColor3 = T.Accent
				tileRing.Color = T.Accent
			end)
			createIcon(safeIcon(entry.Icon, KIND_ICON[entry.Kind or ""] or "sparkles"), tile, 16, "Accent", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				ZIndex = 5,
			})
			new("TextLabel", {
				Position = UDim2.fromOffset(50, 6),
				Size = UDim2.new(1, -90, 0, 18),
				BackgroundTransparency = 1,
				RichText = true,
				Text = highlightText(entry.Name, lastTokens),
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 4,
				Parent = item,
			})
			local sub = new("TextLabel", {
				Position = UDim2.fromOffset(50, 25),
				Size = UDim2.new(1, -90, 0, 14),
				BackgroundTransparency = 1,
				Text = entry.IsTab and "Tab" or (entry.Tab.Name .. " / " .. (entry.Kind or "Option")),
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 4,
				Parent = item,
			})
			bindTheme(sub, function(T)
				sub.TextColor3 = T.Muted
			end)
			createIcon("chevron-right", item, 14, "Accent", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				ZIndex = 4,
			})
			local hit = new("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				ZIndex = 8,
				Parent = item,
			})
			hit.MouseEnter:Connect(function()
				tween(item, 0.25, {BackgroundColor3 = Theme.CardHover}, ES.Quad)
				tween(ring, 0.25, {Color = Theme.Accent, Transparency = 0.35}, ES.Quad)
			end)
			hit.MouseLeave:Connect(function()
				tween(item, 0.35, {BackgroundColor3 = Theme.Card}, ES.Quad)
				tween(ring, 0.35, {Color = Theme.Stroke, Transparency = 0.2}, ES.Quad)
				tween(pop, 0.3, {Scale = 1}, ES.Back)
			end)
			hit.InputBegan:Connect(function(input)
				if isPress(input) then
					tween(pop, 0.1, {Scale = 0.97}, ES.Quad)
				end
			end)
			hit.InputEnded:Connect(function(input)
				if isPress(input) then
					tween(pop, 0.4, {Scale = 1}, ES.Back)
				end
			end)
			hit.MouseButton1Click:Connect(function()
				go(entry)
			end)
			if animate then
				tween(item, 0.35, {GroupTransparency = 0}, ES.Quad, ED.Out, delay or 0)
				tween(pop, 0.5, {Scale = 1}, ES.Back, ED.Out, delay or 0)
			end
		end

		local function refresh(animate)
			local trimmed = (box.Text:gsub("^%s+", ""):gsub("%s+$", ""))
			local tokens = {}
			for word in string.gmatch(string.lower(trimmed), "%S+") do
				table.insert(tokens, word)
			end
			lastTokens = tokens
			for _, child in ipairs(results:GetChildren()) do
				if child:IsA("CanvasGroup") then
					child:Destroy()
				end
			end
			local list = {}
			for _, e in ipairs(collect()) do
				if not (filterTab and (e.IsTab or e.Tab ~= filterTab)) then
					local sc = 0
					if #tokens > 0 then
						sc = scoreEntry(e, tokens)
					end
					if sc then
						table.insert(list, {e = e, score = sc, key = e.Tab.index * 10000 + (e.IsTab and 0 or e.Order)})
					end
				end
			end
			table.sort(list, function(a, b)
				if a.score ~= b.score then
					return a.score > b.score
				end
				return a.key < b.key
			end)
			shown = {}
			for i = 1, math.min(#list, 50) do
				shown[i] = list[i].e
				makeResult(list[i].e, i, animate and i <= 10, (i - 1) * 0.03)
			end
			countLabel.Text = #list > 0 and tostring(#list) or ""
			empty.Visible = #list == 0
			if #list == 0 then
				emptyTitle.Text = (#tokens > 0) and ('No results for "' .. trimmed .. '"') or "Nothing to search yet"
			end
			results.CanvasPosition = Vector2.new(0, 0)
		end

		local function paintChip(ref, selected)
			tween(ref.btn, 0.2, {
				BackgroundTransparency = selected and 0.78 or 1,
				TextColor3 = selected and Theme.Text or Theme.Muted,
			}, ES.Quad)
			tween(ref.ring, 0.2, {Transparency = selected and 0.3 or 0.75}, ES.Quad)
		end

		local function buildChips()
			for _, ref in ipairs(chipRefs) do
				ref.btn:Destroy()
			end
			chipRefs = {}
			local function addChip(label, tabRef, order)
				local btn = new("TextButton", {
					Size = UDim2.fromOffset(0, 26),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = Theme.Accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = label,
					Font = Enum.Font.GothamMedium,
					TextSize = 12,
					TextColor3 = Theme.Muted,
					LayoutOrder = order,
					ZIndex = 3,
					Parent = chipRow,
				})
				round(btn)
				new("UIPadding", {
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
					Parent = btn,
				})
				local ring = stroke(btn, Theme.Accent, 1, 0.75)
				bindTheme(btn, function(T)
					btn.BackgroundColor3 = T.Accent
					ring.Color = T.Accent
				end)
				local ref = {btn = btn, ring = ring, tab = tabRef}
				table.insert(chipRefs, ref)
				btn.MouseButton1Click:Connect(function()
					W.Click()
					filterTab = tabRef
					for _, r in ipairs(chipRefs) do
						paintChip(r, r.tab == filterTab)
					end
					refresh(true)
				end)
				paintChip(ref, tabRef == filterTab)
			end
			addChip("All", nil, 0)
			for i, t in ipairs(tabs) do
				addChip(t.Name, t, i)
			end
			chipRow.CanvasPosition = Vector2.new(0, 0)
		end

		local function setSearch(open, instant)
			if open == searchOpen then
				return
			end
			searchOpen = open
			searchTok = searchTok + 1
			local tok = searchTok
			searchBtn.active = open
			searchBtn.paint()
			if open then
				filterTab = nil
				box.Text = ""
				buildChips()
				refresh(true)
				sheet.Visible = true
				sheet.GroupTransparency = 1
				body.Position = UDim2.fromOffset(12, 16)
				tween(sheet, 0.25, {GroupTransparency = 0}, ES.Quad, ED.Out)
				tween(body, 0.5, {Position = UDim2.fromOffset(12, 0)}, ES.Quint, ED.Out)
				task.delay(0.3, function()
					if searchTok == tok and searchOpen and W.Alive then
						box:CaptureFocus()
					end
				end)
			else
				box:ReleaseFocus()
				if instant then
					sheet.GroupTransparency = 1
					sheet.Visible = false
				else
					tween(sheet, 0.18, {GroupTransparency = 1}, ES.Quad, ED.In)
					tween(body, 0.2, {Position = UDim2.fromOffset(12, 10)}, ES.Quad, ED.In)
					task.delay(0.22, function()
						if searchTok == tok and not searchOpen then
							sheet.Visible = false
						end
					end)
				end
			end
		end

		go = function(entry)
			W.Click()
			setSearch(false)
			local tab = entry.Tab
			if entry.Foldout and entry.Foldout.Get and not entry.Foldout:Get() then
				entry.Foldout:Set(true)
			end
			local same = (currentTab == tab)
			selectTab(tab)
			if entry.IsTab then
				return
			end
			task.delay(same and 0.15 or 0.55, function()
				if not W.Alive or W.CurrentTab ~= tab then
					return
				end
				local slot, scroll = entry.Slot, tab.scroll
				if not (slot and slot.Parent and slot.Visible and scroll) then
					return
				end
				local s = math.max(W._shellScale.Scale, 0.01)
				local y = (slot.AbsolutePosition.Y - scroll.AbsolutePosition.Y) / s + scroll.CanvasPosition.Y - 6
				tween(scroll, 0.55, {CanvasPosition = Vector2.new(0, math.max(0, y))}, ES.Quint, ED.Out)
				local c = entry.C
				if c then
					task.delay(0.3, function()
						if c.sweep then
							c.sweep()
						end
					end)
					for i = 0, 2 do
						task.delay(0.3 + i * 0.4, function()
							if c.flash then
								c.flash()
							end
						end)
					end
					local st = c.stroke
					if st and st.Parent then
						tween(st, 0.25, {Color = Theme.Accent, Transparency = 0, Thickness = 2}, ES.Quad)
						task.delay(1.5, function()
							if st.Parent then
								tween(st, 0.5, {Color = Theme.Stroke, Transparency = 0.2, Thickness = 1}, ES.Quad)
							end
						end)
					end
				end
			end)
		end

		------------------------------------------------------------------
		-- wiring
		------------------------------------------------------------------
		box.Focused:Connect(function()
			tween(barRing, 0.25, {Transparency = 0.05}, ES.Quad)
		end)
		box.FocusLost:Connect(function(enter)
			tween(barRing, 0.3, {Transparency = 0.6}, ES.Quad)
			if enter and searchOpen and UserInputService.KeyboardEnabled and shown[1] then
				go(shown[1])
			end
		end)
		box:GetPropertyChangedSignal("Text"):Connect(function()
			refresh(false)
		end)
		clearBtn.MouseButton1Click:Connect(function()
			W.Click()
			if box.Text ~= "" then
				box.Text = ""
				box:CaptureFocus()
			else
				setSearch(false)
			end
		end)
		searchBtn.Button.MouseButton1Click:Connect(function()
			W.Click()
			setSearch(not searchOpen)
		end)
		gearBtn.Button.MouseButton1Click:Connect(function()
			W.Click()
			if searchOpen then
				setSearch(false)
			end
			if W.SettingsTab then
				selectTab(W.SettingsTab)
			else
				W:Notify({Title = "Settings", Content = "This window has no Settings tab.", Type = "warn", Duration = 2.5})
			end
		end)
		W:_connect(UserInputService.InputBegan, function(input)
			if searchOpen and input.KeyCode == Enum.KeyCode.Escape then
				setSearch(false)
			end
		end)
		W._onTabChanged = function(tab)
			gearBtn.active = (tab == W.SettingsTab)
			gearBtn.paint()
		end
		W._closeSearch = function(instant)
			if searchOpen then
				setSearch(false, instant)
			end
		end
		function W:OpenSearch()
			setSearch(true)
		end
		function W:CloseSearch()
			setSearch(false)
		end
		function W:ToggleSearch()
			setSearch(not searchOpen)
		end
	end)()
	function W:_reveal()
		if not W.Alive or W.Ready then
			return
		end
		W.Ready = true
		applyProfile(PROFILES.pop)
		sp.show.t = 1
		glowKick = 1
		showGroup(idleG, true, 0.1, 0.35)
		idleIntro(0.16)
		task.delay(0.7, function()
			if not W.Alive then
				return
			end
			local pending = W._pending
			W._pending = {}
			for _, data in ipairs(pending) do
				W:Notify(data)
			end
		end)
		if opts.AutoOpen then
			task.delay(0.6, function()
				setState("expanded")
			end)
		end
	end
	function W:Destroy()
		if not W.Alive then
			return
		end
		W.Alive = false
		for _, c in ipairs(W.Connections) do
			pcall(function()
				c:Disconnect()
			end)
		end
		W.Connections = {}
		for i, win in ipairs(Library.Windows) do
			if win == W then
				table.remove(Library.Windows, i)
				break
			end
		end
		pcall(function()
			tween(shellScale, 0.35, {Scale = 0.001}, ES.Back, ED.In)
		end)
		task.delay(0.4, function()
			pcall(function()
				gui:Destroy()
			end)
		end)
	end
end
local function setFlag(o, value)
	if o and o.Flag then
		Library.Flags[o.Flag] = value
	end
end
function Tab:_card(height, name, o)
	o = o or {}
	local W = self.Window
	local c = {}
	self.n = self.n + 1
	local slot = new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = self.n,
		Parent = self.scroll,
	})
	local card = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Card,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ClipsDescendants = o.clip and true or false,
		Parent = slot,
	})
	corner(card, 12)
	local st = stroke(card, Theme.Stroke, 1, 0.2)
	c.slot, c.card, c.stroke = slot, card, st
	if name and tostring(name) ~= "" then
		W._search = W._search or {}
		c.entry = {
			Name = tostring(name),
			Tab = self,
			Slot = slot,
			C = c,
			Icon = o.Icon,
			Foldout = self._foldoutObj,
			Order = #W._search + 1,
		}
		table.insert(W._search, c.entry)
	end
	if self.capture then
		table.insert(self.capture, {slot = slot, frame = card})
	end
	c.restColor = function()
		return Theme.Card
	end
	c.hoverColor = function()
		return Theme.CardHover
	end
	c.alphaBase, c.alphaFactor = 0.12, 0.7
	bindTheme(card, function(T)
		card.BackgroundTransparency = math.clamp(c.alphaBase + Library.Transparency * c.alphaFactor, 0, 0.95)
		card.BackgroundColor3 = c.hovering and c.hoverColor() or c.restColor()
		st.Color = c.hovering and T.Accent or T.Stroke
	end)
	local cardScale = new("UIScale", {Scale = 1, Parent = card})
	c.title = new("TextLabel", {
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -110, 0, math.min(height, 40)),
		BackgroundTransparency = 1,
		Text = name or "",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = card,
	})
	c.iconShift = 0
	if o.Icon then
		c.icon = createIcon(o.Icon, card, 18, "Accent", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(13, math.min(height, 40) / 2),
			ZIndex = 3,
		})
		c.iconShift = 26
		c.title.Position = UDim2.new(0, 14 + c.iconShift, 0, 0)
		c.title.Size = UDim2.new(1, -110 - c.iconShift, 0, math.min(height, 40))
	end
	c.hit = new("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = o.hitHeight and UDim2.new(1, 0, 0, o.hitHeight) or UDim2.fromScale(1, 1),
		ZIndex = 4,
		Parent = card,
	})
	local overlay = new("Frame", {
		Name = "FX",
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = 5,
		Parent = card,
	})
	corner(overlay, 12)
	local sweepFrame = new("Frame", {
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.26, 0, 2, 0),
		Position = UDim2.fromScale(-0.3, 0.5),
		Rotation = 18,
		ZIndex = 5,
		Parent = overlay,
	})
	local sweepGrad = new("UIGradient", {
		Transparency = NumberSequence.new({kp(0, 1), kp(0.5, 0.82), kp(1, 1)}),
		Parent = sweepFrame,
	})
	bindTheme(overlay, function(T)
		overlay.BackgroundColor3 = T.Accent
		sweepGrad.Color = ColorSequence.new(T.Accent)
	end)
	local sweeping = false
	function c.sweep()
		if sweeping or not sweepFrame.Parent then
			return
		end
		sweeping = true
		sweepFrame.Position = UDim2.fromScale(-0.3, 0.5)
		tween(sweepFrame, 0.8, {Position = UDim2.fromScale(1.3, 0.5)}, ES.Quad, ED.InOut)
		task.delay(0.85, function()
			sweeping = false
		end)
	end
	function c.flash()
		overlay.BackgroundTransparency = 0.8
		tween(overlay, 0.5, {BackgroundTransparency = 1}, ES.Quad, ED.Out)
	end
	function c.ripple(px)
		local s = math.max(W._shellScale.Scale, 0.01)
		local relX = (px - card.AbsolutePosition.X) / s
		local circle = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(relX, math.min(card.AbsoluteSize.Y / s, 40) / 2),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.72,
			BorderSizePixel = 0,
			Parent = overlay,
		})
		round(circle)
		local big = card.AbsoluteSize.X / s * 2.2
		tween(circle, 0.65, {Size = UDim2.fromOffset(big, big), BackgroundTransparency = 1}, ES.Quart, ED.Out)
		task.delay(0.7, function()
			circle:Destroy()
		end)
	end
	c.hit.MouseEnter:Connect(function()
		c.hovering = true
		tween(card, 0.3, {BackgroundColor3 = c.hoverColor()}, ES.Quad)
		tween(st, 0.3, {Color = Theme.Accent, Transparency = 0.35}, ES.Quad)
		c.sweep()
	end)
	c.hit.MouseLeave:Connect(function()
		c.hovering = false
		tween(card, 0.45, {BackgroundColor3 = c.restColor()}, ES.Quad)
		tween(st, 0.45, {Color = Theme.Stroke, Transparency = 0.2}, ES.Quad)
		tween(cardScale, 0.3, {Scale = 1}, ES.Back)
	end)
	c.hit.InputBegan:Connect(function(input)
		if isPress(input) then
			c.ripple(input.Position.X)
			tween(cardScale, 0.1, {Scale = 0.985}, ES.Quad)
		end
	end)
	c.hit.InputEnded:Connect(function(input)
		if isPress(input) then
			tween(cardScale, 0.45, {Scale = 1}, ES.Back)
		end
	end)
	if not o.silent then
		c.hit.MouseButton1Click:Connect(function()
			W.Click()
		end)
	end
	table.insert(self.Cards, {frame = card, rest = UDim2.new(), sweep = c.sweep})
	return c
end
function Tab:Section(text, icon)
	if type(text) == "table" then
		icon = icon or text.Icon
		text = text.Text or text.Name
	end
	self.n = self.n + 1
	local slot = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = self.n,
		Parent = self.scroll,
	})
	local holder = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = slot})
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 2),
		Size = UDim2.fromOffset(3, 12),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = holder,
	})
	round(bar)
	local sectionIcon = nil
	if icon and icon ~= "" then
		sectionIcon = createIcon(icon, holder, 14, "Accent", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 15, 0.5, 2),
		})
	end
	local labelX = sectionIcon and 34 or 14
	local label = new("TextLabel", {
		Position = UDim2.fromOffset(labelX, 4),
		Size = UDim2.new(1, -(labelX + 4), 1, -4),
		BackgroundTransparency = 1,
		Text = string.upper(tostring(text or "")),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	bindTheme(label, function(T)
		label.TextColor3 = T.Accent
		bar.BackgroundColor3 = T.Accent
	end)
	if self.capture then
		table.insert(self.capture, {slot = slot, frame = holder})
	end
	table.insert(self.Cards, {frame = holder, rest = UDim2.new(), sweep = function() end})
	local object = {}
	function object:Set(newText)
		label.Text = string.upper(tostring(newText))
	end
	return object
end
function Tab:Label(text, icon)
	if type(text) == "table" then
		icon = icon or text.Icon
		text = text.Text or text.Name
	end
	local c = self:_card(34, "", {silent = true, Icon = icon})
	c.title.Size = UDim2.new(1, -28 - c.iconShift, 1, 0)
	c.title.Text = tostring(text or "")
	c.title.Font = Enum.Font.Gotham
	c.title.TextSize = 12
	c.title.TextColor3 = Theme.Muted
	c.hit.Visible = false
	local object = {}
	function object:Set(newText)
		c.title.Text = tostring(newText)
	end
	return object
end
function Tab:Paragraph(o)
	local W = self.Window
	o = o or {}
	local function textWidth()
		return math.max((W.PageWidth or (W.PW - 24)) - 40, 120)
	end
	local function measure(text)
		local ok, size = pcall(function()
			return TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(textWidth(), 10000))
		end)
		return ok and size.Y or 16
	end
	local content = tostring(o.Content or "")
	local c = self:_card(40, "", {silent = true, Icon = o.Icon})
	c.hit.Visible = false
	c.title.Text = tostring(o.Title or "")
	c.title.Size = UDim2.new(1, -28 - c.iconShift, 0, 24)
	c.title.Position = UDim2.new(0, 14 + c.iconShift, 0, 4)
	c.title.TextSize = 13
	local body = new("TextLabel", {
		Position = UDim2.new(0, 14, 0, 26),
		Size = UDim2.new(1, -28, 1, -32),
		BackgroundTransparency = 1,
		Text = content,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		ZIndex = 2,
		Parent = c.card,
	})
	local function resize()
		c.slot.Size = UDim2.new(1, 0, 0, 36 + measure(body.Text))
	end
	resize()
	if W._layoutHooks then
		table.insert(W._layoutHooks, resize)
	end
	local object = {}
	function object:Set(title, text)
		c.title.Text = tostring(title or "")
		body.Text = tostring(text or "")
		resize()
	end
	return object
end
function Tab:Button(o)
	local W = self.Window
	o = o or {}
	local c = self:_card(40, o.Name, {Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Button"
	end
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = ">",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		ZIndex = 2,
		Parent = c.card,
	})
	if o.Solid then
		c.restColor = function()
			return Theme.Accent
		end
		c.hoverColor = function()
			return lighten(Theme.Accent, 0.2)
		end
		c.alphaBase, c.alphaFactor = 0.05, 0.15
		c.card.BackgroundTransparency = math.clamp(c.alphaBase + Library.Transparency * c.alphaFactor, 0, 0.95)
	end
	bindTheme(arrow, function(T)
		if o.Solid then
			c.title.TextColor3 = onColor(T.Accent)
			arrow.TextColor3 = onColor(T.Accent)
			c.card.BackgroundColor3 = c.hovering and c.hoverColor() or c.restColor()
		else
			arrow.TextColor3 = T.Accent
		end
	end)
	c.hit.MouseButton1Click:Connect(function()
		tween(arrow, 0.12, {Position = UDim2.new(1, -7, 0.5, 0)}, ES.Quad)
		task.delay(0.12, function()
			tween(arrow, 0.45, {Position = UDim2.new(1, -14, 0.5, 0)}, ES.Back, ED.Out)
		end)
		c.flash()
		W:_fire(o.Callback)
	end)
	local object = {}
	function object:SetName(text)
		c.title.Text = tostring(text)
	end
	return object
end
function Tab:Toggle(o)
	local W = self.Window
	o = o or {}
	local c = self:_card(40, o.Name, {silent = true, Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Toggle"
	end
	local on = o.Default and true or false
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(44, 24),
		BackgroundColor3 = Theme.Off,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = c.card,
	})
	round(track)
	local trackStroke = stroke(track, Theme.Stroke, 1, 0.4)
	local knob = new("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = track,
	})
	round(knob)
	local edge = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = c.card,
	})
	round(edge)
	local function paint(animate)
		local tc = on and Theme.Accent or Theme.Off
		local kc = on and onColor(Theme.Accent) or WHITE
		local sc = on and Theme.Accent or Theme.Stroke
		local kx = on and 23 or 3
		edge.BackgroundColor3 = Theme.Accent
		if animate then
			tween(track, 0.3, {BackgroundColor3 = tc}, ES.Quad)
			tween(trackStroke, 0.3, {Color = sc}, ES.Quad)
			tween(knob, 0.42, {Position = UDim2.fromOffset(kx, 3), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = kc}, ES.Back, ED.Out)
			tween(edge, 0.38, {Size = UDim2.fromOffset(3, on and 20 or 0)}, ES.Back, ED.Out)
		else
			track.BackgroundColor3 = tc
			trackStroke.Color = sc
			knob.Position = UDim2.fromOffset(kx, 3)
			knob.Size = UDim2.fromOffset(18, 18)
			knob.BackgroundColor3 = kc
			edge.Size = UDim2.fromOffset(3, on and 20 or 0)
		end
	end
	bindTheme(track, function()
		paint(false)
	end)
	c.hit.InputBegan:Connect(function(input)
		if isPress(input) then
			tween(knob, 0.1, {Size = UDim2.fromOffset(24, 18), Position = UDim2.fromOffset(on and 17 or 3, 3)}, ES.Quad)
		end
	end)
	c.hit.MouseLeave:Connect(function()
		paint(true)
	end)
	local object = {Name = o.Name}
	function object:Set(value, silent)
		value = value and true or false
		local changed = value ~= on
		on = value
		paint(true)
		setFlag(o, on)
		if changed and not silent then
			W:_fire(o.Callback, on)
		end
	end
	function object:Get()
		return on
	end
	function object:Toggle()
		object:Set(not on)
	end
	c.hit.MouseButton1Click:Connect(function()
		W.Sfx("Toggle")
		object:Set(not on)
	end)
	setFlag(o, on)
	return object
end
function Tab:Slider(o)
	local W = self.Window
	o = o or {}
	local min, max = o.Min or 0, o.Max or 100
	local step = o.Step or o.Increment or 1
	local suffix = o.Suffix or ""
	local c = self:_card(58, o.Name, {silent = true, Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Slider"
	end
	c.title.Size = UDim2.new(1, -100 - c.iconShift, 0, 32)
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 5),
		Size = UDim2.fromOffset(78, 24),
		BackgroundColor3 = Theme.Input,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Accent,
		PlaceholderText = "0",
		PlaceholderColor3 = Theme.Muted,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 7,
		Parent = c.card,
	})
	corner(box, 8)
	local boxStroke = stroke(box, Theme.Stroke, 1)
	local track = new("Frame", {
		Position = UDim2.new(0, 14, 1, -20),
		Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Theme.Track,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = c.card,
	})
	round(track)
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	round(fill)
	local fillGrad = new("UIGradient", {Parent = fill})
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = fill,
	})
	round(knob)
	local knobStroke = stroke(knob, Theme.Accent, 3, 0.6)
	local knobScale = new("UIScale", {Scale = 1, Parent = knob})
	bindTheme(track, function(T)
		box.TextColor3 = T.Accent
		knobStroke.Color = T.Accent
		fillGrad.Color = ColorSequence.new({ck(0, T.Accent2:Lerp(T.Accent, 0.35)), ck(1, T.Accent)})
		track.BackgroundColor3 = T.Track
	end)
	local value
	local dragging = false
	local function show(v)
		box.Text = string.format("%g", v) .. suffix
	end
	local lastTick = 0
	local function tickSfx()
		local now = os.clock()
		if now - lastTick >= SLIDER_TICK then
			lastTick = now
			W.Sfx("Slider")
		end
	end
	local function setValue(v, silent, typed)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		v = tonumber(string.format("%.4f", v))
		local changed = v ~= value
		value = v
		if changed and dragging then
			tickSfx()
		end
		local a = max > min and (v - min) / (max - min) or 0
		tween(fill, dragging and 0.06 or 0.22, {Size = UDim2.fromScale(a, 1)}, ES.Quad, ED.Out)
		if not typed then
			show(v)
		end
		setFlag(o, v)
		if changed and not silent then
			W:_fire(o.Callback, v)
		end
	end
	setValue(o.Default or min, true)
	box.Focused:Connect(function()
		W.Click(1.05, 0.7)
		tween(boxStroke, 0.25, {Color = Theme.Accent}, ES.Quad)
		box.Text = string.format("%g", value)
	end)
	box.FocusLost:Connect(function()
		tween(boxStroke, 0.35, {Color = Theme.Stroke}, ES.Quad)
		local cleaned = string.gsub(box.Text, ",", ".")
		cleaned = string.gsub(cleaned, "[^%d%.%-]", "")
		local number = tonumber(cleaned)
		if number and number == number and math.abs(number) < 1e9 then
			setValue(number)
		else
			show(value)
		end
		show(value)
	end)
	local function updateFromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setValue(min + (max - min) * a)
	end
	local function endDrag()
		if dragging then
			dragging = false
			self.scroll.ScrollingEnabled = true
			tween(knobScale, 0.35, {Scale = 1}, ES.Back, ED.Out)
			tween(knobStroke, 0.3, {Transparency = 0.6}, ES.Quad)
		end
	end
	local pending = nil
	local function beginDrag(x)
		dragging = true
		W.Sfx("Slider")
		lastTick = os.clock()
		self.scroll.ScrollingEnabled = false
		tween(knobScale, 0.2, {Scale = 1.4}, ES.Back, ED.Out)
		tween(knobStroke, 0.2, {Transparency = 0.25}, ES.Quad)
		updateFromX(x)
	end
	c.hit.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local s = math.max(W._shellScale.Scale, 0.01)
		local y = input.Position.Y
		local ty = track.AbsolutePosition.Y
		if y >= ty - 16 * s and y <= ty + track.AbsoluteSize.Y + 12 * s then
			if input.UserInputType == Enum.UserInputType.Touch then
				pending = {x = input.Position.X, y = input.Position.Y}
			else
				beginDrag(input.Position.X)
			end
		end
	end)
	W:_connect(UserInputService.InputChanged, function(input)
		if not isMove(input) then
			return
		end
		if dragging then
			updateFromX(input.Position.X)
		elseif pending then
			local dx = math.abs(input.Position.X - pending.x)
			local dy = math.abs(input.Position.Y - pending.y)
			if dx > 6 or dy > 6 then
				pending = nil
				if dx > dy * 1.5 then
					beginDrag(input.Position.X)
				end
			end
		end
	end)
	W:_connect(UserInputService.InputEnded, function(input)
		if isPress(input) then
			if pending then
				local p = pending
				pending = nil
				updateFromX(p.x)
			end
			endDrag()
		end
	end)
	local object = {Name = o.Name}
	function object:Set(v, silent)
		setValue(tonumber(v) or min, silent)
	end
	function object:Get()
		return value
	end
	return object
end
function Tab:Dropdown(o)
	local W = self.Window
	o = o or {}
	local options = o.Options or {}
	local multi = o.Multi and true or false
	local HEAD = 40
	local c = self:_card(HEAD, o.Name, {hitHeight = HEAD, clip = true, Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Dropdown"
	end
	c.title.Size = UDim2.new(0.5, -14 - c.iconShift, 0, HEAD)
	local selected = {}
	local current = nil
	if multi then
		if type(o.Default) == "table" then
			for _, v in ipairs(o.Default) do
				selected[v] = true
			end
		end
	else
		current = o.Default or options[1]
	end
	local valueLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -36, 0, 0),
		Size = UDim2.new(0.5, -20, 0, HEAD),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = c.card,
	})
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -20, 0, HEAD / 2),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = ">",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		Rotation = 90,
		ZIndex = 2,
		Parent = c.card,
	})
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, HEAD + 2),
		Size = UDim2.new(1, -16, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 6,
		Parent = c.card,
	})
	new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
	local buttons = {}
	local open = false
	local openH = HEAD
	local function summary()
		if multi then
			local names = {}
			for _, opt in ipairs(options) do
				if selected[opt] then
					table.insert(names, tostring(opt))
				end
			end
			if #names == 0 then
				return "None"
			elseif #names <= 2 then
				return table.concat(names, ", ")
			end
			return names[1] .. ", " .. names[2] .. " +" .. (#names - 2)
		end
		return current ~= nil and tostring(current) or "None"
	end
	local function paintOptions(animate)
		for _, entry in ipairs(buttons) do
			local isOn = multi and selected[entry.value] or (not multi and current == entry.value)
			local bg = isOn and Theme.Accent or Theme.Button
			local bgT = isOn and 0.8 or 0.1
			local tc = isOn and Theme.Text or Theme.Muted
			if animate then
				tween(entry.button, 0.25, {BackgroundColor3 = bg, BackgroundTransparency = bgT, TextColor3 = tc}, ES.Quad)
				tween(entry.dot, 0.3, {BackgroundTransparency = isOn and 0 or 1, Size = isOn and UDim2.fromOffset(8, 8) or UDim2.fromOffset(2, 2)}, ES.Back, ED.Out)
			else
				entry.button.BackgroundColor3 = bg
				entry.button.BackgroundTransparency = bgT
				entry.button.TextColor3 = tc
				entry.dot.BackgroundTransparency = isOn and 0 or 1
				entry.dot.Size = isOn and UDim2.fromOffset(8, 8) or UDim2.fromOffset(2, 2)
			end
			entry.dot.BackgroundColor3 = Theme.Accent
		end
		valueLabel.Text = summary()
		valueLabel.TextColor3 = Theme.Accent
	end
	local function emit(silent)
		local out
		if multi then
			out = {}
			for _, opt in ipairs(options) do
				if selected[opt] then
					table.insert(out, opt)
				end
			end
		else
			out = current
		end
		setFlag(o, out)
		if not silent then
			W:_fire(o.Callback, out)
		end
	end
	local function setOpen(on)
		open = on
		tween(c.slot, 0.42, {Size = UDim2.new(1, 0, 0, on and openH or HEAD)}, ES.Quint, ED.Out)
		tween(arrow, 0.35, {Rotation = on and -90 or 90}, ES.Back, ED.Out)
		if on then
			for i, entry in ipairs(buttons) do
				entry.button.TextTransparency = 1
				tween(entry.button, 0.3, {TextTransparency = 0}, ES.Quad, ED.Out, 0.04 * math.min(i, 8))
			end
		end
	end
	local function build()
		for _, entry in ipairs(buttons) do
			entry.button:Destroy()
		end
		buttons = {}
		for i, opt in ipairs(options) do
			local b = new("TextButton", {
				Size = UDim2.new(1, -6, 0, 26),
				BackgroundColor3 = Theme.Button,
				BackgroundTransparency = 0.1,
				Text = tostring(opt),
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextColor3 = Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 7,
				Parent = list,
			})
			corner(b, 8)
			new("UIPadding", {PaddingLeft = UDim.new(0, 12), Parent = b})
			local dot = new("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(2, 2),
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 8,
				Parent = b,
			})
			round(dot)
			local entry = {button = b, dot = dot, value = opt}
			buttons[i] = entry
			b.MouseEnter:Connect(function()
				local isOn = multi and selected[opt] or (not multi and current == opt)
				if not isOn then
					tween(b, 0.2, {BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.Text}, ES.Quad)
				end
			end)
			b.MouseLeave:Connect(function()
				paintOptions(true)
			end)
			b.MouseButton1Click:Connect(function()
				W.Click(1.1, 0.7)
				if multi then
					selected[opt] = not selected[opt] or nil
				else
					current = opt
				end
				paintOptions(true)
				emit(false)
				if not multi then
					setOpen(false)
				end
			end)
		end
		local visibleCount = math.min(#options, 5)
		local listH = visibleCount * 29
		list.Size = UDim2.new(1, -16, 0, listH)
		openH = HEAD + 2 + listH + 10
		paintOptions(false)
	end
	build()
	bindTheme(arrow, function(T)
		arrow.TextColor3 = T.Accent
		list.ScrollBarImageColor3 = T.Accent
		paintOptions(false)
	end)
	c.hit.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)
	local object = {Name = o.Name}
	function object:Set(value, silent)
		if multi then
			selected = {}
			if type(value) == "table" then
				for _, v in ipairs(value) do
					selected[v] = true
				end
			end
		else
			current = value
		end
		paintOptions(true)
		emit(silent)
	end
	function object:Get()
		if multi then
			local out = {}
			for _, opt in ipairs(options) do
				if selected[opt] then
					table.insert(out, opt)
				end
			end
			return out
		end
		return current
	end
	function object:Refresh(newOptions, keep)
		options = newOptions or {}
		if not keep then
			selected = {}
			current = options[1]
		end
		build()
		if open then
			setOpen(true)
		end
	end
	function object:Open()
		setOpen(true)
	end
	function object:Close()
		setOpen(false)
	end
	setFlag(o, multi and object:Get() or current)
	return object
end
function Tab:Input(o)
	local W = self.Window
	o = o or {}
	local c = self:_card(40, o.Name, {silent = true, Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Input"
	end
	c.title.Size = UDim2.new(0.48, -14 - c.iconShift, 1, 0)
	c.hit.Size = UDim2.new(0.5, 0, 1, 0)
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.5, -10, 0, 26),
		BackgroundColor3 = Theme.Input,
		Text = tostring(o.Default or ""),
		PlaceholderText = o.Placeholder or "...",
		PlaceholderColor3 = Theme.Muted,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
		Parent = c.card,
	})
	corner(box, 8)
	new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = box})
	local boxStroke = stroke(box, Theme.Stroke, 1)
	local underline = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 8,
		Parent = box,
	})
	round(underline)
	bindTheme(underline, function(T)
		underline.BackgroundColor3 = T.Accent
	end)
	box.Focused:Connect(function()
		W.Click(1.05, 0.7)
		tween(boxStroke, 0.25, {Color = Theme.Accent}, ES.Quad)
		tween(underline, 0.4, {Size = UDim2.new(1, -10, 0, 2)}, ES.Quint, ED.Out)
	end)
	box.FocusLost:Connect(function()
		tween(boxStroke, 0.35, {Color = Theme.Stroke}, ES.Quad)
		tween(underline, 0.3, {Size = UDim2.new(0, 0, 0, 2)}, ES.Quad, ED.In)
		setFlag(o, box.Text)
		W:_fire(o.Callback, box.Text)
	end)
	if o.Numeric then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local cleaned = string.gsub(box.Text, "[^%d%.%-]", "")
			if cleaned ~= box.Text then
				box.Text = cleaned
			end
		end)
	end
	if o.Live then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			W:_fire(o.Callback, box.Text)
		end)
	end
	local object = {Name = o.Name}
	function object:Get()
		return box.Text
	end
	function object:Set(text, silent)
		box.Text = tostring(text or "")
		setFlag(o, box.Text)
		if not silent then
			W:_fire(o.Callback, box.Text)
		end
	end
	setFlag(o, box.Text)
	return object
end
function Tab:Keybind(o)
	local W = self.Window
	o = o or {}
	local key = o.Default or Enum.KeyCode.F
	local c = self:_card(40, o.Name, {silent = true, Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Keybind"
	end
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(78, 26),
		BackgroundColor3 = Theme.Input,
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Theme.Accent,
		AutoButtonColor = false,
		ZIndex = 7,
		Parent = c.card,
	})
	corner(btn, 8)
	local btnStroke = stroke(btn, Theme.Stroke, 1)
	bindTheme(btn, function(T)
		btn.TextColor3 = T.Accent
	end)
	local listening = false
	local object = {Name = o.Name}
	local function label()
		btn.Text = (key == Enum.KeyCode.Unknown) and "None" or key.Name
	end
	label()
	local function stopListen()
		listening = false
		tween(btnStroke, 0.3, {Color = Theme.Stroke}, ES.Quad)
		task.delay(0.1, function()
			if W.Capturing == object then
				W.Capturing = nil
			end
		end)
	end
	local function startListen()
		if listening then
			return
		end
		listening = true
		W.Capturing = object
		btn.Text = "..."
		tween(btnStroke, 0.25, {Color = Theme.Accent}, ES.Quad)
		task.spawn(function()
			while listening and btn.Parent do
				tween(btnStroke, 0.5, {Transparency = 0.7}, ES.Sine)
				task.wait(0.5)
				tween(btnStroke, 0.5, {Transparency = 0}, ES.Sine)
				task.wait(0.5)
			end
			btnStroke.Transparency = 0
		end)
	end
	function object:Get()
		return key
	end
	function object:Set(newKey, silent)
		key = newKey or Enum.KeyCode.Unknown
		label()
		setFlag(o, key)
		if not silent then
			W:_fire(o.Changed, key)
		end
	end
	btn.MouseButton1Click:Connect(function()
		W.Click(1, 0.8)
		startListen()
	end)
	c.hit.MouseButton1Click:Connect(function()
		W.Click(1, 0.8)
		startListen()
	end)
	W:_connect(UserInputService.InputBegan, function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				stopListen()
				if input.KeyCode == Enum.KeyCode.Escape then
					label()
				elseif input.KeyCode == Enum.KeyCode.Backspace then
					object:Set(Enum.KeyCode.Unknown)
				else
					object:Set(input.KeyCode)
				end
			end
			return
		end
		if processed or W.Capturing then
			return
		end
		if key ~= Enum.KeyCode.Unknown and input.KeyCode == key then
			c.flash()
			W:_fire(o.Callback, key)
		end
	end)
	setFlag(o, key)
	return object
end
function Tab:ColorPicker(o)
	local W = self.Window
	o = o or {}
	local color = o.Default or WHITE
	local h, s, v = color:ToHSV()
	local HEAD, BODY = 40, 124
	local c = self:_card(HEAD, o.Name, {hitHeight = HEAD, clip = true, Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Color"
	end
	local swatch = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0, HEAD / 2),
		Size = UDim2.fromOffset(34, 22),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = c.card,
	})
	corner(swatch, 7)
	stroke(swatch, WHITE, 1, 0.7)
	local svBox = new("Frame", {
		Position = UDim2.fromOffset(12, HEAD + 4),
		Size = UDim2.new(1, -52, 0, 100),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = c.card,
	})
	corner(svBox, 8)
	local whiteLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6, Parent = svBox})
	corner(whiteLayer, 8)
	new("UIGradient", {Transparency = NumberSequence.new({kp(0, 0), kp(1, 1)}), Parent = whiteLayer})
	local blackLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 7, Parent = svBox})
	corner(blackLayer, 8)
	new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({kp(0, 1), kp(1, 0)}), Parent = blackLayer})
	local svCursor = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(s, 1 - v),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		ZIndex = 9,
		Parent = svBox,
	})
	round(svCursor)
	stroke(svCursor, WHITE, 2)
	local svBtn = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 10, Parent = svBox})
	local hueBar = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, HEAD + 4),
		Size = UDim2.fromOffset(18, 100),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = c.card,
	})
	corner(hueBar, 8)
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ck(0, Color3.fromHSV(0, 1, 1)),
			ck(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
			ck(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
			ck(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
			ck(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
			ck(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
			ck(1, Color3.fromHSV(0, 1, 1)),
		}),
		Parent = hueBar,
	})
	local hueCursor = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, h),
		Size = UDim2.new(1, 6, 0, 6),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 9,
		Parent = hueBar,
	})
	round(hueCursor)
	stroke(hueCursor, BLACK, 1, 0.5)
	local hueBtn = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 10, Parent = hueBar})
	local function apply(silent)
		color = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = color
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.fromScale(s, 1 - v)
		hueCursor.Position = UDim2.fromScale(0.5, h)
		setFlag(o, color)
		if not silent then
			W:_fire(o.Callback, color)
		end
	end
	local svDrag, hueDrag = false, false
	local function setScroll(on)
		self.scroll.ScrollingEnabled = on
	end
	local function updateSV(pos)
		s = math.clamp((pos.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
		v = 1 - math.clamp((pos.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
		apply(false)
	end
	local function updateHue(pos)
		h = math.clamp((pos.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y, 1), 0, 0.999)
		apply(false)
	end
	svBtn.InputBegan:Connect(function(input)
		if isPress(input) then
			svDrag = true
			setScroll(false)
			updateSV(input.Position)
		end
	end)
	hueBtn.InputBegan:Connect(function(input)
		if isPress(input) then
			hueDrag = true
			setScroll(false)
			updateHue(input.Position)
		end
	end)
	W:_connect(UserInputService.InputChanged, function(input)
		if isMove(input) then
			if svDrag then
				updateSV(input.Position)
			elseif hueDrag then
				updateHue(input.Position)
			end
		end
	end)
	W:_connect(UserInputService.InputEnded, function(input)
		if isPress(input) and (svDrag or hueDrag) then
			svDrag, hueDrag = false, false
			setScroll(true)
		end
	end)
	local open = false
	c.hit.MouseButton1Click:Connect(function()
		open = not open
		tween(c.slot, 0.42, {Size = UDim2.new(1, 0, 0, open and (HEAD + BODY + 8) or HEAD)}, ES.Quint, ED.Out)
	end)
	local object = {Name = o.Name}
	function object:Get()
		return color
	end
	function object:Set(newColor, silent)
		if typeof(newColor) == "Color3" then
			h, s, v = newColor:ToHSV()
			apply(silent)
		end
	end
	setFlag(o, color)
	return object
end
function Tab:Foldout(o)
	local W = self.Window
	o = o or {}
	local c = self:_card(40, o.Name, {Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Group"
	end
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = ">",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		Rotation = 90,
		ZIndex = 2,
		Parent = c.card,
	})
	bindTheme(arrow, function(T)
		arrow.TextColor3 = T.Accent
	end)
	local group = {}
	local object = {}
	self.capture = group
	self._foldoutObj = object
	W:_fire(o.Build, self)
	self.capture = nil
	self._foldoutObj = nil
	local open = o.Open and true or false
	local function apply(animate)
		tween(arrow, 0.35, {Rotation = open and -90 or 90}, ES.Back, ED.Out)
		for i, entry in ipairs(group) do
			entry.slot.Visible = open
			if open and animate then
				entry.frame.Position = UDim2.fromOffset(0, -10)
				tween(entry.frame, 0.4, {Position = UDim2.new()}, ES.Quint, ED.Out, i * 0.03)
			end
		end
	end
	apply(false)
	c.hit.MouseButton1Click:Connect(function()
		open = not open
		apply(true)
	end)
	function object:Set(value)
		open = value and true or false
		apply(true)
	end
	function object:Get()
		return open
	end
	return object
end
function Tab:IconPicker(o)
	local W = self.Window
	o = o or {}
	local names = o.Icons or Library:GetIconNames()
	local HEAD, GRID_H = 40, 138
	local OPEN_H = HEAD + 38 + GRID_H + 26
	local c = self:_card(HEAD, o.Name, {hitHeight = HEAD, clip = true, Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Icons"
	end
	c.title.Size = UDim2.new(0.45, -14 - c.iconShift, 0, HEAD)
	local current = o.Default or ""
	local object = {Name = o.Name}
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -20, 0, HEAD / 2),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = ">",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		Rotation = 90,
		ZIndex = 2,
		Parent = c.card,
	})
	bindTheme(arrow, function(T)
		arrow.TextColor3 = T.Accent
	end)
	local preview = createIcon(current ~= "" and current or "circle", c.card, 20, "Accent", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -38, 0, HEAD / 2),
		ZIndex = 3,
		Visible = current ~= "",
	})
	local nameLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -66, 0, 0),
		Size = UDim2.new(0.4, 0, 0, HEAD),
		BackgroundTransparency = 1,
		Text = current ~= "" and current or "None",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = c.card,
	})
	local search = new("TextBox", {
		Position = UDim2.fromOffset(10, HEAD + 4),
		Size = UDim2.new(1, -86, 0, 26),
		BackgroundColor3 = Theme.Input,
		Text = "",
		PlaceholderText = "Search icons...",
		PlaceholderColor3 = Theme.Muted,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
		Parent = c.card,
	})
	corner(search, 8)
	new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8), Parent = search})
	local searchStroke = stroke(search, Theme.Stroke, 1)
	search.Focused:Connect(function()
		tween(searchStroke, 0.25, {Color = Theme.Accent}, ES.Quad)
	end)
	search.FocusLost:Connect(function()
		tween(searchStroke, 0.35, {Color = Theme.Stroke}, ES.Quad)
	end)
	local clearBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, HEAD + 4),
		Size = UDim2.fromOffset(62, 26),
		BackgroundColor3 = Theme.Button,
		BackgroundTransparency = 0.1,
		Text = "None",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		AutoButtonColor = false,
		ZIndex = 7,
		Parent = c.card,
	})
	corner(clearBtn, 8)
	local grid = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, HEAD + 36),
		Size = UDim2.new(1, -16, 0, GRID_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 6,
		Parent = c.card,
	})
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(34, 34),
		CellPadding = UDim2.fromOffset(5, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4), Parent = grid})
	bindTheme(grid, function(T)
		grid.ScrollBarImageColor3 = T.Accent
	end)
	local footer = new("TextLabel", {
		Position = UDim2.new(0, 12, 0, HEAD + 36 + GRID_H + 4),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Text = #names .. " icons",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
		Parent = c.card,
	})
	local cells = {}
	local built, building, open = false, false, false
	local function paintCells()
		for name, cell in pairs(cells) do
			local on = name == current
			cell.button.BackgroundColor3 = on and Theme.Accent or Theme.Button
			cell.button.BackgroundTransparency = on and 0.78 or 0.15
			cell.stroke.Transparency = on and 0.3 or 1
			cell.icon:SetColor(on and "Accent" or "Muted")
		end
	end
	local function applyFilter()
		local q = string.lower(search.Text or "")
		local shown = 0
		for name, cell in pairs(cells) do
			local vis = q == "" or string.find(name, q, 1, true) ~= nil
			cell.button.Visible = vis
			if vis then
				shown = shown + 1
			end
		end
		footer.Text = shown .. " / " .. #names .. " icons"
	end
	search:GetPropertyChangedSignal("Text"):Connect(applyFilter)
	local function build()
		if built or building then
			return
		end
		building = true
		task.spawn(function()
			for i, name in ipairs(names) do
				if not grid.Parent then
					return
				end
				local b = new("TextButton", {
					BackgroundColor3 = Theme.Button,
					BackgroundTransparency = 0.15,
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = i,
					ZIndex = 7,
					Parent = grid,
				})
				corner(b, 8)
				local st = stroke(b, Theme.Accent, 1, 1)
				local ic = createIcon(name, b, 18, "Muted", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					ZIndex = 8,
				})
				cells[name] = {button = b, icon = ic, stroke = st}
				b.MouseEnter:Connect(function()
					footer.Text = name
					if name ~= current then
						tween(b, 0.15, {BackgroundColor3 = Theme.CardHover}, ES.Quad)
					end
				end)
				b.MouseLeave:Connect(function()
					footer.Text = current ~= "" and current or (#names .. " icons")
					tween(b, 0.25, {BackgroundColor3 = name == current and Theme.Accent or Theme.Button}, ES.Quad)
				end)
				b.MouseButton1Click:Connect(function()
					W.Click(1.1, 0.7)
					object:Set(name)
				end)
				if i % 14 == 0 then
					task.wait()
				end
			end
			built, building = true, false
			paintCells()
			applyFilter()
		end)
	end
	function object:Set(name, silent)
		current = name or ""
		preview.Frame.Visible = current ~= ""
		if current ~= "" then
			preview:SetIcon(current)
		end
		nameLabel.Text = current ~= "" and current or "None"
		paintCells()
		setFlag(o, current)
		if not silent then
			W:_fire(o.Callback, current)
		end
	end
	function object:Get()
		return current
	end
	c.hit.MouseButton1Click:Connect(function()
		open = not open
		tween(c.slot, 0.45, {Size = UDim2.new(1, 0, 0, open and OPEN_H or HEAD)}, ES.Quint, ED.Out)
		tween(arrow, 0.35, {Rotation = open and -90 or 90}, ES.Back, ED.Out)
		if open then
			build()
		end
	end)
	clearBtn.MouseButton1Click:Connect(function()
		W.Click(1, 0.7)
		object:Set("")
	end)
	setFlag(o, current)
	return object
end
function Tab:FontPicker(o)
	local W = self.Window
	o = o or {}
	local names = o.Fonts or Library:GetFontNames()
	local HEAD, LIST_H = 40, 150
	local OPEN_H = HEAD + 38 + LIST_H + 26
	local c = self:_card(HEAD, o.Name, {hitHeight = HEAD, clip = true, Icon = o.Icon})
	if c.entry then
		c.entry.Kind = "Font"
	end
	c.title.Size = UDim2.new(0.4, -14 - c.iconShift, 0, HEAD)
	local current = o.Default or Library.FontName
	local object = {Name = o.Name}
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -20, 0, HEAD / 2),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Text = ">",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		Rotation = 90,
		ZIndex = 2,
		Parent = c.card,
	})
	local nameLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -38, 0, 0),
		Size = UDim2.new(0.55, 0, 0, HEAD),
		BackgroundTransparency = 1,
		Text = current,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = c.card,
	})
	bindTheme(arrow, function(T)
		arrow.TextColor3 = T.Accent
		nameLabel.TextColor3 = T.Accent
	end)
	local search = new("TextBox", {
		Position = UDim2.fromOffset(10, HEAD + 4),
		Size = UDim2.new(1, -20, 0, 26),
		BackgroundColor3 = Theme.Input,
		Text = "",
		PlaceholderText = "Search fonts...",
		PlaceholderColor3 = Theme.Muted,
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
		Parent = c.card,
	})
	corner(search, 8)
	new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8), Parent = search})
	local searchStroke = stroke(search, Theme.Stroke, 1)
	search.Focused:Connect(function()
		tween(searchStroke, 0.25, {Color = Theme.Accent}, ES.Quad)
	end)
	search.FocusLost:Connect(function()
		tween(searchStroke, 0.35, {Color = Theme.Stroke}, ES.Quad)
	end)
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, HEAD + 36),
		Size = UDim2.new(1, -16, 0, LIST_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 6,
		Parent = c.card,
	})
	new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
	new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4), Parent = list})
	bindTheme(list, function(T)
		list.ScrollBarImageColor3 = T.Accent
	end)
	local footer = new("TextLabel", {
		Position = UDim2.new(0, 12, 0, HEAD + 36 + LIST_H + 4),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Text = #names .. " fonts",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
		Parent = c.card,
	})
	local rows = {}
	local built, open = false, false
	local function paintRows()
		for name, row in pairs(rows) do
			local on = name == current
			row.button.BackgroundColor3 = on and Theme.Accent or Theme.Button
			row.button.BackgroundTransparency = on and 0.78 or 0.1
			row.button.TextColor3 = on and Theme.Text or Theme.Muted
		end
	end
	local function applyFilter()
		local q = string.lower(search.Text or "")
		local shown = 0
		for name, row in pairs(rows) do
			local vis = q == "" or string.find(string.lower(name), q, 1, true) ~= nil
			row.button.Visible = vis
			if vis then
				shown = shown + 1
			end
		end
		footer.Text = shown .. " / " .. #names .. " fonts"
	end
	search:GetPropertyChangedSignal("Text"):Connect(applyFilter)
	local function build()
		if built then
			return
		end
		built = true
		for i, name in ipairs(names) do
			local info = Library:GetFontInfo(name)
			local b = new("TextButton", {
				Size = UDim2.new(1, -6, 0, 28),
				BackgroundColor3 = Theme.Button,
				BackgroundTransparency = 0.1,
				Text = name,
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextColor3 = Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 7,
				Parent = list,
			})
			corner(b, 8)
			new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 92), Parent = b})
			new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 84, 0.5, 0),
				Size = UDim2.fromOffset(80, 14),
				BackgroundTransparency = 1,
				Text = (info and info.Id) and tostring(info.Id) or "built-in",
				Font = Enum.Font.Gotham,
				TextSize = 9,
				TextColor3 = Theme.Muted,
				TextTransparency = 0.35,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 8,
				Parent = b,
			})
			rows[name] = {button = b}
			b.MouseEnter:Connect(function()
				if name ~= current then
					tween(b, 0.15, {BackgroundColor3 = Theme.CardHover}, ES.Quad)
				end
			end)
			b.MouseLeave:Connect(function()
				tween(b, 0.25, {BackgroundColor3 = name == current and Theme.Accent or Theme.Button}, ES.Quad)
			end)
			b.MouseButton1Click:Connect(function()
				W.Click(1.1, 0.7)
				object:Set(name)
			end)
		end
		paintRows()
		applyFilter()
	end
	function object:Set(name, silent)
		current = name
		nameLabel.Text = tostring(name)
		paintRows()
		setFlag(o, current)
		if not silent then
			W:_fire(o.Callback, current)
		end
	end
	function object:Get()
		return current
	end
	c.hit.MouseButton1Click:Connect(function()
		open = not open
		tween(c.slot, 0.45, {Size = UDim2.new(1, 0, 0, open and OPEN_H or HEAD)}, ES.Quint, ED.Out)
		tween(arrow, 0.35, {Rotation = open and -90 or 90}, ES.Back, ED.Out)
		if open then
			build()
		end
	end)
	setFlag(o, current)
	return object
end
local function c3ToTable(c)
	return {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
end
local function tableToC3(t)
	if type(t) == "table" and #t == 3 then
		return Color3.fromRGB(t[1], t[2], t[3])
	end
	return nil
end
local function applyWindowConfig(W, wc)
	if type(wc) ~= "table" then
		return
	end
	if type(wc.FX) == "table" then
		for k, v in pairs(wc.FX) do
			if type(v) == "boolean" then
				W:SetEffect(k, v)
			end
		end
	end
	if type(wc.Scale) == "number" then
		W:SetScale(wc.Scale)
	end
	if type(wc.Icon) == "string" and wc.Icon ~= "" then
		W:SetIcon(wc.Icon)
	end
	if type(wc.IslandWidth) == "number" then
		W:SetIslandWidth(wc.IslandWidth)
	end
	if type(wc.BorderSpeed) == "number" then
		W.BorderSpeed = wc.BorderSpeed
	end
	if type(wc.TabPosition) == "string" then
		W:SetTabPosition(wc.TabPosition, true)
	end
	if type(wc.ToggleKey) == "string" then
		local ok, key = pcall(function()
			return Enum.KeyCode[wc.ToggleKey]
		end)
		if ok and key then
			W:SetToggleKey(key)
		end
	end
end
function Library:SaveConfig(fileName)
	if not writefile then
		return false, "writefile tidak tersedia di executor ini"
	end
	fileName = fileName or "RXM_UI_Config.json"
	local raw = self.Intros[self.ActiveIntro] or {}
	local colors = {}
	if type(raw.Colors) == "table" then
		for k, v in pairs(raw.Colors) do
			if typeof(v) == "Color3" then
				colors[k] = c3ToTable(v)
			end
		end
	end
	local data = {
		Font = self.FontName,
		Transparency = self.Transparency,
		Accent = c3ToTable(Theme.Accent),
		Intro = {
			Style = type(raw.Style) == "string" and raw.Style or nil,
			Text = raw.Text,
			Subtitle = raw.Subtitle,
			Image = raw.Image,
			Sound = raw.Sound,
			Volume = raw.Volume,
			Duration = raw.Duration,
			Icon = raw.Icon,
			Enabled = self.IntroEnabled,
			Colors = colors,
		},
	}
	local W = self.Windows[1]
	if W then
		data.Window = {FX = W.FX, Scale = W.Scale, BorderSpeed = W.BorderSpeed, ToggleKey = W.ToggleKey.Name, Icon = W.Icon, IslandWidth = W.IslandWidth, TabPosition = W.TabPosition}
	end
	local okJson, json = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not okJson then
		return false, tostring(json)
	end
	local okWrite, err = pcall(writefile, fileName, json)
	if not okWrite then
		return false, tostring(err)
	end
	return true
end
function Library:LoadConfig(fileName)
	if not (readfile and isfile) then
		return false, "readfile/isfile tidak tersedia di executor ini"
	end
	fileName = fileName or "RXM_UI_Config.json"
	local okExists, exists = pcall(isfile, fileName)
	if not (okExists and exists) then
		return false, "file config tidak ditemukan"
	end
	local okRead, raw = pcall(readfile, fileName)
	if not okRead then
		return false, tostring(raw)
	end
	local okJson, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not okJson or type(data) ~= "table" then
		return false, "isi config tidak valid"
	end
	if type(data.Font) == "string" then
		self:SetFont(data.Font)
	end
	if type(data.Transparency) == "number" then
		self:SetTransparency(data.Transparency)
	end
	local accent = tableToC3(data.Accent)
	if accent then
		self:SetAccent(accent)
	end
	if type(data.Intro) == "table" then
		if type(data.Intro.Enabled) == "boolean" then
			self.IntroEnabled = data.Intro.Enabled
		end
		local patch = {}
		for _, key in ipairs({"Style", "Text", "Subtitle", "Image", "Sound", "Volume", "Duration", "Icon"}) do
			if data.Intro[key] ~= nil then
				patch[key] = data.Intro[key]
			end
		end
		if type(data.Intro.Colors) == "table" then
			local colors = {}
			for k, v in pairs(data.Intro.Colors) do
				local c = tableToC3(v)
				if c then
					colors[k] = c
				end
			end
			patch.Colors = next(colors) and colors or false
		end
		self:SetIntro(patch)
	end
	if type(data.Window) == "table" then
		self._windowConfig = data.Window
		for _, W in ipairs(self.Windows) do
			applyWindowConfig(W, data.Window)
		end
	end
	return true
end
function Library:CreateWindow(opts)
	opts = opts or {}
	local configFile = opts.ConfigFile or "RXM_UI_Config.json"
	if opts.AutoLoad then
		self:LoadConfig(configFile)
	end
	if opts.Font ~= nil then
		self:SetFont(opts.Font)
	end
	if type(opts.Transparency) == "number" then
		self:SetTransparency(opts.Transparency)
	end
	if opts.Preset then
		self:SetPreset(opts.Preset)
	end
	if typeof(opts.Accent) == "Color3" then
		self:SetAccent(opts.Accent)
	end
	local kcfg = self:_resolveKey(opts)
	if kcfg then
		local okKey = self:KeySystem(kcfg)
		if not okKey then
			return nil
		end
	end
	local W = setmetatable({}, Window)
	W.Library = self
	W.Name = tostring(opts.Name or "RXM HUB")
	W.Alive = true
	W.State = "idle"
	W.Ready = false
	W.Tabs = {}
	W.Connections = {}
	W._pending = {}
	W.ConfigFile = configFile
	W.Icon = opts.Icon
	W.IslandWidth = opts.IslandWidth
	W.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightControl
	W.Scale = opts.Scale or 0.9
	W.BorderSpeed = opts.BorderSpeed or 70
	W.TabPosition = normalizeTabPosition(opts.TabPosition) or "Up"
	W.FX = {Border = true, Glow = true, Neon = true, Shimmer = true, Embers = true, Aurora = true, Sounds = true, NotifySounds = true, SliderSounds = true, SwitchSounds = true}
	local wc = self._windowConfig
	if type(wc) == "table" then
		if type(wc.FX) == "table" then
			for k, v in pairs(wc.FX) do
				if W.FX[k] ~= nil and type(v) == "boolean" then
					W.FX[k] = v
				end
			end
		end
		if opts.Scale == nil and type(wc.Scale) == "number" then
			W.Scale = math.clamp(wc.Scale, 0.6, 1.4)
		end
		if opts.Icon == nil and type(wc.Icon) == "string" and wc.Icon ~= "" then
			W.Icon = wc.Icon
		end
		if opts.IslandWidth == nil and type(wc.IslandWidth) == "number" then
			W.IslandWidth = wc.IslandWidth
		end
		if opts.BorderSpeed == nil and type(wc.BorderSpeed) == "number" then
			W.BorderSpeed = wc.BorderSpeed
		end
		if opts.TabPosition == nil then
			local savedPos = normalizeTabPosition(wc.TabPosition)
			if savedPos then
				W.TabPosition = savedPos
			end
		end
		if opts.ToggleKey == nil and type(wc.ToggleKey) == "string" then
			local okKey, key = pcall(function()
				return Enum.KeyCode[wc.ToggleKey]
			end)
			if okKey and key then
				W.ToggleKey = key
			end
		end
	end
	if type(opts.Effects) == "table" then
		for k, v in pairs(opts.Effects) do
			if W.FX[k] ~= nil then
				W.FX[k] = v and true or false
			end
		end
	end
	table.insert(self.Windows, W)
	local okBuild, errBuild = pcall(function()
		W:_build(opts)
	end)
	if not okBuild then
		for i, win in ipairs(self.Windows) do
			if win == W then
				table.remove(self.Windows, i)
				break
			end
		end
		W.Alive = false
		for _, c in ipairs(W.Connections) do
			pcall(function()
				c:Disconnect()
			end)
		end
		if W.Gui then
			pcall(function()
				W.Gui:Destroy()
			end)
		end
		error("RXM UI: gagal membuat window: " .. tostring(errBuild), 0)
	end
	if opts.Welcome ~= false then
		local how = isTouch and "Tap the island to open" or ("Click the island or press " .. W.ToggleKey.Name .. " to hide")
		W:Notify({Title = W.Name .. " loaded", Content = how, Type = "success", Duration = 4})
	end
	local intro = opts.Intro
	if intro == nil then
		intro = self.IntroEnabled
	end
	if intro == false then
		W:_reveal()
	else
		local which = nil
		if intro ~= true then
			which = intro
		end
		self:PlayIntro(which, function()
			W:_reveal()
		end)
	end
	return W
end
function Library:GetWindow()
	return self.Windows[#self.Windows]
end
function Library:Notify(data)
	local W = self.Windows[#self.Windows]
	if W then
		W:Notify(data)
	end
end
local function sortedKeys(t)
	local out = {}
	for k in pairs(t) do
		table.insert(out, k)
	end
	table.sort(out)
	return out
end
function Window:CreateSettingsTab(name, hide)
	local W = self
	if type(name) == "table" then
		hide = name
		name = nil
	end
	local H = {
		UIColor = true,
		Preset = true,
		UIScale = true,
		UITransparency = true,
		IslandWidth = true,
		ToggleKey = true,
		TabPosition = false,
		Font = true,
		Icon = true,
		Effects = false,
		Intro = true,
		Config = true,
		Key = true,
		DestroyUI = true,
	}
	if type(hide) == "table" then
		for k, v in pairs(hide) do
			if H[k] ~= nil then
				H[k] = v and true or false
			end
		end
	end
	local tab = W:AddTab(name or "Settings", "settings")
	W.SettingsTab = tab
	local uiColor, introColor, introText, introSub, introImage, introSound, introDuration, introStyle, introPick
	if not (H.UIColor and H.Preset and H.UIScale and H.UITransparency and H.IslandWidth and H.ToggleKey and H.TabPosition) then
		tab:Section("Appearance")
	end
	if not H.UIColor then
		uiColor = tab:ColorPicker({
			Name = "UI Color",
			Default = Theme.Accent,
			Callback = function(color)
				Library:SetAccent(color)
			end,
		})
	end
	if not H.Preset then
		local presetNames = {"Custom"}
		for _, n in ipairs(sortedKeys(Library.Presets)) do
			table.insert(presetNames, n)
		end
		tab:Dropdown({
			Name = "Preset",
			Options = presetNames,
			Default = "Custom",
			Callback = function(preset)
				if preset ~= "Custom" and Library:SetPreset(preset) and uiColor then
					uiColor:Set(Library.Presets[preset], true)
				end
			end,
		})
	end
	if not H.UIScale then
		tab:Slider({
			Name = "UI Scale",
			Min = 0.6,
			Max = 1.3,
			Step = 0.05,
			Default = W.Scale,
			Callback = function(value)
				W:SetScale(value)
			end,
		})
	end
	if not H.UITransparency then
		tab:Slider({
			Name = "UI Transparency",
			Min = 0,
			Max = 0.8,
			Step = 0.05,
			Default = Library.Transparency,
			Callback = function(value)
				Library:SetTransparency(value)
			end,
		})
	end
	if not H.IslandWidth then
		tab:Slider({
			Name = "Island Width",
			Min = 90,
			Max = 420,
			Step = 2,
			Suffix = " px",
			Default = W:GetIslandWidth(),
			Callback = function(value)
				W:SetIslandWidth(value)
			end,
		})
	end
	if not H.ToggleKey then
		tab:Keybind({
			Name = "Hide / Show UI",
			Default = W.ToggleKey,
			Changed = function(key)
				W:SetToggleKey(key)
			end,
		})
	end
	if not H.TabPosition then
		tab:Dropdown({
			Name = "Tab Position",
			Options = {"Up", "Down", "Left", "Right"},
			Default = W.TabPosition,
			Callback = function(value)
				W:SetTabPosition(value)
			end,
		})
	end
	if not H.Font then
		tab:Section("Font")
		tab:FontPicker({
			Name = "UI Font",
			Default = Library.FontName,
			Callback = function(name)
				Library:SetFont(name)
			end,
		})
	end
	if not H.Icon then
		tab:Section("Icons")
		tab:IconPicker({
			Name = "UI Icon",
			Default = W.Icon or "",
			Callback = function(name)
				W:SetIcon(name ~= "" and name or nil)
			end,
		})
	end
	if not H.Effects then
		tab:Section("Effects")
		local fxNames = {
			{"Border", "Animated Border"},
			{"Glow", "Glow"},
			{"Neon", "Neon Line"},
			{"Shimmer", "Title Shimmer"},
			{"Embers", "Embers"},
			{"Aurora", "Aurora"},
			{"Sounds", "Click Sounds"},
			{"NotifySounds", "Notify Sounds"},
			{"SliderSounds", "Slider Sounds"},
			{"SwitchSounds", "Switch Sounds"},
		}
		for _, entry in ipairs(fxNames) do
			tab:Toggle({
				Name = entry[2],
				Default = W.FX[entry[1]],
				Callback = function(on)
					W:SetEffect(entry[1], on)
				end,
			})
		end
		tab:Slider({
			Name = "Border Speed",
			Min = 10,
			Max = 300,
			Step = 5,
			Default = W.BorderSpeed,
			Callback = function(value)
				W.BorderSpeed = value
			end,
		})
	end
	if not H.Intro then
		tab:Section("Intro")
		tab:Toggle({
			Name = "Loading Screen (next execute)",
			Default = Library.IntroEnabled,
			Callback = function(on)
				Library:SetIntroEnabled(on)
			end,
		})
		local cfg = Library:GetIntroConfig()
		introPick = tab:Dropdown({
			Name = "Intro",
			Options = sortedKeys(Library.Intros),
			Default = Library.ActiveIntro,
			Callback = function(pick)
				Library:SetIntro(pick)
				local now = Library:GetIntroConfig()
				introText:Set(now.Text, true)
				introSub:Set(now.Subtitle, true)
				introImage:Set(now.Image and tostring(now.Image) or "", true)
				introSound:Set(now.Sound and tostring(now.Sound) or "", true)
				introDuration:Set(now.Duration, true)
				introColor:Set(now.ResolvedColors.Primary, true)
			end,
		})
		introStyle = tab:Dropdown({
			Name = "Intro Style",
			Options = sortedKeys(Library.IntroStyles),
			Default = type(cfg.Style) == "string" and cfg.Style or "Emblem",
			Callback = function(style)
				Library:SetIntroStyle(style)
			end,
		})
		introText = tab:Input({
			Name = "Intro Text",
			Default = cfg.Text,
			Placeholder = "title",
			Callback = function(text)
				Library:SetIntro({Text = text})
			end,
		})
		introSub = tab:Input({
			Name = "Intro Subtitle",
			Default = cfg.Subtitle,
			Placeholder = "subtitle",
			Callback = function(text)
				Library:SetIntro({Subtitle = text})
			end,
		})
		introImage = tab:Input({
			Name = "Intro Image",
			Default = cfg.Image and tostring(cfg.Image) or "",
			Placeholder = "id / link / file",
			Callback = function(text)
				Library:SetIntroImage(text ~= "" and text or nil)
			end,
		})
		introSound = tab:Input({
			Name = "Intro Sound",
			Default = cfg.Sound and tostring(cfg.Sound) or "",
			Placeholder = "sound id",
			Callback = function(text)
				Library:SetIntroSound(text ~= "" and text or nil)
			end,
		})
		introDuration = tab:Slider({
			Name = "Intro Duration",
			Min = 2,
			Max = 12,
			Step = 0.5,
			Suffix = "s",
			Default = cfg.Duration,
			Callback = function(value)
				Library:SetIntroDuration(value)
			end,
		})
		introColor = tab:ColorPicker({
			Name = "Intro Color",
			Default = cfg.ResolvedColors.Primary,
			Callback = function(color)
				Library:SetIntroColor(color)
			end,
		})
		tab:IconPicker({
			Name = "Intro Icon",
			Default = cfg.Icon or "",
			Callback = function(name)
				Library:SetIntro({Icon = name ~= "" and name or false})
			end,
		})
		tab:Button({
			Name = "Intro Color = follow UI Color",
			Callback = function()
				Library:SetIntroColor(nil)
				introColor:Set(Theme.Accent, true)
				W:Notify({Title = "Intro color", Content = "Now follows the UI color", Type = "info"})
			end,
		})
		tab:Button({
			Name = "Preview Intro",
			Solid = true,
			Callback = function()
				Library:PlayIntro()
			end,
		})
	end
	if not H.Config then
		tab:Section("Config")
		tab:Button({
			Name = "Save Config",
			Callback = function()
				local ok, err = Library:SaveConfig(W.ConfigFile)
				W:Notify({
					Title = ok and "Config saved" or "Save failed",
					Content = ok and W.ConfigFile or tostring(err),
					Type = ok and "success" or "error",
				})
			end,
		})
		tab:Button({
			Name = "Load Config",
			Callback = function()
				local ok, err = Library:LoadConfig(W.ConfigFile)
				if ok then
					local now = Library:GetIntroConfig()
					if uiColor then
						uiColor:Set(Theme.Accent, true)
					end
					if introText then
						introText:Set(now.Text, true)
						introSub:Set(now.Subtitle, true)
						introImage:Set(now.Image and tostring(now.Image) or "", true)
						introSound:Set(now.Sound and tostring(now.Sound) or "", true)
						introDuration:Set(now.Duration, true)
						introColor:Set(now.ResolvedColors.Primary, true)
					end
				end
				W:Notify({
					Title = ok and "Config loaded" or "Load failed",
					Content = ok and W.ConfigFile or tostring(err),
					Type = ok and "success" or "error",
				})
			end,
		})
	end
	if not H.Key and Library.KeyValid and Library.KeyInfo then
		tab:Section("Key", "key")
		tab:Label("Key: " .. Library:GetMaskedKey(), "key")
		tab:Label("Status: " .. Library:GetKeyStatusText())
		tab:Button({
			Name = "Remove Saved Key",
			Callback = function()
				Library:ClearSavedKey()
				W:Notify({Title = "Key", Content = "Saved key removed. You will be asked again next execute.", Type = "info"})
			end,
		})
	end
	if not H.DestroyUI then
		tab:Section("UI", "trash")
		local confirmAt = -10
		local destroyBtn
		destroyBtn = tab:Button({
			Name = "Destroy UI",
			Icon = "trash",
			Callback = function()
				if os.clock() - confirmAt < 3 then
					W:Destroy()
				else
					confirmAt = os.clock()
					destroyBtn:SetName("Tap again to confirm")
					task.delay(3, function()
						if W.Alive and os.clock() - confirmAt >= 3 then
							destroyBtn:SetName("Destroy UI")
						end
					end)
				end
			end,
		})
	end
	return tab
end
do
	local KeyTexts = {
		Title = "KEY SYSTEM",
		Subtitle = "Enter your key to continue",
		Placeholder = "Paste your key here",
		Verify = "Verify Key",
		Checking = "Checking",
		Accepted = "Accepted",
		Locked = "Too many attempts. Try again in %ds",
		LockedBtn = "Locked",
		GetKey = "Get Key",
		Discord = "Discord",
		Copied = "Copied!",
		Empty = "Please enter your key first",
		Invalid = "Invalid key",
		Expired = "This key has expired",
		Revoked = "This key has been disabled",
		WrongDevice = "This key is locked to another device",
		Offline = "Could not reach the key server",
		Valid = "Key accepted. Welcome!",
		Attempts = "Attempts left: %d",
		LinkCopied = "Link copied to clipboard",
		NoClipboard = "Clipboard unavailable, link placed in the box",
		SavedExpired = "Saved key is no longer valid",
		Kick = "Too many invalid key attempts.",
	}
	local KeyDefaults = {
		Save = true,
		FileName = "RXM_Key.txt",
		AutoLogin = true,
		CaseSensitive = true,
		MaxAttempts = 5,
		Lockout = 30,
		KickOnLock = false,
		Closable = true,
		Wait = true,
		Sounds = true,
		Icon = "key",
		CacheTime = 60,
	}
	Library.KeyTexts = KeyTexts
	Library.KeyValid = false
	Library.KeyEnabled = true
	Library.KeyInfo = nil
	Library._keyCancel = {}
	Library._keyRemote = {}
	Library._keyFile = nil

	local function keyText(cfg, name)
		local custom = cfg.Texts
		if type(custom) == "table" and custom[name] ~= nil then
			return tostring(custom[name])
		end
		return KeyTexts[name] or name
	end
	local function trimText(s)
		return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
	end
	local function fireCallback(fn, ...)
		if type(fn) == "function" then
			task.spawn(fn, ...)
		end
	end
	local function formatSpan(seconds)
		seconds = math.max(0, math.floor(seconds))
		local d = math.floor(seconds / 86400)
		local h = math.floor((seconds % 86400) / 3600)
		local m = math.floor((seconds % 3600) / 60)
		if d > 0 then
			return d .. "d " .. h .. "h"
		end
		if h > 0 then
			return h .. "h " .. m .. "m"
		end
		if m > 0 then
			return m .. "m"
		end
		return "<1m"
	end
	local function copyText(text)
		local fn = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
		if not fn then
			return false
		end
		return (pcall(fn, text))
	end
	local function httpGet(url)
		if requestFunc then
			local ok, res = pcall(requestFunc, {Url = url, Method = "GET"})
			if ok and type(res) == "table" then
				local code = tonumber(res.StatusCode or res.Status)
				if res.Success ~= false and (code == nil or (code >= 200 and code < 300)) and type(res.Body) == "string" then
					return true, res.Body
				end
				return false, "HTTP " .. tostring(code)
			end
		end
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(body) == "string" then
			return true, body
		end
		return false, "request failed"
	end

	function Library:SetKeyConfig(config)
		self.KeyConfig = type(config) == "table" and config or nil
	end

	function Library:GetHWID()
		local ok, id = pcall(function()
			return svc("RbxAnalyticsService"):GetClientId()
		end)
		if ok and id then
			return tostring(id)
		end
		return "unknown"
	end

	local function normalizeEntry(e)
		if type(e) == "string" or type(e) == "number" then
			return {Key = trimText(e)}
		end
		if type(e) ~= "table" then
			return nil
		end
		local key = e.Key or e.key or e[1]
		if key == nil then
			return nil
		end
		local hwid = e.HWID or e.hwid
		return {
			Key = trimText(key),
			Expire = tonumber(e.Expire or e.expire or e.Expires or e.expires),
			HWID = (type(hwid) == "string" and hwid ~= "") and hwid or nil,
			Tier = e.Tier or e.tier,
			Note = e.Note or e.note,
			Disabled = (e.Active == false or e.active == false or e.Enabled == false or e.enabled == false or e.Disabled == true or e.disabled == true) or nil,
		}
	end
	local function addEntries(list, source)
		if type(source) ~= "table" then
			return
		end
		for k, v in pairs(source) do
			local entry
			if type(k) == "string" then
				if type(v) == "table" then
					local t = copy(v)
					t.Key = k
					entry = normalizeEntry(t)
				elseif v then
					entry = normalizeEntry(k)
				elseif v == false then
					entry = normalizeEntry(k)
					entry.Disabled = true
				end
			else
				entry = normalizeEntry(v)
			end
			if entry and entry.Key ~= "" then
				table.insert(list, entry)
			end
		end
	end
	local entryCache = setmetatable({}, {__mode = "k"})
	local function staticEntries(cfg)
		local cached = entryCache[cfg]
		if cached then
			return cached
		end
		local list = {}
		addEntries(list, cfg.Keys)
		if type(cfg.Key) == "string" then
			addEntries(list, {cfg.Key})
		end
		entryCache[cfg] = list
		return list
	end
	local function parseKeyList(body)
		local list = {}
		local okJson, data = pcall(function()
			return HttpService:JSONDecode(body)
		end)
		if okJson and type(data) == "table" then
			if type(data.keys) == "table" then
				data = data.keys
			end
			addEntries(list, data)
			return list
		end
		for line in string.gmatch(body, "[^\r\n]+") do
			line = trimText(line)
			if line ~= "" and not line:find("^#") and not line:find("^%-%-") then
				local key, rest = line:match("^(.-)%s*|%s*(.*)$")
				if key then
					rest = trimText(rest)
					table.insert(list, {
						Key = trimText(key),
						Expire = tonumber(rest:match("^%d+")),
						Disabled = string.lower(rest):match("^false") and true or nil,
					})
				else
					table.insert(list, {Key = line})
				end
			end
		end
		return list
	end
	local function remoteEntries(cfg)
		local cached = Library._keyRemote[cfg.Url]
		if cached and os.clock() - cached.at < (tonumber(cfg.CacheTime) or 60) then
			return cached.list
		end
		local ok, body = httpGet(cfg.Url)
		if not ok then
			return nil, keyText(cfg, "Offline")
		end
		local list = parseKeyList(body)
		Library._keyRemote[cfg.Url] = {at = os.clock(), list = list}
		return list
	end

	local function fixFileName(name)
		name = trimText(name)
		if name == "" then
			name = KeyDefaults.FileName
		end
		if not name:find("%.") then
			name = name .. ".txt"
		end
		return name
	end
	local function flattenKeyOptions(source)
		if type(source) ~= "table" then
			return {}
		end
		if source._flat then
			return source
		end
		local out = {}
		for k, v in pairs(source) do
			out[k] = v
		end
		out.KeySettings = nil
		if type(source.KeySettings) == "table" then
			for k, v in pairs(source.KeySettings) do
				out[k] = v
			end
		end
		if out.SaveKey ~= nil then
			out.Save = out.SaveKey and true or false
			out.SaveKey = nil
		end
		local listKey = out.Key
		if out.GrabKeyFromSite == true then
			local url = type(listKey) == "table" and listKey[1] or listKey
			if type(url) == "string" and trimText(url) ~= "" then
				out.Url = trimText(url)
			end
			out.Key = nil
		elseif type(listKey) == "table" then
			local merged = {}
			if type(out.Keys) == "table" then
				for k, v in pairs(out.Keys) do
					if type(k) == "number" then
						table.insert(merged, v)
					else
						merged[k] = v
					end
				end
			end
			for _, v in ipairs(listKey) do
				table.insert(merged, v)
			end
			out.Keys = merged
			out.Key = nil
		end
		out.GrabKeyFromSite = nil
		out._flat = true
		return out
	end
	local function buildKeyCfg(lib, options)
		local cfg = {}
		for k, v in pairs(KeyDefaults) do
			cfg[k] = v
		end
		for k, v in pairs(flattenKeyOptions(lib.KeyConfig)) do
			cfg[k] = v
		end
		for k, v in pairs(flattenKeyOptions(options)) do
			cfg[k] = v
		end
		cfg.FileName = fixFileName(cfg.FileName)
		cfg._flat = true
		return cfg
	end

	function Library:CheckKey(key, cfg)
		cfg = flattenKeyOptions(cfg)
		key = trimText(key)
		if key == "" then
			return false, keyText(cfg, "Empty")
		end
		local validator = cfg.Validate or cfg.Check
		if type(validator) == "function" then
			local ok, res, msg, extra = pcall(validator, key)
			if not ok then
				return false, "Validator error: " .. tostring(res), nil, true
			end
			if res then
				local info = {}
				if type(extra) == "table" then
					info = copy(extra)
				elseif type(msg) == "table" then
					info = copy(msg)
				end
				info.Key = key
				return true, nil, info
			end
			return false, type(msg) == "string" and msg or keyText(cfg, "Invalid")
		end
		local entries = {}
		for _, e in ipairs(staticEntries(cfg)) do
			table.insert(entries, e)
		end
		local offline
		if type(cfg.Url) == "string" and cfg.Url ~= "" then
			local list, err = remoteEntries(cfg)
			if list then
				for _, e in ipairs(list) do
					table.insert(entries, e)
				end
			else
				offline = err
			end
		end
		local needle = cfg.CaseSensitive == false and string.lower(key) or key
		for _, e in ipairs(entries) do
			local hay = cfg.CaseSensitive == false and string.lower(e.Key) or e.Key
			if hay == needle then
				if e.Disabled then
					return false, keyText(cfg, "Revoked")
				end
				if e.Expire and e.Expire > 0 and os.time() >= e.Expire then
					return false, keyText(cfg, "Expired")
				end
				if e.HWID and e.HWID ~= self:GetHWID() then
					return false, keyText(cfg, "WrongDevice")
				end
				return true, nil, {Key = e.Key, Expire = e.Expire, Tier = e.Tier, Note = e.Note}
			end
		end
		if offline then
			return false, offline, nil, true
		end
		return false, keyText(cfg, "Invalid")
	end

	function Library:GetSavedKey(fileName)
		fileName = fixFileName(fileName or KeyDefaults.FileName)
		if not (readfile and isfile) then
			return nil
		end
		local okExists, exists = pcall(isfile, fileName)
		if not (okExists and exists) then
			return nil
		end
		local okRead, raw = pcall(readfile, fileName)
		if not okRead then
			return nil
		end
		raw = trimText(raw)
		return raw ~= "" and raw or nil
	end
	function Library:ClearSavedKey(fileName)
		fileName = fixFileName(fileName or self._keyFile or KeyDefaults.FileName)
		if delfile and isfile then
			pcall(function()
				if isfile(fileName) then
					delfile(fileName)
				end
			end)
		elseif writefile then
			pcall(writefile, fileName, "")
		end
	end
	function Library:IsKeyValid()
		return self.KeyEnabled == false or self.KeyValid == true
	end
	function Library:GetKey()
		return self.KeyInfo and self.KeyInfo.Key or nil
	end
	function Library:GetKeyInfo()
		return self.KeyInfo and copy(self.KeyInfo) or nil
	end
	function Library:GetMaskedKey()
		local key = self:GetKey()
		if not key then
			return "-"
		end
		if #key <= 6 then
			return string.rep("*", #key)
		end
		return string.sub(key, 1, 3) .. string.rep("*", math.min(#key - 6, 10)) .. string.sub(key, -3)
	end
	function Library:GetKeyTimeLeft()
		local info = self.KeyInfo
		if not info then
			return nil
		end
		if info.Expire and info.Expire > 0 then
			return math.max(0, info.Expire - os.time())
		end
		return math.huge
	end
	function Library:GetKeyStatusText()
		local left = self:GetKeyTimeLeft()
		if left == nil then
			return "No key"
		end
		if left == math.huge then
			return "Lifetime"
		end
		return formatSpan(left) .. " left"
	end
	function Library:ForgetKey()
		self:ClearSavedKey(self._keyFile)
		self.KeyValid = false
		self.KeyInfo = nil
	end

	local function acceptKey(lib, cfg, info)
		lib.KeyValid = true
		lib.KeyInfo = info
		lib._keyFile = cfg.FileName
		if cfg.Save and writefile then
			pcall(writefile, cfg.FileName, info.Key)
		end
	end

	function Library:SetKeyEnabled(state)
		self.KeyEnabled = state and true or false
	end
	function Library:IsKeyEnabled()
		return self.KeyEnabled ~= false
	end
	function Library:IsKey(key, options)
		if self.KeyEnabled == false then
			return true
		end
		local ok = self:CheckKey(key, buildKeyCfg(self, options))
		return ok == true
	end
	function Library:SubmitKey(key, options)
		if self.KeyEnabled == false then
			return true
		end
		local cfg = buildKeyCfg(self, options)
		local ok, msg, info = self:CheckKey(key, cfg)
		if ok then
			acceptKey(self, cfg, info)
			return true
		end
		return false, msg
	end
	function Library:_resolveKey(opts)
		local switch = opts.KeySystem
		if switch == nil and opts.Key ~= nil then
			switch = opts.Key and true or false
		end
		if switch == nil then
			return nil
		end
		local source = {}
		if type(opts.Key) == "table" then
			for k, v in pairs(opts.Key) do
				source[k] = v
			end
		end
		if type(opts.KeySettings) == "table" then
			source.KeySettings = opts.KeySettings
		end
		local kcfg = flattenKeyOptions(source)
		if kcfg.Enabled == false then
			switch = false
		end
		self:SetKeyEnabled(switch)
		if not switch then
			return nil
		end
		if kcfg.Title == nil then
			kcfg.Title = tostring(opts.Name or "RXM HUB")
		end
		kcfg.Wait = true
		return kcfg
	end

	function Library:KeySystem(options)
		local cfg = buildKeyCfg(self, options)
		if self.KeyEnabled == false or cfg.Enabled == false then
			if cfg.Wait == false then
				fireCallback(cfg.OnSuccess, nil, {})
				return {
					Close = function()
					end,
				}
			end
			return true, {}
		end
		if self.KeyValid and not cfg.Force then
			return true, self.KeyInfo
		end
		local prefill, noteText
		if cfg.Save and cfg.AutoLogin then
			local saved = self:GetSavedKey(cfg.FileName)
			if saved then
				local ok, msg, info, neutral = self:CheckKey(saved, cfg)
				if ok then
					acceptKey(self, cfg, info)
					fireCallback(cfg.OnSuccess, info.Key, info)
					return true, info
				end
				if neutral then
					prefill, noteText = saved, msg
				else
					self:ClearSavedKey(cfg.FileName)
					noteText = keyText(cfg, "SavedExpired")
				end
			end
		end

		local viewport = viewportSize()
		local PW = 380
		if isTouch or viewport.X < 700 then
			PW = math.clamp(viewport.X - 32, 280, 380)
		end
		local hasLink = type(cfg.KeyLink) == "string" and cfg.KeyLink ~= ""
		local hasDiscord = type(cfg.Discord) == "string" and cfg.Discord ~= ""
		local panelNote = (type(cfg.Note) == "string" and cfg.Note ~= "") and cfg.Note or nil
		local NOTE_H = panelNote and 34 or 0
		local PAD = 20
		local ICON_Y, TITLE_Y, SUB_Y, NOTE_Y, INPUT_Y = 20, 76, 102, 134, 142 + NOTE_H
		local STATUS_Y, VERIFY_Y, LINKS_Y = 188 + NOTE_H, 212 + NOTE_H, 258 + NOTE_H
		local bottomY = (hasLink or hasDiscord) and (LINKS_Y + 34) or (VERIFY_Y + 38)
		local FOOT_Y = bottomY + 10
		local PH = FOOT_Y + 14 + 12

		local gui = new("ScreenGui", {
			Name = "RXMUI_Key",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 200,
			IgnoreGuiInset = true,
		})
		if not mountGui(gui) then
			error("RXM UI: GUI key tidak bisa dipasang (gethui / CoreGui / PlayerGui gagal)", 0)
		end
		local click = makeClicker(gui, function()
			return cfg.Sounds ~= false
		end)

		local finished, accepted, locked, busy = false, false, false, false
		local resultOk, resultInfo = false, nil
		local event = Instance.new("BindableEvent")
		local attempts = 0
		local tint = nil
		local conn
		local cancelFn
		local submit

		local dim = new("TextButton", {
			Name = "Dim",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = BLACK,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 1,
			Parent = gui,
		})
		local shell = new("Frame", {
			Name = "Shell",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(PW, PH),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = gui,
		})
		local shellScale = new("UIScale", {Scale = 0.85, Parent = shell})
		local glow = new("ImageLabel", {
			Name = "Glow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(PW + 190, PH + 190),
			BackgroundTransparency = 1,
			Image = GLOW,
			ImageColor3 = Theme.Accent,
			ImageTransparency = 1,
			ZIndex = 1,
			Parent = shell,
		})
		bindTheme(glow, function(T, f)
			f.ImageColor3 = tint or T.Accent
		end)
		local body = new("CanvasGroup", {
			Name = "Body",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Background,
			BorderSizePixel = 0,
			GroupTransparency = 1,
			ZIndex = 2,
			Active = true,
			Parent = shell,
		})
		corner(body, 22)
		bindTheme(body, function(T, f)
			f.BackgroundColor3 = T.Background
			f.BackgroundTransparency = math.clamp(Library.Transparency, 0, 0.5)
		end)
		local borderFrame = new("Frame", {
			Name = "Border",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 6,
			Parent = shell,
		})
		corner(borderFrame, 22)
		local borderStroke = stroke(borderFrame, WHITE, 1.6, 1)
		local borderGrad = new("UIGradient", {
			Transparency = NumberSequence.new({kp(0, 0), kp(0.3, 0.78), kp(0.7, 0.78), kp(1, 0)}),
			Parent = borderStroke,
		})
		bindTheme(borderFrame, function(T)
			local a = tint or T.Accent
			local b = tint and darken(tint, 0.4) or T.Accent2
			borderGrad.Color = ColorSequence.new({ck(0, a), ck(0.5, b), ck(1, a)})
		end)

		local badge = new("Frame", {
			Name = "Badge",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, ICON_Y),
			Size = UDim2.fromOffset(48, 48),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = body,
		})
		round(badge)
		local badgeStroke = stroke(badge, Theme.Accent, 1.2, 0.55)
		bindTheme(badge, function(T)
			if not tint then
				badge.BackgroundColor3 = T.Accent
				badgeStroke.Color = T.Accent
			end
		end)
		local badgeIcon = createIcon(cfg.Icon, badge, 24, "Accent", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 4,
		})

		local title = new("TextLabel", {
			Position = UDim2.new(0, PAD, 0, TITLE_Y),
			Size = UDim2.new(1, -PAD * 2, 0, 24),
			BackgroundTransparency = 1,
			Text = tostring(cfg.Title or keyText(cfg, "Title")),
			Font = Enum.Font.GothamBold,
			TextSize = 18,
			TextColor3 = Theme.Text,
			ZIndex = 3,
			Parent = body,
		})
		bindTheme(title, function(T)
			title.TextColor3 = T.Text
		end)
		local subtitle = new("TextLabel", {
			Position = UDim2.new(0, PAD, 0, SUB_Y),
			Size = UDim2.new(1, -PAD * 2, 0, 30),
			BackgroundTransparency = 1,
			Text = tostring(cfg.Subtitle or keyText(cfg, "Subtitle")),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Theme.Muted,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 3,
			Parent = body,
		})
		bindTheme(subtitle, function(T)
			subtitle.TextColor3 = T.Muted
		end)
		if panelNote then
			local noteLabel = new("TextLabel", {
				Position = UDim2.new(0, PAD, 0, NOTE_Y),
				Size = UDim2.new(1, -PAD * 2, 0, 30),
				BackgroundTransparency = 1,
				Text = panelNote,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = Theme.Muted,
				TextTransparency = 0.25,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 3,
				Parent = body,
			})
			bindTheme(noteLabel, function(T)
				noteLabel.TextColor3 = T.Muted
			end)
		end

		local inputBox = new("Frame", {
			Name = "Input",
			Position = UDim2.new(0, PAD, 0, INPUT_Y),
			Size = UDim2.new(1, -PAD * 2, 0, 40),
			BackgroundColor3 = Theme.Input,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = body,
		})
		corner(inputBox, 12)
		local inputStroke = stroke(inputBox, Theme.Stroke, 1)
		bindTheme(inputBox, function(T)
			inputBox.BackgroundColor3 = T.Input
		end)
		createIcon("lock", inputBox, 16, "Muted", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			ZIndex = 4,
		})
		local box = new("TextBox", {
			Position = UDim2.new(0, 38, 0, 0),
			Size = UDim2.new(1, -48, 1, 0),
			BackgroundTransparency = 1,
			Text = prefill or "",
			PlaceholderText = tostring(cfg.Placeholder or keyText(cfg, "Placeholder")),
			PlaceholderColor3 = Theme.Muted,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 5,
			Parent = inputBox,
		})
		bindTheme(box, function(T)
			box.TextColor3 = T.Text
			box.PlaceholderColor3 = T.Muted
		end)
		local underline = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(0, 0, 0, 2),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = inputBox,
		})
		round(underline)
		bindTheme(underline, function(T)
			underline.BackgroundColor3 = T.Accent
		end)

		local status = new("TextLabel", {
			Position = UDim2.new(0, PAD, 0, STATUS_Y),
			Size = UDim2.new(1, -PAD * 2, 0, 16),
			BackgroundTransparency = 1,
			Text = noteText or "",
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = noteText and kindColor("warn") or Theme.Muted,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 3,
			Parent = body,
		})
		local function setStatus(text, kind, quiet)
			status.Text = text
			if kind == nil or kind == "info" then
				status.TextColor3 = Theme.Muted
			else
				status.TextColor3 = kindColor(kind)
			end
			if not quiet then
				status.TextTransparency = 1
				tween(status, 0.25, {TextTransparency = 0}, ES.Quad)
			end
		end

		local function decorate(btn, rest, hover)
			local sc = new("UIScale", {Scale = 1, Parent = btn})
			btn.MouseEnter:Connect(function()
				if accepted then
					return
				end
				tween(btn, 0.15, {BackgroundColor3 = hover()}, ES.Quad)
			end)
			btn.MouseLeave:Connect(function()
				tween(sc, 0.15, {Scale = 1}, ES.Quad)
				if accepted then
					return
				end
				tween(btn, 0.2, {BackgroundColor3 = rest()}, ES.Quad)
			end)
			btn.MouseButton1Down:Connect(function()
				tween(sc, 0.08, {Scale = 0.97}, ES.Quad)
			end)
			btn.MouseButton1Up:Connect(function()
				tween(sc, 0.25, {Scale = 1}, ES.Back, ED.Out)
			end)
		end
		local function accentRest()
			return Theme.Accent
		end
		local function accentHover()
			return lighten(Theme.Accent, 0.18)
		end
		local function plainRest()
			return Theme.Button
		end
		local function plainHover()
			return Theme.CardHover
		end
		local verifyBtn = new("TextButton", {
			Name = "Verify",
			Position = UDim2.new(0, PAD, 0, VERIFY_Y),
			Size = UDim2.new(1, -PAD * 2, 0, 38),
			BackgroundColor3 = Theme.Accent,
			AutoButtonColor = false,
			Text = keyText(cfg, "Verify"),
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = onColor(Theme.Accent),
			ZIndex = 4,
			Parent = body,
		})
		corner(verifyBtn, 12)
		decorate(verifyBtn, accentRest, accentHover)
		bindTheme(verifyBtn, function(T)
			if not accepted then
				verifyBtn.BackgroundColor3 = T.Accent
				verifyBtn.TextColor3 = onColor(T.Accent)
			end
		end)

		local function plainButton(parent, text, pos, size)
			local btn = new("TextButton", {
				Position = pos,
				Size = size,
				BackgroundColor3 = Theme.Button,
				AutoButtonColor = false,
				Text = text,
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextColor3 = Theme.Text,
				ZIndex = 4,
				Parent = parent,
			})
			corner(btn, 12)
			stroke(btn, Theme.Stroke, 1)
			decorate(btn, plainRest, plainHover)
			bindTheme(btn, function(T)
				btn.BackgroundColor3 = T.Button
				btn.TextColor3 = T.Text
			end)
			return btn
		end
		local function linkAction(btn, link, label)
			click(1, 0.8)
			if copyText(link) then
				btn.Text = keyText(cfg, "Copied")
				setStatus(keyText(cfg, "LinkCopied"), "success")
				task.delay(1.6, function()
					if btn.Parent then
						btn.Text = label
					end
				end)
			else
				box.Text = link
				setStatus(keyText(cfg, "NoClipboard"), "warn")
			end
		end
		if hasLink or hasDiscord then
			local row = new("Frame", {
				Position = UDim2.new(0, PAD, 0, LINKS_Y),
				Size = UDim2.new(1, -PAD * 2, 0, 34),
				BackgroundTransparency = 1,
				ZIndex = 3,
				Parent = body,
			})
			local both = hasLink and hasDiscord
			if hasLink then
				local label = keyText(cfg, "GetKey")
				local btn = plainButton(row, label, UDim2.new(0, 0, 0, 0), both and UDim2.new(0.5, -4, 1, 0) or UDim2.fromScale(1, 1))
				btn.MouseButton1Click:Connect(function()
					linkAction(btn, cfg.KeyLink, label)
				end)
			end
			if hasDiscord then
				local label = keyText(cfg, "Discord")
				local btn = plainButton(row, label, both and UDim2.new(0.5, 4, 0, 0) or UDim2.new(0, 0, 0, 0), both and UDim2.new(0.5, -4, 1, 0) or UDim2.fromScale(1, 1))
				btn.MouseButton1Click:Connect(function()
					linkAction(btn, cfg.Discord, label)
				end)
			end
		end
		local footer = new("TextLabel", {
			Position = UDim2.new(0, PAD, 0, FOOT_Y),
			Size = UDim2.new(1, -PAD * 2, 0, 14),
			BackgroundTransparency = 1,
			Text = tostring(cfg.Footer or ("RXM UI v" .. Library.Version)),
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = Theme.Muted,
			TextTransparency = 0.4,
			ZIndex = 3,
			Parent = body,
		})
		bindTheme(footer, function(T)
			footer.TextColor3 = T.Muted
		end)

		local function closeUI(instant)
			if conn then
				conn:Disconnect()
				conn = nil
			end
			Library._keyCancel[cancelFn] = nil
			local function destroy()
				pcall(function()
					gui:Destroy()
				end)
			end
			if instant then
				destroy()
				return
			end
			tween(shellScale, 0.3, {Scale = 0.9}, ES.Quad, ED.In)
			tween(body, 0.25, {GroupTransparency = 1}, ES.Quad, ED.In)
			tween(dim, 0.3, {BackgroundTransparency = 1}, ES.Quad)
			tween(borderStroke, 0.25, {Transparency = 1}, ES.Quad)
			tween(glow, 0.25, {ImageTransparency = 1}, ES.Quad)
			task.delay(0.4, destroy)
		end
		local function finish(ok, info, instant)
			if finished then
				return
			end
			finished = true
			resultOk, resultInfo = ok, info
			closeUI(instant)
			if ok then
				fireCallback(cfg.OnSuccess, info.Key, info)
			else
				fireCallback(cfg.OnClose)
			end
			event:Fire()
		end
		cancelFn = function()
			finish(false, nil, true)
		end
		Library._keyCancel[cancelFn] = true

		local function setTint(color)
			tint = color
			badge.BackgroundColor3 = color
			badgeStroke.Color = color
			badgeIcon:TweenColor(color, 0.3)
			borderGrad.Color = ColorSequence.new({ck(0, color), ck(0.5, darken(color, 0.4)), ck(1, color)})
			glow.ImageColor3 = color
		end
		local function shake()
			task.spawn(function()
				for _, dx in ipairs({9, -9, 6, -6, 3, 0}) do
					if finished then
						return
					end
					tween(shell, 0.05, {Position = UDim2.new(0.5, dx, 0.5, 0)}, ES.Quad)
					task.wait(0.05)
				end
			end)
			tween(inputStroke, 0.1, {Color = kindColor("error")}, ES.Quad)
			task.delay(0.9, function()
				if not finished and inputStroke.Parent then
					tween(inputStroke, 0.35, {Color = Theme.Stroke}, ES.Quad)
				end
			end)
		end
		local function startLock()
			if cfg.KickOnLock then
				pcall(function()
					LocalPlayer:Kick(keyText(cfg, "Kick"))
				end)
			end
			local seconds = math.floor(tonumber(cfg.Lockout) or 0)
			if seconds <= 0 then
				attempts = 0
				setStatus(keyText(cfg, "Invalid"), "error")
				return
			end
			locked = true
			box.TextEditable = false
			verifyBtn.Text = keyText(cfg, "LockedBtn")
			tween(verifyBtn, 0.2, {BackgroundTransparency = 0.6}, ES.Quad)
			task.spawn(function()
				for s = seconds, 1, -1 do
					if finished then
						return
					end
					setStatus(string.format(keyText(cfg, "Locked"), s), "error", true)
					task.wait(1)
				end
				if finished then
					return
				end
				locked = false
				attempts = 0
				box.TextEditable = true
				verifyBtn.Text = keyText(cfg, "Verify")
				tween(verifyBtn, 0.2, {BackgroundTransparency = 0}, ES.Quad)
				setStatus("", "info")
			end)
		end
		submit = function()
			if finished or accepted or busy or locked then
				return
			end
			local key = trimText(box.Text)
			click(1.05, 0.8)
			if key == "" then
				setStatus(keyText(cfg, "Empty"), "warn")
				shake()
				return
			end
			busy = true
			local checking = true
			task.spawn(function()
				local dots = 0
				while checking and not finished do
					dots = dots % 3 + 1
					verifyBtn.Text = keyText(cfg, "Checking") .. string.rep(".", dots)
					task.wait(0.3)
				end
			end)
			task.spawn(function()
				local ok, msg, info, neutral = Library:CheckKey(key, cfg)
				checking = false
				busy = false
				if finished then
					return
				end
				if ok then
					accepted = true
					acceptKey(Library, cfg, info)
					local good = kindColor("success")
					setTint(good)
					badgeIcon:SetIcon("unlock")
					verifyBtn.Text = keyText(cfg, "Accepted")
					tween(verifyBtn, 0.25, {BackgroundColor3 = good, TextColor3 = onColor(good)}, ES.Quad)
					setStatus(keyText(cfg, "Valid"), "success")
					click(0.9, 1)
					task.delay(0.8, function()
						finish(true, info)
					end)
					return
				end
				verifyBtn.Text = keyText(cfg, "Verify")
				if neutral then
					setStatus(msg, "warn")
					return
				end
				attempts = attempts + 1
				shake()
				local limit = tonumber(cfg.MaxAttempts) or 0
				if limit > 0 and attempts >= limit then
					setStatus(msg, "error")
					startLock()
				elseif limit > 0 then
					setStatus(msg .. "  -  " .. string.format(keyText(cfg, "Attempts"), limit - attempts), "error")
				else
					setStatus(msg, "error")
				end
			end)
		end
		verifyBtn.MouseButton1Click:Connect(submit)
		box.Focused:Connect(function()
			click(1.05, 0.6)
			tween(inputStroke, 0.25, {Color = Theme.Accent}, ES.Quad)
			tween(underline, 0.4, {Size = UDim2.new(1, -24, 0, 2)}, ES.Quint, ED.Out)
		end)
		box.FocusLost:Connect(function(enter)
			tween(inputStroke, 0.35, {Color = Theme.Stroke}, ES.Quad)
			tween(underline, 0.3, {Size = UDim2.new(0, 0, 0, 2)}, ES.Quad, ED.In)
			if enter then
				submit()
			end
		end)
		if cfg.Closable then
			local closeBtn = new("TextButton", {
				Name = "Close",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 10),
				Size = UDim2.fromOffset(28, 28),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 7,
				Parent = body,
			})
			local xIcon = createIcon("x", closeBtn, 14, "Muted", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			})
			closeBtn.MouseEnter:Connect(function()
				xIcon:TweenColor(kindColor("error"), 0.15)
			end)
			closeBtn.MouseLeave:Connect(function()
				xIcon:SetColor("Muted")
			end)
			closeBtn.MouseButton1Click:Connect(function()
				if accepted then
					return
				end
				click(0.95, 0.8)
				finish(false, nil)
			end)
		end

		local clock = 0
		conn = RunService.Heartbeat:Connect(function(dt)
			clock = clock + dt
			borderGrad.Rotation = (borderGrad.Rotation + 70 * dt) % 360
			if not accepted then
				badgeStroke.Transparency = 0.55 + 0.2 * math.sin(clock * 2.4)
			end
		end)
		tween(dim, 0.35, {BackgroundTransparency = 0.45}, ES.Quad)
		tween(body, 0.4, {GroupTransparency = 0}, ES.Quad)
		tween(shellScale, 0.55, {Scale = 1}, ES.Back, ED.Out)
		tween(borderStroke, 0.4, {Transparency = 0.2}, ES.Quad)
		tween(glow, 0.6, {ImageTransparency = 0.8}, ES.Quad)

		if cfg.Wait == false then
			return {
				Gui = gui,
				Close = function()
					finish(false, nil)
				end,
			}
		end
		if not finished then
			event.Event:Wait()
		end
		return resultOk, resultInfo
	end
	Library.CreateKeySystem = Library.KeySystem
end
function Library:Unload()
	for cancel in pairs(self._keyCancel or {}) do
		pcall(cancel)
	end
	self._keyCancel = {}
	for i = #self.Windows, 1, -1 do
		local W = self.Windows[i]
		pcall(function()
			W.Alive = false
			for _, c in ipairs(W.Connections) do
				pcall(function()
					c:Disconnect()
				end)
			end
			if W.Gui then
				W.Gui:Destroy()
			end
		end)
		self.Windows[i] = nil
	end
	for gui in pairs(self._intros) do
		pcall(function()
			gui:Destroy()
		end)
	end
	self._intros = {}
	for i = #binds, 1, -1 do
		binds[i] = nil
	end
	if genv.RXM_UI_LIBRARY == self then
		genv.RXM_UI_LIBRARY = nil
	end
end
Library.Window = Window
Library.Tab = Tab
return Library
