-- ==========================================================
-- NoirButtonFactory v1.5
-- Author: Noir (fix ZIndex icon)
-- Description: Module tạo nút nổi hình vuông, nền đen mờ, icon
-- ==========================================================

local NoirButtonFactory = {}

-- ===== SERVICE REFERENCES =====
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- ===== INTERNAL FUNCTION =====
local function CreateBaseButton(parent, config, iconId, callback)
    local size = config.Size or 55
    local transparency = config.BackgroundTransparency or 0.3
    local cornerRadius = config.CornerRadius or 10
    local draggable = config.Draggable ~= false

    -- Tạo nút
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, size, 0, size)
    btn.Position = config.Position
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = transparency
    btn.Draggable = draggable
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = parent

    -- Bo góc
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = btn

    -- Icon (ZIndex cao hơn nút để không bị đè)
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = iconId
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 3 -- ✅ Cao hơn btn (2)
    icon.Parent = btn

    -- Lưu các connection để cleanup
    local connections = {}

    -- Hover effect
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

    -- Callback click
    table.insert(connections, btn.MouseButton1Click:Connect(callback))

    -- Trả về btn kèm connections để cleanup sau này
    return btn, connections
end

-- ==========================================================
-- PUBLIC API - Nút thường
-- ==========================================================
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
    gui.ZIndex = 999 -- ✅ ScreenGui cũng có ZIndex
    gui.Parent = player:WaitForChild("PlayerGui")

    local btn, connections = CreateBaseButton(gui, config, config.IconId, config.Callback)

    return {
        Button = btn,
        Gui = gui,
        Destroy = function()
            for _, con in ipairs(connections) do
                con:Disconnect()
            end
            if gui and gui.Parent then
                gui:Destroy()
            end
        end,
        SetVisible = function(state)
            if gui then
                gui.Enabled = state
            end
        end,
        SetPosition = function(newPos)
            if btn then
                btn.Position = newPos
            end
        end,
        SetSize = function(newSize)
            if btn then
                btn.Size = UDim2.new(0, newSize, 0, newSize)
            end
        end,
        SetIcon = function(newIconId)
            local icon = btn:FindFirstChildOfClass("ImageLabel")
            if icon then
                icon.Image = newIconId
            end
        end
    }
end

-- ==========================================================
-- PUBLIC API - Nút Toggle
-- ==========================================================
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
    gui.ZIndex = 999
    gui.Parent = player:WaitForChild("PlayerGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, config.Size or 55, 0, config.Size or 55)
    btn.Position = config.Position
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = config.BackgroundTransparency or 0.3
    btn.Draggable = config.Draggable ~= false
    btn.Text = ""
    btn.ZIndex = 2
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
    icon.ZIndex = 3 -- ✅ Cao hơn btn
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
            if config.OnColor then
                btn.BackgroundColor3 = config.OnColor
            end
            if config.OnIconId then
                icon.Image = config.OnIconId
            end
            config.OnCallback()
        else
            if config.OffColor then
                btn.BackgroundColor3 = config.OffColor
            elseif config.OnColor then
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
            if config.OffIconId then
                icon.Image = config.OffIconId
            elseif config.OnIconId then
                icon.Image = config.IconId
            end
            config.OffCallback()
        end
    end))

    if defaultState then
        if config.OnColor then
            btn.BackgroundColor3 = config.OnColor
        end
        if config.OnIconId then
            icon.Image = config.OnIconId
        end
    end

    return {
        Button = btn,
        Gui = gui,
        GetState = function()
            return state
        end,
        SetState = function(newState)
            state = newState
            if state then
                if config.OnColor then
                    btn.BackgroundColor3 = config.OnColor
                end
                if config.OnIconId then
                    icon.Image = config.OnIconId
                end
                config.OnCallback()
            else
                if config.OffColor then
                    btn.BackgroundColor3 = config.OffColor
                elseif config.OnColor then
                    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                end
                if config.OffIconId then
                    icon.Image = config.OffIconId
                elseif config.OnIconId then
                    icon.Image = config.IconId
                end
                config.OffCallback()
            end
        end,
        Toggle = function()
            state = not state
            if state then
                if config.OnColor then
                    btn.BackgroundColor3 = config.OnColor
                end
                if config.OnIconId then
                    icon.Image = config.OnIconId
                end
                config.OnCallback()
            else
                if config.OffColor then
                    btn.BackgroundColor3 = config.OffColor
                elseif config.OnColor then
                    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                end
                if config.OffIconId then
                    icon.Image = config.OffIconId
                elseif config.OnIconId then
                    icon.Image = config.IconId
                end
                config.OffCallback()
            end
        end,
        Destroy = function()
            for _, con in ipairs(connections) do
                con:Disconnect()
            end
            if gui and gui.Parent then
                gui:Destroy()
            end
        end,
        SetVisible = function(state)
            if gui then
                gui.Enabled = state
            end
        end,
        SetPosition = function(newPos)
            if btn then
                btn.Position = newPos
            end
        end,
        SetSize = function(newSize)
            if btn then
                btn.Size = UDim2.new(0, newSize, 0, newSize)
            end
        end,
        SetIcon = function(newIconId)
            if icon then
                icon.Image = newIconId
            end
        end
    }
end

return NoirButtonFactory
