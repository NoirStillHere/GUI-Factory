-- ==========================================================
-- NoirCore v1.0 - Hệ sinh thái quản lý nút
-- ==========================================================
local NoirCore = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Internal state
local isLocked = false
local allButtons = {}
local lockButtonInstance = nil
local settingsButtonInstance = nil
local settingsPanelInstance = nil
local isLoaded = false
local buttonCounter = 0

-- ===== RESIZE HANDLE =====
local function CreateResizeHandle(btn)
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 10, 0, 10)
    handle.Position = UDim2.new(1, -10, 1, -10)
    handle.AnchorPoint = Vector2.new(0, 0)
    handle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    handle.BackgroundTransparency = 0.4
    handle.ZIndex = 20
    handle.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 2)
    corner.Parent = handle

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://12232156257"  -- Icon mũi tên chéo
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
            handle.BackgroundTransparency = 0.4
        end
    end)

    handle.MouseEnter:Connect(function()
        if not isLocked then handle.BackgroundTransparency = 0.2 end
    end)
    
    handle.MouseLeave:Connect(function()
        if not isResizing then handle.BackgroundTransparency = 0.4 end
    end)

    return handle
end

-- ===== TẠO NÚT CƠ BẢN =====
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

    -- Main panel (nhỏ hơn)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 500, 0, 450)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    panel.BackgroundTransparency = 0.05
    panel.ZIndex = 1
    panel.Parent = gui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    -- Tiêu đề
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Settings"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 2
    title.Parent = panel

    -- Nút đóng
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 2
    closeBtn.Parent = panel

    -- Tabs
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(1, 0, 0, 30)
    tabsContainer.Position = UDim2.new(0, 0, 0, 35)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.ZIndex = 2
    tabsContainer.Parent = panel

    local mainTab = Instance.new("TextButton")
    mainTab.Size = UDim2.new(0.5, 0, 1, 0)
    mainTab.Position = UDim2.new(0, 0, 0, 0)
    mainTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    mainTab.BackgroundTransparency = 0.2
    mainTab.Text = "Main"
    mainTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainTab.TextSize = 14
    mainTab.Font = Enum.Font.GothamBold
    mainTab.ZIndex = 2
    mainTab.Parent = tabsContainer

    local configTab = Instance.new("TextButton")
    configTab.Size = UDim2.new(0.5, 0, 1, 0)
    configTab.Position = UDim2.new(0.5, 0, 0, 0)
    configTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    configTab.BackgroundTransparency = 0.2
    configTab.Text = "Config"
    configTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    configTab.TextSize = 14
    configTab.Font = Enum.Font.GothamBold
    configTab.ZIndex = 2
    configTab.Parent = tabsContainer

    -- Content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -20, 1, -90)
    contentContainer.Position = UDim2.new(0, 10, 0, 70)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ZIndex = 2
    contentContainer.Parent = panel

    -- Main content
    local mainContent = Instance.new("ScrollingFrame")
    mainContent.Size = UDim2.new(1, 0, 1, 0)
    mainContent.Position = UDim2.new(0, 0, 0, 0)
    mainContent.BackgroundTransparency = 1
    mainContent.BorderSizePixel = 0
    mainContent.ScrollBarThickness = 4
    mainContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    mainContent.ZIndex = 3
    mainContent.Parent = contentContainer

    -- Config content
    local configContent = Instance.new("ScrollingFrame")
    configContent.Size = UDim2.new(1, 0, 1, 0)
    configContent.Position = UDim2.new(0, 0, 0, 0)
    configContent.BackgroundTransparency = 1
    configContent.BorderSizePixel = 0
    configContent.ScrollBarThickness = 4
    configContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    configContent.ZIndex = 3
    configContent.Visible = false
    configContent.Parent = contentContainer

    -- Nút thêm button (ở Main tab)
    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0, 120, 0, 30)
    addBtn.Position = UDim2.new(0.5, 0, 1, -40)
    addBtn.AnchorPoint = Vector2.new(0.5, 0)
    addBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    addBtn.BackgroundTransparency = 0.2
    addBtn.Text = "+ Add Button"
    addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    addBtn.TextSize = 12
    addBtn.Font = Enum.Font.GothamBold
    addBtn.ZIndex = 5
    addBtn.Parent = mainContent

    -- Hàm refresh Main tab
    local function RefreshMainTab()
        mainContent:ClearAllChildren()
        
        -- Tiêu đề + nút Add
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 35)
        header.Position = UDim2.new(0, 0, 0, 0)
        header.BackgroundTransparency = 1
        header.Parent = mainContent

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
        titleLabel.Position = UDim2.new(0, 10, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Buttons (" .. #allButtons .. ")"
        titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = header

        local addBtn = Instance.new("TextButton")
        addBtn.Size = UDim2.new(0, 80, 0, 25)
        addBtn.Position = UDim2.new(1, -90, 0.5, 0)
        addBtn.AnchorPoint = Vector2.new(0, 0.5)
        addBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        addBtn.BackgroundTransparency = 0.2
        addBtn.Text = "+ Add"
        addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        addBtn.TextSize = 12
        addBtn.Font = Enum.Font.GothamBold
        addBtn.ZIndex = 5
        addBtn.Parent = header

        addBtn.MouseButton1Click:Connect(function()
            -- Mở input để nhập script
            local input = Instance.new("TextBox")
            input.Size = UDim2.new(0, 400, 0, 100)
            input.Position = UDim2.new(0.5, 0, 0.5, 0)
            input.AnchorPoint = Vector2.new(0.5, 0.5)
            input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            input.TextColor3 = Color3.fromRGB(255, 255, 255)
            input.TextSize = 14
            input.Font = Enum.Font.Gotham
            input.PlaceholderText = "Paste your button script here..."
            input.ZIndex = 10
            input.Parent = gui

            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 8)
            inputCorner.Parent = input

            local confirmBtn = Instance.new("TextButton")
            confirmBtn.Size = UDim2.new(0, 80, 0, 30)
            confirmBtn.Position = UDim2.new(0.5, 0, 1, 10)
            confirmBtn.AnchorPoint = Vector2.new(0.5, 0)
            confirmBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
            confirmBtn.BackgroundTransparency = 0.2
            confirmBtn.Text = "Run"
            confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            confirmBtn.TextSize = 12
            confirmBtn.Font = Enum.Font.GothamBold
            confirmBtn.Parent = input

            confirmBtn.MouseButton1Click:Connect(function()
                local code = input.Text
                if code and code ~= "" then
                    -- Chạy script được dán vào
                    loadstring(code)()
                end
                input:Destroy()
            end)
        end)

        -- Danh sách nút
        local yOffset = 45
        for i, btnData in ipairs(allButtons) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 40)
            row.Position = UDim2.new(0, 0, 0, yOffset + (i-1) * 42)
            row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            row.BackgroundTransparency = 0.5
            row.ZIndex = 4
            row.Parent = mainContent

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 5)
            rowCorner.Parent = row

            -- Icon nhỏ
            local iconSmall = Instance.new("ImageLabel")
            iconSmall.Size = UDim2.new(0, 20, 0, 20)
            iconSmall.Position = UDim2.new(0, 8, 0.5, 0)
            iconSmall.AnchorPoint = Vector2.new(0, 0.5)
            iconSmall.BackgroundTransparency = 1
            iconSmall.Image = btnData.Config.IconId or "rbxassetid://12232156257"
            iconSmall.ImageColor3 = Color3.fromRGB(255, 255, 255)
            iconSmall.ScaleType = Enum.ScaleType.Fit
            iconSmall.ZIndex = 5
            iconSmall.Parent = row

            -- Tên
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 35, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = btnData.Name or "Button " .. i
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 12
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.ZIndex = 5
            nameLabel.Parent = row

            -- Kích thước
            local sizeLabel = Instance.new("TextLabel")
            sizeLabel.Size = UDim2.new(0.2, 0, 1, 0)
            sizeLabel.Position = UDim2.new(0.35, 0, 0, 0)
            sizeLabel.BackgroundTransparency = 1
            sizeLabel.Text = math.round(btnData.Button.Size.X.Offset) .. "px"
            sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            sizeLabel.TextSize = 10
            sizeLabel.Font = Enum.Font.Gotham
            sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
            sizeLabel.ZIndex = 5
            sizeLabel.Parent = row

            -- Nút ẩn/hiện (icon)
            local toggleBtn = Instance.new("ImageButton")
            toggleBtn.Size = UDim2.new(0, 20, 0, 20)
            toggleBtn.Position = UDim2.new(0.65, 0, 0.5, 0)
            toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
            toggleBtn.BackgroundTransparency = 1
            toggleBtn.Image = "rbxassetid://12232156257"  -- Icon mắt
            toggleBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
            toggleBtn.ZIndex = 5
            toggleBtn.Parent = row

            -- Nút xóa (icon)
            local deleteBtn = Instance.new("ImageButton")
            deleteBtn.Size = UDim2.new(0, 20, 0, 20)
            deleteBtn.Position = UDim2.new(0.8, 0, 0.5, 0)
            deleteBtn.AnchorPoint = Vector2.new(0, 0.5)
            deleteBtn.BackgroundTransparency = 1
            deleteBtn.Image = "rbxassetid://12232156257"  -- Icon thùng rác
            deleteBtn.ImageColor3 = Color3.fromRGB(255, 80, 80)
            deleteBtn.ZIndex = 5
            deleteBtn.Parent = row

            -- Nút đổi tên (icon)
            local renameBtn = Instance.new("ImageButton")
            renameBtn.Size = UDim2.new(0, 20, 0, 20)
            renameBtn.Position = UDim2.new(0.95, 0, 0.5, 0)
            renameBtn.AnchorPoint = Vector2.new(1, 0.5)
            renameBtn.BackgroundTransparency = 1
            renameBtn.Image = "rbxassetid://12232156257"  -- Icon bút
            renameBtn.ImageColor3 = Color3.fromRGB(80, 80, 255)
            renameBtn.ZIndex = 5
            renameBtn.Parent = row

            local visible = true
            toggleBtn.MouseButton1Click:Connect(function()
                visible = not visible
                btnData.Gui.Enabled = visible
                toggleBtn.ImageColor3 = visible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            end)

            deleteBtn.MouseButton1Click:Connect(function()
                btnData:Destroy()
                RefreshMainTab()
            end)

            renameBtn.MouseButton1Click:Connect(function()
                local input = Instance.new("TextBox")
                input.Size = UDim2.new(0, 200, 0, 30)
                input.Position = UDim2.new(0.5, 0, 0.5, 0)
                input.AnchorPoint = Vector2.new(0.5, 0.5)
                input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                input.TextColor3 = Color3.fromRGB(255, 255, 255)
                input.TextSize = 14
                input.Font = Enum.Font.Gotham
                input.PlaceholderText = "New name..."
                input.Text = btnData.Name or ""
                input.ZIndex = 10
                input.Parent = gui

                local inputCorner = Instance.new("UICorner")
                inputCorner.CornerRadius = UDim.new(0, 8)
                inputCorner.Parent = input

                input.FocusLost:Connect(function()
                    local newName = input.Text
                    if newName and newName ~= "" then
                        btnData.Name = newName
                        nameLabel.Text = newName
                    end
                    input:Destroy()
                end)
            end)
        end
    end

    -- Hàm refresh Config tab
    local function RefreshConfigTab()
        configContent:ClearAllChildren()
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 25)
        titleLabel.Position = UDim2.new(0, 0, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Configurations"
        titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.ZIndex = 5
        titleLabel.Parent = configContent

        -- Nút Save/Load
        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0, 80, 0, 25)
        saveBtn.Position = UDim2.new(0, 10, 0, 30)
        saveBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        saveBtn.BackgroundTransparency = 0.2
        saveBtn.Text = "Save"
        saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        saveBtn.TextSize = 12
        saveBtn.Font = Enum.Font.GothamBold
        saveBtn.ZIndex = 5
        saveBtn.Parent = configContent

        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0, 80, 0, 25)
        loadBtn.Position = UDim2.new(0, 100, 0, 30)
        loadBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
        loadBtn.BackgroundTransparency = 0.2
        loadBtn.Text = "Load"
        loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        loadBtn.TextSize = 12
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.ZIndex = 5
        loadBtn.Parent = configContent

        local autoBtn = Instance.new("TextButton")
        autoBtn.Size = UDim2.new(0, 80, 0, 25)
        autoBtn.Position = UDim2.new(0, 190, 0, 30)
        autoBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 80)
        autoBtn.BackgroundTransparency = 0.2
        autoBtn.Text = "Auto"
        autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        autoBtn.TextSize = 12
        autoBtn.Font = Enum.Font.GothamBold
        autoBtn.ZIndex = 5
        autoBtn.Parent = configContent

        -- Danh sách config
        local yOffset = 65
        for i, btnData in ipairs(allButtons) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 40)
            row.Position = UDim2.new(0, 0, 0, yOffset + (i-1) * 42)
            row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            row.BackgroundTransparency = 0.5
            row.ZIndex = 4
            row.Parent = configContent

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 5)
            rowCorner.Parent = row

            local idLabel = Instance.new("TextLabel")
            idLabel.Size = UDim2.new(0.2, 0, 1, 0)
            idLabel.Position = UDim2.new(0, 8, 0, 0)
            idLabel.BackgroundTransparency = 1
            idLabel.Text = "#" .. i
            idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            idLabel.TextSize = 10
            idLabel.Font = Enum.Font.Gotham
            idLabel.TextXAlignment = Enum.TextXAlignment.Left
            idLabel.ZIndex = 5
            idLabel.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
            nameLabel.Position = UDim2.new(0.2, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = btnData.Name or "Button " .. i
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 12
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.ZIndex = 5
            nameLabel.Parent = row

            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(0.5, 0, 1, 0)
            infoLabel.Position = UDim2.new(0.5, 0, 0, 0)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = math.round(btnData.Button.Size.X.Offset) .. "px | " .. btnData.Type
            infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            infoLabel.TextSize = 10
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.ZIndex = 5
            infoLabel.Parent = row
        end
    end

    -- Tab switching
    mainTab.MouseButton1Click:Connect(function()
        mainTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        configTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        mainTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        configTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        mainContent.Visible = true
        configContent.Visible = false
        RefreshMainTab()
    end)

    configTab.MouseButton1Click:Connect(function()
        configTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        mainTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        configTab.TextColor3 = Color3.fromRGB(255, 255, 255)
        mainTab.TextColor3 = Color3.fromRGB(200, 200, 200)
        mainContent.Visible = false
        configContent.Visible = true
        RefreshConfigTab()
    end)

    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            gui.Enabled = false
        end
    end)

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
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Position = UDim2.new(0.9, 0, 0.8, 0)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
    btn.BackgroundTransparency = 0.3
    btn.Draggable = true
    btn.Text = ""
    btn.ZIndex = 1
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
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
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Position = UDim2.new(0.9, 0, 0.9, 0)
    btn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    btn.BackgroundTransparency = 0.3
    btn.Draggable = true
    btn.Text = ""
    btn.ZIndex = 1
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://12232156257"  -- Icon mở khóa
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
            btn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
            icon.Image = "rbxassetid://12232156257"  -- Icon khóa
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
            btn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
            icon.Image = "rbxassetid://12232156257"  -- Icon mở khóa
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
                btn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
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
                btn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
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
                btn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
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
                btn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
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

-- ===== PUBLIC API =====
function NoirCore.CreateFloatingButton(config)
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

function NoirCore.CreateToggleButton(config)
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

-- ===== INIT =====
local function Init()
    if isLoaded then return end
    isLoaded = true
    
    local player = Players.LocalPlayer
    if player then
        player:WaitForChild("PlayerGui")
        CreateAutoLockButton()
        CreateSettingsButton()
    end
end

Init()

-- ===== EXPORT =====
function NoirCore.GetLockState() return isLocked end
function NoirCore.SetLockState(state)
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

function NoirCore.DestroyAllButtons()
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

function NoirCore.GetLockButton() return lockButtonInstance end
function NoirCore.GetSettingsButton() return settingsButtonInstance end
function NoirCore.GetSettingsPanel() return settingsPanelInstance end
function NoirCore.GetAllButtons() return allButtons end
function NoirCore.OpenSettings()
    local panel = CreateSettingsPanel()
    if panel then
        panel:Show()
    end
end

return NoirCore
