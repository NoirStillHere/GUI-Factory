-- ==========================================================
-- NoirButtonFactory v2.1 (Singleton Lock)
-- Author: Noir
-- ==========================================================

local NoirButtonFactory = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ===== SHARED STATE (dùng chung cho mọi lần require) =====
local SharedState = {
    isLocked = false,
    allButtons = {},
    lockButtonInstance = nil,
    isModuleLoaded = false,
}

-- ===== TOOLTIP HELPER =====
local function CreateTooltip(btn, config)
    local tooltipText = config.TooltipText or ""
    local tooltipIcon = config.TooltipIcon or nil
    local showPosition = config.ShowPosition or false
    
    if not tooltipText and not tooltipIcon and not showPosition then return nil end

    -- Tạo tooltip container
    local tooltip = Instance.new("Frame")
    tooltip.Size = UDim2.new(0, 0, 0, 0)
    tooltip.Position = UDim2.new(0, 0, 0, -40)
    tooltip.AnchorPoint = Vector2.new(0.5, 0.5)
    tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tooltip.BackgroundTransparency = 0.7
    tooltip.ZIndex = 100
    tooltip.Visible = false
    tooltip.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = tooltip

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = tooltip

    local iconImg = nil
    if tooltipIcon then
        iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 20, 0, 20)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = tooltipIcon
        iconImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.ZIndex = 101
        iconImg.LayoutOrder = 1
        iconImg.Parent = tooltip
    end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = tooltipText or ""
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 101
    label.LayoutOrder = 2
    label.Parent = tooltip

    local function UpdateTooltipContent()
        local finalText = tooltipText
        
        if showPosition then
            local pos = btn.Position
            local x = math.floor(pos.X.Scale * 1000) / 1000
            local y = math.floor(pos.Y.Scale * 1000) / 1000
            local xOffset = math.floor(pos.X.Offset)
            local yOffset = math.floor(pos.Y.Offset)
            
            local posText = string.format("X: %.3f + %d | Y: %.3f + %d", x, xOffset, y, yOffset)
            
            if finalText and finalText ~= "" then
                finalText = finalText .. "\n" .. posText
            else
                finalText = posText
            end
        end
        
        label.Text = finalText
        
        local textBounds = label.TextBounds
        label.Size = UDim2.new(0, textBounds.X + 4, 0, textBounds.Y + 4)
        
        local totalWidth = textBounds.X + 16
        local totalHeight = math.max(textBounds.Y + 8, 24)
        
        if iconImg then
            totalWidth = totalWidth + 26
            totalHeight = math.max(totalHeight, 24)
        end
        
        tooltip.Size = UDim2.new(0, totalWidth, 0, totalHeight)
        tooltip.Position = UDim2.new(0.5, 0, 0, -totalHeight - 10)
        tooltip.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    btn.MouseEnter:Connect(function()
        if config.ShowTooltip ~= false then
            UpdateTooltipContent()
            tooltip.Visible = true
            tooltip.BackgroundTransparency = 0.7
        end
    end)

    btn.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)

    if showPosition then
        btn:GetPropertyChangedSignal("Position"):Connect(function()
            if tooltip.Visible then
                UpdateTooltipContent()
            end
        end)
    end

    return {
        Instance = tooltip,
        Label = label,
        Icon = iconImg,
        Update = UpdateTooltipContent,
        SetText = function(newText)
            tooltipText = newText
            UpdateTooltipContent()
        end,
        SetIcon = function(newIconId)
            if iconImg then
                iconImg.Image = newIconId
            end
        end,
    }
end

-- ===== INTERNAL FUNCTION =====
local function CreateBaseButton(parent, config, iconId, callback)
    local size = config.Size or 55
    local transparency = config.BackgroundTransparency or 0.3
    local cornerRadius = config.CornerRadius or 10
    local draggable = config.Draggable ~= false
    local showPosition = config.ShowPosition or false

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, size, 0, size)
    btn.Position = config.Position
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = transparency
    btn.Draggable = draggable and not SharedState.isLocked
    btn.Text = ""
    btn.ZIndex = 1
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = btn

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = iconId
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 10
    icon.Parent = btn

    local tooltipData = nil
    if config.TooltipText or config.TooltipIcon or showPosition then
        tooltipData = CreateTooltip(btn, {
            TooltipText = config.TooltipText,
            TooltipIcon = config.TooltipIcon,
            ShowPosition = showPosition,
            ShowTooltip = config.ShowTooltip ~= false,
        })
    end

    local connections = {}

    local function OnHover()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = math.max(transparency - 0.1, 0)
        }):Play()
    end
    local function OnLeave()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = transparency
        }):Play()
    end
    table.insert(connections, btn.MouseEnter:Connect(OnHover))
    table.insert(connections, btn.MouseLeave:Connect(OnLeave))
    table.insert(connections, btn.MouseButton1Click:Connect(callback))

    return btn, connections, tooltipData
end

-- ===== TỰ ĐỘNG TẠO LOCK BUTTON (chỉ tạo 1 lần duy nhất) =====
local function CreateAutoLockButton()
    -- Nếu đã tồn tại, trả về luôn
    if SharedState.lockButtonInstance then return SharedState.lockButtonInstance end

    local player = Players.LocalPlayer
    if not player then return nil end

    -- Kiểm tra xem Lock button đã tồn tại trong PlayerGui chưa
    local existingGui = player:WaitForChild("PlayerGui"):FindFirstChild("NoirLockButton")
    if existingGui then
        -- Nếu đã có, lấy lại instance
        local btn = existingGui:FindFirstChildWhichIsA("TextButton")
        if btn then
            SharedState.lockButtonInstance = {
                Button = btn,
                Gui = existingGui,
                -- Các API khác sẽ được khởi tạo sau...
            }
            return SharedState.lockButtonInstance
        end
    end

    -- Chưa có, tạo mới
    local gui = Instance.new("ScreenGui")
    gui.Name = "NoirLockButton"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999999
    gui.Parent = player:WaitForChild("PlayerGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 55)
    btn.Position = UDim2.new(0.9, 0, 0.9, 0)
    btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
    btn.BackgroundTransparency = 0.3
    btn.Draggable = true
    btn.Text = ""
    btn.ZIndex = 1
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://10747366027"
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 10
    icon.Parent = btn

    local tooltipData = CreateTooltip(btn, {
        TooltipText = "Unlock - Click to lock",
        TooltipIcon = "rbxassetid://10747366027",
        ShowTooltip = true,
    })

    local state = false
    local connections = {}
    local transparency = 0.3

    local function OnHover()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = math.max(transparency - 0.1, 0)
        }):Play()
    end
    local function OnLeave()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = transparency
        }):Play()
    end
    table.insert(connections, btn.MouseEnter:Connect(OnHover))
    table.insert(connections, btn.MouseLeave:Connect(OnLeave))

    table.insert(connections, btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            icon.Image = "rbxassetid://12232156257"
            SharedState.isLocked = true
            tooltipData.SetText("Locked - Click to unlock")
            tooltipData.SetIcon("rbxassetid://10723434711")
            
            for _, btnData in ipairs(SharedState.allButtons) do
                if btnData and btnData.Button then
                    btnData.Button.Draggable = false
                end
            end
        else
            btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
            icon.Image = "rbxassetid://12232156257"
            SharedState.isLocked = false
            tooltipData.SetText("Unlock - Click to lock")
            tooltipData.SetIcon("rbxassetid://10747366027")
            
            for _, btnData in ipairs(SharedState.allButtons) do
                if btnData and btnData.Button then
                    btnData.Button.Draggable = true
                end
            end
        end
    end))

    tooltipData.Update()

    SharedState.lockButtonInstance = {
        Button = btn,
        Gui = gui,
        GetState = function() return state end,
        SetState = function(newState)
            state = newState
            if state then
                btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                icon.Image = "rbxassetid://12232156257"
                SharedState.isLocked = true
                tooltipData.SetText("Locked - Click to unlock")
                tooltipData.SetIcon("rbxassetid://10723434711")
                for _, btnData in ipairs(SharedState.allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = false
                    end
                end
            else
                btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
                icon.Image = "rbxassetid://12232156257"
                SharedState.isLocked = false
                tooltipData.SetText("Unlock - Click to lock")
                tooltipData.SetIcon("rbxassetid://10747366027")
                for _, btnData in ipairs(SharedState.allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = true
                    end
                end
            end
        end,
        Toggle = function()
            state = not state
            if state then
                btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                icon.Image = "rbxassetid://12232156257"
                SharedState.isLocked = true
                tooltipData.SetText("Locked - Click to unlock")
                tooltipData.SetIcon("rbxassetid://10723434711")
                for _, btnData in ipairs(SharedState.allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = false
                    end
                end
            else
                btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
                icon.Image = "rbxassetid://12232156257"
                SharedState.isLocked = false
                tooltipData.SetText("Unlock - Click to lock")
                tooltipData.SetIcon("rbxassetid://10747366027")
                for _, btnData in ipairs(SharedState.allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = true
                    end
                end
            end
        end,
        Destroy = function()
            for _, con in ipairs(connections) do con:Disconnect() end
            if gui and gui.Parent then gui:Destroy() end
            SharedState.lockButtonInstance = nil
        end,
        SetVisible = function(state) if gui then gui.Enabled = state end end,
        SetPosition = function(newPos) if btn then btn.Position = newPos end end,
        SetSize = function(newSize) if btn then btn.Size = UDim2.new(0, newSize, 0, newSize) end end,
    }

    return SharedState.lockButtonInstance
end

-- ===== PUBLIC API - Nút thường =====
function NoirButtonFactory.CreateFloatingButton(config)
    if not config.Position then error("config.Position is required!") end
    if not config.IconId then error("config.IconId is required!") end
    if not config.Callback then error("config.Callback is required!") end

    local name = config.Name or "NoirFloatingButton"
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999999
    gui.Parent = player:WaitForChild("PlayerGui")

    local btn, connections, tooltipData = CreateBaseButton(gui, config, config.IconId, config.Callback)
    
    local btnData = { 
        Button = btn, 
        Gui = gui,
        TooltipData = tooltipData
    }
    table.insert(SharedState.allButtons, btnData)

    return {
        Button = btn,
        Gui = gui,
        Destroy = function()
            for i, data in ipairs(SharedState.allButtons) do
                if data == btnData then
                    table.remove(SharedState.allButtons, i)
                    break
                end
            end
            for _, con in ipairs(connections) do con:Disconnect() end
            if gui and gui.Parent then gui:Destroy() end
        end,
        SetVisible = function(state) if gui then gui.Enabled = state end end,
        SetPosition = function(newPos) if btn then btn.Position = newPos end end,
        SetSize = function(newSize) if btn then btn.Size = UDim2.new(0, newSize, 0, newSize) end end,
        SetIcon = function(newIconId)
            local icon = btn:FindFirstChildOfClass("ImageLabel")
            if icon then icon.Image = newIconId end
        end,
        IsLocked = function() return SharedState.isLocked end,
        SetDraggable = function(state)
            if btn then
                btn.Draggable = state and not SharedState.isLocked
            end
        end,
        SetTooltip = function(newText, newIconId)
            if tooltipData then
                if newText then tooltipData.SetText(newText) end
                if newIconId then tooltipData.SetIcon(newIconId) end
            end
        end,
        ShowTooltip = function(state)
            if tooltipData and tooltipData.Instance then
                tooltipData.Instance.Visible = state and not SharedState.isLocked
            end
        end,
        GetPosition = function()
            if btn then
                return btn.Position
            end
            return UDim2.new(0, 0, 0, 0)
        end,
    }
end

-- ===== PUBLIC API - Nút Toggle =====
function NoirButtonFactory.CreateToggleButton(config)
    if not config.Position then error("config.Position is required!") end
    if not config.IconId then error("config.IconId is required!") end
    if not config.OnCallback then error("config.OnCallback is required!") end
    if not config.OffCallback then error("config.OffCallback is required!") end

    local name = config.Name or "NoirToggleButton"
    local defaultState = config.DefaultState or false

    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999999
    gui.Parent = player:WaitForChild("PlayerGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, config.Size or 55, 0, config.Size or 55)
    btn.Position = config.Position
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = config.BackgroundTransparency or 0.3
    btn.Draggable = (config.Draggable ~= false) and not SharedState.isLocked
    btn.Text = ""
    btn.ZIndex = 1
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, config.CornerRadius or 10)
    corner.Parent = btn

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = config.IconId
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 10
    icon.Parent = btn

    local showPosition = config.ShowPosition or false
    local tooltipData = nil
    if config.TooltipText or config.TooltipIcon or showPosition then
        tooltipData = CreateTooltip(btn, {
            TooltipText = config.TooltipText,
            TooltipIcon = config.TooltipIcon,
            ShowPosition = showPosition,
            ShowTooltip = config.ShowTooltip ~= false,
        })
    end

    local state = defaultState
    local connections = {}
    local transparency = config.BackgroundTransparency or 0.3

    local function OnHover()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = math.max(transparency - 0.1, 0)
        }):Play()
    end
    local function OnLeave()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = transparency
        }):Play()
    end
    table.insert(connections, btn.MouseEnter:Connect(OnHover))
    table.insert(connections, btn.MouseLeave:Connect(OnLeave))

    table.insert(connections, btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            if config.OnColor then btn.BackgroundColor3 = config.OnColor end
            if config.OnIconId then icon.Image = config.OnIconId end
            config.OnCallback()
        else
            if config.OffColor then btn.BackgroundColor3 = config.OffColor
            elseif config.OnColor then btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end
            if config.OffIconId then icon.Image = config.OffIconId
            elseif config.OnIconId then icon.Image = config.IconId end
            config.OffCallback()
        end
    end))

    if defaultState then
        if config.OnColor then btn.BackgroundColor3 = config.OnColor end
        if config.OnIconId then icon.Image = config.OnIconId end
    end

    local btnData = { 
        Button = btn, 
        Gui = gui,
        TooltipData = tooltipData
    }
    table.insert(SharedState.allButtons, btnData)

    return {
        Button = btn,
        Gui = gui,
        GetState = function() return state end,
        SetState = function(newState)
            state = newState
            if state then
                if config.OnColor then btn.BackgroundColor3 = config.OnColor end
                if config.OnIconId then icon.Image = config.OnIconId end
                config.OnCallback()
            else
                if config.OffColor then btn.BackgroundColor3 = config.OffColor
                elseif config.OnColor then btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end
                if config.OffIconId then icon.Image = config.OffIconId
                elseif config.OnIconId then icon.Image = config.IconId end
                config.OffCallback()
            end
        end,
        Toggle = function()
            state = not state
            if state then
                if config.OnColor then btn.BackgroundColor3 = config.OnColor end
                if config.OnIconId then icon.Image = config.OnIconId end
                config.OnCallback()
            else
                if config.OffColor then btn.BackgroundColor3 = config.OffColor
                elseif config.OnColor then btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end
                if config.OffIconId then icon.Image = config.OffIconId
                elseif config.OnIconId then icon.Image = config.IconId end
                config.OffCallback()
            end
        end,
        Destroy = function()
            for i, data in ipairs(SharedState.allButtons) do
                if data == btnData then
                    table.remove(SharedState.allButtons, i)
                    break
                end
            end
            for _, con in ipairs(connections) do con:Disconnect() end
            if gui and gui.Parent then gui:Destroy() end
        end,
        SetVisible = function(state) if gui then gui.Enabled = state end end,
        SetPosition = function(newPos) if btn then btn.Position = newPos end end,
        SetSize = function(newSize) if btn then btn.Size = UDim2.new(0, newSize, 0, newSize) end end,
        IsLocked = function() return SharedState.isLocked end,
        SetDraggable = function(state)
            if btn then
                btn.Draggable = state and not SharedState.isLocked
            end
        end,
        SetTooltip = function(newText, newIconId)
            if tooltipData then
                if newText then tooltipData.SetText(newText) end
                if newIconId then tooltipData.SetIcon(newIconId) end
            end
        end,
        ShowTooltip = function(state)
            if tooltipData and tooltipData.Instance then
                tooltipData.Instance.Visible = state and not SharedState.isLocked
            end
        end,
        GetPosition = function()
            if btn then
                return btn.Position
            end
            return UDim2.new(0, 0, 0, 0)
        end,
    }
end

-- ===== TỰ ĐỘNG KÍCH HOẠT (chỉ tạo Lock 1 lần) =====
local function Init()
    if SharedState.isModuleLoaded then return end
    SharedState.isModuleLoaded = true
    
    local player = Players.LocalPlayer
    if player then
        player:WaitForChild("PlayerGui")
        CreateAutoLockButton()
    end
end

Init()

-- ===== PUBLIC API =====
function NoirButtonFactory.GetLockState()
    return SharedState.isLocked
end

function NoirButtonFactory.SetLockState(state)
    if SharedState.lockButtonInstance then
        SharedState.lockButtonInstance.SetState(state)
    else
        SharedState.isLocked = state
        for _, btnData in ipairs(SharedState.allButtons) do
            if btnData and btnData.Button then
                btnData.Button.Draggable = not SharedState.isLocked
                if btnData.TooltipData and btnData.TooltipData.Instance then
                    btnData.TooltipData.Instance.Visible = not SharedState.isLocked
                end
            end
        end
    end
end

function NoirButtonFactory.DestroyAllButtons()
    for _, btnData in ipairs(SharedState.allButtons) do
        if btnData and btnData.Destroy then
            btnData:Destroy()
        end
    end
    SharedState.allButtons = {}
    if SharedState.lockButtonInstance then
        SharedState.lockButtonInstance:Destroy()
        SharedState.lockButtonInstance = nil
    end
end

function NoirButtonFactory.GetLockButton()
    return SharedState.lockButtonInstance
end

return NoirButtonFactory
