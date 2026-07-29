local NoirButtonFactory = {}

-- services
local CoreGui = game:GetService("CoreGui")
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

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = math.max(transparency - 0.1, 0)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = transparency
        }):Play()
    end)

    -- Callback click
    btn.MouseButton1Click:Connect(callback)

    return btn
end

-- ==========================================================
-- PUBLIC API
-- ==========================================================

-- Hàm tạo nút nổi
-- config: Bảng cấu hình
--   Position (UDim2, bắt buộc): Vị trí nút trên màn hình
--   IconId (string, bắt buộc): ID của icon (vd: "rbxassetid://123456")
--   Callback (function, bắt buộc): Hàm chạy khi bấm nút
--   Size (number, optional): Kích thước nút (mặc định 55)
--   BackgroundTransparency (number, optional): Độ mờ nền (0-1, mặc định 0.3)
--   CornerRadius (number, optional): Độ bo góc (mặc định 10)
--   Draggable (boolean, optional): Cho phép kéo thả? (mặc định true)
--   Name (string, optional): Tên của ScreenGui (mặc định "NoirFloatingButton")
--   StrokeColor (Color3, optional): Màu viền (mặc định không có)
--   StrokeThickness (number, optional): Độ dày viền (mặc định 2)
function NoirButtonFactory.CreateFloatingButton(config)
    -- Kiểm tra các tham số bắt buộc
    if not config.Position then error("config.Position is required!") end
    if not config.IconId then error("config.IconId is required!") end
    if not config.Callback then error("config.Callback is required!") end

    local name = config.Name or "NoirFloatingButton"

    -- Tạo ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999999
    gui.Parent = CoreGui

    -- Tạo nút
    local btn = CreateBaseButton(gui, config, config.IconId, config.Callback)

    -- Thêm stroke nếu có yêu cầu
    if config.StrokeColor then
        local stroke = Instance.new("UIStroke")
        stroke.Color = config.StrokeColor
        stroke.Thickness = config.StrokeThickness or 2
        stroke.Parent = btn
    end

    -- Trả về API để quản lý nút
    return {
        Button = btn,
        Gui = gui,
        Destroy = function()
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
