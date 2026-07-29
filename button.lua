local NoirButtonFactory = {}

-- services 
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- func
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

    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = iconId
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
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

    -- Thêm stroke nếu có yêu cầu
    if config.StrokeColor then
        local stroke = Instance.new("UIStroke")
        stroke.Color = config.StrokeColor
        stroke.Thickness = config.StrokeThickness or 2
        stroke.Parent = btn
    end

    -- Trả về btn kèm connections để cleanup sau này
    return btn, connections
end

-- snap
local function SnapToEdge(btn)
    if not btn then return end
    local screenSize = btn.AbsoluteSize
    local btnPos = btn.AbsolutePosition
    local centerX = btnPos.X + (screenSize.X / 2)
    local viewportX = workspace.CurrentCamera.ViewportSize.X

    -- Snap về trái hoặc phải
    local targetX = (centerX < viewportX / 2) and 0 or 1
    btn.Position = UDim2.new(targetX, 0, btn.Position.Y.Scale, btn.Position.Y.Offset)
end

-- api
function NoirButtonFactory.CreateFloatingButton(config)
    -- Kiểm tra tham số bắt buộc
    if not config.Position then error("config.Position is required!") end
    if not config.IconId then error("config.IconId is required!") end
    if not config.Callback then error("config.Callback is required!") end

    local name = config.Name or "NoirFloatingButton"

    -- Lấy PlayerGui (dễ test hơn CoreGui)
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999999
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Tạo nút và lấy connections
    local btn, connections = CreateBaseButton(gui, config, config.IconId, config.Callback)

    -- Trả về API quản lý nút
    return {
        Button = btn,
        Gui = gui,
        -- Gọi hàm snap khi người dùng muốn (chỉ gọi thôi, không tự động)
        SnapToEdge = function()
            SnapToEdge(btn)
        end,
        Destroy = function()
            -- Ngắt kết nối để tránh memory leak
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

return NoirButtonFactory
