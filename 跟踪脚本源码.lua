--[[
    追踪玩家脚本 (仅供娱乐)
    功能: 可拖动悬浮窗, 显示玩家列表, 点击玩家跟随, 多种跟随模式
    修复: 脚下模式完全站在脚底
    作者: AI 助手
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- 状态变量
local isFollowing = false
local targetPlayer = nil
local followMode = "背后" -- 模式: 背后, 头上, 脚下, 环绕
local followDistance = 3 -- 背后距离
local orbitRadius = 5 -- 环绕半径
local orbitSpeed = 2 -- 环绕速度 (弧度/秒)
local currentAngle = 0
local isMinimized = false
local isUIVisible = true

-- GUI 创建
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.Name = "PlayerTrackerGUI"
screenGui.ResetOnSpawn = false

-- ===== 主窗口 (缩小版) =====
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 300)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 255)
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- 标题栏
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 22)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "冷川自制_吸附玩家脚本"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamMedium
titleLabel.TextSize = 12
titleLabel.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 22, 1, 0)
minimizeBtn.Position = UDim2.new(1, -44, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamMedium
minimizeBtn.TextSize = 16
minimizeBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 1, 0)
closeBtn.Position = UDim2.new(1, -22, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamMedium
closeBtn.TextSize = 14
closeBtn.Parent = titleBar

-- 玩家列表区域
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -115)
contentFrame.Position = UDim2.new(0, 0, 0, 22)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local scroller = Instance.new("ScrollingFrame")
scroller.Size = UDim2.new(1, 0, 1, 0)
scroller.BackgroundTransparency = 1
scroller.BorderSizePixel = 0
scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
scroller.ScrollBarThickness = 5
scroller.Parent = contentFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = scroller

-- ===== 控制面板 (独立选项选择) =====
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, 0, 0, 93)
controlFrame.Position = UDim2.new(0, 0, 1, -93)
controlFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
controlFrame.BackgroundTransparency = 0.3
controlFrame.BorderSizePixel = 0
controlFrame.Parent = mainFrame

-- 第一行: 模式选择标签
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(1, -8, 0, 16)
modeLabel.Position = UDim2.new(0, 4, 0, 2)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "选择跟随模式:"
modeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
modeLabel.TextSize = 10
modeLabel.Font = Enum.Font.GothamMedium
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = controlFrame

-- 模式按钮容器 (四个独立按钮)
local modeContainer = Instance.new("Frame")
modeContainer.Size = UDim2.new(1, -8, 0, 20)
modeContainer.Position = UDim2.new(0, 4, 0, 20)
modeContainer.BackgroundTransparency = 1
modeContainer.Parent = controlFrame

-- 背后按钮
local behindBtn = Instance.new("TextButton")
behindBtn.Size = UDim2.new(0, 40, 0, 18)
behindBtn.Position = UDim2.new(0, 0, 0, 1)
behindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
behindBtn.Text = "背后"
behindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
behindBtn.Font = Enum.Font.GothamMedium
behindBtn.TextSize = 10
behindBtn.BorderSizePixel = 0
behindBtn.Parent = modeContainer

-- 头上按钮
local headBtn = Instance.new("TextButton")
headBtn.Size = UDim2.new(0, 40, 0, 18)
headBtn.Position = UDim2.new(0, 44, 0, 1)
headBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
headBtn.Text = "头上"
headBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
headBtn.Font = Enum.Font.GothamMedium
headBtn.TextSize = 10
headBtn.BorderSizePixel = 0
headBtn.Parent = modeContainer

-- 脚下按钮
local footBtn = Instance.new("TextButton")
footBtn.Size = UDim2.new(0, 40, 0, 18)
footBtn.Position = UDim2.new(0, 88, 0, 1)
footBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
footBtn.Text = "脚下"
footBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
footBtn.Font = Enum.Font.GothamMedium
footBtn.TextSize = 10
footBtn.BorderSizePixel = 0
footBtn.Parent = modeContainer

-- 环绕按钮
local orbitBtn = Instance.new("TextButton")
orbitBtn.Size = UDim2.new(0, 40, 0, 18)
orbitBtn.Position = UDim2.new(0, 132, 0, 1)
orbitBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
orbitBtn.Text = "环绕"
orbitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
orbitBtn.Font = Enum.Font.GothamMedium
orbitBtn.TextSize = 10
orbitBtn.BorderSizePixel = 0
orbitBtn.Parent = modeContainer

-- 第二行: 参数调节 (分开)
local paramFrame = Instance.new("Frame")
paramFrame.Size = UDim2.new(1, -8, 0, 20)
paramFrame.Position = UDim2.new(0, 4, 0, 44)
paramFrame.BackgroundTransparency = 1
paramFrame.Parent = controlFrame

-- 参数1: 距离/半径
local param1Label = Instance.new("TextLabel")
param1Label.Size = UDim2.new(0, 30, 0, 18)
param1Label.Position = UDim2.new(0, 0, 0, 1)
param1Label.BackgroundTransparency = 1
param1Label.Text = "距离:"
param1Label.TextColor3 = Color3.fromRGB(200, 200, 200)
param1Label.TextSize = 10
param1Label.Font = Enum.Font.GothamMedium
param1Label.Parent = paramFrame

local param1Slider = Instance.new("TextBox")
param1Slider.Size = UDim2.new(0, 45, 0, 18)
param1Slider.Position = UDim2.new(0, 32, 0, 1)
param1Slider.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
param1Slider.Text = "3"
param1Slider.TextColor3 = Color3.fromRGB(255, 255, 255)
param1Slider.Font = Enum.Font.GothamMedium
param1Slider.TextSize = 11
param1Slider.Parent = paramFrame

-- 参数2: 速度 (仅环绕)
local param2Label = Instance.new("TextLabel")
param2Label.Size = UDim2.new(0, 30, 0, 18)
param2Label.Position = UDim2.new(0, 84, 0, 1)
param2Label.BackgroundTransparency = 1
param2Label.Text = "速度:"
param2Label.TextColor3 = Color3.fromRGB(200, 200, 200)
param2Label.TextSize = 10
param2Label.Font = Enum.Font.GothamMedium
param2Label.Parent = paramFrame

local param2Slider = Instance.new("TextBox")
param2Slider.Size = UDim2.new(0, 45, 0, 18)
param2Slider.Position = UDim2.new(0, 116, 0, 1)
param2Slider.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
param2Slider.Text = "2"
param2Slider.TextColor3 = Color3.fromRGB(255, 255, 255)
param2Slider.Font = Enum.Font.GothamMedium
param2Slider.TextSize = 11
param2Slider.Parent = paramFrame

-- 第三行: 状态 + 跟随切换
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -8, 0, 18)
statusFrame.Position = UDim2.new(0, 4, 0, 68)
statusFrame.BackgroundTransparency = 1
statusFrame.Parent = controlFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 80, 0, 18)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "未跟随"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusFrame

local stopFollowBtn = Instance.new("TextButton")
stopFollowBtn.Size = UDim2.new(0, 50, 0, 18)
stopFollowBtn.Position = UDim2.new(1, -50, 0, 0)
stopFollowBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
stopFollowBtn.Text = "停止跟随"
stopFollowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopFollowBtn.Font = Enum.Font.GothamMedium
stopFollowBtn.TextSize = 10
stopFollowBtn.BorderSizePixel = 0
stopFollowBtn.Parent = statusFrame

-- ===== 半关闭小条 =====
local miniBar = Instance.new("Frame")
miniBar.Size = UDim2.new(0, 160, 0, 26)
miniBar.Position = UDim2.new(0, 20, 0, 100)
miniBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
miniBar.BackgroundTransparency = 0.15
miniBar.BorderSizePixel = 1
miniBar.BorderColor3 = Color3.fromRGB(100, 100, 255)
miniBar.Active = true
miniBar.Draggable = true
miniBar.Visible = false
miniBar.Parent = screenGui

local miniLabel = Instance.new("TextLabel")
miniLabel.Size = UDim2.new(1, -30, 1, 0)
miniLabel.BackgroundTransparency = 1
miniLabel.Text = "追踪 (半关)"
miniLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
miniLabel.TextXAlignment = Enum.TextXAlignment.Left
miniLabel.Font = Enum.Font.GothamMedium
miniLabel.TextSize = 12
miniLabel.Parent = miniBar

local restoreBtn = Instance.new("TextButton")
restoreBtn.Size = UDim2.new(0, 26, 1, 0)
restoreBtn.Position = UDim2.new(1, -26, 0, 0)
restoreBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
restoreBtn.Text = "+"
restoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
restoreBtn.Font = Enum.Font.GothamMedium
restoreBtn.TextSize = 16
restoreBtn.Parent = miniBar

-- ===== 模式选择函数 =====
local function setMode(mode)
    followMode = mode
    -- 更新按钮高亮
    local buttons = {behindBtn, headBtn, footBtn, orbitBtn}
    local modes = {"背后", "头上", "脚下", "环绕"}
    for i, btn in ipairs(buttons) do
        if modes[i] == mode then
            btn.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
        else
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        end
    end
    -- 更新参数标签
    if mode == "背后" then
        param1Label.Text = "距离:"
        param2Label.Visible = false
        param2Slider.Visible = false
    elseif mode == "头上" then
        param1Label.Text = "高度:"
        param2Label.Visible = false
        param2Slider.Visible = false
    elseif mode == "脚下" then
        param1Label.Text = "偏移:"
        param2Label.Visible = false
        param2Slider.Visible = false
    elseif mode == "环绕" then
        param1Label.Text = "半径:"
        param2Label.Visible = true
        param2Slider.Visible = true
    end
    -- 更新状态
    if isFollowing and targetPlayer then
        statusLabel.Text = "跟随: " .. targetPlayer.Name .. " (" .. mode .. ")"
    end
end

-- ===== 模式按钮事件 =====
behindBtn.MouseButton1Click:Connect(function() setMode("背后") end)
headBtn.MouseButton1Click:Connect(function() setMode("头上") end)
footBtn.MouseButton1Click:Connect(function() setMode("脚下") end)
orbitBtn.MouseButton1Click:Connect(function() setMode("环绕") end)

-- ===== 停止跟随按钮 =====
stopFollowBtn.MouseButton1Click:Connect(function()
    isFollowing = false
    targetPlayer = nil
    statusLabel.Text = "未跟随"
    -- 更新列表高亮
    updatePlayerList()
end)

-- ===== 更新玩家列表 =====
local function updatePlayerList()
    for _, child in ipairs(scroller:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local playerList = Players:GetPlayers()
    table.sort(playerList, function(a, b) return a.Name < b.Name end)
    
    for _, player in ipairs(playerList) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 20)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            btn.Text = player.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 12
            btn.BorderSizePixel = 0
            btn.Parent = scroller
            
            btn.MouseButton1Click:Connect(function()
                if isFollowing and targetPlayer == player then
                    -- 如果已跟随该玩家，点击取消跟随
                    isFollowing = false
                    targetPlayer = nil
                    statusLabel.Text = "未跟随"
                else
                    -- 跟随该玩家
                    targetPlayer = player
                    isFollowing = true
                    currentAngle = 0
                    statusLabel.Text = "跟随: " .. player.Name .. " (" .. followMode .. ")"
                end
                updatePlayerList()
            end)
            
            if isFollowing and targetPlayer == player then
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
            end
        end
    end
    
    local count = #scroller:GetChildren()
    scroller.CanvasSize = UDim2.new(0, 0, 0, count * 22 + 5)
end

-- ===== 获取玩家脚底位置 =====
local function getPlayerFootPosition(player)
    local char = player.Character
    if not char then return nil end
    
    -- 方法1: 尝试获取HumanoidRootPart的位置，然后向下偏移
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        -- 获取角色的大致高度，从脚底到根部件
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- 使用Humanoid的HipHeight来估算脚底位置
            local footY = rootPart.Position.Y - humanoid.HipHeight
            return Vector3.new(rootPart.Position.X, footY, rootPart.Position.Z)
        else
            -- 如果没有Humanoid，尝试查找腿或脚
            local leftLeg = char:FindFirstChild("Left Leg")
            local rightLeg = char:FindFirstChild("Right Leg")
            if leftLeg and rightLeg then
                local avgY = (leftLeg.Position.Y + rightLeg.Position.Y) / 2
                return Vector3.new(rootPart.Position.X, avgY, rootPart.Position.Z)
            else
                -- 降级方案：从根部件向下偏移2单位
                return Vector3.new(rootPart.Position.X, rootPart.Position.Y - 2, rootPart.Position.Z)
            end
        end
    end
    
    -- 方法2: 尝试查找脚部部件
    local footParts = {"LeftFoot", "RightFoot", "Left Leg", "Right Leg"}
    for _, partName in ipairs(footParts) do
        local part = char:FindFirstChild(partName)
        if part then
            return part.Position
        end
    end
    
    return nil
end

-- ===== 跟随逻辑 (各模式独立) =====
local function followPlayer(dt)
    if not isFollowing or not targetPlayer then return end
    
    local targetChar = targetPlayer.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then return end
    
    local targetRoot = targetChar.HumanoidRootPart
    local myRoot = Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local targetPos = targetRoot.Position
    local targetCFrame = targetRoot.CFrame
    local goalPosition = targetPos
    local lookAtTarget = true
    
    -- ===== 各模式独立处理 =====
    if followMode == "背后" then
        local dist = tonumber(param1Slider.Text) or 3
        local backDir = -targetCFrame.LookVector
        goalPosition = targetPos + backDir * dist + Vector3.new(0, 1, 0)
        
    elseif followMode == "头上" then
        local height = tonumber(param1Slider.Text) or 1.5
        local head = targetChar:FindFirstChild("Head")
        if head then
            goalPosition = head.Position + Vector3.new(0, height, 0)
        else
            goalPosition = targetPos + Vector3.new(0, 3 + height, 0)
        end
        
    elseif followMode == "脚下" then
        -- 修复：完全站在脚底
        local offset = tonumber(param1Slider.Text) or 0
        local footPos = getPlayerFootPosition(targetPlayer)
        
        if footPos then
            -- 站在脚底位置，加上偏移量（前后左右偏移）
            local forwardDir = targetCFrame.LookVector
            local rightDir = targetCFrame.RightVector
            
            -- 计算偏移方向（默认站在脚底正下方，可通过偏移参数调节前后左右）
            if offset ~= 0 then
                -- 使用偏移参数在脚底周围移动
                goalPosition = footPos + forwardDir * offset * 0.5 + rightDir * offset * 0.3
            else
                goalPosition = footPos
            end
            
            -- 确保站在地面上，不穿透
            goalPosition = Vector3.new(goalPosition.X, math.max(goalPosition.Y, 0.5), goalPosition.Z)
            lookAtTarget = false -- 脚底模式下不需要面向目标
        else
            -- 降级方案：站在根部件下方2.5单位
            goalPosition = targetPos + Vector3.new(0, -2.5, 0)
            lookAtTarget = false
        end
        
    elseif followMode == "环绕" then
        local radius = tonumber(param1Slider.Text) or 5
        local speed = tonumber(param2Slider.Text) or 2
        currentAngle = currentAngle + speed * dt
        local xOffset = math.cos(currentAngle) * radius
        local zOffset = math.sin(currentAngle) * radius
        goalPosition = targetPos + Vector3.new(xOffset, 0, zOffset) + Vector3.new(0, 1, 0)
        lookAtTarget = true
    end
    
    -- 应用位置
    if goalPosition then
        goalPosition = Vector3.new(goalPosition.X, math.max(goalPosition.Y, 0.5), goalPosition.Z)
        myRoot.CFrame = CFrame.new(goalPosition)
        
        if lookAtTarget and followMode ~= "脚下" then
            local lookDir = (targetPos - goalPosition).Unit
            if lookDir.Magnitude > 0.1 then
                myRoot.CFrame = CFrame.lookAt(goalPosition, targetPos)
            end
        end
    end
end

-- ===== 窗口控制事件 =====
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    isFollowing = false
    targetPlayer = nil
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    miniBar.Visible = true
    isMinimized = true
end)

restoreBtn.MouseButton1Click:Connect(function()
    miniBar.Visible = false
    mainFrame.Visible = true
    isMinimized = false
end)

-- ===== 初始化 =====
setMode("背后")
updatePlayerList()

-- ===== 刷新列表 (1.5秒) =====
local refreshConnection
refreshConnection = game:GetService("RunService").Stepped:Connect(function()
    if not isMinimized and mainFrame.Visible then
        if not refreshConnection._lastUpdate or tick() - refreshConnection._lastUpdate > 1.5 then
            updatePlayerList()
            refreshConnection._lastUpdate = tick()
        end
    end
end)

-- ===== 跟随更新 =====
local followConnection = RunService.Heartbeat:Connect(function(dt)
    followPlayer(dt)
end)

-- ===== 人物重生 =====
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
end)

-- ===== 清理 =====
screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        if followConnection then followConnection:Disconnect() end
        if refreshConnection then refreshConnection:Disconnect() end
    end
end)

print("追踪玩家脚本已加载 (仅供娱乐) - 脚下模式修复版")