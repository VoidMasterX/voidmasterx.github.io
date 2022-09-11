local library = {
    espCache = {},
    connections = {},
    settings = {
        enemies = {
            enabled = true,
            name = false,
            namecolor = Color3.new(1, 1, 1),
            box = false,
            boxcolor = Color3.new(1, 1, 1),
            boxoutlinecolor = Color3.new(0.1, 0.1, 0.1),
            boxfill = false,
            boxfillcolor = Color3.new(1, 1, 1),
            healthbar = false,
            healthbarcolor = Color3.new(1, 1, 1),
            healthbaroutlinecolor = Color3.new(),
            healthbarsize = 1,
            healthtext = false,
            healthtextcolor = Color3.new(1, 1, 1),
            distance = false,
            distancecolor = Color3.new(1, 1, 1),
            weapon = false,
            weaponcolor = Color3.new(1, 1, 1),
            oofarrows = false,
            oofarrowcolor = Color3.new(1, 1, 1),
            oofarrowalpha = 1,
        },
        teamates = {
            enabled = false,
            name = false,
            namecolor = Color3.new(1, 1, 1),
            box = false,
            boxcolor = Color3.new(1, 1, 1),
            boxoutlinecolor = Color3.new(0.1, 0.1, 0.1),
            boxfill = false,
            boxfillcolor = Color3.new(1, 1, 1),
            healthbar = false,
            healthbarcolor = Color3.new(0, 1, 0),
            healthbaroutlinecolor = Color3.new(),
            healthbarsize = 1,
            healthtext = false,
            healthtextcolor = Color3.new(1, 1, 1),
            distance = false,
            distancecolor = Color3.new(1, 1, 1),
            weapon = false,
            weaponcolor = Color3.new(1, 1, 1),
            oofarrows = false,
            oofarrowcolor = Color3.new(1, 1, 1),
            oofarrowalpha = 1,
        },
        general = {
            arrowSize = 15,
            arrowRadius = 150,
            textFont = "Plex",
            textCase = "Default",
            textSize = 13
        }
    }
};
library.__index = library;

-- variables
local getService = game.GetService;
local findFirstChild = game.FindFirstChild;
local findFirstChildOfClass = game.FindFirstChildOfClass;
local tableInsert = table.insert;
local stringLower = string.lower;
local stringUpper = string.upper;
local vector2New = Vector2.new;
local vector3New = Vector3.new;
local cframeNew = CFrame.new;
local drawingNew = Drawing.new;
local color3New = Color3.new;
local mathFloor = math.floor;
local mathTan = math.tan;
local mathRad = math.rad;
local pointToObjectSpace = cframeNew().PointToObjectSpace;
local cross = vector3New().Cross;

-- services
local players = getService(game, "Players");
local workspace = getService(game, "Workspace");
local runService = getService(game, "RunService");

-- cache
local currentCamera = workspace.CurrentCamera;
local localPlayer = players.LocalPlayer;
local lastScale, lastFov;

-- support functions
local ccWorldToViewportPoint = currentCamera.WorldToViewportPoint;
local function worldToViewportPoint(position)
    if (worldtoscreen) then
        local screenPosition = worldtoscreen({ position })[1];
        return vector2New(screenPosition.X, screenPosition.Y), screenPosition.Z > 0, screenPosition.Z;
    end

    local screenPosition, onScreen = ccWorldToViewportPoint(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
end

local function addConnection(signal, func)
    local connection = signal:Connect(func);
    tableInsert(library.connections, connection);
    return connection;
end

local function round(vec)
    return vector2New(mathFloor(vec.X), mathFloor(vec.Y));
end

local function parseText(text)
    local casing = library.settings.general.textCase;

    if (casing == "lowercase") then
        text = stringLower(text);
    elseif (casing == "UPPERCASE") then
        text = stringUpper(text);
    end

    return text
end

local function parseSetting(setting, team)
    return library.settings[library.getTeam(localPlayer) ~= team and "enemies" or "teamates"][setting];
end

local function create(type, properties)
    local object = drawingNew(type);

    if (properties) then
        for property, value in next, properties do
            object[property] = value;
        end
    end

    return object;
end

-- module
function library.getTeam(player)
    return player.Team;
end

function library.getCharacter(player)
    local character = player.Character;
    return character, character and findFirstChild(character, "HumanoidRootPart");
end

function library.getHealth(player, character)
    local humanoid = character ~= nil and findFirstChildOfClass(character, "Humanoid");
    if (humanoid) then
        return humanoid.Health, humanoid.MaxHealth;
    end
    return 100, 100;
end

function library.getWeapon(player, character)
    return "UNKNOWN";
end

function library._getScaleFactor(fov, depth)
    if (lastFov ~= fov) then
        lastScale = mathTan(mathRad(fov * 0.5)) * 2;
        lastFov = fov;
    end

    return 1 / (lastScale * depth) * 1000;
end

function library._getBoxData(depth)
    local scaleFactor = library._getScaleFactor(currentCamera.FieldOfView, depth);
    local width, height = mathFloor(4 * scaleFactor), mathFloor(5 * scaleFactor);
    return width, height;
end

function library._addEsp(player)
    if (player == localPlayer) then
        return
    end

    local objects = {
        name = create("Text", {
            Text = player.Name,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
        }),
        boxFill = create("Square", {
            Thickness = 1,
            Transparency = 0.5,
            Filled = true,
        }),
        boxOutline = create("Square", {
            Thickness = 3,
            Filled = false,
        }),
        box = create("Square", {
            Thickness = 1,
            Filled = false,
        }),
        healthbarOutline = create("Square", {
            Thickness = 1,
            Filled = true,
        }),
        healthbar = create("Square", {
            Thickness = 1,
            Filled = true,
        }),
        healthText = create("Text", {
            Outline = true,
            OutlineColor = color3New(),
        }),
        distance = create("Text", {
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
        }),
        weapon = create("Text", {
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
        }),
        arrow = create("Triangle", {
            Thickness = 1,
            Filled = true,
        })
    };

    library.espCache[player] = objects;
end

function library._removeEsp(player)
    local objects = library.espCache[player];

    if (objects) then
        for index, drawing in next, objects do
            drawing:Remove();
            objects[index] = nil;
        end

        library.espCache[player] = nil;
    end
end

function library:Load()
    addConnection(players.PlayerAdded, function(player)
        self._addEsp(player);
    end);

    addConnection(players.PlayerRemoving, function(player)
        self._removeEsp(player);
    end);

    for _, player in next, players:GetPlayers() do
        self._addEsp(player);
    end

    addConnection(runService.RenderStepped, function()
        for player, objects in next, self.espCache do
            local character, torso = self.getCharacter(player);

            if (character and torso) then
                local team = self.getTeam(player);
                local position = torso.Position;
                local torsoPosition, onScreen, depth = worldToViewportPoint(position);
                local canShow = onScreen and parseSetting("enabled", team);

                if (not canShow) then
                    local viewportSize = currentCamera.ViewportSize;
                    local screenCenter = vector2New(viewportSize.X * 0.5, viewportSize.Y * 0.5);
                    local objectSpacePoint = (pointToObjectSpace(currentCamera.CFrame, position) * vector3New(1, 0, 1)).Unit;
                    local crossVector = cross(objectSpacePoint, vector3New(0, 1, 1));
                    local rightVector = vector2New(crossVector.X, crossVector.Z);
                    local arrowRadius, arrowSize = self.settings.general.arrowRadius, self.settings.general.arrowSize;
                    local arrowPosition = screenCenter + vector2New(objectSpacePoint.X, objectSpacePoint.Z) * arrowRadius;
                    local arrowDirection = (arrowPosition - screenCenter).Unit;
                    local pointA, pointB, pointC = arrowPosition, screenCenter + arrowDirection * (arrowRadius - arrowSize) + rightVector * arrowSize, screenCenter + arrowDirection * (arrowRadius - arrowSize) + -rightVector * arrowSize;
                    local color = parseSetting("oofarrowcolor", team);

                    objects.arrow.Visible = (parseSetting("enabled", team) and parseSetting("oofarrows", team));
                    objects.arrow.Transparency = color and parseSetting("oofarrowalpha", team) or 0;
                    objects.arrow.Color = color and color or color3New(1, 1, 1);
                    objects.arrow.PointA = pointA;
                    objects.arrow.PointB = pointB;
                    objects.arrow.PointC = pointC;
                else
                    objects.arrow.Visible = false;
                end

                if (canShow) then
                    local width, height = self._getBoxData(depth);
                    local x, y = torsoPosition.X, torsoPosition.Y;
                    local boxSize = round(vector2New(width, height));
                    local boxPosition = round(vector2New(x - width * 0.5, y - height * 0.5));

                    local health, maxHealth = self.getHealth(player, character);
                    local healthbarSize = round(vector2New(parseSetting("healthbarsize", team), -(height * (health / maxHealth))));
                    local healthbarPosition = round(boxPosition + vector2New(-(3 + healthbarSize.X), height));

                    local magnitude = (currentCamera.CFrame.Position - position).Magnitude;
                    local currentWeapon = self.getWeapon(player, character);
                    local textFont, textSize = self.settings.general.textFont, self.settings.general.textSize;

                    objects.name.Visible = parseSetting("name", team);
                    objects.name.Text = parseText(player.Name, team);
                    objects.name.Font = Drawing.Fonts[textFont];
                    objects.name.Size = textSize;
                    objects.name.Color = parseSetting("namecolor", team);
                    objects.name.Position = round(boxPosition + vector2New(width * 0.5, -(objects.name.TextBounds.Y + 2)));

                    objects.box.Visible = parseSetting("box", team);
                    objects.box.Color = parseSetting("boxcolor", team);
                    objects.box.Position = boxPosition;
                    objects.box.Size = boxSize;

                    objects.boxOutline.Visible = parseSetting("box", team);
                    objects.boxOutline.Color = parseSetting("boxoutlinecolor", team);
                    objects.boxOutline.Position = boxPosition;
                    objects.boxOutline.Size = boxSize;

                    objects.boxFill.Visible = parseSetting("boxfill", team);
                    objects.boxFill.Color = parseSetting("boxfillcolor", team);
                    objects.boxFill.Position = boxPosition;
                    objects.boxFill.Size = boxSize;

                    objects.healthbar.Visible = parseSetting("healthbar", team);
                    objects.healthbar.Color = parseSetting("healthbarcolor", team);
                    objects.healthbar.Position = healthbarPosition;
                    objects.healthbar.Size = healthbarSize;

                    objects.healthbarOutline.Visible = parseSetting("healthbar", team);
                    objects.healthbarOutline.Color = parseSetting("healthbaroutlinecolor", team);
                    objects.healthbarOutline.Position = healthbarPosition - vector2New(1, -1);
                    objects.healthbarOutline.Size = round(vector2New(healthbarSize.X, -height) + vector2New(2, -2));

                    objects.healthText.Visible = parseSetting("healthtext", team);
                    objects.healthText.Text = parseText(mathFloor(health) .. "%", team);
                    objects.healthText.Font = Drawing.Fonts[textFont];
                    objects.healthText.Size = textSize;
                    objects.healthText.Color = parseSetting("healthtextcolor", team);
                    objects.healthText.Position = round(healthbarPosition + vector2New(-(objects.healthText.TextBounds.X + 4), healthbarSize.Y - 4));

                    objects.distance.Visible = parseSetting("distance", team);
                    objects.distance.Text = parseText(mathFloor(magnitude) .. " Studs", team);
                    objects.distance.Font = Drawing.Fonts[textFont];
                    objects.distance.Size = textSize;
                    objects.distance.Color = parseSetting("distancecolor", team);
                    objects.distance.Position = round(boxPosition + vector2New(width * 0.5, height + 1));

                    objects.weapon.Visible = parseSetting("weapon", team);
                    objects.weapon.Text = parseText(currentWeapon or "NONE", team);
                    objects.weapon.Font = Drawing.Fonts[textFont];
                    objects.weapon.Size = textSize;
                    objects.weapon.Color = parseSetting("weaponcolor", team);
                    objects.weapon.Position = round(boxPosition + vector2New(width * 0.5, (parseSetting("distance", team) and objects.weapon.TextBounds.Y or 0) + (height + 1)));
                else
                    for name, drawing in next, objects do
                        if (name ~= "arrow") then
                            drawing.Visible = false;
                        end
                    end
                end
            else
                for _, drawing in next, objects do
                    drawing.Visible = false;
                end
            end
        end
    end);
end

function library:Unload()
    for _, player in next, players:GetPlayers() do
        self._removeEsp(player);
    end
    
    for _, connection in next, library.connections do
        connection:Disconnect();
    end
end

return setmetatable({}, library);
