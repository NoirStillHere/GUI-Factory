-- ==========================================================
-- NoirButtonFactory v1.9
-- Author: Noir (nâng cấp Settings Panel: quản lý nút + config)
-- ==========================================================

local NoirButtonFactory = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ===== INTERNAL STATE =====
local isLocked = false
local allButtons = {}
local lockButtonInstance = nil
local settingsButtonInstance = nil
local settingsPanelInstance = nil
local isModuleLoaded = false
local buttonCounter = 0
local savedConfigs = {}  -- Lưu config của các nút

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
    icon.Image = "rbxassetid://12232156257"
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
        end
    end)

    handle.MouseEnter:Connect(function()
        if not isLocked then handle.BackgroundTransparency = 0.2 end
    end)
    
    handle.MouseLeave:Connect(function()
        if not isResizing then handle.BackgroundTransparency = 0.5 end
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
    local buttonId = config.Id or "btn_" .. tostring(buttonCounter)
    buttonCounter = buttonCounter + 1

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, size, 0, size)
    btn.Position = config.Position
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = transparency
    btn.Draggable = draggable and not isLocked
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

    local resizeHandle = nil
    if showResize then
        resizeHandle = CreateResizeHandle(btn)
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

    return btn, connections, resizeHandle, buttonId
end

-- ===== SETTINGS PANEL =====
local function CreateSettingsPanel()
    if settingsPanelInstance then return settingsPanelInstance end

    local player = Players.LocalPlayer
    if not player then return nil end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NoirSettingsPanel"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999998
    gui.Parent = player:WaitForChild("PlayerGui")

    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 0
    overlay.Parent = gui

    -- Main panel
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 600, 0, 500)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    panel.BackgroundTransparency = 0.1
    panel.ZIndex = 1
    panel.Parent = gui

    -- Bo góc panel
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 15)
    panelCorner.Parent = panel

    -- Tiêu đề
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚙️ Settings Manager"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 2
    title.Parent = panel

    -- Nút đóng
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 2
    closeBtn.Parent = panel

    -- Tabs container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(1, 0, 0, 35)
    tabsContainer.Position = UDim2.new(0, 0, 0, 40)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.ZIndex = 2
    tabsContainer.Parent = panel

    -- Tab Main
    local mainTab = Instance.new("TextButton")
    mainTab.Size = UDim2.new(0.5, 0, 1, 0)
    mainTab.Position = UDim2.new(0, 0, 0, 0)
    mainTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    mainTab.BackgroundTransparency = 0.3
    mainTab.Text = "📋 Main (Manage)"
    mainTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainTab.TextSize = 16
    mainTab.Font = Enum.Font.GothamBold
    mainTab.ZIndex = 2
    mainTab.Parent = tabsContainer

    -- Tab Config
    local configTab = Instance.new("TextButton")
    configTab.Size = UDim2.new(0.5, 0, 1, 0)
    configTab.Position = UDim2.new(0.5, 0, 0, 0)
    configTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    configTab.BackgroundTransparency = 0.3
    configTab.Text = "⚙️ Config (Save/Load)"
    configTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    configTab.TextSize = 16
    configTab.Font = Enum.Font.GothamBold
    configTab.ZIndex = 2
    configTab.Parent = tabsContainer

    -- Tab content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -20, 1, -100)
    contentContainer.Position = UDim2.new(0, 10, 0, 80)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ZIndex = 2
    contentContainer.Parent = panel

    -- ===== MAIN TAB CONTENT =====
    local mainContent = Instance.new("ScrollingFrame")
    mainContent.Size = UDim2.new(1, 0, 1, 0)
    mainContent.Position = UDim2.new(0, 0, 0, 0)
    mainContent.BackgroundTransparency = 1
    mainContent.BorderSizePixel = 0
    mainContent.ScrollBarThickness = 5
    mainContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    mainContent.ZIndex = 3
    mainContent.Parent = contentContainer

    -- ===== CONFIG TAB CONTENT =====
    local configContent = Instance.new("ScrollingFrame")
    configContent.Size = UDim2.new(1, 0, 1, 0)
    configContent.Position = UDim2.new(0, 0, 0, 0)
    configContent.BackgroundTransparency = 1
    configContent.BorderSizePixel = 0
    configContent.ScrollBarThickness = 5
    configContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    configContent.ZIndex = 3
    configContent.Visible = false
    configContent.Parent = contentContainer

    -- ===== HÀM REFRESH MAIN TAB =====
    local function RefreshMainTab()
        mainContent:ClearAllChildren()
        
        for i, btnData in ipairs(allButtons) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 45)
            row.Position = UDim2.new(0, 0, 0, (i-1) * 47)
            row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            row.BackgroundTransparency = 0.5
            row.ZIndex = 4
            row.Parent = mainContent

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 5)
            rowCorner.Parent = row

            -- Tên nút
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = btnData.Name or "Button " .. i
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.ZIndex = 5
            nameLabel.Parent = row

            -- Kích thước
            local sizeLabel = Instance.new("TextLabel")
            sizeLabel.Size = UDim2.new(0.2, 0, 1, 0)
            sizeLabel.Position = UDim2.new(0.3, 0, 0, 0)
            sizeLabel.BackgroundTransparency = 1
            sizeLabel.Text = "Size: " .. math.round(btnData.Button.Size.X.Offset) .. "px"
            sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            sizeLabel.TextSize = 12
            sizeLabel.Font = Enum.Font.Gotham
            sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
            sizeLabel.ZIndex = 5
            sizeLabel.Parent = row

            -- Vị trí
            local posLabel = Instance.new("TextLabel")
            posLabel.Size = UDim2.new(0.2, 0, 1, 0)
            posLabel.Position = UDim2.new(0.5, 0, 0, 0)
            posLabel.BackgroundTransparency = 1
            posLabel.Text = string.format("Pos: (%.1f, %.1f)", 
                btnData.Button.Position.X.Scale * 100, 
                btnData.Button.Position.Y.Scale * 100)
            posLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            posLabel.TextSize = 12
            posLabel.Font = Enum.Font.Gotham
            posLabel.TextXAlignment = Enum.TextXAlignment.Left
            posLabel.ZIndex = 5
            posLabel.Parent = row

            -- Nút ẩn/hiện
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 40, 0, 30)
            toggleBtn.Position = UDim2.new(0.75, 0, 0.5, 0)
            toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
            toggleBtn.BackgroundTransparency = 0.2
            toggleBtn.Text = "👁"
            toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleBtn.TextSize = 14
            toggleBtn.Font = Enum.Font.GothamBold
            toggleBtn.ZIndex = 5
            toggleBtn.Parent = row

            -- Nút xóa
            local deleteBtn = Instance.new("TextButton")
            deleteBtn.Size = UDim2.new(0, 40, 0, 30)
            deleteBtn.Position = UDim2.new(0.85, 0, 0.5, 0)
            deleteBtn.AnchorPoint = Vector2.new(0, 0.5)
            deleteBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            deleteBtn.BackgroundTransparency = 0.2
            deleteBtn.Text = "🗑"
            deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            deleteBtn.TextSize = 14
            deleteBtn.Font = Enum.Font.GothamBold
            deleteBtn.ZIndex = 5
            deleteBtn.Parent = row

            -- Nút đổi tên
            local renameBtn = Instance.new("TextButton")
            renameBtn.Size = UDim2.new(0, 40, 0, 30)
            renameBtn.Position = UDim2.new(0.95, 0, 0.5, 0)
            renameBtn.AnchorPoint = Vector2.new(1, 0.5)
            renameBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
            renameBtn.BackgroundTransparency = 0.2
            renameBtn.Text = "✏️"
            renameBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            renameBtn.TextSize = 14
            renameBtn.Font = Enum.Font.GothamBold
            renameBtn.ZIndex = 5
            renameBtn.Parent = row

            -- Sự kiện ẩn/hiện
            local visible = true
            toggleBtn.MouseButton1Click:Connect(function()
                visible = not visible
                btnData.Gui.Enabled = visible
                toggleBtn.BackgroundColor3 = visible and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(200, 200, 200)
                toggleBtn.Text = visible and "👁" or "🚫"
            end)

            -- Sự kiện xóa
            deleteBtn.MouseButton1Click:Connect(function()
                if btnData.Destroy then
                    btnData:Destroy()
                    RefreshMainTab()
                end
            end)

            -- Sự kiện đổi tên
            renameBtn.MouseButton1Click:Connect(function()
                local newName = "Button_" .. os.time()  -- Tạo tên mới
                btnData.Name = newName
                nameLabel.Text = newName
                -- Ở đây bạn có thể mở input box để nhập tên mới
            end)
        end
    end

    -- ===== HÀM REFRESH CONFIG TAB =====
    local function RefreshConfigTab()
        configContent:ClearAllChildren()
        
        -- Tiêu đề
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 30)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "📁 Button Configurations"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 16
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.ZIndex = 5
        titleLabel.Parent = configContent

        -- Nút Save All
        local saveAllBtn = Instance.new("TextButton")
        saveAllBtn.Size = UDim2.new(0, 120, 0, 30)
        saveAllBtn.Position = UDim2.new(0, 10, 0, 35)
        saveAllBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        saveAllBtn.BackgroundTransparency = 0.2
        saveAllBtn.Text = "💾 Save All"
        saveAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        saveAllBtn.TextSize = 14
        saveAllBtn.Font = Enum.Font.GothamBold
        saveAllBtn.ZIndex = 5
        saveAllBtn.Parent = configContent

        -- Nút Load All
        local loadAllBtn = Instance.new("TextButton")
        loadAllBtn.Size = UDim2.new(0, 120, 0, 30)
        loadAllBtn.Position = UDim2.new(0, 140, 0, 35)
        loadAllBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
        loadAllBtn.BackgroundTransparency = 0.2
        loadAllBtn.Text = "📂 Load All"
        loadAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        loadAllBtn.TextSize = 14
        loadAllBtn.Font = Enum.Font.GothamBold
        loadAllBtn.ZIndex = 5
        loadAllBtn.Parent = configContent

        -- Nút Auto Config
        local autoBtn = Instance.new("TextButton")
        autoBtn.Size = UDim2.new(0, 120, 0, 30)
        autoBtn.Position = UDim2.new(0, 270, 0, 35)
        autoBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 80)
        autoBtn.BackgroundTransparency = 0.2
        autoBtn.Text = "🔧 Auto Config"
        autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        autoBtn.TextSize = 14
        autoBtn.Font = Enum.Font.GothamBold
        autoBtn.ZIndex = 5
        autoBtn.Parent = configContent

        -- Sự kiện Save All
        saveAllBtn.MouseButton1Click:Connect(function()
            savedConfigs = {}
            for i, btnData in ipairs(allButtons) do
                savedConfigs[btnData.Id] = {
                    Name = btnData.Name or "Button " .. i,
                    Position = btnData.Button.Position,
                    Size = btnData.Button.Size,
                    Visible = btnData.Gui.Enabled,
                    IconId = btnData.Config.IconId,
                    Type = btnData.Config.Type or "Floating"
                }
            end
            print("✅ Saved configs:", savedConfigs)
            -- Ở đây bạn có thể lưu vào file hoặc HttpService
        end)

        -- Sự kiện Load All
        loadAllBtn.MouseButton1Click:Connect(function()
            for id, config in pairs(savedConfigs) do
                for _, btnData in ipairs(allButtons) do
                    if btnData.Id == id then
                        btnData.Name = config.Name
                        btnData.Button.Position = config.Position
                        btnData.Button.Size = config.Size
                        btnData.Gui.Enabled = config.Visible
                        -- Cập nhật icon nếu cần
                        break
                    end
                end
            end
            RefreshConfigTab()
            RefreshMainTab()
            print("✅ Loaded configs")
        end)

        -- Sự kiện Auto Config (tự động chạy khi load game)
        autoBtn.MouseButton1Click:Connect(function()
            -- Lưu config
            savedConfigs = {}
            for i, btnData in ipairs(allButtons) do
                savedConfigs[btnData.Id] = {
                    Name = btnData.Name or "Button " .. i,
                    Position = btnData.Button.Position,
                    Size = btnData.Button.Size,
                    Visible = btnData.Gui.Enabled,
                    IconId = btnData.Config.IconId,
                    Type = btnData.Config.Type or "Floating"
                }
            end
            print("✅ Auto Config saved")
            -- Lưu vào file để tự động load khi game chạy lại
            -- Ở đây bạn có thể dùng HttpService hoặc WriteFile
        end)

        -- Danh sách config từng nút
        local yOffset = 75
        for i, btnData in ipairs(allButtons) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 60)
            row.Position = UDim2.new(0, 0, 0, yOffset + (i-1) * 65)
            row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            row.BackgroundTransparency = 0.5
            row.ZIndex = 4
            row.Parent = configContent

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 5)
            rowCorner.Parent = row

            -- ID
            local idLabel = Instance.new("TextLabel")
            idLabel.Size = UDim2.new(0.2, 0, 0.4, 0)
            idLabel.Position = UDim2.new(0, 10, 0, 5)
            idLabel.BackgroundTransparency = 1
            idLabel.Text = "ID: " .. (btnData.Id or "unknown")
            idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            idLabel.TextSize = 12
            idLabel.Font = Enum.Font.Gotham
            idLabel.TextXAlignment = Enum.TextXAlignment.Left
            idLabel.ZIndex = 5
            idLabel.Parent = row

            -- Tên
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.2, 0, 0.4, 0)
            nameLabel.Position = UDim2.new(0.2, 0, 0, 5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = "Name: " .. (btnData.Name or "Button " .. i)
            nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            nameLabel.TextSize = 12
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.ZIndex = 5
            nameLabel.Parent = row

            -- Vị trí
            local posLabel = Instance.new("TextLabel")
            posLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
            posLabel.Position = UDim2.new(0.4, 0, 0, 5)
            posLabel.BackgroundTransparency = 1
            posLabel.Text = string.format("Pos: (%.2f, %.2f)", 
                btnData.Button.Position.X.Scale, 
                btnData.Button.Position.Y.Scale)
            posLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            posLabel.TextSize = 12
            posLabel.Font = Enum.Font.Gotham
            posLabel.TextXAlignment = Enum.TextXAlignment.Left
            posLabel.ZIndex = 5
            posLabel.Parent = row

            -- Kích thước
            local sizeLabel = Instance.new("TextLabel")
            sizeLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
            sizeLabel.Position = UDim2.new(0.7, 0, 0, 5)
            sizeLabel.BackgroundTransparency = 1
            sizeLabel.Text = "Size: " .. math.round(btnData.Button.Size.X.Offset) .. "px"
            sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            sizeLabel.TextSize = 12
            sizeLabel.Font = Enum.Font.Gotham
            sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
            sizeLabel.ZIndex = 5
            sizeLabel.Parent = row

            -- Nút Export từng nút
            local exportBtn = Instance.new("TextButton")
            exportBtn.Size = UDim2.new(0, 60, 0, 25)
            exportBtn.Position = UDim2.new(1, -70, 0, 30)
            exportBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
            exportBtn.BackgroundTransparency = 0.2
            exportBtn.Text = "Export"
            exportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            exportBtn.TextSize = 10
            exportBtn.Font = Enum.Font.GothamBold
            exportBtn.ZIndex = 5
            exportBtn.Parent = row

            exportBtn.MouseButton1Click:Connect(function()
                local configData = {
                    Id = btnData.Id,
                    Name = btnData.Name or "Button " .. i,
                    Position = btnData.Button.Position,
                    Size = btnData.Button.Size,
                    Visible = btnData.Gui.Enabled,
                    IconId = btnData.Config.IconId,
                    Type = btnData.Config.Type or "Floating"
                }
                print("📤 Exported config:", configData)
            end)
        end
    end

    -- ===== TAB SWITCHING =====
    local activeTab = "main"
    mainTab.MouseButton1Click:Connect(function()
        activeTab = "main"
        mainTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        configTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        mainTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        configTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        mainContent.Visible = true
        configContent.Visible = false
        RefreshMainTab()
    end)

    configTab.MouseButton1Click:Connect(function()
        activeTab = "config"
        configTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        mainTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        configTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        mainTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        mainContent.Visible = false
        configContent.Visible = true
        RefreshConfigTab()
    end)

    -- Close button
    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    -- Click outside to close
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            gui.Enabled = false
        end
    end)

    -- Khởi tạo tab main
    RefreshMainTab()

    settingsPanelInstance = {
        Gui = gui,
        Panel = panel,
        Show = function()
            RefreshMainTab()
            RefreshConfigTab()
            gui.Enabled = true
        end,
        Hide = function()
            gui.Enabled = false
        end,
        Toggle = function()
            gui.Enabled = not gui.Enabled
            if gui.Enabled then
                RefreshMainTab()
                RefreshConfigTab()
            end
        end,
        Destroy = function()
            if gui and gui.Parent then gui:Destroy() end
            settingsPanelInstance = nil
        end,
        Refresh = function()
            RefreshMainTab()
            RefreshConfigTab()
        end
    }

    return settingsPanelInstance
end

-- ===== SETTINGS BUTTON =====
local function CreateSettingsButton()
    if settingsButtonInstance then return settingsButtonInstance end

    local player = Players.LocalPlayer
    if not player then return nil end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NoirSettingsButton"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999999
    gui.Parent = player:WaitForChild("PlayerGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 45)
    btn.Position = UDim2.new(0.9, 0, 0.8, 0)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
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
    icon.Image = "rbxassetid://12232156257"  -- Icon bánh răng
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 10
    icon.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local panel = CreateSettingsPanel()
        if panel then
            panel:Toggle()
        end
    end)

    settingsButtonInstance = {
        Button = btn,
        Gui = gui,
        Destroy = function()
            if gui and gui.Parent then gui:Destroy() end
            settingsButtonInstance = nil
        end,
        SetVisible = function(state)
            if gui then gui.Enabled = state end
        end
    }

    return settingsButtonInstance
end

-- ===== LOCK BUTTON =====
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
    icon.Image = "rbxassetid://12232156257"
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

    local btn, connections, resizeHandle, btnId = CreateBaseButton(gui, config, config.IconId, config.Callback)
    
    local btnData = { 
        Button = btn, 
        Gui = gui,
        ResizeHandle = resizeHandle,
        Id = btnId,
        Name = config.Name or "Button " .. tostring(buttonCounter),
        Config = config,
        Type = "Floating",
        Destroy = nil  -- Sẽ gán sau
    }

    -- Hàm Destroy riêng
    local function DestroySelf()
        for i, data in ipairs(allButtons) do
            if data == btnData then
                table.remove(allButtons, i)
                break
            end
        end
        for _, con in ipairs(connections) do con:Disconnect() end
        if gui and gui.Parent then gui:Destroy() end
        if settingsPanelInstance then
            settingsPanelInstance:Refresh()
        end
    end
    btnData.Destroy = DestroySelf

    table.insert(allButtons, btnData)

    if settingsPanelInstance then
        settingsPanelInstance:Refresh()
    end

    return {
        Button = btn,
        Gui = gui,
        Destroy = DestroySelf,
        SetVisible = function(state) if gui then gui.Enabled = state end end,
        SetPosition = function(newPos) if btn then btn.Position = newPos end end,
        SetSize = function(newSize) if btn then btn.Size = UDim2.new(0, newSize, 0, newSize) end end,
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
        GetId = function() return btnId end,
        GetConfig = function() return config end,
        SetName = function(newName)
            btnData.Name = newName
            if settingsPanelInstance then
                settingsPanelInstance:Refresh()
            end
        end,
        GetName = function() return btnData.Name end,
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
    btn.Draggable = (config.Draggable ~= false) and not isLocked
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

    local btnId = config.Id or "toggle_" .. tostring(buttonCounter)
    buttonCounter = buttonCounter + 1

    local btnData = { 
        Button = btn, 
        Gui = gui,
        ResizeHandle = resizeHandle,
        Id = btnId,
        Name = config.Name or "Toggle " .. tostring(buttonCounter),
        Config = config,
        Type = "Toggle",
        Destroy = nil
    }

    local function DestroySelf()
        for i, data in ipairs(allButtons) do
            if data == btnData then
                table.remove(allButtons, i)
                break
            end
        end
        for _, con in ipairs(connections) do con:Disconnect() end
        if gui and gui.Parent then gui:Destroy() end
        if settingsPanelInstance then
            settingsPanelInstance:Refresh()
        end
    end
    btnData.Destroy = DestroySelf

    table.insert(allButtons, btnData)

    if settingsPanelInstance then
        settingsPanelInstance:Refresh()
    end

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
        Destroy = DestroySelf,
        SetVisible = function(state) if gui then gui.Enabled = state end end,
        SetPosition = function(newPos) if btn then btn.Position = newPos end end,
        SetSize = function(newSize) if btn then btn.Size = UDim2.new(0, newSize, 0, newSize) end end,
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
        GetId = function() return btnId end,
        GetConfig = function() return config end,
        SetName = function(newName)
            btnData.Name = newName
            if settingsPanelInstance then
                settingsPanelInstance:Refresh()
            end
        end,
        GetName = function() return btnData.Name end,
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
        CreateSettingsButton()
        
        -- Auto load config nếu có
        if savedConfigs and next(savedConfigs) then
            -- Ở đây bạn có thể tự động load config
            print("🔄 Auto loading saved configs...")
        end
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
    if settingsButtonInstance then
        settingsButtonInstance:Destroy()
        settingsButtonInstance = nil
    end
    if settingsPanelInstance then
        settingsPanelInstance:Destroy()
        settingsPanelInstance = nil
    end
end

function NoirButtonFactory.GetLockButton()
    return lockButtonInstance
end

function NoirButtonFactory.GetSettingsButton()
    return settingsButtonInstance
end

function NoirButtonFactory.GetSettingsPanel()
    return settingsPanelInstance
end

function NoirButtonFactory.GetAllButtons()
    return allButtons
end

function NoirButtonFactory.OpenSettings()
    local panel = CreateSettingsPanel()
    if panel then
        panel:Show()
    end
end

function NoirButtonFactory.SaveAllConfigs()
    savedConfigs = {}
    for i, btnData in ipairs(allButtons) do
        savedConfigs[btnData.Id] = {
            Name = btnData.Name or "Button " .. i,
            Position = btnData.Button.Position,
            Size = btnData.Button.Size,
            Visible = btnData.Gui.Enabled,
            IconId = btnData.Config.IconId,
            Type = btnData.Type or "Floating"
        }
    end
    return savedConfigs
end

function NoirButtonFactory.LoadAllConfigs(configs)
    savedConfigs = configs or savedConfigs
    for id, config in pairs(savedConfigs) do
        for _, btnData in ipairs(allButtons) do
            if btnData.Id == id then
                btnData.Name = config.Name
                btnData.Button.Position = config.Position
                btnData.Button.Size = config.Size
                btnData.Gui.Enabled = config.Visible
                break
            end
        end
    end
    if settingsPanelInstance then
        settingsPanelInstance:Refresh()
    end
end

return NoirButtonFactory
