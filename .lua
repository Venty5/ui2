local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local Library = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	SearchRegistry = {},
	Themes = {
		Default = {
			Main = Color3.fromRGB(20, 20, 22),
			Second = Color3.fromRGB(30, 30, 32),
			Stroke = Color3.fromRGB(60, 60, 65),
			Divider = Color3.fromRGB(40, 40, 45),
			Text = Color3.fromRGB(240, 240, 245),
			TextDark = Color3.fromRGB(160, 160, 165),
			MainTransparency = 0,
			SecondTransparency = 0,
			FrameTransparency = 0
		},
		Black = {
			Main = Color3.fromRGB(10, 10, 12),
			Second = Color3.fromRGB(18, 18, 20),
			Stroke = Color3.fromRGB(45, 45, 50),
			Divider = Color3.fromRGB(28, 28, 32),
			Text = Color3.fromRGB(240, 240, 245),
			TextDark = Color3.fromRGB(140, 140, 145),
			MainTransparency = 0,
			SecondTransparency = 0,
			FrameTransparency = 0
		},
		White = {
			Main = Color3.fromRGB(230, 230, 235),
			Second = Color3.fromRGB(215, 215, 220),
			Stroke = Color3.fromRGB(180, 180, 185),
			Divider = Color3.fromRGB(195, 195, 200),
			Text = Color3.fromRGB(20, 20, 25),
			TextDark = Color3.fromRGB(80, 80, 85),
			MainTransparency = 0,
			SecondTransparency = 0,
			FrameTransparency = 0
		},
		Gray = {
			Main = Color3.fromRGB(55, 55, 60),
			Second = Color3.fromRGB(70, 70, 75),
			Stroke = Color3.fromRGB(100, 100, 105),
			Divider = Color3.fromRGB(85, 85, 90),
			Text = Color3.fromRGB(235, 235, 240),
			TextDark = Color3.fromRGB(170, 170, 175),
			MainTransparency = 0,
			SecondTransparency = 0,
			FrameTransparency = 0
		},
		Blue = {
			Main = Color3.fromRGB(10, 20, 45),
			Second = Color3.fromRGB(15, 30, 65),
			Stroke = Color3.fromRGB(40, 70, 130),
			Divider = Color3.fromRGB(25, 50, 95),
			Text = Color3.fromRGB(200, 220, 255),
			TextDark = Color3.fromRGB(110, 150, 210),
			MainTransparency = 0,
			SecondTransparency = 0,
			FrameTransparency = 0
		},
		Purple = {
			Main = Color3.fromRGB(25, 10, 45),
			Second = Color3.fromRGB(38, 15, 65),
			Stroke = Color3.fromRGB(90, 40, 150),
			Divider = Color3.fromRGB(60, 25, 100),
			Text = Color3.fromRGB(220, 200, 255),
			TextDark = Color3.fromRGB(155, 120, 210),
			MainTransparency = 0,
			SecondTransparency = 0,
			FrameTransparency = 0
		},
		Red = {
			Main = Color3.fromRGB(35, 8, 8),
			Second = Color3.fromRGB(55, 12, 12),
			Stroke = Color3.fromRGB(130, 35, 35),
			Divider = Color3.fromRGB(85, 20, 20),
			Text = Color3.fromRGB(255, 210, 210),
			TextDark = Color3.fromRGB(200, 120, 120),
			MainTransparency = 0,
			SecondTransparency = 0,
			FrameTransparency = 0
		},
	},
	SelectedTheme = "Default",
	Font = Enum.Font.Gotham,
	UserConfig = {},
	ConfigFile = nil
}

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

function Library:LoadConfig()
	if not self.ConfigFile then return end
	if isfile and isfile(self.ConfigFile) then
		local success, data = pcall(function()
			return HttpService:JSONDecode(readfile(self.ConfigFile))
		end)
		if success and data then
			self.UserConfig = data
			if data.__theme and self.Themes[data.__theme] then
				self.SelectedTheme = data.__theme
			end
			for flag, value in pairs(self.UserConfig) do
				if flag ~= "__theme" and self.Flags[flag] then
					if self.Flags[flag].Type == "Colorpicker" then
						self.Flags[flag]:Set(UnpackColor(value))
					else
						self.Flags[flag]:Set(value)
					end
				end
			end
		end
	end
end

function Library:SaveConfig()
	if not self.ConfigFile or not writefile then return end
	pcall(function()
		self.UserConfig.__theme = self.SelectedTheme
		writefile(self.ConfigFile, HttpService:JSONEncode(self.UserConfig))
	end)
end

local function GetIcon(IconName)
	return nil
end

function Library:CleanupInstance()
	for _, instance in pairs(game:GetService("CoreGui"):GetChildren()) do
		if instance:IsA("ScreenGui") and instance.Name:match("^[A-Z]%d%d%d$") then
			instance:Destroy()
		end
	end
end

Library:CleanupInstance()
local Container = Instance.new("ScreenGui")
Container.Name = string.char(math.random(65, 90))..tostring(math.random(100, 999))
Container.DisplayOrder = 2147483647
Container.Parent = game:GetService("CoreGui")

function Library:IsRunning()
	return Container and Container.Parent == game:GetService("CoreGui")
end

local function AddConnection(Signal, Function)
	if not Library:IsRunning() then return end
	local SignalConnect = Signal:Connect(Function)
	table.insert(Library.Connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while Library:IsRunning() do wait() end
	for _, Connection in next, Library.Connections do
		Connection:Disconnect()
	end
end)

local function MakeDraggable(DragPoint, Main)
	local IsResizing = false
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos = false
		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				if not IsResizing then
					Dragging = true
					MousePos = Input.Position
					FramePos = Main.Position
				end
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
				end)
			end
		end)
		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
				DragInput = Input
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging and not IsResizing then
				local Delta = Input.Position - MousePos
				TweenService:Create(Main, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
				}):Play()
			end
		end)
	end)
	return function(resizing)
		IsResizing = resizing
		if resizing then Dragging = false end
	end
end

local function MakeResizable(ResizeButton, Main, MinSize, MaxSize, SetResizingCallback)
	pcall(function()
		local Resizing = false
		local StartSize, StartPos
		ResizeButton.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Resizing = true
				if SetResizingCallback then SetResizingCallback(true) end
				StartSize = Main.Size
				StartPos = Vector2.new(Mouse.X, Mouse.Y)
			end
		end)
		ResizeButton.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Resizing = false
				if SetResizingCallback then SetResizingCallback(false) end
			end
		end)
		UserInputService.InputChanged:Connect(function()
			if Resizing then
				local CurrentPos = Vector2.new(Mouse.X, Mouse.Y)
				local Delta = CurrentPos - StartPos
				local NewWidth = math.clamp(StartSize.X.Offset + Delta.X, MinSize.X, MaxSize.X)
				local NewHeight = math.clamp(StartSize.Y.Offset + Delta.Y, MinSize.Y, MaxSize.Y)
				Main.Size = UDim2.new(0, NewWidth, 0, NewHeight)
			end
		end)
	end)
end

local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in next, Properties or {} do Object[i] = v end
	for i, v in next, Children or {} do v.Parent = Object end
	return Object
end

local function CreateElement(ElementName, ElementFunction)
	Library.Elements[ElementName] = function(...) return ElementFunction(...) end
end

local function MakeElement(ElementName, ...)
	return Library.Elements[ElementName](...)
end

local function SetProps(Element, Props)
	table.foreach(Props, function(Property, Value) Element[Property] = Value end)
	return Element
end

local function SetChildren(Element, Children)
	table.foreach(Children, function(_, Child) Child.Parent = Element end)
	return Element
end

local function Round(Number, Factor)
	if not Factor or Factor == 0 then return Number end
	local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
	if Result < 0 then Result = Result + Factor end
	return Result
end

local function ReturnProperty(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then return "BackgroundColor3" end
	if Object:IsA("ScrollingFrame") then return "ScrollBarImageColor3" end
	if Object:IsA("UIStroke") then return "Color" end
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then return "TextColor3" end
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then return "ImageColor3" end
end

local function AddThemeObject(Object, Type)
	if not Library.ThemeObjects[Type] then Library.ThemeObjects[Type] = {} end
	table.insert(Library.ThemeObjects[Type], Object)
	Object[ReturnProperty(Object)] = Library.Themes[Library.SelectedTheme][Type]
	return Object
end

local function SetTheme()
	for Name, Type in pairs(Library.ThemeObjects) do
		for _, Object in pairs(Type) do
			Object[ReturnProperty(Object)] = Library.Themes[Library.SelectedTheme][Name]
		end
	end
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3, Enum.UserInputType.Touch}
local BlacklistedKeys = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
	for _, v in next, Table do
		if v == Key then return true end
	end
end

CreateElement("Corner", function(Scale, Offset)
	return Create("UICorner", {CornerRadius = UDim.new(Scale or 0, Offset or 12)})
end)

CreateElement("Stroke", function(Color, Thickness)
	return Create("UIStroke", {Color = Color or Color3.fromRGB(255,255,255), Thickness = Thickness or 0.5})
end)

CreateElement("List", function(Scale, Offset)
	return Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 0)})
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	return Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft   = UDim.new(0, Left   or 4),
		PaddingRight  = UDim.new(0, Right  or 4),
		PaddingTop    = UDim.new(0, Top    or 4)
	})
end)

CreateElement("TFrame", function()
	return Create("Frame", {BackgroundTransparency = 1})
end)

CreateElement("Frame", function(Color)
	return Create("Frame", {BackgroundColor3 = Color or Color3.fromRGB(255,255,255), BorderSizePixel = 0})
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	return Create("Frame", {BackgroundColor3 = Color or Color3.fromRGB(255,255,255), BorderSizePixel = 0}, {
		Create("UICorner", {CornerRadius = UDim.new(Scale, Offset)})
	})
end)

CreateElement("Button", function()
	local Button = Create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0})
	Button.MouseButton1Click:Connect(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6895079853"
		sound.Volume = 0.5
		sound.Parent = game:GetService("SoundService")
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 1)
	end)
	return Button
end)

CreateElement("ScrollFrame", function(Color, Width)
	return Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = Color,
		BorderSizePixel = 0,
		ScrollBarThickness = Width,
		CanvasSize = UDim2.new(0,0,0,0)
	})
end)

CreateElement("Image", function(ImageID)
	local ImageNew = Create("ImageLabel", {Image = ImageID, BackgroundTransparency = 1})
	if GetIcon(ImageID) ~= nil then ImageNew.Image = GetIcon(ImageID) end
	return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
	return Create("ImageButton", {Image = ImageID, BackgroundTransparency = 1})
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	return Create("TextLabel", {
		Text = Text or "",
		TextColor3 = Color3.fromRGB(240,240,240),
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 15,
		Font = Enum.Font.GothamSemibold,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
end)

local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 5)
	})
}), {
	Position = UDim2.new(1, -25, 1, -25),
	Size = UDim2.new(0, 300, 1, -25),
	AnchorPoint = Vector2.new(1, 1),
	Parent = Container
})

function Library:MakeNotification(NotificationConfig)
	spawn(function()
		NotificationConfig.Name    = NotificationConfig.Name    or "Notification"
		NotificationConfig.Content = NotificationConfig.Content or "Test"
		NotificationConfig.Image   = NotificationConfig.Image   or "rbxassetid://4384403532"
		NotificationConfig.Time    = NotificationConfig.Time    or 15

		local NotificationParent = SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25,25,25), 0, 10), {
			Parent = NotificationParent,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 0.15,
			AutomaticSize = Enum.AutomaticSize.Y
		}), {
			MakeElement("Stroke", Color3.fromRGB(93,93,93), 1.2),
			MakeElement("Padding", 12, 12, 12, 12),
			SetProps(MakeElement("Image", NotificationConfig.Image), {
				Size = UDim2.new(0, 20, 0, 20),
				ImageColor3 = Color3.fromRGB(240,240,240),
				Name = "Icon"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font = Enum.Font.FredokaOne,
				Name = "Title"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 25),
				Font = Enum.Font.FredokaOne,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = Color3.fromRGB(200,200,200),
				TextWrapped = true
			})
		})

		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0,0,0,0)}):Play()
		wait(NotificationConfig.Time)
		TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Position = UDim2.new(1,0,0,0)}):Play()
		wait(0.8)
		NotificationParent:Destroy()
	end)
end

function Library:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local Loaded = false
	local UIHidden = false
	local CurrentTabMode = "Themes" -- "Themes" or "Configs"

	WindowConfig = WindowConfig or {}
	WindowConfig.Name            = WindowConfig.Name            or "Void Menu"
	WindowConfig.HidePremium     = WindowConfig.HidePremium     or false
	WindowConfig.SaveConfig      = WindowConfig.SaveConfig      or false
	WindowConfig.ConfigFile      = WindowConfig.ConfigFile      or WindowConfig.Name .. ".json"
	if WindowConfig.IntroEnabled == nil then WindowConfig.IntroEnabled = true end
	WindowConfig.IntroToggleIcon = WindowConfig.IntroToggleIcon or "rbxassetid://123912257208121"
	WindowConfig.IntroText       = WindowConfig.IntroText       or "Launching Void Menu..."
	WindowConfig.CloseCallback   = WindowConfig.CloseCallback   or function() end
	WindowConfig.ShowIcon        = WindowConfig.ShowIcon        or false
	WindowConfig.Icon            = WindowConfig.Icon            or "rbxassetid://123912257208121"
	WindowConfig.IntroIcon       = WindowConfig.IntroIcon       or "rbxassetid://123912257208121"

	Library.ConfigFile = WindowConfig.ConfigFile

	if WindowConfig.SaveConfig then
		Library:LoadConfig()
	end

	-- Tab Holder for Themes/Configs tabs
	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 4), {
		Size = UDim2.new(1, 0, 1, -50)
	}), {
		MakeElement("List"),
		MakeElement("Padding", 8, 0, 0, 8)
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	-- Close button
	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18)
		}), "Text")
	})

	-- Minimize button
	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18),
			Name = "Ico"
		}), "Text")
	})

	local DragPoint = SetProps(MakeElement("TFrame"), {Size = UDim2.new(1, 0, 0, 50)})

	-- Main content area (where tabs content will be placed)
	local ContentContainer = SetChildren(SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 1, -50),
		Position = UDim2.new(0, 0, 0, 50)
	}), {})

	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 10), {
		Size = UDim2.new(0, 150, 1, -50),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundTransparency = 0.15
	}), {
		AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 0.15}), "Second"),
		AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(0,10,1,0), Position = UDim2.new(1,-10,0,0), BackgroundTransparency = 0.15}), "Second"),
		AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,-1,0,0)}), "Stroke"),
		TabHolder,
		ContentContainer,
		SetChildren(SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,50), Position = UDim2.new(0,0,1,-50)}), {
			AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(1,0,0,1)}), "Stroke"),
			AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
				AnchorPoint = Vector2.new(0,0.5),
				Size = UDim2.new(0,32,0,32),
				Position = UDim2.new(0,10,0.5,0),
				BackgroundTransparency = 0.2
			}), {
				SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId="..(LocalPlayer and LocalPlayer.UserId or 0).."&width=420&height=420&format=png"), {Size = UDim2.new(1,0,1,0)}),
				AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {Size = UDim2.new(1,0,1,0)}), "Second"),
				MakeElement("Corner", 1)
			}), "Divider"),
			SetChildren(SetProps(MakeElement("TFrame"), {
				AnchorPoint = Vector2.new(0,0.5),
				Size = UDim2.new(0,32,0,32),
				Position = UDim2.new(0,10,0.5,0)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				MakeElement("Corner", 1)
			}),
			AddThemeObject(SetProps(MakeElement("Label", "Void Menu", WindowConfig.HidePremium and 14 or 13), {
				Size = UDim2.new(1,-60,0,13),
				Position = WindowConfig.HidePremium and UDim2.new(0,50,0,19) or UDim2.new(0,50,0,12),
				Font = Enum.Font.FredokaOne,
				ClipsDescendants = true
			}), "Text"),
			SetProps(MakeElement("Label", "No Vip", 12), {
				Size = UDim2.new(1,-60,0,12),
				Position = UDim2.new(0,50,1,-25),
				Visible = not WindowConfig.HidePremium,
				TextColor3 = Color3.fromRGB(150, 150, 165)
			})
		}),
	}), "Second")

	-- TopBar
	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
		Size = UDim2.new(1,-30,2,0),
		Position = UDim2.new(0,25,0,-24),
		Font = Enum.Font.GothamBlack,
		TextSize = 20
	}), "Text")

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1,0,0,1),
		Position = UDim2.new(0,0,1,-1)
	}), "Stroke")

	-- TopBar buttons: Minimize and Close (2 buttons)
	local TopBarButtonContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 7), {
		Size = UDim2.new(0, 70, 0, 30),
		Position = UDim2.new(1, -85, 0, 10),
		BackgroundTransparency = 0.15
	}), {
		AddThemeObject(MakeElement("Stroke"), "Stroke"),
		AddThemeObject(SetProps(MakeElement("Frame"), {Size = UDim2.new(0,1,1,0), Position = UDim2.new(0.5,0,0,0)}), "Stroke"),
		MinimizeBtn,
		CloseBtn
	}), "Second")

	-- Theme buttons container (below the top bar)
	local ThemeButtonContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 7), {
		Size = UDim2.new(0, 490, 0, 34),
		Position = UDim2.new(0.5, -245, 0, 52),
		BackgroundTransparency = 0.05
	}), {
		AddThemeObject(MakeElement("Stroke"), "Stroke"),
	}), "Second")

	-- Theme buttons
	local themeColors = {
		{name = "Default", color = Color3.fromRGB(40,40,45)},
		{name = "Black", color = Color3.fromRGB(10,10,12)},
		{name = "White", color = Color3.fromRGB(230,230,235)},
		{name = "Gray", color = Color3.fromRGB(55,55,60)},
		{name = "Blue", color = Color3.fromRGB(10,20,45)},
		{name = "Purple", color = Color3.fromRGB(25,10,45)},
		{name = "Red", color = Color3.fromRGB(35,8,8)},
	}

	local ThemeButtons = {}
	local ThemeButtonFrame = ThemeButtonContainer

	for i, themeData in ipairs(themeColors) do
		local btn = Create("TextButton", {
			Size = UDim2.new(0, 56, 0, 26),
			Position = UDim2.new(0, 8 + (i-1) * 64, 0.5, -13),
			BackgroundColor3 = themeData.color,
			BackgroundTransparency = (Library.SelectedTheme == themeData.name) and 0.5 or 0.2,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = ThemeButtonFrame,
		})
		Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = btn})
		Create("UIStroke", {Color = (Library.SelectedTheme == themeData.name) and Color3.fromRGB(255,255,255) or Color3.fromRGB(80,80,85), Thickness = 1.5, Parent = btn})

		-- Add a checkmark if selected
		local checkmark = Create("ImageLabel", {
			Image = "rbxassetid://3944680095",
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.new(1, -10, 0, 2),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(255,255,255),
			Visible = (Library.SelectedTheme == themeData.name),
			Parent = btn,
		})

		ThemeButtons[themeData.name] = {button = btn, checkmark = checkmark}

		btn.MouseEnter:Connect(function()
			if Library.SelectedTheme ~= themeData.name then
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if Library.SelectedTheme ~= themeData.name then
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
			end
		end)
		btn.MouseButton1Click:Connect(function()
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://6895079853"
			sound.Volume = 0.5
			sound.Parent = game:GetService("SoundService")
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 1)

			-- Update selected theme
			Library.SelectedTheme = themeData.name
			SetTheme()

			-- Update all theme buttons
			for name, data in pairs(ThemeButtons) do
				data.checkmark.Visible = (name == themeData.name)
				TweenService:Create(data.button, TweenInfo.new(0.15), {
					BackgroundTransparency = (name == themeData.name) and 0.5 or 0.2
				}):Play()
				local stroke = data.button:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = (name == themeData.name) and Color3.fromRGB(255,255,255) or Color3.fromRGB(80,80,85)
				end
			end

			-- Auto-save theme
			if WindowConfig.SaveConfig and Library.ConfigFile then
				Library.UserConfig.__theme = themeData.name
				Library:SaveConfig()
			end

			Library:MakeNotification({
				Name = "Theme geändert",
				Content = "Theme wurde auf " .. themeData.name .. " gesetzt.",
				Time = 3
			})
		end)
	end

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 10), {
		Parent = Container,
		Position = UDim2.new(0.5,-307,0.5,-240),
		Size = UDim2.new(0,615,0,480),
		ClipsDescendants = true,
		BackgroundTransparency = 0
	}), {
		SetChildren(SetProps(MakeElement("TFrame"), {Size = UDim2.new(1,0,0,50), Name = "TopBar"}), {
			WindowName,
			WindowTopBarLine,
			TopBarButtonContainer,
		}),
		DragPoint,
		WindowStuff,
		ThemeButtonContainer,
	}), "Main")

	local SetResizingCallback = MakeDraggable(DragPoint, MainWindow)

	local MobileReopenButton = SetChildren(SetProps(MakeElement("Button"), {
		Parent = Container,
		Size = UDim2.new(0,40,0,40),
		Position = UDim2.new(0.5,-20,0,20),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Library.Themes[Library.SelectedTheme].Main,
		Visible = false
	}), {
		AddThemeObject(SetProps(MakeElement("Image", WindowConfig.IntroToggleIcon or "http://www.roblox.com/asset/?id=8834748103"), {
			AnchorPoint = Vector2.new(0.5,0.5),
			Position = UDim2.new(0.5,0,0.5,0),
			Size = UDim2.new(0.7,0,0.7,0),
		}), "Text"),
		MakeElement("Corner", 1)
	})

	AddConnection(CloseBtn.MouseButton1Up, function()
		MainWindow.Visible = false
		if UserInputService.TouchEnabled then MobileReopenButton.Visible = true end
		UIHidden = true
		Library:MakeNotification({
			Name = "Interface Hidden",
			Content = UserInputService.TouchEnabled and "Tap the button or Left Control to reopen the interface" or "Press Left Control to reopen the interface",
			Time = 5
		})
		WindowConfig.CloseCallback()
	end)

	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == Enum.KeyCode.LeftControl and UIHidden == true then
			MainWindow.Visible = true
			MobileReopenButton.Visible = false
		end
	end)

	AddConnection(MobileReopenButton.Activated, function()
		MainWindow.Visible = true
		MobileReopenButton.Visible = false
	end)

	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0,615,0,480)}):Play()
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
			wait(.02)
			MainWindow.ClipsDescendants = false
			WindowStuff.Visible = true
			WindowTopBarLine.Visible = true
		else
			MainWindow.ClipsDescendants = true
			WindowTopBarLine.Visible = false
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WindowName.TextBounds.X + 175, 0, 50)}):Play()
			wait(0.1)
			WindowStuff.Visible = false
		end
		Minimized = not Minimized
	end)

	local function LoadSequence()
		MainWindow.Visible = false

		local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
			Parent = Container,
			AnchorPoint = Vector2.new(0.5,0.5),
			Position = UDim2.new(0.5,0,0.4,0),
			Size = UDim2.new(0,28,0,28),
			ImageColor3 = Color3.fromRGB(255,255,255),
			ImageTransparency = 1
		})

		local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
			Parent = Container,
			Size = UDim2.new(1,0,1,0),
			AnchorPoint = Vector2.new(0.5,0.5),
			Position = UDim2.new(0.5,19,0.5,0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		local LoadingBarBackground = Instance.new("Frame")
		LoadingBarBackground.Size = UDim2.new(0, 200, 0, 4)
		LoadingBarBackground.Position = UDim2.new(0.5, -100, 0.55, 0)
		LoadingBarBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		LoadingBarBackground.BorderSizePixel = 0
		LoadingBarBackground.Parent = Container
		LoadingBarBackground.BackgroundTransparency = 1
		Instance.new("UICorner", LoadingBarBackground).CornerRadius = UDim.new(0, 2)

		local LoadingBarFill = Instance.new("Frame")
		LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
		LoadingBarFill.Position = UDim2.new(0, 0, 0, 0)
		LoadingBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		LoadingBarFill.BorderSizePixel = 0
		LoadingBarFill.Parent = LoadingBarBackground
		Instance.new("UICorner", LoadingBarFill).CornerRadius = UDim.new(0, 2)

		local PercentageText = SetProps(MakeElement("Label", "0%", 14), {
			Parent = Container,
			Size = UDim2.new(0, 50, 0, 20),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.57, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5,0,0.5,0)}):Play()
		wait(0.8)
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
		wait(0.3)
		TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		TweenService:Create(LoadingBarBackground, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
		TweenService:Create(PercentageText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		wait(0.5)

		local function UpdateLoading(percentage)
			TweenService:Create(LoadingBarFill, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {Size = UDim2.new(percentage/100, 0, 1, 0)}):Play()
			PercentageText.Text = percentage .. "%"
		end

		for i = 0, 100 do
			UpdateLoading(i)
			wait(0.03)
		end

		wait(0.3)

		TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
		TweenService:Create(LoadingBarBackground, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		TweenService:Create(PercentageText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
		wait(0.3)

		MainWindow.Visible = true
		LoadSequenceLogo:Destroy()
		LoadSequenceText:Destroy()
		LoadingBarBackground:Destroy()
		PercentageText:Destroy()
	end

	if WindowConfig.IntroEnabled then LoadSequence() end

	-- Build Themes Tab content
	local function BuildThemesTab()
		local tabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder,
			LayoutOrder = 1
		}), {
			AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0,18,0,18),
				Position = UDim2.new(0,10,0.5,0),
				ImageTransparency = 0,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", "Themes", 14), {
				Size = UDim2.new(1,-35,1,0),
				Position = UDim2.new(0,35,0,0),
				Font = Enum.Font.GothamBlack,
				TextTransparency = 0,
				Name = "Title"
			}), "Text")
		})

		local tabItemContainer = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 5), {
			Size = UDim2.new(1,-150,1,-50),
			Position = UDim2.new(0,150,0,50),
			Parent = ContentContainer,
			Visible = true,
			Name = "ItemContainer"
		}), {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15)
		}), "Divider")

		AddConnection(tabItemContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			tabItemContainer.CanvasSize = UDim2.new(0, 0, 0, tabItemContainer.UIListLayout.AbsoluteContentSize.Y + 30)
		end)

		-- Add theme description
		local descFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(1,-16,0,40),
			Position = UDim2.new(0,8,0,0),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "Wähle ein Theme für die UI", 15), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.FredokaOne,
				Name = "Content"
			}), "Text"),
			AddThemeObject(MakeElement("Stroke"), "Stroke")
		}), "Second")

		-- Also add theme buttons in the content area as a reference
		local themeGrid = SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, -16, 0, 220),
			Position = UDim2.new(0, 8, 0, 50),
			Parent = tabItemContainer
		}), {MakeElement("List", 0, 8)})

		for i, themeData in ipairs(themeColors) do
			local btn = SetChildren(SetProps(MakeElement("RoundFrame", themeData.color, 0, 5), {
				Size = UDim2.new(0.23, -8, 1, -8),
				BackgroundTransparency = 0.2,
				Parent = themeGrid
			}), {
				MakeElement("Stroke"),
				SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)}),
				SetProps(MakeElement("Label", themeData.name, 14), {
					Size = UDim2.new(1,0,1,0),
					Position = UDim2.new(0,0,0,0),
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				})
			})
		end

		return tabFrame, tabItemContainer
	end

	-- Build Configs Tab content
	local function BuildConfigsTab()
		local tabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder,
			LayoutOrder = 2
		}), {
			AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3944703587"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0,18,0,18),
				Position = UDim2.new(0,10,0.5,0),
				ImageTransparency = 0.4,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", "Configs", 14), {
				Size = UDim2.new(1,-35,1,0),
				Position = UDim2.new(0,35,0,0),
				Font = Enum.Font.GothamBlack,
				TextTransparency = 0.4,
				Name = "Title"
			}), "Text")
		})

		local tabItemContainer = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 5), {
			Size = UDim2.new(1,-150,1,-50),
			Position = UDim2.new(0,150,0,50),
			Parent = ContentContainer,
			Visible = false,
			Name = "ItemContainer"
		}), {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15)
		}), "Divider")

		AddConnection(tabItemContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			tabItemContainer.CanvasSize = UDim2.new(0, 0, 0, tabItemContainer.UIListLayout.AbsoluteContentSize.Y + 30)
		end)

		-- Active Config
		local activeFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(1,-16,0,45),
			Position = UDim2.new(0,8,0,0),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "Aktive Config", 12), {
				Size = UDim2.new(1,-12,0,14),
				Position = UDim2.new(0,12,0,4),
				Font = Enum.Font.GothamBold,
				Name = "Title"
			}), "TextDark"),
			AddThemeObject(SetProps(MakeElement("Label", "Config: 2992873140", 15), {
				Size = UDim2.new(1,-12,0,16),
				Position = UDim2.new(0,12,0,22),
				Font = Enum.Font.FredokaOne,
				Name = "Content"
			}), "Text"),
			AddThemeObject(MakeElement("Stroke"), "Stroke")
		}), "Second")

		-- Save Button
		local saveBtn = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(1,-16,0,33),
			Position = UDim2.new(0,8,0,55),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "Save", 15), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.FredokaOne,
				Name = "Content"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
				Size = UDim2.new(0,20,0,20),
				Position = UDim2.new(1,-30,0,7),
			}), "TextDark"),
			AddThemeObject(MakeElement("Stroke"), "Stroke"),
			SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
		})

		-- New Config section
		local newConfigLabel = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(1,-16,0,30),
			Position = UDim2.new(0,8,0,98),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "Neue Config", 12), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.GothamBold,
				Name = "Content"
			}), "TextDark"),
			AddThemeObject(MakeElement("Stroke"), "Stroke")
		}), "Second")

		-- Config name input
		local nameInput = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(0.7, -12, 0, 33),
			Position = UDim2.new(0, 8, 0, 138),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "Config name...", 14), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.FredokaOne,
				Name = "Content",
				TextColor3 = Color3.fromRGB(160,160,165)
			}), "Text"),
			AddThemeObject(MakeElement("Stroke"), "Stroke"),
			SetProps(MakeElement("TextBox"), {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Color3.fromRGB(240,240,245),
				PlaceholderText = "Config name...",
				PlaceholderColor3 = Color3.fromRGB(160,160,165),
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				Position = UDim2.new(0,12,0,0),
				Size = UDim2.new(1,-12,1,0)
			})
		})

		-- Create button
		local createBtn = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(0.25, -8, 0, 33),
			Position = UDim2.new(0.7, 4, 0, 138),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "+ Create", 14), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.FredokaOne,
				Name = "Content"
			}), "Text"),
			AddThemeObject(MakeElement("Stroke"), "Stroke"),
			SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
		})

		-- Load ID section
		local loadLabel = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(1,-16,0,30),
			Position = UDim2.new(0,8,0,181),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "Config ID laden", 12), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.GothamBold,
				Name = "Content"
			}), "TextDark"),
			AddThemeObject(MakeElement("Stroke"), "Stroke")
		}), "Second")

		-- Load ID input
		local loadInput = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(0.7, -12, 0, 33),
			Position = UDim2.new(0, 8, 0, 221),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "Load ID...", 14), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.FredokaOne,
				Name = "Content",
				TextColor3 = Color3.fromRGB(160,160,165)
			}), "Text"),
			AddThemeObject(MakeElement("Stroke"), "Stroke"),
			SetProps(MakeElement("TextBox"), {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = Color3.fromRGB(240,240,245),
				PlaceholderText = "Load ID...",
				PlaceholderColor3 = Color3.fromRGB(160,160,165),
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				Position = UDim2.new(0,12,0,0),
				Size = UDim2.new(1,-12,1,0)
			})
		})

		-- Load button
		local loadBtn = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(0.25, -8, 0, 33),
			Position = UDim2.new(0.7, 4, 0, 221),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "+ Load", 14), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.FredokaOne,
				Name = "Content"
			}), "Text"),
			AddThemeObject(MakeElement("Stroke"), "Stroke"),
			SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
		})

		-- Configs list
		local configsLabel = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(1,-16,0,30),
			Position = UDim2.new(0,8,0,264),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "Configs", 12), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.GothamBold,
				Name = "Content"
			}), "TextDark"),
			AddThemeObject(MakeElement("Stroke"), "Stroke")
		}), "Second")

		-- Config item
		local configItem = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255), 0, 5), {
			Size = UDim2.new(1,-16,0,33),
			Position = UDim2.new(0,8,0,304),
			BackgroundTransparency = 0.2,
			Parent = tabItemContainer
		}), {
			AddThemeObject(SetProps(MakeElement("Label", "2992873140", 15), {
				Size = UDim2.new(1,-12,1,0),
				Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.FredokaOne,
				Name = "Content"
			}), "Text"),
			AddThemeObject(MakeElement("Stroke"), "Stroke"),
			SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
		})

		return tabFrame, tabItemContainer
	end

	-- Build both tabs
	local themesTabFrame, themesContainer = BuildThemesTab()
	local configsTabFrame, configsContainer = BuildConfigsTab()

	-- Set themes tab as active initially
	themesTabFrame.Ico.ImageTransparency = 0
	themesTabFrame.Title.TextTransparency = 0
	themesTabFrame.Title.Font = Enum.Font.GothamBlack
	themesTabFrame.Ico.ImageColor3 = Color3.fromRGB(255, 255, 255)
	themesTabFrame.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	themesContainer.Visible = true
	configsContainer.Visible = false

	-- Tab switching
	local function SwitchTab(activeTab, activeContainer, inactiveTab, inactiveContainer)
		-- Update active tab
		TweenService:Create(activeTab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageTransparency = 0,
			ImageColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		TweenService:Create(activeTab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		activeTab.Title.Font = Enum.Font.GothamBlack
		activeContainer.Visible = true

		-- Update inactive tab
		TweenService:Create(inactiveTab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageTransparency = 0.4,
			ImageColor3 = Color3.fromRGB(240, 240, 240)
		}):Play()
		TweenService:Create(inactiveTab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 0.4,
			TextColor3 = Color3.fromRGB(240, 240, 240)
		}):Play()
		inactiveTab.Title.Font = Enum.Font.GothamBlack
		inactiveContainer.Visible = false
	end

	-- Click handlers for tabs
	themesTabFrame.MouseButton1Click:Connect(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6895079853"
		sound.Volume = 0.5
		sound.Parent = game:GetService("SoundService")
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 1)
		SwitchTab(themesTabFrame, themesContainer, configsTabFrame, configsContainer)
	end)

	configsTabFrame.MouseButton1Click:Connect(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6895079853"
		sound.Volume = 0.5
		sound.Parent = game:GetService("SoundService")
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 1)
		SwitchTab(configsTabFrame, configsContainer, themesTabFrame, themesContainer)
	end)

	local TabFunction = {}

	function TabFunction:MakeTab(TabConfig)
		-- This is now handled by the built-in tabs above
		return {}
	end

	return TabFunction
end

return Library
