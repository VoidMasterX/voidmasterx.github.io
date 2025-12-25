-- localization
local evo = getgenv().Evo;
local worldToScreen, getBoundingBox = worldtoscreen, getboundingbox;
local game, workspace, table, debug, math, cframe, vector2, vector3, color3, instance, drawing, raycastParams = game, workspace, table, debug, math, CFrame, Vector2, Vector3, Color3, Instance, Drawing, RaycastParams;
local getService, isA, findFirstChild, getChildren, getDescendants = game.GetService, game.IsA, game.FindFirstChild, game.GetChildren, game.GetDescendants;
local raycast = workspace.Raycast;
local tableInsert, tableFind, tableClear = table.insert, table.find, table.clear;
local profileBegin, profileEnd = debug.profilebegin, debug.profileend;
local mathFloor, mathSin, mathCos, mathRad, mathTan, mathAtan2, mathClamp, mathPi = math.floor, math.sin, math.cos, math.rad, math.tan, math.atan2, math.clamp, math.pi;
local cframeNew, vector2New, vector3New = cframe.new, vector2.new, vector3.new;
local color3New = color3.new;
local instanceNew, drawingNew = instance.new, drawing.new;
local raycastParamsNew = raycastParams.new;
local emptyVector3, emptyCFrame, emptyColor3 = vector3.zero, cframe.identity, color3New();
local vector3Min, vector3Max = emptyVector3.Min, emptyVector3.Max;

-- services
local players = getService(game, "Players");
local coreGui = getService(game, "CoreGui");
local runService = getService(game, "RunService");

-- cache
local localPlayer = players.LocalPlayer;
local currentCamera = workspace.CurrentCamera;
local filterType = Enum.RaycastFilterType.Blacklist;
local depthMode = Enum.HighlightDepthMode;
local lastScale, lastFov;

-- function localization
local ccWorldToViewportPoint = currentCamera.WorldToViewportPoint;
local pointToObjectSpace = emptyCFrame.PointToObjectSpace;

-- support functions
local function worldToViewportPoint(position)
    if (worldToScreen) then
        local screenPosition = worldToScreen({ position })[1];
        local depth = screenPosition.Z;
        return vector2New(screenPosition.X, screenPosition.Y), depth > 0, depth;
    end

    local screenPosition, onScreen = ccWorldToViewportPoint(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
end

local function rotateVector(vector, radian)
    local angleCos, angleSine = mathCos(radian), mathSin(radian);
    return vector2New(angleCos * vector.X - angleSine * vector.Y, angleSine * vector.X + angleCos * vector.Y);
end

local function roundVector(vector)
    return vector2New(mathFloor(vector.X), mathFloor(vector.Y));
end

-- interface
local library = {
    _initialized = false,
    _connections = {},
    _cache = {},

    prioritized = {},
    friended = {},
    settings = {
        enabled = false,
        visibleOnly = false,
        teamCheck = false,
        prioritizedColor = color3New(1, 1, 0),
        friendedColor = color3New(0, 1, 1),
        boxStaticWidth = 4,
        boxStaticHeight = 5,
        maxBoxWidth = 6,
        maxBoxHeight = 6,
        limitDistance = false,
        maxDistance = 300,

        chams = false,
        chamsDepthMode = "AlwaysOnTop",
        chamsInlineColor = color3New(0.701960, 0.721568, 1),
        chamsInlineTransparency = 0,
        chamsOutlineColor = emptyColor3,
        chamsOutlineTransparency = 0,
        sound = false,
        soundColor = color3New(1, 0, 0),
        names = false,
        nameColor = color3New(1, 1, 1),
        teams = false,
        teamColor = color3New(1, 1, 1),
        boxes = false,
        boxColor = color3New(1, 0, 0),
        boxType = "Static",
        boxFill = false,
        boxFillColor = color3New(1, 0, 0),
        boxFillTransparency = 0.5,
        skeletons = false,
        skeletonColor = color3New(1, 1, 1),
        healthbar = false,
        healthbarColor = color3New(0, 1, 0.4),
        healthbarSize = 1,
        healthtext = false,
        healthtextColor = color3New(1, 1, 1),
        distance = false,
        distanceColor = color3New(1, 1, 1),
        weapon = false,
        weaponColor = color3New(1, 1, 1),
        oofArrows = false,
        oofArrowsColor = color3New(0.8, 0.2, 0.2),
        oofArrowsAlpha = 1,
        oofArrowsSize = 30,
        oofArrowsRadius = 150,
    }
};

-- esp class
local esp = {}; do
    esp.__index = esp;

    function esp.new(player)
        if (player == localPlayer) then
            return
        end

        return setmetatable({
            _id = -player.UserId,
            _objects = {},
            _player = player,
            _soundTransparency = 0
        }, esp);
    end

    function esp:Destroy()
        for index, object in next, self._objects do
            object:Remove();
            self._objects[index] = nil;
        end

        tableClear(self);
    end

    function esp:Create(class, properties, zindex)
        local object = library:Create(class, properties);

        object.ZIndex = zindex or self._id;

        if (not zindex) then
            self._id -= 1;
        end

        return object;
    end

    function esp:SoundPulsate(magnitude)
        local objects = self._objects;
        local dot = objects.Dot;

        if (dot) then
            dot.Radius = magnitude * mathPi;
            self._soundTransparency = 1;
        end
    end

    function esp:Build()
        local objects, settings = {}, library.settings;
        local font = 4;

        objects.Name = self:Create("Text", {
            Color = settings.nameColor,
            Text = self._player.Name,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = emptyColor3,
            Font = font
        });

        objects.Team = self:Create("Text", {
            Color = settings.teamColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        });

        objects.Box = self:Create("Square", {
            Color = settings.boxColor,
            Thickness = 1,
            Filled = false
        });

        objects.BoxFill = self:Create("Square", {
            Color = settings.boxFillColor,
            Transparency = settings.boxFillTransparency,
            Thickness = 1,
            Filled = true
        }, objects.Box.ZIndex + 1);

        objects.BoxOutline = self:Create("Square", {
            Color = emptyColor3,
            Thickness = 3,
            Filled = false
        });

        objects.Healthbar = self:Create("Square", {
            Color = settings.healthbarColor,
            Thickness = 1,
            Filled = true
        });

        objects.HealthbarOutline = self:Create("Square", {
            Color = emptyColor3,
            Transparency = 0.5,
            Thickness = 1,
            Filled = true
        });

        objects.Healthtext = self:Create("Text", {
            Color = settings.healthtextColor,
            Size = 13,
            Center = false,
            Outline = true,
            OutlineColor = emptyColor3,
            Font = font
        });

        objects.Distance = self:Create("Text", {
            Color = settings.distanceColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = emptyColor3,
            Font = font
        });

        objects.Weapon = self:Create("Text", {
            Color = settings.weaponColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = emptyColor3,
            Font = font
        });

        objects.Arrow = self:Create("Triangle", {
            Color = settings.oofArrowsColor,
            Thickness = 1,
            Filled = true
        });

        objects.Dot = self:Create("Circle", {
            Color = settings.soundColor,
            Thickness = 1,
            NumSides = 128,
            Radius = 5,
            Filled = true,
        });

        self._objects = objects;
    end

    function esp:Update(deltaTime)
        local player, settings = self._player, library.settings;
        local team = library._getTeam(player);

        if (settings.teamCheck and team == library._getTeam(localPlayer)) then
            return
        end

        local character, rootPart = library._getCharacter(player);

        if (not character or not rootPart) then
            return
        end

        local cameraCFrame = currentCamera.CFrame;
        local cameraPosition, rootPosition = cameraCFrame.Position, rootPart.Position;

        if (settings.visibleOnly and not library._visibleCheck(character, cameraPosition, rootPosition)) then
            return
        end

        local magnitude = (cameraPosition - rootPosition).Magnitude;

        if (settings.limitDistance and magnitude > settings.maxDistance) then
            return
        end

        local screenPosition, onScreen, depth = worldToViewportPoint(rootPosition);
        local width, height = library._getBoxData(character, depth);
        local health, max = library._getHealth(player, character);

        local objectSpace = pointToObjectSpace(cameraCFrame, rootPosition);
        local angle = mathAtan2(objectSpace.Z, objectSpace.X);
        local direction = vector2New(mathCos(angle), mathSin(angle));

        self._character = character;
        self._team = team;
        self._weapon = library._getWeapon(player, character);
        self._color = library.prioritized[player] ~= nil and settings.prioritizedColor or (library.friended[player] ~= nil and settings.friendedColor);
        self._screenX = screenPosition.X;
        self._screenY = screenPosition.Y;
        self._width = width;
        self._height = height;
        self._healthData = { hp = health, max = max };
        self._magnitude = magnitude;
        self._arrowDirection = direction;
        self._soundTransparency = mathClamp(self._soundTransparency - (deltaTime * 5), 0, 1);

        self._visible = onScreen;
        self._render = true;
    end

    function esp:Render()
        local objects, settings, canRender = self._objects, library.settings, self._render;

        if (not canRender or not settings.enabled) then
            for _, object in next, objects do
                object.Visible = false;
            end

            return
        end

        local canShow = self._visible;
        local x, y = self._screenX, self._screenY;
        local width, height = self._width, self._height;
        local healthData = self._healthData;
        local health, maxHealth = healthData.hp, healthData.max;

        local color = self._color;

        local size = vector2New(width, height);
        local position = vector2New(x - width * 0.5, y - height * 0.5);
        local hSize = vector2New(settings.healthbarSize, height);
        local hPosition = position - vector2New(hSize.X + (worldToScreen and 4 or 3), 0);

        local viewportSize = currentCamera.ViewportSize;
        local screenCenter, direction = vector2New(viewportSize.X * 0.5, viewportSize.Y * 0.5), self._arrowDirection;
        local arrowSize, arrowRadius = settings.oofArrowsSize, settings.oofArrowsRadius;
        local arrowPosition = screenCenter + direction * arrowRadius;

        local name, team, box, boxFill, boxOutline, healthbar, healthbarOutline, healthtext, distance, weapon, arrow, dot = objects.Name, objects.Team, objects.Box, objects.BoxFill, objects.BoxOutline, objects.Healthbar, objects.HealthbarOutline, objects.Healthtext, objects.Distance, objects.Weapon, objects.Arrow, objects.Dot;

        name.Visible = canShow and settings.names;
        name.Color = color or settings.nameColor;
        name.Position = vector2New(x, position.Y - name.TextBounds.Y - 2);

        team.Visible = canShow and settings.teams;
        team.Text = self._team ~= nil and self._team.Name or "No Team";
        team.Color = settings.teamColor;
        team.Position = vector2New(x + width * 0.5 + team.TextBounds.X * 0.5 + 2, position.Y - 2);

        box.Visible = canShow and settings.boxes;
        box.Color = color or settings.boxColor;
        box.Size = size;
        box.Position = position;

        boxFill.Visible = canShow and settings.boxFill;
        boxFill.Color = color or settings.boxFillColor;
        boxFill.Transparency = settings.boxFillTransparency;
        boxFill.Size = size;
        boxFill.Position = position;

        boxOutline.Visible = box.Visible;
        boxOutline.Size = size;
        boxOutline.Position = position;

        healthbar.Visible = canShow and settings.healthbar;
        healthbar.Color = color or settings.healthbarColor;
        healthbar.Size = vector2New(hSize.X, -(height * (health / maxHealth)));
        healthbar.Position = hPosition + vector2New(0, height);

        healthbarOutline.Visible = healthbar.Visible;
        healthbarOutline.Size = hSize + vector2New(2, 2);
        healthbarOutline.Position = hPosition - vector2New(1, 1);

        healthtext.Visible = canShow and settings.healthtext;
        healthtext.Text = mathFloor(health) .. " HP";
        healthtext.Color = color or settings.healthtextColor;
        healthtext.Position = hPosition - vector2New(healthtext.TextBounds.X + 2, -(height * (1 - (health / maxHealth))) + 2);

        distance.Visible = canShow and settings.distance;
        distance.Text = mathFloor(self._magnitude) .. " Studs";
        distance.Color = color or settings.distanceColor;
        distance.Position = vector2New(x, position.Y + height);

        weapon.Visible = canShow and settings.weapon;
        weapon.Text = self._weapon;
        weapon.Color = color or settings.weaponColor;
        weapon.Position = vector2New(x, position.Y + height + (distance.Visible and distance.TextBounds.Y + 1 or 0));

        arrow.Visible = not canShow and settings.oofArrows;
        arrow.Color = color or settings.oofArrowsColor;
        arrow.Transparency = settings.oofArrowsAlpha;
        arrow.PointA = roundVector(arrowPosition);
        arrow.PointB = roundVector(arrowPosition - rotateVector(direction, 0.6) * arrowSize);
        arrow.PointC = roundVector(arrowPosition - rotateVector(direction, -0.6) * arrowSize);

        dot.Visible = not canShow and settings.sound;
        dot.Color = color or settings.soundColor;
        dot.Transparency = self._soundTransparency;
        dot.Position = roundVector(screenCenter + direction * 250);

        self._render = false;
    end
end

local chams = {}; do
    chams.__index = chams;

    function chams.new(player)
        if (player == localPlayer) then
            return
        end

        return setmetatable({
            _player = player,
            _highlight = nil,
        }, chams);
    end

    function chams:Destroy()
        local highlight = self._highlight;

        if (highlight) then
            highlight:Destroy();
            self._highlight = nil;
        end

        tableClear(self);
    end

    function chams:Build()
        local settings = library.settings;

        self._highlight = library:Create("Highlight", {
            Parent = library._screenGui,
            DepthMode = depthMode[settings.chamsDepthMode],
            FillColor = settings.chamsInlineColor,
            FillTransparency = settings.chamsInlineTransparency,
            OutlineColor = settings.chamsOutlineColor,
            OutlineTransparency = settings.chamsOutlineTransparency,
        });
    end

    function chams:Update()
        local player, settings = self._player, library.settings;
        local team = library._getTeam(player);

        if (settings.teamCheck and team == library._getTeam(localPlayer)) then
            return
        end

        local character, rootPart = library._getCharacter(player);

        if (not character or not rootPart) then
            return
        end

        self._character = character;
        self._color = library.prioritized[player] ~= nil and settings.prioritizedColor or (library.friended[player] ~= nil and settings.friendedColor);

        self._render = true;
    end

    function chams:Render()
        local canRender, settings = self._render, library.settings;
        local highlight = self._highlight;

        if (not canRender or not settings.enabled) then
            highlight.Enabled = nil;
            highlight.Adornee = nil;
            return
        end

        local color = self._color;
        local outlineColor = color and color3New(mathClamp(color.R - 0.1, 0, 1), mathClamp(color.G - 0.1, 0, 1), mathClamp(color.B - 0.1, 0, 1));

        highlight.Enabled = settings.chams;
        highlight.Adornee = self._character;
        highlight.DepthMode = depthMode[settings.chamsDepthMode];
        highlight.FillColor = color or settings.chamsInlineColor;
        highlight.FillTransparency = settings.chamsInlineTransparency;
        highlight.OutlineColor = outlineColor or settings.chamsOutlineColor;
        highlight.OutlineTransparency = settings.chamsOutlineTransparency;

        self._render = false;
    end
end

-- private methods
function library._getTeam(player)
    return player.Team;
end

function library._getCharacter(player)
    local character = player.Character;
    return character, character and findFirstChild(character, "HumanoidRootPart");
end

function library._getHealth(player, character)
    local humanoid = findFirstChild(character, "Humanoid");

    if (humanoid) then
        return humanoid.Health, humanoid.MaxHealth;
    end

    return 100, 100;
end

function library._getWeapon(player, character)
    return "Hands";
end

function library._visibleCheck(character, origin, target)
    local params = raycastParamsNew();

    params.FilterDescendantsInstances = { library._getCharacter(localPlayer), character, currentCamera };
    params.FilterType = filterType;
    params.IgnoreWater = true;

    return raycast(workspace, origin, target - origin, params) == nil;
end

function library._getScaleFactor(fov, depth)
    if (lastFov ~= fov) then
        lastScale = mathTan(mathRad(fov * 0.5)) * 2;
        lastFov = fov;
    end

    return 1 / (lastScale * depth) * 1000;
end

function library._getBoundingBox(inst)
    local parts = isA(inst, "BasePart") and { inst, unpack(getChildren(inst)) } or getChildren(inst);

    if (getBoundingBox) then
        return getBoundingBox(parts);
    end

    local min, max;

	for _, part in next, parts do
		if (isA(part, "BasePart")) then
            local cframe, size = part.CFrame, part.Size;

            min = vector3Min(min or cframe.Position, (cframe - size * 0.5).Position);
            max = vector3Max(max or cframe.Position, (cframe + size * 0.5).Position);
        end
	end

	local center = (min + max) * 0.5;
	local front = vector3New(center.X, center.Y, max.Z);
	return cframeNew(center, front), max - min;
end

function library._getBoxSize(model)
    if (library.settings.boxType == "Static" or not isA(model, "Model")) then
        return vector2New(library.settings.boxStaticWidth, library.settings.boxStaticHeight);
    end

    local _, size = library._getBoundingBox(model);
    return vector2New(mathClamp(size.X, 0, library.settings.maxBoxWidth), mathClamp(size.Y, 0, library.settings.maxBoxHeight));
end

function library._getBoxData(model, depth)
    local size = (typeof(model) == "Vector2" or typeof(model) == "Vector3") and model or library._getBoxSize(model);
    local scaleFactor = library._getScaleFactor(currentCamera.FieldOfView, depth);
    return mathFloor(size.X * scaleFactor), mathFloor(size.Y * scaleFactor);
end

-- public methods
function library:Connect(signal, callback)
    local connection = signal:Connect(callback);
    tableInsert(self._connections, connection);
    return connection;
end

function library:IsDrawing(class)
    return class == "Line" or class == "Text" or class == "Image" or class == "Circle" or class == "Square" or class == "Quad" or class == "Triangle";
end

function library:Create(class, properties, parent)
    local drawing = self:IsDrawing(class);
    local object = drawing and drawingNew(class) or instanceNew(class);

    if (properties) then
        for property, value in next, properties do
            object[property] = value;
        end
    end

    if (not drawing and parent and object.Parent) then
        object.Parent = parent;
    end

    return object;
end

function library:AddClass(id, class)
    if (self._cache[id] or not class) then
        return
    end

    class:Build();
    self._cache[id] = class;
    return class;
end

function library:GetClass(id)
    return self._cache[id];
end

function library:RemoveClass(id)
    local cache = self._cache[id];

    if (cache) then
        self._cache[id] = nil;
        cache:Destroy();
    end
end

function library:Load(custom)
    if (self._initialized) then
        return
    end

    if (not custom) then
        self._screenGui = self:Create("ScreenGui", {
            Parent = coreGui,
        });

        for _, player in next, players:GetPlayers() do
            self:AddClass(player.Name .. ".Esp", esp.new(player));
            self:AddClass(player.Name .. ".Chams", chams.new(player));
        end

        self:Connect(players.PlayerAdded, function(player)
            self:AddClass(player.Name .. ".Esp", esp.new(player));
            self:AddClass(player.Name .. ".Chams", chams.new(player));
        end);

        self:Connect(players.PlayerRemoving, function(player)
            self:RemoveClass(player.Name .. ".Esp");
            self:RemoveClass(player.Name .. ".Chams");
        end);

        self:Connect(runService.RenderStepped, function(deltaTime)
            profileBegin("Esp Renderer");

            for id, class in next, self._cache do
                profileBegin(id .. ":Render");
                class:Render(deltaTime);
                profileEnd();
            end

            profileEnd();
        end);

        self:Connect(runService.Heartbeat, function(deltaTime)
            profileBegin("Esp Updater");

            for id, class in next, self._cache do
                profileBegin(id .. ":Update");
                class:Update(deltaTime);
                profileEnd();
            end

            profileEnd();
        end);
    end

    self._initialized = true;
end

function library:Unload()
    if (not self._initialized) then
        return
    end

    local screenGui = self._screenGui;

    if (screenGui) then
        screenGui:Destroy();
        self._screenGui = nil;
    end

    for index, connection in next, self._connections do
        connection:Disconnect();
        self._connections[index] = nil;
    end

    for id, _ in next, self._cache do
        self:RemoveClass(id);
    end

    self._initialized = false;
end

if (evo) then
    evo.Unloaded:Once(function()
        library:Unload();
    end);
end

return library;
