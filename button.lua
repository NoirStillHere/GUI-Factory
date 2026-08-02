-- v2.6 - nothing
local NoirButtonFactory = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local GITHUB_RAW_URL = "https://raw.githubusercontent.com/NoirStillHere/GUI-Factory/refs/heads/main/Icons.lua"
local FALLBACK_ICONS = {
    ['settings'] = "rbxassetid://14007344336",
    ['lock'] = "rbxassetid://10723434711",
    ['unlock'] = "rbxassetid://10747366027",
    ['home'] = "rbxassetid://10723407389",
    ['user'] = "rbxassetid://10747373176",
    ['bell'] = "rbxassetid://10709775704",
    ['cog'] = "rbxassetid://10709810948",
    ['gear'] = "rbxassetid://10709810948",
    ['x'] = "rbxassetid://10747384394",
    ['check'] = "rbxassetid://10709790644",
    ['plus'] = "rbxassetid://10734924532",
    ['minus'] = "rbxassetid://10734896206",
    ['search'] = "rbxassetid://10734943674",
    ['trash'] = "rbxassetid://10747362393",
    ['edit'] = "rbxassetid://10734883598",
    ['save'] = "rbxassetid://10734941499",
    ['download'] = "rbxassetid://10723344270",
    ['upload'] = "rbxassetid://10747366434",
    ['play'] = "rbxassetid://10734923549",
    ['pause'] = "rbxassetid://10734919336",
    ['stop'] = "rbxassetid://74753225999323",
    ['info'] = "rbxassetid://10723415903",
    ['warning'] = "rbxassetid://10723374276",
    ['error'] = "rbxassetid://10709753149",
}

local Icons = nil
local isLoading = false

local function LoadIconsFromGitHub()
    if Icons ~= nil then return Icons end
    if isLoading then return nil end
    
    isLoading = true
    
    task.spawn(function()
        local success, result = pcall(function()
            return HttpService:GetAsync(GITHUB_RAW_URL)
        end)
        
        if success then
            local successLoad, loadedIcons = pcall(function()
                return loadstring(result)()
            end)
            
            if successLoad and type(loadedIcons) == "table" then
                Icons = loadedIcons
            else
                Icons = FALLBACK_ICONS
            end
        else
            Icons = FALLBACK_ICONS
        end
        
        isLoading = false
    end)
    
    return nil
end

local function GetIconId(iconName)
    if not iconName then return nil end
    
    if string.match(iconName, "^rbxassetid://") then
        return iconName
    end
    
    if Icons == nil then
        LoadIconsFromGitHub()
        local lowerName = iconName:lower()
        return FALLBACK_ICONS[lowerName] or FALLBACK_ICONS[iconName] or nil
    end
    
    local lowerName = iconName:lower()
    return Icons[lowerName] or Icons[iconName] or nil
end

local SharedState = {
    isLocked = false,
    allButtons = {},
    lockButtonInstance = nil,
    isModuleLoaded = false,
}

local function CreateBaseButton(parent, config, iconId, callback)
    local size = config.Size or 55
    local transparency = config.BackgroundTransparency or 0.3
    local cornerRadius = config.CornerRadius or 10
    local draggable = config.Draggable ~= false

    local finalIconId = GetIconId(iconId) or iconId

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
    icon.Image = finalIconId or "rbxassetid://14007344336"
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 10
    icon.Parent = btn

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

    return btn, connections
end

local function CreateAutoLockButton()
    if SharedState.lockButtonInstance then return SharedState.lockButtonInstance end

    local player = Players.LocalPlayer
    if not player then return nil end

    local existingGui = player:WaitForChild("PlayerGui"):FindFirstChild("NoirLockButton")
    if existingGui then
        local btn = existingGui:FindFirstChildWhichIsA("TextButton")
        if btn then
            SharedState.lockButtonInstance = {
                Button = btn,
                Gui = existingGui,
            }
            return SharedState.lockButtonInstance
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NoirLockButton"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999999
    gui.Parent = player:WaitForChild("PlayerGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Position = UDim2.new(0.9, -30, 0.9, -340)
    btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
    btn.BackgroundTransparency = 0.3
    btn.Draggable = true
    btn.Text = ""
    btn.ZIndex = 1
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local unlockIconId = GetIconId("unlock") or "rbxassetid://10747366027"
    local lockIconId = GetIconId("lock") or "rbxassetid://10723434711"

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = unlockIconId
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 10
    icon.Parent = btn

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
            icon.Image = lockIconId
            SharedState.isLocked = true
            
            for _, btnData in ipairs(SharedState.allButtons) do
                if btnData and btnData.Button then
                    btnData.Button.Draggable = false
                end
            end
        else
            btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
            icon.Image = unlockIconId
            SharedState.isLocked = false
            
            for _, btnData in ipairs(SharedState.allButtons) do
                if btnData and btnData.Button then
                    btnData.Button.Draggable = true
                end
            end
        end
    end))

    SharedState.lockButtonInstance = {
        Button = btn,
        Gui = gui,
        GetState = function() return state end,
        SetState = function(newState)
            state = newState
            if state then
                btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
                icon.Image = lockIconId
                SharedState.isLocked = true
                for _, btnData in ipairs(SharedState.allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = false
                    end
                end
            else
                btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
                icon.Image = unlockIconId
                SharedState.isLocked = false
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
                icon.Image = lockIconId
                SharedState.isLocked = true
                for _, btnData in ipairs(SharedState.allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = false
                    end
                end
            else
                btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
                icon.Image = unlockIconId
                SharedState.isLocked = false
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
        SetCornerRadius = function(newRadius)
            if corner then
                corner.CornerRadius = UDim.new(0, newRadius)
            end
        end,
    }

    return SharedState.lockButtonInstance
end

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

    local btn, connections = CreateBaseButton(gui, config, config.IconId, config.Callback)
    
    local btnData = { 
        Button = btn, 
        Gui = gui
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
        SetCornerRadius = function(newRadius)
            local corner = btn:FindFirstChildOfClass("UICorner")
            if corner then
                corner.CornerRadius = UDim.new(0, newRadius)
            end
        end,
        SetIcon = function(newIconId)
            local icon = btn:FindFirstChildOfClass("ImageLabel")
            if icon then
                local id = GetIconId(newIconId) or newIconId
                if id then icon.Image = id end
            end
        end,
        IsLocked = function() return SharedState.isLocked end,
        SetDraggable = function(state)
            if btn then
                btn.Draggable = state and not SharedState.isLocked
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
    icon.Image = GetIconId(config.IconId) or config.IconId
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 10
    icon.Parent = btn

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
            if config.OnIconId then icon.Image = GetIconId(config.OnIconId) or config.OnIconId end
            config.OnCallback()
        else
            if config.OffColor then btn.BackgroundColor3 = config.OffColor
            elseif config.OnColor then btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end
            if config.OffIconId then icon.Image = GetIconId(config.OffIconId) or config.OffIconId
            elseif config.OnIconId then icon.Image = GetIconId(config.IconId) or config.IconId end
            config.OffCallback()
        end
    end))

    if defaultState then
        if config.OnColor then btn.BackgroundColor3 = config.OnColor end
        if config.OnIconId then icon.Image = GetIconId(config.OnIconId) or config.OnIconId end
    end

    local btnData = { 
        Button = btn, 
        Gui = gui
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
                if config.OnIconId then icon.Image = GetIconId(config.OnIconId) or config.OnIconId end
                config.OnCallback()
            else
                if config.OffColor then btn.BackgroundColor3 = config.OffColor
                elseif config.OnColor then btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end
                if config.OffIconId then icon.Image = GetIconId(config.OffIconId) or config.OffIconId
                elseif config.OnIconId then icon.Image = GetIconId(config.IconId) or config.IconId end
                config.OffCallback()
            end
        end,
        Toggle = function()
            state = not state
            if state then
                if config.OnColor then btn.BackgroundColor3 = config.OnColor end
                if config.OnIconId then icon.Image = GetIconId(config.OnIconId) or config.OnIconId end
                config.OnCallback()
            else
                if config.OffColor then btn.BackgroundColor3 = config.OffColor
                elseif config.OnColor then btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0) end
                if config.OffIconId then icon.Image = GetIconId(config.OffIconId) or config.OffIconId
                elseif config.OnIconId then icon.Image = GetIconId(config.IconId) or config.IconId end
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
        SetCornerRadius = function(newRadius)
            if corner then
                corner.CornerRadius = UDim.new(0, newRadius)
            end
        end,
        IsLocked = function() return SharedState.isLocked end,
        SetDraggable = function(state)
            if btn then
                btn.Draggable = state and not SharedState.isLocked
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

local function Init()
    if SharedState.isModuleLoaded then return end
    SharedState.isModuleLoaded = true
    
    local player = Players.LocalPlayer
    if player then
        player:WaitForChild("PlayerGui")
        CreateAutoLockButton()
    end
    
    LoadIconsFromGitHub()
end

Init()

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

function NoirButtonFactory.GetIcon(iconName)
    return GetIconId(iconName)
end

return NoirButtonFactory
