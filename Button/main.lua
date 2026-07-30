-- ==========================================================
-- NoirButtonFactory - Wrapper để dễ sử dụng
-- ==========================================================
local NoirButtonFactory = {}

-- Kiểm tra xem core đã tồn tại chưa
local Core = nil
if _G.NoirCore then
    Core = _G.NoirCore
else
    -- Tạo core mới nếu chưa có
    Core = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirStillHere/GUI-Factory/refs/heads/main/Button/core.lua"))()
    _G.NoirCore = Core
end

-- Wrapper các hàm
function NoirButtonFactory.CreateFloatingButton(config)
    return Core.CreateFloatingButton(config)
end

function NoirButtonFactory.CreateToggleButton(config)
    return Core.CreateToggleButton(config)
end

function NoirButtonFactory.GetLockState()
    return Core.GetLockState()
end

function NoirButtonFactory.SetLockState(state)
    return Core.SetLockState(state)
end

function NoirButtonFactory.DestroyAllButtons()
    return Core.DestroyAllButtons()
end

function NoirButtonFactory.GetLockButton()
    return Core.GetLockButton()
end

function NoirButtonFactory.GetSettingsButton()
    return Core.GetSettingsButton()
end

function NoirButtonFactory.GetSettingsPanel()
    return Core.GetSettingsPanel()
end

function NoirButtonFactory.GetAllButtons()
    return Core.GetAllButtons()
end

function NoirButtonFactory.OpenSettings()
    return Core.OpenSettings()
end

return NoirButtonFactory
