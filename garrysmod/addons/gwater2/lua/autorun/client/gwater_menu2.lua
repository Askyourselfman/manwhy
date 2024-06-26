AddCSLuaFile()

if SERVER or !gwater2 then return end

-- *Ehem*
-- BEHOLD. THE GWATER MENU CODE
-- THIS MY FRIEND.. IS THE SINGLE WORST PIECE OF CODE I HAVE EVER WRITTEN
-- PLEASE NOTE THAT: 
	-- SOURCE VGUI IS ABSOLUTELY DOODOO
	-- THE GMOD INTERFACE IS ABSOLULTELY DOODOO
	-- HALF OF THIS CODE WAS WRITTEN AT 3 AM
-- THANK YOU FOR COMING TO MY TED TALK

local version = "0.3.1b"
local options = {
	solver = FlexSolver(1000),
	tab = CreateClientConVar("gwater2_tab"..version, "1", true),
	blur_passes = CreateClientConVar("gwater2_blur_passes", "3", true),
	absorption = CreateClientConVar("gwater2_absorption", "1", true),
	depth_fix = CreateClientConVar("gwater2_depth_fix", "0", true),
	menu_key = CreateClientConVar("gwater2_menukey", KEY_G, true),
	color = Color(209, 237, 255, 25),
	parameter_tab_header = "Parameter Tab",
	parameter_tab_text = "This tab is where you can change how the water interacts with itself and the environment.\n\nHover over a parameter to reveal its functionality.",
	adv_parameter_tab_header = "Adv. Parameter Tab",
	adv_parameter_tab_text = "This tab is similar to the parameter tab but includes settings which aren't as obvious.\n\nHover over a parameter to reveal its functionality.",
	visuals_tab_header = "Visuals Tab",
	visuals_tab_text = "This tab controls what the fluid looks like.\n\nHover over a parameter to reveal its functionality",
	about_tab_header = "About Tab",
	about_tab_text = "On each tab, this area will contain useful information.\n\nFor example:\nClicking anywhere outside the menu, or re-pressing the menu button will close it.\n\nMake sure to read this area!",
	performance_tab_header = "Performance Tab",
	performance_tab_text = "This tab has options which can help and alter your performance.\n\nEach option is colored between green and red to indicate its performance hit.\n\nAll parameters directly impact the GPU.",
	patron_tab_header = "Patron Tab",
	patron_tab_text = "This tab has a list of all my patrons.\n\nThe list is sorted in alphabetical order.\n\nIt will be updated routinely until release.",

	-- Physics Parameters
	Cohesion = {text = "Controls how well particles hold together.\n\nHigher values make the fluid more solid/rigid, while lower values make it more fluid and loose."},
	Adhesion = {text = "Controls how well particles stick to surfaces.\n\nNote that this specific parameter doesn't reflect changes in the preview very well and may need to be viewed externally."},
	Gravity = {text = "Controls how strongly fluid is pulled down. This value is measured in meters per second.\n\nNote that The default source gravity is -15.24 which is NOT the same as Earths gravity of -9.81."},
	Viscosity = {text = "Controls how much particles resist movement.\n\nHigher values look more like honey or syrup, while lower values look like water or oil."},
	Radius = {text = "Controls the size of each particle.\n\nIn the preview it is clamped to 15 to avoid weirdness.\n\nRadius is measured in source units and is the same for all particles."},
	["Surface Tension"] = {text = "Controls how strongly particles minimize surface area.\n\nThis parameter tends to make particles behave oddly if set too high\n\nUsually bundled with cohesion."},
	["Fluid Rest Distance"] = {text = "Controls the collision distance between particles.\n\nHigher values cause more lumpy liquids while lower values cause smoother liquids"},
	["Timescale"] = {text = "Sets the speed of the simulation.\n\nNote that some parameters like cohesion and surface tension may behave differently due to smaller or larger compute times"},
	["Collision Distance"] = {text = "Controls the collision distance between particles and objects.\n\nNote that a lower collision distance will cause particles to clip through objects more often."},
	["Vorticity Confinement"] = {text = "Increases the vorticity effect by applying rotational forces to particles.\n\nThis exists because air pressure cannot be efficiently simulated."},
	["Dynamic Friction"] = {text = "Controls the amount of friction particles receive on surfaces.\n\nCauses Adhesion to behave weirdly when set to 0."},
	
	-- Visual Parameters
	Color = {text = "Controls the color of the fluid.\n\nThe alpha (transparency) channel controls the amount of color absorbsion.\n\nAn alpha value of 255 (maxxed) makes the fluid opaque."},
	["Anisotropy Min"] = {text = "Controls the minimum size that particles can be."}, 
	["Anisotropy Max"] = {text = "Controls the maximum size that particles are allowed to stretch between particles."},
	["Anisotropy Scale"] = {text = "Controls the size of stretching between particles.\n\nMaking this value zero will turn off stretching."},
	["Diffuse Threshold"] = {text = "Controls the amount of force required to make a bubble/foam particle."},
	["Diffuse Lifetime"] = {text = "Controls how long bubbles/foam particles last after being created.\n\nThis is affected by the Timescale parameter.\n\nSetting this to zero will spawn no diffuse particles"},

	Iterations = {text = "Controls how many times the physics solver attempts to converge to a solution per substep.\n\nMedium performance impact."},
	Substeps = {text = "Controls the number of physics steps done per tick.\n\nNote that parameters may not be properly tuned for different substeps!\n\nMedium-High performance impact."},
	["Blur Passes"] = {text = "Controls the number of blur passes done per frame. More passes creates a smoother water surface. Zero passes will do no blurring.\n\nLow performance impact."},
	["Absorption"] = {text = "Enables absorption of light over distance inside of fluid.\n\n(more depth = darker color)\n\nMedium performance impact."},
	["Depth Fix"] = {text = "Makes particles appear spherical instead of flat, creating a cleaner and smoother water surface.\n\nCauses shader overdraw.\n\nMedium-High performance impact."},
	["Particle Limit"] = {text = "USE THIS PARAMETER AT YOUR OWN RISK.\n\nChanges the limit of particles.\n\nNote that a higher limit will negatively impact performance even with the same number of particles spawned."},
	["Old Solver"] = {text = "If checked, uses the solver used in 0.1b and 0.2b.\n\nThe old solver usually grants better performance, but causes more particle leakage.\n\nI suggest using the old solver when recording."},
}

-- setup percentage values
gwater2["surface_tension"] = gwater2.solver:GetParameter("surface_tension") * gwater2.solver:GetParameter("radius")^4	-- dont ask me why its a power of 4
gwater2["fluid_rest_distance"] = gwater2.solver:GetParameter("fluid_rest_distance") / gwater2.solver:GetParameter("radius")
gwater2["collision_distance"] = gwater2.solver:GetParameter("collision_distance") / gwater2.solver:GetParameter("radius")

-- garry, sincerely... fuck you
timer.Simple(0, function() 
	Material("gwater2/volumetric"):SetFloat("$alpha", options.absorption:GetBool() and 0.125 or 0)
	Material("gwater2/normals"):SetInt("$depthfix", options.depth_fix:GetBool() and 1 or 0)
end)

options.solver:SetParameter("gravity", 15.24)	-- flip gravity because y axis positive is down
options.solver:SetParameter("static_friction", 0)	-- stop adhesion sticking to front and back walls
options.solver:SetParameter("dynamic_friction", 0)	-- ^
options.solver:SetParameter("diffuse_lifetime", math.huge)	-- no diffuse particles allowed in preview

-- designs for tabs and frames
local function draw_tabs(self, w, h)
	if h ~= 20 then
		surface.SetDrawColor(0, 80, 255, 230)
		surface.DrawRect(2,0,w - 4,h - 8)
	else
		draw.RoundedBox(0, 2, 0, w - 4, 20, Color( 27, 27, 27, 230))
	end
	surface.SetDrawColor(255, 255, 255)
	surface.DrawOutlinedRect(2, 0, w - 4, 21, 1)
end

local function draw_label(self, w, h) 
	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawRect(0, 0, w - 201, h)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawOutlinedRect(0, 0, w - 201, h)
end

surface.CreateFont("GWater2Param", {
    font = "Space Mono", 
    extended = false,
    size = 20,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

surface.CreateFont("GWater2Title", {
    font = "coolvetica", 
    extended = false,
    size = 24,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = false,
})

-- Smooth scrollbar (code from Spanky)
local GFScrollPanel = {}
AccessorFunc(GFScrollPanel, "scrolldistance", "ScrollDistance", FORCE_NUMBER)
function GFScrollPanel:Init()
    self:SetScrollDistance(32)
    local scrollPanel = self

    local vbar = self:GetVBar()
    function vbar:OnMouseWheeled( dlta )
        if not self:IsVisible() then return false end
        -- We return true if the scrollbar changed.
        -- If it didn't, we feed the mousehweeling to the parent panel
        if self.CurrentScroll == nil then self.CurrentScroll = self:GetScroll() end
        self.CurrentScroll = math.Clamp(self.CurrentScroll + (dlta * -scrollPanel:GetScrollDistance()), 0, self.CanvasSize)
        self:AnimateTo(self.CurrentScroll, 0.1, 0, 0.5)
        return self:AddScroll( dlta * -2 )
    end
    function vbar:OnMouseReleased()
        self.CurrentScroll = self:GetScroll()

        self.Dragging = false
        self.DraggingCanvas = nil
        self:MouseCapture( false )
    
        self.btnGrip.Depressed = false
    end
end
vgui.Register("GF_ScrollPanel", GFScrollPanel, "DScrollPanel")

local function set_gwater_parameter(option, val)
	if gwater2[option] then
		gwater2[option] = val
		if option == "surface_tension" then	-- hack hack hack! this parameter scales based on radius
			local thing = val / gwater2.solver:GetParameter("radius")^4	-- cant think of a name for this variable rn
			gwater2.solver:SetParameter(option, thing)
			options.solver:SetParameter(option, thing)
		elseif option == "fluid_rest_distance" or option == "collision_distance" then -- hack hack hack! this parameter scales based on radius
			local thing = val * gwater2.solver:GetParameter("radius")
			gwater2.solver:SetParameter(option, thing)
			options.solver:SetParameter(option, thing)
		end
		return
	end

	gwater2.solver:SetParameter(option, val)

	if option == "gravity" then val = -val end	-- hack hack hack! y coordinate is considered down in screenspace!
	if option == "radius" then 					-- hack hack hack! radius needs to edit multiple parameters!
		gwater2.solver:SetParameter("surface_tension", gwater2["surface_tension"] / val^4)	-- literally no idea why this is a power of 4
		gwater2.solver:SetParameter("fluid_rest_distance", val * gwater2["fluid_rest_distance"])
		gwater2.solver:SetParameter("collision_distance", val * gwater2["collision_distance"])
		
		if val > 15 then val = 15 end	-- explody
		options.solver:SetParameter("surface_tension", gwater2["surface_tension"] / val^4)
		options.solver:SetParameter("fluid_rest_distance", val * gwater2["fluid_rest_distance"])
		options.solver:SetParameter("collision_distance", val * gwater2["collision_distance"])
	end

	if option != "diffuse_threshold" and option != "dynamic_friction" then -- hack hack hack! fluid preview doesn't use diffuse particles
		options.solver:SetParameter(option, val)
	end
end

-- some helper functions
local function create_slider(self, text, min, max, decimals, dock, length, out)
	length = length or 450
	out = out or -90

	local option = string.lower(text)
	option = string.gsub(option, " ", "_")
	local param = gwater2[option] or gwater2.solver:GetParameter(option)

	if options[text] then
		options[text].default = options[text].default or param
	else
		print("Undefined parameter '" .. text .. "'!") 
	end
	
	local label = vgui.Create("DLabel", self)
	label:SetPos(10, dock)
	label:SetSize(200, 20)
	label:SetText(text)
	label:SetColor(Color(255, 255, 255))
	label:SetFont("GWater2Param")

	local slider = vgui.Create("DNumSlider", self)
	slider:SetPos(out, dock)
	slider:SetSize(length, 20)
	slider:SetMinMax(min, max)
	slider:SetValue(param)
	slider:SetDecimals(decimals)
	
	-- rounds slider to nearest decimal
	function slider:OnValueChanged(val)
		if decimals == 0 and val != math.Round(val, decimals) then
			self:SetValue(math.Round(val, decimals))
			return
		end
		set_gwater_parameter(option, val)
	end

	local button = vgui.Create("DButton", self)
	button:SetPos(355, dock)
	button:SetSize(20, 20)
	button:SetText("")
	button:SetImage("icon16/arrow_refresh.png")
	button.Paint = nil

	function button:DoClick()
		slider:SetValue(options[text].default)
		surface.PlaySound("buttons/button15.wav")
	end

	return label, slider
end

local function create_label(self, text, subtext, dock, size)
	local label = vgui.Create("DLabel", self)
	label:SetPos(dock, dock)
	label:SetSize(383, size or 320)
	label:SetText("")

	function label:Paint(w, h)
		draw.DrawText(text, "GWater2Title", 1, 1, Color(0, 0, 0), TEXT_ALIGN_LEFT)
		draw.DrawText(text, "GWater2Title", 0, 0, Color(187, 245, 255), TEXT_ALIGN_LEFT)
		draw.DrawText(subtext, "DermaDefault", 0, 24, Color(187, 245, 255), TEXT_ALIGN_LEFT)
	end
	return label
end

-- color picker
local function copy_color(c) return Color(c.r, c.g, c.b, c.a) end
local function create_picker(self, text, dock, size)
	local label = vgui.Create("DLabel", self)
	label:SetPos(10, dock)
	label:SetSize(100, 100)
	label:SetFont("GWater2Param")
	label:SetText(text)
	label:SetColor(Color(255, 255, 255))
	label:SetContentAlignment(7)

	if options[text] then 
		options[text].default = options[text].default or copy_color(options.color)	-- copy, dont reference
	else
		print("Undefined parameter '" .. text .. "'!") 
	end

	local finalpass = Material("gwater2/finalpass")
	local mixer = vgui.Create("DColorMixer", self)
	mixer:SetPos(65, dock + 5)
	mixer:SetSize(276, 110)
	mixer:SetPalette(false)
	mixer:SetLabel()
	mixer:SetAlphaBar(true)
	mixer:SetWangs(true)

	for k, wang in pairs(mixer:GetChildren()[3]:GetChildren()) do
		for k, arrow in pairs(wang:GetChildren()) do
			function arrow:Paint(w, h)
				surface.SetDrawColor(255, 255, 255)
				
				if k == 1 then
					surface.DrawLine(w * 0.5, 4, w * 0.5 - 4, 8)
					surface.DrawLine(w * 0.5, 4, w * 0.5 + 4, 8)
				else
					surface.DrawLine(w * 0.5, h - 3, w * 0.5 - 4, h - 7)
					surface.DrawLine(w * 0.5, h - 3, w * 0.5 + 4, h - 7)
				end
			end
		end

		-- this probably could be mathematically created but im too lazy to think of a way to do this properly
		local colors = {
			Color(255, 0, 0),
			Color(0, 255, 0),
			Color(0, 0, 255),
			Color(255, 255, 255)
		}

		function wang:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(colors[k])
			surface.DrawOutlinedRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255, 50)
			surface.DrawLine(w * 0.5 + 10, 4, w * 0.5 + 10, h - 4)
			local cutoff_start_x, cutoff_start_y = wang:LocalToScreen(0,0)
			local cutoff_end_x, cutoff_end_y = wang:LocalToScreen(w * 0.5 + 10,h)
			render.SetScissorRect(cutoff_start_x, cutoff_start_y, cutoff_end_x, cutoff_end_y, true)
				draw.DrawText(self:GetValue(), "DermaDefault", 5, 3, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
			render.SetScissorRect(cutoff_start_x, cutoff_start_y, cutoff_end_x, cutoff_end_y, false)
		end
	end

	mixer:SetColor(options.color) 
	function mixer:ValueChanged(col)
		options.color = copy_color(col)	-- color returned by ValueChanged doesnt have any metatables
		finalpass:SetVector4D("$color2", col.r, col.g, col.b, col.a)
	end

	local button = vgui.Create("DButton", self)
	button:SetPos(355, dock)
	button:SetText("")
	button:SetSize(20, 20)
	button:SetImage("icon16/arrow_refresh.png")
	button.Paint = nil
	function button:DoClick()
		local copy = copy_color(options[text].default)
		mixer:SetColor(copy)
		surface.PlaySound("buttons/button15.wav")
	end

	return label, mixer
end

local function create_explanation(parent)
	local explanation = vgui.Create("DLabel", parent)
	explanation:SetTextInset(5, 30)
	explanation:SetWrap(true)
	explanation:SetColor(Color(255, 255, 255))
	explanation:SetContentAlignment(7)	-- shove text in top left corner
	explanation:SetFont("GWater2Param")
	explanation:SetSize(175, 329)
	explanation:SetPos(390, 0)

	return explanation
end

--------------- Actual menu code ------------------------------

local mainFrame = nil
local just_closed = false
concommand.Add("gwater2_menu", function()
	if IsValid(mainFrame) then return end

	local average_fps = 1 / 60
	local particle_material = CreateMaterial("gwater2_menu_material", "UnlitGeneric", {
		["$basetexture"] = "vgui/circle",
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
		["$ignorez"] = 1
	})

    -- start creating visual design
    mainFrame = vgui.Create("DFrame")
    mainFrame:SetSize(800, 400)
	mainFrame:SetSizable(false)
    mainFrame:Center()
	mainFrame:SetTitle("gwater2 (v" .. version .. ")")
    mainFrame:MakePopup()
	mainFrame:SetScreenLock(true)

	local minimize_btn = mainFrame:GetChildren()[3]
	--minimize_btn:SetMouseInputEnabled(false)
	minimize_btn:SetVisible(false)
	
	local maximize_btn = mainFrame:GetChildren()[2]
	--maximize_btn:SetMouseInputEnabled(false)
	maximize_btn:SetVisible(false)

	local close_btn = mainFrame:GetChildren()[1]
	close_btn:SetVisible(false)

	local new_close_btn = vgui.Create("DButton", mainFrame)
	new_close_btn:SetPos(777, 3)
	new_close_btn:SetSize(20, 20)
	new_close_btn:SetText("")

	function new_close_btn:DoClick()
		mainFrame:Remove()
		--surface.PlaySound("buttons/lightswitch2.wav")
		just_closed = false
	end

	function new_close_btn:Paint(w, h)
		if self:IsHovered() then
			surface.SetDrawColor(255, 0, 0, 127)
			surface.DrawRect(0, 0, w, h)
		end
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.DrawLine(5, 5, w - 5, h - 5)
		surface.DrawLine(w - (5 + 1), 5, 5 - 1, h - 5)
	end

	function mainFrame:Paint(w, h)
		-- dark background around 2d water sim
		surface.SetDrawColor(0, 0, 0, 230)
		surface.DrawRect(0, 0, w, 25)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 25, w, h - 25)

		-- 2d simulation
		local x, y = mainFrame:LocalToScreen()
		options.solver:InitBounds(Vector(x, 0, y + 25), Vector(x + 192, options.solver:GetParameter("radius"), y + 390))
		options.solver:AddCube(Vector(x + 60 + math.random(), 0, y + 50), Vector(0, 0, 50), Vector(4, 1, 1), options.solver:GetParameter("radius") * 0.65, color_white)
		options.solver:Tick(average_fps * 10)
		
		local radius = options.solver:GetParameter("radius")
		local function exp(v) return Vector(math.exp(v[1]), math.exp(v[2]), math.exp(v[3])) end
		local is_translucent = options.color.a < 255
		surface.SetMaterial(particle_material)
		options.solver:RenderParticles(function(pos)
			local depth = math.max((pos[3] - y) / 390, 0) * 20	-- ranges from 0 to 20 down
			local absorption = is_translucent and exp((options.color:ToVector() - Vector(1, 1, 1)) * options.color.a / 255 * depth) or options.color:ToVector()
			surface.SetDrawColor(absorption[1] * 255, absorption[2] * 255, absorption[3] * 255, 255)
			surface.DrawTexturedRect(pos[1] - x, pos[3] - y, radius, radius)
		end)
		
		average_fps = average_fps + (FrameTime() - average_fps) * 0.01

		-- main outline
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.DrawOutlinedRect(5, 30, 192, h - 35)

		draw.RoundedBox(5, 36, 35, 125, 30, Color(10, 10, 10, 230))
		draw.DrawText("Fluid Preview", "GWater2Title", 100, 40, color_white, TEXT_ALIGN_CENTER)
	end

	-- close menu if menu button is pressed
	function mainFrame:OnKeyCodePressed(key)
		if key == options.menu_key:GetInt() then
			mainFrame:Remove()
			just_closed = true
		end
	end

	-- menu "center" button
	local button = vgui.Create("DButton", mainFrame)
	button:SetPos(755, 3)
	button:SetSize(20, 20)
	button:SetText("")
	button:SetImage("icon16/anchor.png")
	button.Paint = nil
	function button:DoClick()
		mainFrame:Center()
		surface.PlaySound("buttons/button15.wav")
	end

	input.SetCursorPos(ScrW() / 2 - 80, ScrH() / 2 - 188)

	-- 2d simulation
	options.solver:Reset()

    -- the tabs
    local tabsFrame = vgui.Create("DPanel", mainFrame)
    tabsFrame:SetSize(600, 365)
    tabsFrame:SetPos(200, 30)
    tabsFrame.Paint = nil

	-- used in presets to update menu sliders after selection
	local sliders = {}

    -- the parameter tab, contains settings for the water
    local function parameter_tab(tabs)
        local scrollPanel = vgui.Create("GF_ScrollPanel", tabs)
		scrollPanel.Paint = draw_label

        local scrollEditTab = tabs:AddSheet("Parameters", scrollPanel, "icon16/cog.png").Tab
		scrollEditTab.Paint = draw_tabs
		
		-- explanation area 
		local explanation = create_explanation(scrollPanel)
		explanation:SetText(options.parameter_tab_text)
		local explanation_header = options.parameter_tab_header
		function explanation:Paint(w, h)
			self:SetPos(390, scrollPanel:GetVBar():GetScroll())
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.DrawText(explanation_header, "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			draw.DrawText(explanation_header, "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
		end

		-- parameters
		local labels = {}

		create_label(scrollPanel, "Physics Parameters", "These parameters directly influence physics.", 5)
		labels[1], sliders["Radius"] = create_slider(scrollPanel, "Radius", 1, 100, 1, 50)
		labels[2], sliders["Cohesion"] = create_slider(scrollPanel, "Cohesion", 0, 2, 3, 80)
		labels[3], sliders["Adhesion"] = create_slider(scrollPanel, "Adhesion", 0, 0.2, 3, 110)
		labels[4], sliders["Gravity"] = create_slider(scrollPanel, "Gravity", -30.48, 30.48, 2, 140)
		labels[5], sliders["Viscosity"] = create_slider(scrollPanel, "Viscosity", 0, 20, 2, 170)
		labels[6], sliders["Timescale"] = create_slider(scrollPanel, "Timescale", 0, 2, 2, 200)
		labels[7], sliders["Surface Tension"] = create_slider(scrollPanel, "Surface Tension", 0, 1, 2, 230, 350, 10)
		
		function scrollPanel:AnimationThink()
			local mousex, mousey = self:LocalCursorPos()
			local text_name = nil
			for _, label in pairs(labels) do
				local x, y = label:GetPos()
				local w, h = 345, 22
				if y >= -20 and mousex > x and mousey > y and mousex < x + w and mousey < y + h then
					label:SetColor(Color(177, 255, 154))
					text_name = label:GetText()
				else
					label:SetColor(Color(255, 255, 255))
				end
			end

			if text_name then
				explanation:SetText(options[text_name].text)
				explanation_header = text_name
			else
				explanation:SetText(options.parameter_tab_text)
				explanation_header = options.parameter_tab_header
			end
		end

		-- Presets
		local presets = vgui.Create("DComboBox", scrollPanel)
		presets:SetPos(240, 20)
		presets:SetSize(135, 20)
		presets:SetText("Presets (click to open)")
		presets:AddChoice("Acid", "Color:240 255 0 150\nCohesion:\nAdhesion:0.1\nViscosity:0\nSurface Tension:\nFluid Rest Distance:")
		presets:AddChoice("Blood", "Color:240 0 0 250\nCohesion:0.45\nAdhesion:0.15\nViscosity:1\nSurface Tension:0\nFluid Rest Distance:0.55")	-- Parameters by GHM
		presets:AddChoice("Glue", "Color:230 230 230 255\nCohesion:0.03\nAdhesion:0.1\nViscosity:10\nSurface Tension:\nFluid Rest Distance:")	-- yeah sure.. "glue"...
		presets:AddChoice("Lava", "Color:255 210 0 200\nCohesion:0.1\nAdhesion:0.01\nViscosity:10\nSurface Tension:\nFluid Rest Distance:")
		presets:AddChoice("Oil", "Color:0 0 0 255\nCohesion:0\nAdhesion:0\nViscosity:0\nSurface Tension:0\nFluid Rest Distance:")
		presets:AddChoice("Goop", "Color:170 240 140 50\nCohesion:1\nAdhesion:0.1\nViscosity:0\nSurface Tension:0.25\nFluid Rest Distance:")

		presets:AddChoice("Portal Gel (Blue)", "Color:0 127 255 255\nCohesion:0.1\nAdhesion:0.3\nViscosity:10\nSurface Tension:0.5\nFluid Rest Distance:")
		presets:AddChoice("Portal Gel (Orange)", "Color:255 127 0 255\nCohesion:0.1\nAdhesion:0.3\nViscosity:10\nSurface Tension:0.5\nFluid Rest Distance:")

		presets:AddChoice("(Default) Water", "Color:\nCohesion:\nAdhesion:\nViscosity:\nSurface Tension:\nFluid Rest Distance:")

		function presets:OnSelect(index, value, data)
			--EmitSound("buttons/lightswitch2.wav", Vector(), -2, CHAN_AUTO, 1, nil, nil, 200)
			local params = string.Split(data, "\n")
			for _, param in ipairs(params) do
				local key, val = unpack(string.Split(param, ":"))
				if val == "" then val = tostring(options[key].default) end
				if key != "Color" then
					sliders[key]:SetValue(tonumber(val))
				else
					sliders[key]:SetColor(string.ToColor(val))
				end
			end
		end

		function presets:ApplySchemeSettings()
			presets:SetFGColor(Color(255, 255, 255))
		end

		function presets:OnMenuOpened(pnl)
			--EmitSound("buttons/lightswitch2.wav", Vector(), -2, CHAN_AUTO, 1, nil, nil, 200)
			for k, label in pairs(pnl:GetCanvas():GetChildren()) do
				function label:Paint(w, h)
					if self:IsHovered() then
						surface.SetDrawColor(0,80,255, 60)
						surface.DrawRect(0, 0, w, h)
					end
					surface.SetDrawColor(255, 255, 255)
					surface.DrawOutlinedRect(5, h, w - 10, 0, 1)
				end
				label:SetTextColor(Color(255, 255, 255))
			end
			function pnl:Paint(w, h)
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(255, 255, 255)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end
		end

		function presets:Paint(w, h)
			if presets:IsMenuOpen() then
				surface.SetDrawColor(0, 80, 255, 60)
			else
				surface.SetDrawColor(0, 0, 0, 100)
			end
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
    end

	local function adv_parameter_tab(tabs)
        local scrollPanel = vgui.Create("GF_ScrollPanel", tabs)
		scrollPanel.Paint = draw_label

        local scrollEditTab = tabs:AddSheet("Adv. Parameters", scrollPanel, "icon16/cog_add.png").Tab
		scrollEditTab.Paint = draw_tabs
		
		-- explanation area 
		local explanation = create_explanation(scrollPanel)
		explanation:SetText(options.parameter_tab_text)
		local explanation_header = options.parameter_tab_header
		function explanation:Paint(w, h)
			self:SetPos(390, scrollPanel:GetVBar():GetScroll())
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.DrawText(explanation_header, "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			draw.DrawText(explanation_header, "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
		end

		-- parameters
		local labels = {}
		create_label(scrollPanel, "Advanced Parameters", "These parameters also directly influence physics.", 5)
		labels[1], sliders["Collision Distance"] = create_slider(scrollPanel, "Collision Distance", 0.1, 1, 2, 50, 315, 55)
		labels[2], sliders["Fluid Rest Distance"] = create_slider(scrollPanel, "Fluid Rest Distance", 0.55, 0.85, 2, 80, 315, 55)
		labels[3], sliders["Dynamic Friction"] = create_slider(scrollPanel, "Dynamic Friction", 0, 1, 2, 110, 315, 55)
		labels[4], sliders["Vorticity Confinement"] = create_slider(scrollPanel, "Vorticity Confinement", 0, 100, 0, 140, 300, 75)
		
		function scrollPanel:AnimationThink()
			local mousex, mousey = self:LocalCursorPos()
			local text_name = nil
			for _, label in pairs(labels) do
				local x, y = label:GetPos()
				local w, h = 345, 22
				if y >= -20 and mousex > x and mousey > y and mousex < x + w and mousey < y + h then
					label:SetColor(Color(177, 255, 154))
					text_name = label:GetText()
				else
					label:SetColor(Color(255, 255, 255))
				end
			end

			if text_name then
				explanation:SetText(options[text_name].text)
				explanation_header = text_name
			else
				explanation:SetText(options.adv_parameter_tab_text)
				explanation_header = options.adv_parameter_tab_header
			end
		end
    end

	-- the parameter tab, contains settings for the water
    local function visuals_tab(tabs)
        local scrollPanel = vgui.Create("GF_ScrollPanel", tabs)
		scrollPanel.Paint = draw_label

        local scrollEditTab = tabs:AddSheet("Visuals", scrollPanel, "icon16/picture.png").Tab
		scrollEditTab.Paint = draw_tabs
		
		-- explanation area 
		local explanation = create_explanation(scrollPanel)
		explanation:SetText(options.visuals_tab_text)
		local explanation_header = options.visuals_tab_header
		function explanation:Paint(w, h)
			self:SetPos(390, scrollPanel:GetVBar():GetScroll())
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.DrawText(explanation_header, "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			draw.DrawText(explanation_header, "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
		end

		-- parameters
		local labels = {}
		create_label(scrollPanel, "Visual Parameters", "These parameters directly influence visuals.", 5)
		labels[1], sliders["Anisotropy Min"] = create_slider(scrollPanel, "Anisotropy Min", 0, 1, 2, 50, 350, 20)
		labels[2], sliders["Anisotropy Max"] = create_slider(scrollPanel, "Anisotropy Max", 0, 2, 2, 80, 350, 20)
		labels[3], sliders["Anisotropy Scale"] = create_slider(scrollPanel, "Anisotropy Scale", 0, 2, 2, 110, 350, 20)
		labels[4], sliders["Diffuse Threshold"] = create_slider(scrollPanel, "Diffuse Threshold", 1, 1000, 0, 140, 350, 20)
		labels[5], sliders["Diffuse Lifetime"] = create_slider(scrollPanel, "Diffuse Lifetime", 0, 20, 1, 170, 350, 20)
		labels[6], sliders["Color"] = create_picker(scrollPanel, "Color", 200, 200)
		
		function scrollPanel:AnimationThink()
			local mousex, mousey = self:LocalCursorPos()
			local text_name = nil
			for _, label in pairs(labels) do
				local x, y = label:GetPos()
				local w, h = 345, 22
				if y >= -20 and mousex > x and mousey > y and mousex < x + w and mousey < y + h then
					label:SetColor(Color(177, 255, 154))
					text_name = label:GetText()
				else
					label:SetColor(Color(255, 255, 255))
				end
			end

			if text_name then
				explanation:SetText(options[text_name].text)
				explanation_header = text_name
			else
				explanation:SetText(options.visuals_tab_text)
				explanation_header = options.visuals_tab_header
			end
		end
    end


    local function performance_tab(tabs)
        local scrollPanel = vgui.Create("GF_ScrollPanel", tabs)
		scrollPanel.Paint = draw_label

        local scrollEditTab = tabs:AddSheet("Performance", scrollPanel, "icon16/application_xp_terminal.png").Tab
		scrollEditTab.Paint = draw_tabs

		-- explanation area 
		local explanation = create_explanation(scrollPanel)
		explanation:SetText(options.performance_tab_text)
		local explanation_header = options.performance_tab_header
		function explanation:Paint(w, h)
			self:SetPos(390, scrollPanel:GetVBar():GetScroll())
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.DrawText(explanation_header, "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			draw.DrawText(explanation_header, "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
		end

		local colors = {
			Color(250, 250, 0),
			Color(255, 127, 0),
			Color(127, 255, 0),
			Color(255, 0, 0),
			Color(250, 250, 0),
			Color(255, 127, 0),
			Color(255, 0, 0),
		}

		local labels = {}
		create_label(scrollPanel, "Performance Settings", "These settings directly influence performance", 5)
		-- create_slider(self, text, min, max, decimals, dock, x_offset, length, label_offset_x, reset_offset_x)
		labels[1] = create_slider(scrollPanel, "Iterations", 1, 10, 0, 50, 410, -50)
		labels[2] = create_slider(scrollPanel, "Substeps", 1, 10, 0, 80, 410, -50)
		--labels[3] = create_slider(scrollPanel, "Blur Passes", 0, 4, 0, 110) 

		-- blur passes slider is special since it uses a convar
		local label = vgui.Create("DLabel", scrollPanel)
		label:SetPos(10, 110)
		label:SetSize(200, 20)
		label:SetText("Blur Passes")
		label:SetFont("GWater2Param")
		labels[3] = label

		local slider = vgui.Create("DNumSlider", scrollPanel)
		slider:SetPos(-50, 110)
		slider:SetSize(410, 20)
		slider:SetMinMax(0, 4)
		slider:SetValue(options.blur_passes:GetInt())
		slider:SetDecimals(0)
		function slider:OnValueChanged(val)
			if val != math.Round(val, decimals) then 
				self:SetValue(math.Round(val, decimals))
				return
			end

			options.blur_passes:SetInt(val)
		end
		local button = vgui.Create("DButton", scrollPanel)
		button:SetPos(355, 110)
		button:SetText("")
		button:SetSize(20, 20)
		button:SetImage("icon16/arrow_refresh.png")
		button.Paint = nil
		function button:DoClick()
			slider:SetValue(3)
			surface.PlaySound("buttons/button15.wav")
		end

		-- particle limit box
		local label = vgui.Create("DLabel", scrollPanel)
		label:SetPos(10, 140)
		label:SetSize(200, 20)
		label:SetText("Particle Limit")
		label:SetFont("GWater2Param")
		labels[4] = label

		local slider = vgui.Create("DNumSlider", scrollPanel)
		slider:SetPos(0, 140)
		slider:SetSize(330, 20)
		slider:SetMinMax(1, 1000000)
		slider:SetValue(gwater2.solver:GetMaxParticles())
		slider:SetDecimals(0)

		local button = vgui.Create("DButton", scrollPanel)
		button:SetPos(355, 140)
		button:SetText("")
		button:SetSize(20, 20)
		button:SetImage("icon16/arrow_refresh.png")
		button.Paint = nil
		function button:DoClick()
			slider:SetValue(100000)
			surface.PlaySound("buttons/button15.wav")
		end

		-- 'confirm' particle limit button. Creates another DFrame
		local button = vgui.Create("DButton", scrollPanel)
		button:SetPos(330, 140)
		button:SetText("")
		button:SetSize(20, 20)
		button:SetImage("icon16/accept.png")
		button.Paint = nil
		function button:DoClick()
			local x, y = mainFrame:GetPos() x = x + 200 y = y + 100
			local frame = vgui.Create("DFrame", mainFrame)
			frame:SetSize(400, 200)
			frame:SetPos(x, y)
			frame:SetTitle("gwater2 (v" .. version .. ")")
			frame:MakePopup()
			frame:SetBackgroundBlur(true)
			frame:SetScreenLock(true)
			function frame:Paint(w, h)
				-- Blur background
				render.UpdateScreenEffectTexture()
				render.BlurRenderTarget(render.GetScreenEffectTexture(), 5, 5, 1)
				render.SetRenderTarget()
				render.DrawScreenQuad()

				-- dark background around 2d water sim
				surface.SetDrawColor(0, 0, 0, 200)
				surface.DrawRect(0, 0, w, h)

				-- main outline
				surface.SetDrawColor(255, 255, 255)
				surface.DrawOutlinedRect(0, 0, w, h)
	
				draw.DrawText("You are about to change the limit to " .. slider:GetValue() .. ".\nAre you sure?", "GWater2Title", 200, 30, color_white, TEXT_ALIGN_CENTER)
				draw.DrawText([[This can be dangerous, because all particles must be allocated on the GPU.
DO NOT set the limit to a number higher then you think your computer can handle.
I DO NOT take responsiblity for any hardware damage this may cause]], "DermaDefault", 200, 90, color_white, TEXT_ALIGN_CENTER)
			
			end

			local confirm = vgui.Create("DButton", frame)
			confirm:SetPos(260, 150)
			confirm:SetText("")
			confirm:SetSize(20, 20)
			confirm:SetImage("icon16/accept.png")
			confirm.Paint = nil
			function confirm:DoClick()
				gwater2.solver:Destroy()
				gwater2.solver = FlexSolver(slider:GetValue())
				gwater2.meshes = {}
				gwater2.reset_solver(true)
				frame:Close()
				surface.PlaySound("buttons/button15.wav")
			end

			local deny = vgui.Create("DButton", frame)
			deny:SetPos(110, 150)
			deny:SetText("")
			deny:SetSize(20, 20)
			deny:SetImage("icon16/cross.png")
			deny.Paint = nil
			function deny:DoClick() 
				frame:Close()
				surface.PlaySound("buttons/button15.wav")
			end

			surface.PlaySound("buttons/button15.wav")
		end

		-- Absorption checkbox & label
		local label = vgui.Create("DLabel", scrollPanel)	
		label:SetPos(10, 170)
		label:SetSize(100, 100)
		label:SetFont("GWater2Param")
		label:SetText("Absorption")
		label:SetContentAlignment(7)
		labels[5] = label

		local box = vgui.Create("DCheckBox", scrollPanel)
		box:SetPos(132, 170)
		box:SetSize(20, 20)
		box:SetChecked(options.absorption:GetBool())
		local water_volumetric = Material("gwater2/volumetric")
		function box:OnChange(val)
			options.absorption:SetBool(val)
			water_volumetric:SetFloat("$alpha", val and 0.125 or 0)
		end

		-- Depth fix checkbox & label
		local label = vgui.Create("DLabel", scrollPanel)	
		label:SetPos(10, 200)
		label:SetSize(100, 100)
		label:SetFont("GWater2Param")
		label:SetText("Depth Fix")
		label:SetContentAlignment(7)
		labels[6] = label

		local box = vgui.Create("DCheckBox", scrollPanel)
		box:SetPos(132, 200)
		box:SetSize(20, 20)
		box:SetChecked(options.depth_fix:GetBool())
		local water_normals = Material("gwater2/normals")
		function box:OnChange(val)
			options.depth_fix:SetBool(val)
			water_normals:SetInt("$depthfix", val and 1 or 0)
		end

		-- Solver checkbox
		local label = vgui.Create("DLabel", scrollPanel)	
		label:SetPos(10, 230)
		label:SetSize(100, 100)
		label:SetFont("GWater2Param")
		label:SetText("Old Solver")
		label:SetContentAlignment(7)
		labels[7] = label

		local box = vgui.Create("DCheckBox", scrollPanel)
		box:SetPos(132, 230)
		box:SetSize(20, 20)
		box:SetChecked(gwater2.old_ticker)
		function box:OnChange(val)
			gwater2.old_ticker = !gwater2.old_ticker
		end

		-- light up & change explanation area
		function scrollPanel:AnimationThink()
			if !mainFrame:HasFocus() then return end
			local mousex, mousey = self:LocalCursorPos()
			local text_name = nil
			for i, label in pairs(labels) do
				local x, y = label:GetPos()
				y = y - self:GetVBar():GetScroll() - 1
				local w, h = 345, 22
				if y >= -20 and mousex > x and mousey > y and mousex < x + w and mousey < y + h then
					label:SetColor(Color(colors[i].r + 127, colors[i].g + 127, colors[i].b + 127))
					text_name = label:GetText()
				else
					label:SetColor(colors[i])
				end
			end

			if text_name then
				explanation:SetText(options[text_name].text)
				explanation_header = text_name
			else
				explanation:SetText(options.performance_tab_text)
				explanation_header = options.performance_tab_header
			end
		end

    end

	local function about_tab(tabs)
        local scrollPanel = vgui.Create("GF_ScrollPanel", tabs)
        local scrollEditTab = tabs:AddSheet("About", scrollPanel, "icon16/exclamation.png").Tab
		scrollEditTab.Paint = draw_tabs

		local label = vgui.Create("DLabel", scrollPanel)
		label:SetPos(0, 0)
		label:SetSize(383, 800)
		label:SetText([[
			Thank you for downloading gwater2 beta! This menu is the interface that you will be using to control everything about gwater. So get used to it! :D

			Make sure to read the changelog to see what has been updated!

			Changelog (v0.3.1b):
			- Fixed timescale 0 breaking fluid preview
			- Removed DRM due to backlash

			Changelog (v0.3b):
			- Added NPC, player, and ragdoll collisions
			- Added more fluid parameters
			- Added visual parameters
			- Added diffuse particles (bubbles/foam)
			- Added DRM
			- Improved (optimized) particle spawning code
			- Improved surface estimation (smoother water surface)
			- Improved anisotropy code
			- Doubled viscosity slider limit
			- Fixed flashing when spawning particles after changing limits
			- Fixed 'Depth fix' parameter not saving properly
			- Fixed a crash when loading into some maps
			- Fixed menu opening when using e2 editor
			- Updated patron list
			- General micro-optimizations and codebase rewrites (performance improvement of ~30% in my testing)
		]])
		label:SetColor(Color(255, 255, 255))
		label:SetTextInset(5, 30)
		label:SetWrap(true)
		label:SetContentAlignment(7)	-- shove text in top left corner
		label:SetFont("GWater2Param")
		function label:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 1)

			draw.DrawText("Welcome to gwater2! (v" .. version .. ")", "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			draw.DrawText("Welcome to gwater2! (v" .. version .. ")", "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
		end

		-- explanation area 
		local explanation = create_explanation(scrollPanel)
		explanation:SetText(options.about_tab_text)
		function explanation:Paint(w, h)
			self:SetPos(390, scrollPanel:GetVBar():GetScroll())
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.DrawText(options.about_tab_header, "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			draw.DrawText(options.about_tab_header, "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
		end
    end

	local function patron_tab(tabs)
        local scrollPanel = vgui.Create("DScrollPanel", tabs)
        local scrollEditTab = tabs:AddSheet("Patrons", scrollPanel, "icon16/award_star_gold_3.png").Tab
		scrollEditTab.Paint = draw_tabs

		-- DONT FORGET TO ADD 'Xenthio'
		-- & Spaghetti Regretti
		local patrons = file.Read("gwater2_patrons.lua", "LUA") or "<Failed to load patron data!>"
		local patrons_table = string.Split(patrons, "\n")

		local label = vgui.Create("DLabel", scrollPanel)
		label:SetPos(0, 0)
		label:SetSize(383, 14720)
		label:SetText([[
			Thanks to everyone here who supported me throughout the development of GWater2!
			
			All revenue generated from this project goes directly to my college fund. Thanks so much guys :)
			-----------------------------------------
			]])
		label:SetColor(Color(255, 255, 255))
		label:SetTextInset(5, 30)
		label:SetWrap(true)
		label:SetContentAlignment(7)	-- shove text in top left corner
		label:SetFont("GWater2Param")
		function label:Paint(w, h)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 1)

			draw.DrawText("Patrons", "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			draw.DrawText("Patrons", "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
			
			-- unoptimized as shit but im at the mercy of vgui. 
			local patron_color = Color(171, 255, 163)
			for k, v in ipairs(patrons_table) do
				draw.DrawText(v, "GWater2Param", 6, 150 + k * 20, patron_color, TEXT_ALIGN_LEFT)
			end
		end

		-- explanation area 
		local explanation = create_explanation(scrollPanel)
		explanation:SetText(options.patron_tab_text)
		function explanation:Paint(w, h)
			--self:SetPos(390, scrollPanel:GetVBar():GetScroll())
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.DrawText(options.patron_tab_header, "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
			draw.DrawText(options.patron_tab_header, "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
		end
    end

    local tabs = vgui.Create("DPropertySheet", tabsFrame)
	tabs:Dock(FILL)
	function tabs:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 20, w, h - 20)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, 20, w, h - 20, 1)
	
		--surface.SetSize(192, 365)
		--SetPos(603, 30)
	end

	-- we need to save the index the tab is in, and when the menu is reopened it will set to that tab
	-- we cant use a reference to an actual panel because it wont be valid the next time the menu is opened... so we use the index instead
	function tabs:OnActiveTabChanged(old, new)
		for k, v in ipairs(self.Items) do
			if v.Tab == new then
				options.tab:SetInt(k)
			end
		end
	end

	about_tab(tabs)
    parameter_tab(tabs)
	adv_parameter_tab(tabs)
	visuals_tab(tabs)
    performance_tab(tabs)
	patron_tab(tabs)

	tabs:SetActiveTab(tabs.Items[options.tab:GetInt()].Tab)
end)

-- closes menu if mouse presses on the outside
hook.Add("GUIMousePressed", "gwater2_menuclose", function(mouse_code, aim_vector)
	if !IsValid(mainFrame) then return end

	local x, y = gui.MouseX(), gui.MouseY()
	local frame_x, frame_y = mainFrame:GetPos()
	if x < frame_x or x > frame_x + mainFrame:GetWide() or y < frame_y or y > frame_y + mainFrame:GetTall() then
		mainFrame:Remove()
	end

	options.mouse_pos = {x, y}
end)

hook.Add("PopulateToolMenu", "gwater2_menu", function()
    spawnmenu.AddToolMenuOption("Utilities", "gwater2", "gwater2_menu", "Menu Options", "", "", function(panel)
		panel:ClearControls()
		panel:Button("Open Menu", "gwater2_menu")
        panel:KeyBinder("Menu Key", "gwater2_menukey")
	end)
end)

function OpenGW2Menu(ply, key)
	if key != options.menu_key:GetInt() or just_closed == true then return end
	RunConsoleCommand("gwater2_menu")
end

function CloseGW2Menu(ply, key)
	if key != options.menu_key:GetInt() then return end
	just_closed = false
end

-- shit breaks in singleplayer due to predicted hooks
if game.SinglePlayer() then return end

hook.Add("PlayerButtonDown", "gwater2_menu", OpenGW2Menu)
hook.Add("PlayerButtonUp", "gwater2_menu", CloseGW2Menu)