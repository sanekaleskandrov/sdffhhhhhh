--[[
    ================================================================
    🚀 BABFT LOADER v2.0 — Fixed Edition
    ================================================================
    Оригинальный Loader от TheRealAsu/BABFT использовал luau.pro/loader
    который больше не работает. Этот loader загружает скрипты
    НАПРЯМУЮ из GitHub репозитория.

    Возможности:
      ✅ Грузит скрипты напрямую из GitHub (без luau.pro)
      ✅ GUI с выбором скрипта
      ✅ Поддержка кастомных URL (можно залить свои скрипты)
      ✅ Авто-проверка доступности скрипта
      ✅ Логирование процесса загрузки

    Доступные скрипты:
      • UAP.lua — основной скрипт (обфусцирован, 216 KB)
      • TestBeta.lua — бета версия (245 KB)
      • CandyFarm.lua — ферма Хэллоуина (только на evento)
      • LoopCandyFarm.lua — цикл для CandyFarm

    Использование:
      loadstring(game:HttpGet('https://raw.githubusercontent.com/TheRealAsu/BABFT/main/Loader.lua'))()

    Или с кастомным URL:
      loadstring(game:HttpGet('ТВОЙ_URL/Loader.lua'))()
    ================================================================
]]

-- ============================================================
-- СЕРВИСЫ
-- ============================================================
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

print("[BABFT Loader] v2.0 Fixed Edition — запуск...")

-- ============================================================
-- КОНФИГУРАЦИЯ
-- ============================================================
-- Базовый URL репозитория
-- Если ты заливаешь скрипты на свой GitHub — поменяй эту переменную!
local REPO_URL = "https://raw.githubusercontent.com/TheRealAsu/BABFT/main"

-- Список доступных скриптов
local SCRIPTS = {
    {
        name = "UAP (основной)",
        file = "UAP.lua",
        desc = "Основной BABFT скрипт от Asu. Image Loader, AutoBuilder, AutoFarm",
        recommended = true,
    },
    {
        name = "TestBeta (бета)",
        file = "TestBeta.lua",
        desc = "Бета версия с последними фичами. Может быть нестабильна",
    },
    {
        name = "CandyFarm (Хэллоуин)",
        file = "CandyFarm.lua",
        desc = "Ферма конфет. Работает ТОЛЬКО во время Хэллоуин события",
    },
    {
        name = "LoopCandyFarm",
        file = "LoopCandyFarm.lua",
        desc = "Цикл для CandyFarm. Запускать после CandyFarm.lua",
    },
    {
        name = "Library (UI библиотека)",
        file = "Library.lua",
        desc = "UI библиотека Asu. Загружает только UI, без основного скрипта",
    },
}

-- ============================================================
-- ЛОГ
-- ============================================================
local LogLines = {}
local function log(msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
    table.insert(LogLines, line)
    if #LogLines > 200 then table.remove(LogLines, 1) end
    print("[BABFT Loader] " .. tostring(msg))
end

log("Loader запущен")
log("Репозиторий: " .. REPO_URL)

-- ============================================================
-- HTTP УТИЛИТЫ
-- ============================================================
local function getHttp(url)
    local req = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not req then
        return false, "request() не поддерживается экзекутором"
    end
    local ok, res = pcall(req, {
        Url = url,
        Method = "GET",
        Headers = {
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) BABFT-Loader",
            ["Cache-Control"] = "no-cache",
        },
    })
    if not ok then
        return false, "Ошибка сети: " .. tostring(res)
    end
    if not res.Body or #res.Body == 0 then
        return false, "Пустой ответ от сервера"
    end
    -- Проверяем HTTP код
    local code = res.StatusCode or 200
    if code >= 400 then
        return false, "HTTP " .. tostring(code) .. " — файл не найден"
    end
    return true, res.Body
end

-- ============================================================
-- ЗАГРУЗКА СКРИПТА
-- ============================================================
local function loadScript(scriptInfo)
    local url = REPO_URL .. "/" .. scriptInfo.file
    log("Загружаю: " .. scriptInfo.name .. " (" .. url .. ")")

    local ok, body = getHttp(url)
    if not ok then
        log("❌ Ошибка: " .. tostring(body))
        return false, body
    end

    log("Получено байт: " .. #body)

    -- Проверяем что это Lua код
    if #body < 100 then
        return false, "Слишком короткий ответ — возможно это 404 страница"
    end

    -- Пробуем скомпилировать и запустить
    local fn, err = loadstring(body, scriptInfo.file)
    if not fn then
        log("❌ Ошибка компиляции: " .. tostring(err))
        return false, "Compile error: " .. tostring(err)
    end

    log("✓ Компиляция успешна, запускаю...")
    local okRun, runErr = pcall(fn)
    if not okRun then
        log("❌ Ошибка выполнения: " .. tostring(runErr))
        return false, "Run error: " .. tostring(runErr)
    end

    log("✓ Скрипт " .. scriptInfo.name .. " запущен!")
    return true
end

-- ============================================================
-- СОЗДАНИЕ GUI
-- ============================================================
log("Создание GUI...")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BABFTLoader_" .. tostring(math.random(1000, 9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 99999
ScreenGui.IgnoreGuiInset = true

local parentOk = pcall(function() ScreenGui.Parent = CoreGui end)
if not parentOk then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 500)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = MainFrame

-- DRAG
local dragToggle, dragStart, dragPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        dragPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragToggle then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            dragPos.X.Scale, dragPos.X.Offset + delta.X,
            dragPos.Y.Scale, dragPos.Y.Offset + delta.Y
        )
    end
end)

-- Заголовок
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🚀 BABFT Loader v2.0 (Fixed)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local LogBtn = Instance.new("TextButton")
LogBtn.Size = UDim2.new(0, 36, 0, 32)
LogBtn.Position = UDim2.new(1, -76, 0, 6)
LogBtn.BackgroundColor3 = Color3.fromRGB(70, 100, 160)
LogBtn.Text = "LOG"
LogBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LogBtn.Font = Enum.Font.GothamBold
LogBtn.TextSize = 11
LogBtn.Parent = TitleBar
local logBtnCorner = Instance.new("UICorner")
logBtnCorner.CornerRadius = UDim.new(0, 6)
logBtnCorner.Parent = LogBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Поле кастомного URL
local UrlLabel = Instance.new("TextLabel")
UrlLabel.Size = UDim2.new(1, -20, 0, 22)
UrlLabel.Position = UDim2.new(0, 10, 0, 52)
UrlLabel.BackgroundTransparency = 1
UrlLabel.Text = "📦 Репозиторий (URL без имени файла):"
UrlLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
UrlLabel.Font = Enum.Font.GothamBold
UrlLabel.TextSize = 13
UrlLabel.TextXAlignment = Enum.TextXAlignment.Left
UrlLabel.Parent = MainFrame

local UrlBox = Instance.new("TextBox")
UrlBox.Size = UDim2.new(1, -20, 0, 32)
UrlBox.Position = UDim2.new(0, 10, 0, 76)
UrlBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
UrlBox.Text = REPO_URL
UrlBox.TextColor3 = Color3.fromRGB(255, 255, 255)
UrlBox.Font = Enum.Font.Code
UrlBox.TextSize = 11
UrlBox.ClearTextOnFocus = false
UrlBox.Parent = MainFrame
local urlCorner = Instance.new("UICorner")
urlCorner.CornerRadius = UDim.new(0, 6)
urlCorner.Parent = UrlBox
local urlPad = Instance.new("UIPadding")
urlPad.PaddingLeft = UDim.new(0, 8)
urlPad.PaddingRight = UDim.new(0, 8)
urlPad.Parent = UrlBox

UrlBox.FocusLost:Connect(function()
    local newUrl = UrlBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if newUrl ~= "" then
        -- Удаляем trailing slash
        newUrl = newUrl:gsub("/$", "")
        REPO_URL = newUrl
        log("URL репозитория изменён: " .. REPO_URL)
    end
    UrlBox.Text = REPO_URL
end)

-- Список скриптов
local ScriptsLabel = Instance.new("TextLabel")
ScriptsLabel.Size = UDim2.new(1, -20, 0, 22)
ScriptsLabel.Position = UDim2.new(0, 10, 0, 116)
ScriptsLabel.BackgroundTransparency = 1
ScriptsLabel.Text = "📋 Выбери скрипт для загрузки:"
ScriptsLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
ScriptsLabel.Font = Enum.Font.GothamBold
ScriptsLabel.TextSize = 13
ScriptsLabel.TextXAlignment = Enum.TextXAlignment.Left
ScriptsLabel.Parent = MainFrame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 0, 200)
ScrollFrame.Position = UDim2.new(0, 10, 0, 140)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ScrollFrame

-- Создаём кнопки для каждого скрипта
local scriptButtons = {}
for i, info in ipairs(SCRIPTS) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 56)
    btn.BackgroundColor3 = info.recommended and Color3.fromRGB(60, 100, 60) or Color3.fromRGB(50, 50, 60)
    btn.Text = "  " .. info.name .. (info.recommended and "  ⭐ РЕКОМЕНДУЕТСЯ" or "") ..
               "\n  " .. info.desc
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextYAlignment = Enum.TextYAlignment.Top
    btn.Parent = ScrollFrame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        -- Запускаем в отдельном потоке
        task.spawn(function()
            btn.BackgroundColor3 = Color3.fromRGB(100, 100, 60)
            local ok, err = loadScript(info)
            if ok then
                btn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
                StatusLabel.Text = "✓ " .. info.name .. " запущен!"
                StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
                -- Закрываем loader через 2 сек
                task.wait(2)
                -- НЕ закрываем — пусть пользователь видит лог
            else
                btn.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
                StatusLabel.Text = "❌ " .. tostring(err)
                StatusLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
            end
        end)
    end)
    table.insert(scriptButtons, btn)
end

-- Кнопка "Загрузить по URL"
local CustomLabel = Instance.new("TextLabel")
CustomLabel.Size = UDim2.new(1, -20, 0, 22)
CustomLabel.Position = UDim2.new(0, 10, 0, 348)
CustomLabel.BackgroundTransparency = 1
CustomLabel.Text = "🔗 Или загрузи любой .lua файл по URL:"
CustomLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
CustomLabel.Font = Enum.Font.GothamBold
CustomLabel.TextSize = 13
CustomLabel.TextXAlignment = Enum.TextXAlignment.Left
CustomLabel.Parent = MainFrame

local CustomUrlBox = Instance.new("TextBox")
CustomUrlBox.Size = UDim2.new(1, -100, 0, 32)
CustomUrlBox.Position = UDim2.new(0, 10, 0, 372)
CustomUrlBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
CustomUrlBox.PlaceholderText = "https://example.com/script.lua"
CustomUrlBox.Text = ""
CustomUrlBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CustomUrlBox.Font = Enum.Font.Code
CustomUrlBox.TextSize = 11
CustomUrlBox.ClearTextOnFocus = false
CustomUrlBox.Parent = MainFrame
local cuCorner = Instance.new("UICorner")
cuCorner.CornerRadius = UDim.new(0, 6)
cuCorner.Parent = CustomUrlBox
local cuPad = Instance.new("UIPadding")
cuPad.PaddingLeft = UDim.new(0, 8)
cuPad.PaddingRight = UDim.new(0, 8)
cuPad.Parent = CustomUrlBox

local CustomLoadBtn = Instance.new("TextButton")
CustomLoadBtn.Size = UDim2.new(0, 80, 0, 32)
CustomLoadBtn.Position = UDim2.new(1, -90, 0, 372)
CustomLoadBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 100)
CustomLoadBtn.Text = "ЗАГРУЗИТЬ"
CustomLoadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CustomLoadBtn.Font = Enum.Font.GothamBold
CustomLoadBtn.TextSize = 11
CustomLoadBtn.Parent = MainFrame
local clCorner = Instance.new("UICorner")
clCorner.CornerRadius = UDim.new(0, 6)
clCorner.Parent = CustomLoadBtn

CustomLoadBtn.MouseButton1Click:Connect(function()
    local url = CustomUrlBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if url == "" then
        StatusLabel.Text = "❌ Вставь URL скрипта!"
        StatusLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
        return
    end
    if not url:find("^https?://") then
        StatusLabel.Text = "❌ URL должен начинаться с http:// или https://"
        StatusLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
        return
    end

    task.spawn(function()
        CustomLoadBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 60)
        log("Загрузка кастомного скрипта: " .. url)
        local ok, body = getHttp(url)
        if not ok then
            StatusLabel.Text = "❌ " .. tostring(body)
            StatusLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
            CustomLoadBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 100)
            return
        end

        log("Получено байт: " .. #body)
        local fn, err = loadstring(body, "CustomScript")
        if not fn then
            StatusLabel.Text = "❌ Compile error: " .. tostring(err)
            StatusLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
            CustomLoadBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 100)
            return
        end

        local okRun, runErr = pcall(fn)
        if okRun then
            StatusLabel.Text = "✓ Кастомный скрипт запущен!"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
            CustomLoadBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
        else
            StatusLabel.Text = "❌ Run error: " .. tostring(runErr)
            StatusLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
            CustomLoadBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 100)
        end
    end)
end)

-- Статус
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 28)
StatusLabel.Position = UDim2.new(0, 10, 0, 414)
StatusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
StatusLabel.Text = "✓ Готов к работе. Выбери скрипт выше."
StatusLabel.TextColor3 = Color3.fromRGB(150, 200, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame
local stCorner = Instance.new("UICorner")
stCorner.CornerRadius = UDim.new(0, 6)
stCorner.Parent = StatusLabel
local stPad = Instance.new("UIPadding")
stPad.PaddingLeft = UDim.new(0, 8)
stPad.Parent = StatusLabel

-- Подсказка внизу
local HintLabel = Instance.new("TextLabel")
HintLabel.Size = UDim2.new(1, -20, 0, 50)
HintLabel.Position = UDim2.new(0, 10, 0, 448)
HintLabel.BackgroundTransparency = 1
HintLabel.Text = "💡 Совет: если UAP не работает, попробуй TestBeta.\n" ..
                 "Если оригинальный репозиторий недоступен — поменяй URL выше на свой форк."
HintLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
HintLabel.Font = Enum.Font.Gotham
HintLabel.TextSize = 11
HintLabel.TextWrapped = true
HintLabel.TextXAlignment = Enum.TextXAlignment.Left
HintLabel.TextYAlignment = Enum.TextYAlignment.Top
HintLabel.Parent = MainFrame

-- ============================================================
-- ОКНО ЛОГА
-- ============================================================
local logFrame = Instance.new("Frame")
logFrame.Size = UDim2.new(0, 460, 0, 360)
logFrame.Position = UDim2.new(0.5, -230, 0.5, -180)
logFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
logFrame.BorderSizePixel = 0
logFrame.Visible = false
logFrame.ZIndex = 2000
logFrame.Parent = ScreenGui
local lfCorner = Instance.new("UICorner")
lfCorner.CornerRadius = UDim.new(0, 8)
lfCorner.Parent = logFrame
local lfStroke = Instance.new("UIStroke")
lfStroke.Color = Color3.fromRGB(80, 100, 140)
lfStroke.Thickness = 1
lfStroke.Parent = logFrame

local logTitle = Instance.new("TextLabel")
logTitle.Size = UDim2.new(1, -50, 0, 30)
logTitle.Position = UDim2.new(0, 10, 0, 5)
logTitle.BackgroundTransparency = 1
logTitle.Text = "📋 Лог загрузчика"
logTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 14
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.ZIndex = 2001
logTitle.Parent = logFrame

local logCloseBtn = Instance.new("TextButton")
logCloseBtn.Size = UDim2.new(0, 28, 0, 28)
logCloseBtn.Position = UDim2.new(1, -34, 0, 6)
logCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
logCloseBtn.Text = "✕"
logCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
logCloseBtn.Font = Enum.Font.GothamBold
logCloseBtn.TextSize = 12
logCloseBtn.ZIndex = 2001
logCloseBtn.Parent = logFrame
local lcCorner = Instance.new("UICorner")
lcCorner.CornerRadius = UDim.new(0, 4)
lcCorner.Parent = logCloseBtn

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -20, 1, -50)
logScroll.Position = UDim2.new(0, 10, 0, 40)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 4
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.ZIndex = 2001
logScroll.Parent = logFrame

local logTextLabel = Instance.new("TextLabel")
logTextLabel.Size = UDim2.new(1, 0, 0, 0)
logTextLabel.BackgroundTransparency = 1
logTextLabel.Text = ""
logTextLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
logTextLabel.Font = Enum.Font.Code
logTextLabel.TextSize = 11
logTextLabel.TextXAlignment = Enum.TextXAlignment.Left
logTextLabel.TextYAlignment = Enum.TextYAlignment.Top
logTextLabel.TextWrapped = true
logTextLabel.AutomaticSize = Enum.AutomaticSize.Y
logTextLabel.Parent = logScroll

local function refreshLogUI()
    logTextLabel.Text = table.concat(LogLines, "\n")
end

LogBtn.MouseButton1Click:Connect(function()
    refreshLogUI()
    logFrame.Visible = not logFrame.Visible
end)
logCloseBtn.MouseButton1Click:Connect(function()
    logFrame.Visible = false
end)

-- ============================================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================================
log("=== Loader готов ===")
log("Доступно скриптов: " .. #SCRIPTS)
log("Если скрипт не запускается — попробуй TestBeta")
log("Если репозиторий недоступен — поменяй URL на свой форк")

-- Уведомление
local notify = Instance.new("TextLabel")
notify.Size = UDim2.new(0, 340, 0, 44)
notify.Position = UDim2.new(0.5, -170, 0, 20)
notify.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
notify.Text = "🚀 BABFT Loader v2.0 готов!\nВыбери скрипт для запуска."
notify.TextColor3 = Color3.fromRGB(255, 255, 255)
notify.Font = Enum.Font.GothamBold
notify.TextSize = 12
notify.TextWrapped = true
notify.ZIndex = 9999
notify.Parent = ScreenGui
local nc = Instance.new("UICorner")
nc.CornerRadius = UDim.new(0, 8)
nc.Parent = notify
local nstroke = Instance.new("UIStroke")
nstroke.Color = Color3.fromRGB(80, 160, 220)
nstroke.Thickness = 1
nstroke.Parent = notify

task.delay(5, function()
    TweenService:Create(notify, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -170, 0, -60)}):Play()
    task.wait(0.5)
    notify:Destroy()
end)
