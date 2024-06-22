-- Copyright (c) 2024 Shinji esk.
-- このソフトウェアはMITライセンスのもとで公開されています。
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

-- フォントサイズの定数
local FONT_SIZE = 11

-- プラグインの設定を保存・読み込みするための関数
local function saveSettings(settings)
	plugin:SetSetting("ArrayCopySettings", settings)
end

local function loadSettings()
	return plugin:GetSetting("ArrayCopySettings") or {
		offsetX = 0,
		offsetY = 0,
		offsetZ = 0,
		copyCount = 1,
		selectCopies = false,
		useLocalSpace = true
	}
end

-- UIの作成
local toolbar = plugin:CreateToolbar("配列複製")
local button = toolbar:CreateButton("配列複製", "選択したオブジェクトを配列複製する", "rbxassetid://18155801323")

local widget = plugin:CreateDockWidgetPluginGui(
	"ArrayCopyWidget",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 300, 420, 300, 420)
)
widget.Title = "配列複製"

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
frame.Parent = widget

local function createLabel(text, position, color)
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Position = position
	label.Size = UDim2.new(0, 100, 0, 30)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextSize = FONT_SIZE
	label.Parent = frame
	return label
end

local function createTextBox(position)
	local textBox = Instance.new("TextBox")
	textBox.Position = position
	textBox.Size = UDim2.new(0, 100, 0, 30)
	textBox.BackgroundColor3 = Color3.new(1, 1, 1)
	textBox.TextColor3 = Color3.new(0, 0, 0)
	textBox.TextSize = FONT_SIZE
	textBox.ClearTextOnFocus = false
	textBox.Parent = frame

	-- テキストボックスをクリックしたときに全選択する
	textBox.Focused:Connect(function()
		textBox.SelectionStart = 1
		textBox.CursorPosition = #textBox.Text + 1
	end)

	return textBox
end

-- 座標系ラジオボタンの枠とラベル
local coordinateFrame = Instance.new("Frame")
coordinateFrame.Position = UDim2.new(0, 10, 0, 10)
coordinateFrame.Size = UDim2.new(1, -20, 0, 70)
coordinateFrame.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
coordinateFrame.BorderSizePixel = 1
coordinateFrame.Parent = frame

local coordinateLabel = Instance.new("TextLabel")
coordinateLabel.Text = "座標系："
coordinateLabel.Position = UDim2.new(0, 5, 0, 5)
coordinateLabel.Size = UDim2.new(0, 60, 0, 20)
coordinateLabel.BackgroundTransparency = 1
coordinateLabel.TextColor3 = Color3.new(0, 0, 0)
coordinateLabel.TextXAlignment = Enum.TextXAlignment.Left
coordinateLabel.TextSize = FONT_SIZE
coordinateLabel.Parent = coordinateFrame

-- ラジオボタンの作成
local function createRadioButton(text, position)
	local button = Instance.new("TextButton")
	button.Position = position
	button.Size = UDim2.new(0, 20, 0, 20)
	button.Text = ""
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	button.BorderColor3 = Color3.new(0, 0, 0)
	button.Parent = coordinateFrame

	local label = Instance.new("TextLabel")
	label.Text = text
	label.Position = UDim2.new(0, 30, 0, 0) + position
	label.Size = UDim2.new(0, 100, 0, 20)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(0, 0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextSize = FONT_SIZE
	label.Parent = coordinateFrame

	return button
end

local localSpaceButton = createRadioButton("ローカル座標", UDim2.new(0, 10, 0, 30))
local worldSpaceButton = createRadioButton("ワールド座標", UDim2.new(0, 140, 0, 30))

local function updateRadioButtons(useLocalSpace)
	localSpaceButton.Text = useLocalSpace and "●" or ""
	worldSpaceButton.Text = useLocalSpace and "" or "●"
end

-- オフセットと複製数の枠
local inputFrame = Instance.new("Frame")
inputFrame.Position = UDim2.new(0, 10, 0, 90)
inputFrame.Size = UDim2.new(1, -20, 0, 180)
inputFrame.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
inputFrame.BorderSizePixel = 1
inputFrame.Parent = frame

-- オフセット入力欄の作成
createLabel("X オフセット:", UDim2.new(0, 10, 0, 10), Color3.fromRGB(200, 0, 0)).Parent = inputFrame
local xOffsetBox = createTextBox(UDim2.new(0, 120, 0, 10))
xOffsetBox.Parent = inputFrame

createLabel("Y オフセット:", UDim2.new(0, 10, 0, 50), Color3.fromRGB(0, 160, 0)).Parent = inputFrame
local yOffsetBox = createTextBox(UDim2.new(0, 120, 0, 50))
yOffsetBox.Parent = inputFrame

createLabel("Z オフセット:", UDim2.new(0, 10, 0, 90), Color3.fromRGB(0, 0, 200)).Parent = inputFrame
local zOffsetBox = createTextBox(UDim2.new(0, 120, 0, 90))
zOffsetBox.Parent = inputFrame

createLabel("複製数:", UDim2.new(0, 10, 0, 130), Color3.new(0, 0, 0)).Parent = inputFrame
local copyCountBox = createTextBox(UDim2.new(0, 120, 0, 130))
copyCountBox.Parent = inputFrame

-- チェックボックスの追加
local selectCopiesCheckbox = Instance.new("TextButton")
selectCopiesCheckbox.Position = UDim2.new(0, 10, 0, 280)
selectCopiesCheckbox.Size = UDim2.new(0, 20, 0, 20)
selectCopiesCheckbox.Text = ""
selectCopiesCheckbox.BackgroundColor3 = Color3.new(1, 1, 1)
selectCopiesCheckbox.Parent = frame

local selectCopiesLabel = Instance.new("TextLabel")
selectCopiesLabel.Text = "複製したオブジェクトを選択する"
selectCopiesLabel.Position = UDim2.new(0, 40, 0, 280)
selectCopiesLabel.Size = UDim2.new(0, 200, 0, 20)
selectCopiesLabel.TextXAlignment = Enum.TextXAlignment.Left
selectCopiesLabel.BackgroundTransparency = 1
selectCopiesLabel.TextColor3 = Color3.new(0, 0, 0)
selectCopiesLabel.TextSize = FONT_SIZE
selectCopiesLabel.Parent = frame

local executeButton = Instance.new("TextButton")
executeButton.Text = "実行"
executeButton.Position = UDim2.new(0.5, -50, 1, -50)
executeButton.Size = UDim2.new(0, 100, 0, 30)
executeButton.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
executeButton.TextColor3 = Color3.new(0, 0, 0)
executeButton.TextSize = FONT_SIZE
executeButton.Parent = frame

-- ダイアログの作成
local function createDialog(message, buttonTexts, callbacks)
	local dialogBackground = Instance.new("Frame")
	dialogBackground.Size = UDim2.new(1, 0, 1, 0)
	dialogBackground.BackgroundColor3 = Color3.new(0, 0, 0)
	dialogBackground.BackgroundTransparency = 0.5
	dialogBackground.Parent = widget

	local dialogFrame = Instance.new("Frame")
	dialogFrame.Size = UDim2.new(0, 300, 0, 150)
	dialogFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
	dialogFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	dialogFrame.BorderSizePixel = 2
	dialogFrame.Parent = dialogBackground

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Text = message
	messageLabel.Size = UDim2.new(1, -20, 1, -60)
	messageLabel.Position = UDim2.new(0, 10, 0, 10)
	messageLabel.TextWrapped = true
	messageLabel.TextSize = FONT_SIZE
	messageLabel.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
	messageLabel.Parent = dialogFrame

	for i, buttonText in ipairs(buttonTexts) do
		local button = Instance.new("TextButton")
		button.Text = buttonText
		button.Size = UDim2.new(0, 100, 0, 30)
		if #buttonTexts == 2 then
			-- 2つのボタンがある場合、左右に配置
			button.Position = UDim2.new(i == 1 and 0.25 or 0.75, -50, 1, -40)
		else
			-- それ以外の場合は均等に配置
			button.Position = UDim2.new((i - 1) / (#buttonTexts + 1) + 1 / (#buttonTexts + 1), -50, 1, -40)
		end
		button.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
		button.TextSize = FONT_SIZE
		button.Parent = dialogFrame

		button.MouseButton1Click:Connect(function()
			dialogBackground:Destroy()
			if callbacks[i] then
				callbacks[i]()
			end
		end)
	end

	return dialogBackground
end

-- 設定の読み込みと適用
local settings = loadSettings()
xOffsetBox.Text = tostring(settings.offsetX)
yOffsetBox.Text = tostring(settings.offsetY)
zOffsetBox.Text = tostring(settings.offsetZ)
copyCountBox.Text = tostring(settings.copyCount)
selectCopiesCheckbox.Text = settings.selectCopies and "✓" or ""
updateRadioButtons(settings.useLocalSpace)

-- 配列複製関数
local function arrayClone(offset, count, selectCopies, useLocalSpace)
	local selectedObjects = Selection:Get()
	if #selectedObjects == 0 then
		createDialog("ひとつ以上のオブジェクトを選択してから実行してください。", {"OK"}, {})
		return
	end

	ChangeHistoryService:SetWaypoint("配列複製前")

	local newObjects = {}
	for _, obj in ipairs(selectedObjects) do
		if obj:IsA("BasePart") or obj:IsA("Model") then
			local objectCFrame = obj:IsA("Model") and obj:GetPivot() or obj.CFrame
			for i = 1, count do
				local clone = obj:Clone()
				clone.Parent = obj.Parent

				local offsetVector = Vector3.new(offset.X * i, offset.Y * i, offset.Z * i)

				if useLocalSpace then
					clone:PivotTo(objectCFrame * CFrame.new(offsetVector))
				else
					-- ワールド座標系での計算
					clone:PivotTo(objectCFrame + offsetVector)
				end

				table.insert(newObjects, clone)
			end
		end
	end

	ChangeHistoryService:SetWaypoint("配列複製後")

	if selectCopies then
		for _, obj in ipairs(selectedObjects) do
			table.insert(newObjects, obj)
		end
		Selection:Set(newObjects)
	end
end

-- イベント接続
localSpaceButton.MouseButton1Click:Connect(function()
	settings.useLocalSpace = true
	updateRadioButtons(true)
	saveSettings(settings)
end)

worldSpaceButton.MouseButton1Click:Connect(function()
	settings.useLocalSpace = false
	updateRadioButtons(false)
	saveSettings(settings)
end)

selectCopiesCheckbox.MouseButton1Click:Connect(function()
	settings.selectCopies = not settings.selectCopies
	selectCopiesCheckbox.Text = settings.selectCopies and "✓" or ""
	saveSettings(settings)
end)

button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

executeButton.MouseButton1Click:Connect(function()
	local offsetX = tonumber(xOffsetBox.Text) or 0
	local offsetY = tonumber(yOffsetBox.Text) or 0
	local offsetZ = tonumber(zOffsetBox.Text) or 0
	local copyCount = math.max(1, math.floor(tonumber(copyCountBox.Text) or 1))

	if offsetX == 0 and offsetY == 0 and offsetZ == 0 then
		createDialog(
			string.format("オフセット値がすべて0です。同じ位置に%d個のオブジェクトを複製してよろしいですか？", copyCount),
			{"複製する", "キャンセル"},
			{
				function()
					arrayClone(Vector3.new(offsetX, offsetY, offsetZ), copyCount, settings.selectCopies, settings.useLocalSpace)
				end,
				function() end
			}
		)
	else
		arrayClone(Vector3.new(offsetX, offsetY, offsetZ), copyCount, settings.selectCopies, settings.useLocalSpace)
	end

	-- 設定の保存
	settings.offsetX = offsetX
	settings.offsetY = offsetY
	settings.offsetZ = offsetZ
	settings.copyCount = copyCount
	saveSettings(settings)
end)

-- プラグインの終了処理
plugin.Unloading:Connect(function()
	widget:Destroy()
	print("配列複製プラグインがアンロードされました")
end)
