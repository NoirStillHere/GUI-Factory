-- ==========================================================
-- NoirButtonFactory v2.3 (GitHub Icons Loader)
-- Author: Noir
-- ==========================================================

local NoirButtonFactory = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- ===== CẤU HÌNH GITHUB =====
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/NoirStillHere/GUI-Factory/refs/heads/main/Icons.lua"  -- <-- Thay URL của bạn
local FALLBACK_ICONS = {  -- Fallback nếu không tải được từ GitHub
    ['settings'] = "rbxassetid://14007344336",
    ['lock'] = "rbxassetid://10723434711",
    ['unlock'] = "rbxassetid://10747366027",
    ['home'] = "rbxassetid://10723407389",
    ['user'] = "rbxassetid://10747373176",
    -- Thêm các icon fallback cần thiết
}

-- ===== LOAD ICONS TỪ GITHUB =====
local Icons = nil
local isLoading = false
local loadCallbacks = {}

local function LoadIconsFromGitHub()
    if Icons ~= nil then return Icons end  -- Đã load rồi
    if isLoading then 
        -- Nếu đang load, chờ đến khi xong
        return nil
    end
    
    isLoading = true
    
    -- Tạo task tải từ GitHub
    task.spawn(function()
        local success, result = pcall(function()
            return HttpService:GetAsync(GITHUB_RAW_URL)
        end)
        
        if success then
            local successLoad, loadedIcons = pcall(function()
                -- Chuyển string thành table
                return loadstring(result)()
            end)
            
            if successLoad and type(loadedIcons) == "table" then
                Icons = loadedIcons
                print("✅ Loaded icons from GitHub")
            else
                Icons = FALLBACK_ICONS
                print("⚠️ Failed to parse icons from GitHub, using fallback")
            end
        else
            Icons = FALLBACK_ICONS
            print("⚠️ Failed to load icons from GitHub, using fallback")
        end
        
        isLoading = false
        
        -- Gọi tất cả callback đang chờ
        for _, callback in ipairs(loadCallbacks) do
            callback(Icons)
        end
        loadCallbacks = {}
    end)
    
    return nil  -- Trả về nil vì chưa load xong
end

-- Hàm lấy icon ID từ tên
local function GetIconId(iconName)
    if not iconName then return nil end
    
    -- Nếu đã là ID đầy đủ, trả về luôn
    if string.match(iconName, "^rbxassetid://") then
        return iconName
    end
    
    -- Nếu icon chưa load, load ngay
    if Icons == nil then
        LoadIconsFromGitHub()
        -- Trong lần đầu gọi, có thể chưa có icon, sẽ dùng fallback tạm
        local lowerName = iconName:lower()
        return FALLBACK_ICONS[lowerName] or FALLBACK_ICONS[iconName] or nil
    end
    
    -- Đã có icons, lấy từ bảng
    local lowerName = iconName:lower()
    return Icons[lowerName] or Icons[iconName] or nil
end

-- Hàm chờ icon load xong (cho trường hợp cần chắc chắn)
local function WaitForIcons(callback)
    if Icons ~= nil then
        callback(Icons)
        return
    end
    
    if isLoading then
        table.insert(loadCallbacks, callback)
    else
        LoadIconsFromGitHub()
        table.insert(loadCallbacks, callback)
    end
end

-- ===== SHARED STATE =====
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
        local iconId = GetIconId(tooltipIcon)
        if iconId then
            iconImg = Instance.new("ImageLabel")
            iconImg.Size = UDim2.new(0, 20, 0, 20)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = iconId
            iconImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
            iconImg.ScaleType = Enum.ScaleType.Fit
            iconImg.ZIndex = 101
            iconImg.LayoutOrder = 1
            iconImg.Parent = tooltip
        end
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
                local id = GetIconId(newIconId)
                if id then
                    iconImg.Image = id
                end
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

    -- Lấy icon ID từ tên hoặc ID đầy đủ
    local finalIconId = GetIconId(iconId) or iconId  -- Fallback nếu không tìm thấy

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
    icon.Image = finalIconId or "rbxassetid://14007344336"  -- Fallback icon settings
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

-- ===== TỰ ĐỘNG TẠO LOCK BUTTON =====
local function CreateAutoLockButton()
    if SharedState.lockButtonInstance then return SharedState.lockButtonInstance end

    local player = Players.LocalPlayer
    if not player then return nil end

    -- Kiểm tra xem Lock button đã tồn tại chưa
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

    -- Dùng icon từ GetIconId
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

    local tooltipData = CreateTooltip(btn, {
        TooltipText = "🔓 Unlock - Click to lock",
        TooltipIcon = "unlock",
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
            -- Lock
            btn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            icon.Image = lockIconId
            SharedState.isLocked = true
            tooltipData.SetText("🔒 Locked - Click to unlock")
            tooltipData.SetIcon("lock")
            
            for _, btnData in ipairs(SharedState.allButtons) do
                if btnData and btnData.Button then
                    btnData.Button.Draggable = false
                end
            end
            print("🔒 Locked all buttons")
        else
            -- Unlock
            btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
            icon.Image = unlockIconId
            SharedState.isLocked = false
            tooltipData.SetText("🔓 Unlock - Click to lock")
            tooltipData.SetIcon("unlock")
            
            for _, btnData in ipairs(SharedState.allButtons) do
                if btnData and btnData.Button then
                    btnData.Button.Draggable = true
                end
            end
            print("🔓 Unlocked all buttons")
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
                icon.Image = lockIconId
                SharedState.isLocked = true
                tooltipData.SetText("🔒 Locked - Click to unlock")
                tooltipData.SetIcon("lock")
                for _, btnData in ipairs(SharedState.allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = false
                    end
                end
            else
                btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
                icon.Image = unlockIconId
                SharedState.isLocked = false
                tooltipData.SetText("🔓 Unlock - Click to lock")
                tooltipData.SetIcon("unlock")
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
                tooltipData.SetText("🔒 Locked - Click to unlock")
                tooltipData.SetIcon("lock")
                for _, btnData in ipairs(SharedState.allButtons) do
                    if btnData and btnData.Button then
                        btnData.Button.Draggable = false
                    end
                end
            else
                btn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
                icon.Image = unlockIconId
                SharedState.isLocked = false
                tooltipData.SetText("🔓 Unlock - Click to lock")
                tooltipData.SetIcon("unlock")
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
    icon.Image = GetIconId(config.IconId) or config.IconId
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

-- ===== TỰ ĐỘNG KÍCH HOẠT =====
local function Init()
    if SharedState.isModuleLoaded then return end
    SharedState.isModuleLoaded = true
    
    local player = Players.LocalPlayer
    if player then
        player:WaitForChild("PlayerGui")
        CreateAutoLockButton()
    end
    
    -- Bắt đầu tải icon từ GitHub
    LoadIconsFromGitHub()
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

function NoirButtonFactory.GetIcon(iconName)
    return GetIconId(iconName)
end

function NoirButtonFactory.WaitForIcons(callback)
    WaitForIcons(callback)
end

return NoirButtonFactory
