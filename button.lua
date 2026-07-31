-- ==========================================================
-- NoirButtonFactory v1.8 (LocalStorage Version - Full)
-- Author: Noir
-- Description: Tạo nút nổi, toggle, lock/unlock, resize, auto-save vị trí & kích thước
-- ==========================================================

local NoirButtonFactory = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalStorageService = game:GetService("LocalStorageService")

-- ===== LOCAL STORAGE (Lưu file trên máy Client) =====
local function GetButtonStorage()
    local storage = LocalStorageService:GetJsonStorage("NoirButtonData")
    return storage
end

local function SaveButtonPosition(name, position, size)
    local storage = GetButtonStorage()
    if not storage then return end
    
    local data = storage:GetData() or {}
    data[name] = {
        Position = {
            X = position.X.Scale,
            Y = position.Y.Scale,
            OffsetX = position.X.Offset,
            OffsetY = position.Y.Offset
        },
        Size = {
            Scale = size.X.Scale,
            Offset = size.X.Offset
        }
    }
    storage:SetData(data)
end

local function LoadButtonPosition(name)
    local storage = GetButtonStorage()
    if not storage then return nil end
    
    local data = storage:GetData()
    if data and data[name] then
        return data[name]
    end
    return nil
end

-- ===== INTERNAL STATE =====
local isLocked = false
local allButtons = {}
local lockButtonInstance = nil
local isModuleLoaded = false
local buttonIdCounter = 0

-- ===== RESIZE HANDLE =====
local function CreateResizeHandle(btn)
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 12, 0, 12)
    handle.Position = UDim2.new(1, -12, 1, -12)
    handle.AnchorPoint = Vector2.new(0, 0)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BackgroundTransparency = 0.5
    handle.ZIndex = 20
    handle.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = handle

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://12232156257"  -- Thay icon mũi tên chéo nếu có
    icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 21
    icon.Parent = handle

    local isResizing = false
    local startMousePos = nil
    local startSize = nil
    local minSize = 30

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if isLocked then return end
            isResizing = true
            startMousePos = input.Position
            startSize = btn.Size
            handle.BackgroundTransparency = 0.2
        end
    end)

    handle.InputChanged:Connect(function(input)
        if isResizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startMousePos
            local newSize = UDim2.new(
                0, math.max(startSize.X.Offset + delta.X, minSize),
                0, math.max(startSize.Y.Offset + delta.Y, minSize)
            )
            btn.Size = newSize
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isResizing = false
            handle.BackgroundTransparency = 0.5
            -- Lưu kích thước mới sau khi resize
            local btnData = allButtons[btn.Name]
            if btnData and btnData.SaveData then
                btnData:SaveData()
            end
        end
    end)

    handle.MouseEnter:Connect(function()
        if not isLocked then
            handle.BackgroundTransparency = 0.2
        end
    end)
    
    handle.MouseLeave:Connect(function()
        if not isResizing then
            handle.BackgroundTransparency = 0.5
        end
    end)

    return handle
end

-- ===== INTERNAL FUNCTION =====
local function CreateBaseButton(parent, config, iconId, callback)
    local size = config.Size or 55
    local transparency = config.BackgroundTransparency or 0.3
    local cornerRadius = config.CornerRadius or 10
    local draggable = config.Draggable ~= false
    local showResize = config.ShowResize ~= false
    local buttonId = config.Name or "NoirButton_" .. tostring(buttonIdCounter)
    buttonIdCounter = buttonIdCounter + 1

    -- Load vị trí đã lưu (nếu có)
    local savedData = LoadButtonPosition(buttonId)
    local position = savedData and UDim2.new(
        savedData.Position.X, savedData.Position.OffsetX,
        savedData.Position.Y, savedData.Position.OffsetY
    ) or config.Position

    local savedSize = savedData and UDim2.new(
        savedData.Size.Scale, savedData.Size.Offset,
        savedData.Size.Scale, savedData.Size.Offset
    ) or UDim2.new(0, size, 0, size)

    local btn = Instance.new("TextButton")
    btn.Size = savedSize
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = transparency
    btn.Draggable = draggable and not isLocked
    btn.Text = ""
    btn.ZIndex = 1
    btn.Name = buttonId
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

    -- Resize handle
    local resizeHandle = nil
    if showResize then
        resizeHandle = CreateResizeHandle(btn)
    end

    -- Hàm lưu dữ liệu
    local function SaveData()
        SaveButtonPosition(buttonId, btn.Position, btn.Size)
    end

    -- Lưu khi drag
    local oldPosition = btn.Position
    btn:GetPropertyChangedSignal("Position"):Connect(function()
        if btn.Draggable and not isLocked then
            task.wait(0.5)
            if btn.Position ~= oldPosition then
                SaveData()
                oldPosition = btn.Position
            end
        end
    end)

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

    return btn, connections, resizeHandle, SaveData
end

-- ===== TỰ ĐỘNG TẠO LOCK BUTTON =====
local function CreateAutoLockButton()
    if lockButtonInstance then return lockButtonInstance end

    local player = Players.LocalPlayer
    if not player then return nil end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NoirLockButton"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999999
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Load vị trí lock button
    local savedData = LoadButtonPosition("NoirLockButton")
    local position = savedData and UDim2.new(
        savedData.Position.X, savedData.Position.OffsetX,
        savedData.Position.Y, savedData.Position.OffsetY
    ) or UDim2.new(0.9, 0, 0.9, 0)

    local size = savedData and UDim2.new(
        savedData.Size.Scale, savedData.Size.Offset,
        savedData.Size.Scale, savedData.Size.Offset
    ) or UDim2.new(0, 55, 0, 55)

    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
    btn.BackgroundTransparency = 0.3
    btn.Draggable = true
    btn.Text = ""
    btn.ZIndex = 1
    btn.Name = "NoirLockButton"
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://12232156257"  -- Icon unlock
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 10
    icon.Parent = btn

    -- Hàm lưu vị trí lock button
    local function SaveLockButtonData()
        SaveButtonPosition("NoirLockButton", btn.Position, btn.Size)
    end

    local oldLockPos = btn.Position
    btn:GetPropertyChangedSignal("Position"):Connect(function()
        task.wait(0.5)
        if btn.Position ~= oldLockPos then
            SaveLockButtonData()
            oldLockPos = btn.Position
        end
    end)

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
            icon.Image = "rbxassetid://12232156257"  -- Icon lock
            isLocked = true
            for _, btnData in ipairs(allButtons) do
                if btnData and btnData.Button then
                    btnData.Button.Draggable = false
                    if btnData.ResizeHandle then
                        btnData.ResizeHandle.Visible = false
                    end
                end
            end
            print("🔒 Locked all buttons")
        else
            btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
            icon.Image = "rbxassetid://12232156257"  -- Icon unlock
            isLocked = false
            for _, btnData in ipairs(allButtons) do
                if btnData and btnData.Button then
                    btnData.Button.Draggable = true
                    if btnData.ResizeHandle then
                        btnData.ResizeHandle.Visible = true
                    end
                end
            end
            print("🔓 Unlocked all buttons")
        end
    end))

    lockButtonInstance = {
        Button = btn,
        Gui = gui,
        GetState = function() return state end,
        SetState = function(newState)
            state = newState
            if state then
                btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                icon.Image = "rbxassetid://12232156257"
                isLocked = true
                for _, btnData in ipairs(allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = false
                        if btnData.ResizeHandle then
                            btnData.ResizeHandle.Visible = false
                        end
                    end
                end
            else
                btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
                icon.Image = "rbxassetid://12232156257"
                isLocked = false
                for _, btnData in ipairs(allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = true
                        if btnData.ResizeHandle then
                            btnData.ResizeHandle.Visible = true
                        end
                    end
                end
            end
        end,
        Toggle = function()
            state = not state
            if state then
                btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                icon.Image = "rbxassetid://12232156257"
                isLocked = true
                for _, btnData in ipairs(allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = false
                        if btnData.ResizeHandle then
                            btnData.ResizeHandle.Visible = false
                        end
                    end
                end
            else
                btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
                icon.Image = "rbxassetid://12232156257"
                isLocked = false
                for _, btnData in ipairs(allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = true
                        if btnData.ResizeHandle then
                            btnData.ResizeHandle.Visible = true
                        end
                    end
                end
            end
        end,
        Destroy = function()
            for _, con in ipairs(connections) do con:Disconnect() end
            if gui and gui.Parent then gui:Destroy() end
            lockButtonInstance = nil
        end,
        SetVisible = function(state) if gui then gui.Enabled = state end end,
        SetPosition = function(newPos) if btn then btn.Position = newPos end end,
        SetSize = function(newSize) if btn then btn.Size = UDim2.new(0, newSize, 0, newSize) end end,
        SaveData = SaveLockButtonData,
    }

    return lockButtonInstance
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

    local btn, connections, resizeHandle, SaveData = CreateBaseButton(gui, config, config.IconId, config.Callback)
    
    local btnData = { 
        Button = btn, 
        Gui = gui,
        ResizeHandle = resizeHandle,
        SaveData = SaveData
    }
    table.insert(allButtons, btnData)

    return {
        Button = btn,
        Gui = gui,
        Destroy = function()
            for i, data in ipairs(allButtons) do
                if data == btnData then
                    table.remove(allButtons, i)
                    break
                end
            end
            for _, con in ipairs(connections) do con:Disconnect() end
            if gui and gui.Parent then gui:Destroy() end
        end,
        SetVisible = function(state) if gui then gui.Enabled = state end end,
        SetPosition = function(newPos) 
            if btn then 
                btn.Position = newPos
                SaveData()
            end
        end,
        SetSize = function(newSize) 
            if btn then 
                btn.Size = UDim2.new(0, newSize, 0, newSize)
                SaveData()
            end
        end,
        SetIcon = function(newIconId)
            local icon = btn:FindFirstChildOfClass("ImageLabel")
            if icon then icon.Image = newIconId end
        end,
        IsLocked = function() return isLocked end,
        SetDraggable = function(state)
            if btn then
                btn.Draggable = state and not isLocked
            end
        end,
        SetResizeable = function(state)
            if resizeHandle then
                resizeHandle.Visible = state and not isLocked
            end
        end,
        GetSize = function()
            if btn then
                return btn.Size.X.Offset
            end
            return 0
        end,
        SaveData = SaveData,
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

    -- Load vị trí đã lưu
    local savedData = LoadButtonPosition(name)
    local position = savedData and UDim2.new(
        savedData.Position.X, savedData.Position.OffsetX,
        savedData.Position.Y, savedData.Position.OffsetY
    ) or config.Position

    local savedSize = savedData and UDim2.new(
        savedData.Size.Scale, savedData.Size.Offset,
        savedData.Size.Scale, savedData.Size.Offset
    ) or UDim2.new(0, config.Size or 55, 0, config.Size or 55)

    local btn = Instance.new("TextButton")
    btn.Size = savedSize
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = config.BackgroundTransparency or 0.3
    btn.Draggable = (config.Draggable ~= false) and not isLocked
    btn.Text = ""
    btn.ZIndex = 1
    btn.Name = name
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

    -- Hàm lưu dữ liệu
    local function SaveData()
        SaveButtonPosition(name, btn.Position, btn.Size)
    end

    -- Lưu khi drag
    local oldTogglePos = btn.Position
    btn:GetPropertyChangedSignal("Position"):Connect(function()
        if btn.Draggable and not isLocked then
            task.wait(0.5)
            if btn.Position ~= oldTogglePos then
                SaveData()
                oldTogglePos = btn.Position
            end
        end
    end)

    -- Resize handle
    local showResize = config.ShowResize ~= false
    local resizeHandle = nil
    if showResize then
        resizeHandle = CreateResizeHandle(btn)
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
        ResizeHandle = resizeHandle,
        SaveData = SaveData
    }
    table.insert(allButtons, btnData)

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
            for i, data in ipairs(allButtons) do
                if data == btnData then
                    table.remove(allButtons, i)
                    break
                end
            end
            for _, con in ipairs(connections) do con:Disconnect() end
            if gui and gui.Parent then gui:Destroy() end
        end,
        SetVisible = function(state) if gui then gui.Enabled = state end end,
        SetPosition = function(newPos) 
            if btn then 
                btn.Position = newPos
                SaveData()
            end
        end,
        SetSize = function(newSize) 
            if btn then 
                btn.Size = UDim2.new(0, newSize, 0, newSize)
                SaveData()
            end
        end,
        IsLocked = function() return isLocked end,
        SetDraggable = function(state)
            if btn then
                btn.Draggable = state and not isLocked
            end
        end,
        SetResizeable = function(state)
            if resizeHandle then
                resizeHandle.Visible = state and not isLocked
            end
        end,
        GetSize = function()
            if btn then
                return btn.Size.X.Offset
            end
            return 0
        end,
        SaveData = SaveData,
    }
end

-- ===== TỰ ĐỘNG KÍCH HOẠT =====
local function Init()
    if isModuleLoaded then return end
    isModuleLoaded = true
    
    local player = Players.LocalPlayer
    if player then
        player:WaitForChild("PlayerGui")
        CreateAutoLockButton()
    end
end

Init()

-- ===== PUBLIC API =====
function NoirButtonFactory.GetLockState()
    return isLocked
end

function NoirButtonFactory.SetLockState(state)
    if lockButtonInstance then
        lockButtonInstance.SetState(state)
    else
        isLocked = state
        for _, btnData in ipairs(allButtons) do
            if btnData and btnData.Button then
                btnData.Button.Draggable = not isLocked
                if btnData.ResizeHandle then
                    btnData.ResizeHandle.Visible = not isLocked
                end
            end
        end
    end
end

function NoirButtonFactory.DestroyAllButtons()
    for _, btnData in ipairs(allButtons) do
        if btnData and btnData.Destroy then
            btnData:Destroy()
        end
    end
    allButtons = {}
    if lockButtonInstance then
        lockButtonInstance:Destroy()
        lockButtonInstance = nil
    end
end

function NoirButtonFactory.GetLockButton()
    return lockButtonInstance
end

return NoirButtonFactory
