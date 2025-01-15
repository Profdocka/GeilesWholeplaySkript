THREAD_SLEEP_DURATION = 500
THREAD_TIMEOUT = 10000

---Clientseitige Klasse für eine Fahrgemeinschaft
DriversTask = {}
function DriversTask:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.vehNet = o.vehNet
    self.passengers = o.passengers
    self.taskAction = nil
    self.previousTaskAction = self.taskAction
    self.behaviorSwitch = false
    self.taskInfo = o.taskInfo
    self.vehHandle = 0
    self.passengersHandle = {}
    self.interruptor = nil
    self.groupIds = {}
    return o
end

---Fügt Ped Gruppen Ids hinzu sollten Passagiere zu einer Gruppe gehören
---@param passengerHandle number
---@param squadID number
function DriversTask:SetGroupIds(passengerHandle, squadID)
    self.groupIds[passengerHandle] = squadID
end

---Konsolenausgabe über den Status des Clienthandlings von Fahrgemeinschaften
PrintDriversTask = function()
    if DriversRunningTasks ~= nil then
        for vehNet, task in pairs(DriversRunningTasks) do
            print("VehNetID: " .. vehNet)
            if DriversRunningTasks[vehNet].taskAction ~= nil then
                print("\tTask-Action is active")
            else
                print("\tTask-Action is not active")
            end
            if DriversRunningTasks[vehNet].previousTaskAction ~= nil then
                print("\tPreviousTask-Action is set")
            else
                print("\tPreviousTask-Action is not set")
            end
            print("\tBehavior Switch Set to: " .. BoolToString(DriversRunningTasks[vehNet].behaviorSwitch))
            print("\tIs marked for termination: " .. BoolToString(DriversRunningTasks[vehNet].markedForTermination))
            print("\tTask Type: " .. DriversRunningTasks[vehNet].taskInfo.type)
            print("\tRunning Interruptors: ")
            if type(DriversRunningTasks[vehNet].threadsActive) == "table" then
                for key, value in pairs(DriversRunningTasks[vehNet].threadsActive) do
                    print("\t\tThread: " .. key)
                end
            end
            print("\tGroup Ids: ")
            if type(DriversRunningTasks[vehNet].groupIds) == "table" then
                for member, groupid in pairs(DriversRunningTasks[vehNet].groupIds) do
                    print("\t\tMember: " .. member .. " in Group: " .. groupid)
                end
            end
        end
    end
end

---Stoppt alle Client Threads von Fahrgemeinschaften
---@return promise
StopAllDriversRunningTasks = function()
    local promise = promise.new()
    local oldRunningTasks = {}
    for vehNet, drivertask in pairs(DriversRunningTasks) do
        if drivertask ~= nil then
            drivertask.markedForTermination = true
            oldRunningTasks[vehNet] = drivertask
            DriversRunningTasks[vehNet] = nil
        end
    end
    Wait(THREAD_SLEEP_DURATION)
    CreateThread(function()
        CleanUpOldRunningTask(oldRunningTasks)
    end)
    DriversRunningTasks = {}
    promise:resolve()
    return promise
end

---Alte deaktivierte Client Threads von Fahrgemeinschaften werden entfernt
---@param oldRunningTasks any
CleanUpOldRunningTask = function(oldRunningTasks)
    for vehNet, drivertask in pairs(oldRunningTasks) do
        --Alle Interruptor werden gestoppt
        if drivertask ~= nil then
            drivertask.markedForTermination = true
            drivertask:Interrupt()
            drivertask:StopAllInterruptors()
        end
        Wait(THREAD_SLEEP_DURATION + 1)
        --Liste wird bereinigt
        if type(oldRunningTasks[vehNet]) == "table" then
            for key, value in pairs(oldRunningTasks[vehNet]) do
                if type(value) == "table" then
                    for lowerkey, lowervalue in pairs(value) do
                        oldRunningTasks[vehNet][key][lowerkey] = nil
                    end
                end
                oldRunningTasks[vehNet][key] = nil
            end
        end
        oldRunningTasks[vehNet] = nil
    end
    oldRunningTasks = nil
end

---Erzeugt die clientseitigen Threads zur Behandlung der serverseitigen Definition der Fahrgemeinschaften
---@param DriversInfoFromServer table
ApplyDrivers = function(DriversInfoFromServer)
    Citizen.Await(StopAllDriversRunningTasks())
    DriversRunningTasks = {}
    for vehNet, passengers in pairs(DriversInfoFromServer.drivers) do
        if DriversInfoFromServer.driverstaskhost[vehNet] == GetPlayerServerId(PlayerId()) then
            local taskInfo = DriversInfoFromServer.driverstask[vehNet]
            local taskType = taskInfo.type
            Wait(THREAD_SLEEP_DURATION + 100)
            if TryForNetworkIDAvailability(vehNet) then
                local driveTask = DriversTask:new({ vehNet = vehNet, passengers = passengers, taskInfo = taskInfo })
                driveTask.markedForTermination = false
                local vehHandle = NetworkGetEntityFromNetworkId(vehNet)
                local tempPassengersHandles = {}
                ---Zuweisung der Client Handles und der Ped Gruppen Ids, falls vorhande
                for seatindex, passengerNet in pairs(passengers) do
                    if TryForNetworkIDAvailability(passengerNet) then
                        local passengerHandle = NetworkGetEntityFromNetworkId(passengerNet)
                        tempPassengersHandles[seatindex] = passengerHandle
                        local squad = GetPedGroupIndex(passengerHandle)
                        if squad ~= -1 and squad ~= 0 then
                            driveTask:SetGroupIds(passengerHandle, squad)
                        end
                    end
                end
                local tempPlayerGroupHandles = {}
                tempPlayerGroupHandles = PlayerGroupHandles
                for seatIndex, handle in pairs(tempPassengersHandles) do
                    for index, grouppedhandle in pairs(tempPlayerGroupHandles) do
                        if handle == grouppedhandle then
                            tempPlayerGroupHandles[index] = nil
                        end
                    end
                end
                PlayerGroupHandles = tempPlayerGroupHandles
                ---Entscheidung bezüglich der TaskAction
                if taskType == DRIVERS_TASK.DRIVETOCOORDS.type then
                    driveTask = DriversAdvancedTaskInterruptor:new({
                        vehNet = vehNet,
                        passengers = passengers,
                        taskInfo =
                            taskInfo
                    })
                    driveTask.threadsActive = {}
                    driveTask.vehHandle = vehHandle
                    driveTask.passengersHandle = tempPassengersHandles
                    driveTask.taskAction = nil
                    driveTask.previousTaskAction = driveTask.DriversDriveToCoordsTask
                    driveTask.groupIds = {}
                    driveTask:SetUpInterruptors()
                    Wait(100)
                elseif taskType == DRIVERS_TASK.NONE.type then
                    driveTask = DriversTaskInterruptor:new({
                        vehNet = vehNet,
                        passengers = passengers,
                        taskInfo =
                            taskInfo
                    })
                    driveTask.threadsActive = {}
                    driveTask.vehHandle = vehHandle
                    driveTask.passengersHandle = tempPassengersHandles
                    driveTask.taskAction = nil
                    driveTask.previousTaskAction = driveTask.DriversDoNothingTask
                    driveTask.groupIds = {}
                    driveTask:SetUpInterruptors()
                    Wait(100)
                elseif taskType == DRIVERS_TASK.ESCORT.type then
                    if TryForNetworkIDAvailability(taskInfo.targetNet) then
                        driveTask = DriversAdvancedTargetTaskInterruptor:new({
                            vehNet = vehNet,
                            passengers = passengers,
                            taskInfo =
                                taskInfo
                        })
                        driveTask.threadsActive = {}
                        driveTask.vehHandle = vehHandle
                        driveTask.passengersHandle = tempPassengersHandles
                        driveTask.targetHandle = NetworkGetEntityFromNetworkId(taskInfo.targetNet)
                        driveTask.taskAction = nil
                        driveTask.previousTaskAction = driveTask.DriversEscortTargetSubtaskTargetInVehicle
                        driveTask.groupIds = {}
                        driveTask:SetUpInterruptors()
                        Wait(100)
                    end
                elseif taskType == DRIVERS_TASK.CHASE.type then
                    if TryForNetworkIDAvailability(taskInfo.targetNet) then
                        driveTask = DriversAdvancedTargetTaskInterruptor:new({
                            vehNet = vehNet,
                            passengers = passengers,
                            taskInfo =
                                taskInfo
                        })
                        driveTask.threadsActive = {}
                        driveTask.vehHandle = vehHandle
                        driveTask.passengersHandle = tempPassengersHandles
                        driveTask.targetHandle = NetworkGetEntityFromNetworkId(taskInfo.targetNet)
                        driveTask.taskAction = driveTask.DriversChaseTargetSubtaskTargetInVehicle
                        driveTask.previousTaskAction = driveTask.taskAction
                        driveTask.groupIds = {}
                        driveTask:SetUpEliminationInterruptors()
                        Wait(100)
                        driveTask:SetUpAdvancedTargetInterruptors()
                        Wait(100)
                    end
                elseif taskType == DRIVERS_TASK.GETINVEHICLE.type then
                    driveTask = DriversTaskInterruptor:new({
                        vehNet = vehNet,
                        passengers = passengers,
                        taskInfo =
                            taskInfo
                    })
                    driveTask.threadsActive = {}
                    driveTask.vehHandle = vehHandle
                    driveTask.passengersHandle = tempPassengersHandles
                    driveTask.taskAction = nil
                    driveTask.previousTaskAction = driveTask.DriversWaitForAllPedsToEnterVehicle
                    driveTask.groupIds = {}
                    driveTask:SetUpInterruptors()
                    Wait(100)
                elseif taskType == DRIVERS_TASK.GETOUTOFVEHICLE.type then
                    driveTask = DriversTaskInterruptor:new({
                        vehNet = vehNet,
                        passengers = passengers,
                        taskInfo =
                            taskInfo
                    })
                    driveTask.threadsActive = {}
                    driveTask.vehHandle = vehHandle
                    driveTask.passengersHandle = tempPassengersHandles
                    driveTask.taskAction = nil
                    driveTask.previousTaskAction = driveTask.DriversWaitForAllPedsToLeaveVehicle
                    driveTask.groupIds = {}
                    driveTask:SetUpInterruptors()
                    Wait(100)
                end

                DriversRunningTasks[vehNet] = driveTask
                --Main Task Action Thread einer jeden Fahrgemeinschaft
                Citizen.CreateThread(function()
                    while driveTask ~= nil do
                        if driveTask.taskAction ~= nil then
                            Citizen.Await(driveTask:taskAction(vehNet))
                        end
                        Wait(THREAD_SLEEP_DURATION)
                    end
                end)
            end
        end
    end
end
---Beurteilung ob eine TaskAction ausgeführt werden kann
---@return boolean
function DriversTask:IsAbleToFulfillTaskAction()
    if not self.markedForTermination and self.taskAction ~= nil then
        return true
    else
        return false
    end
end

---Entfernte Charaktere werden wieder ihren Ped Gruppen Ids zugeordnet
function DriversTask:ReapplyPlayerGroup()
    if PlayerGroupID ~= 0 then
        for _, handle in pairs(PlayerGroupHandles) do
            SetPedAsGroupMember(handle, PlayerGroupID)
        end
    end
end

---Setzt die Task Action einer Fahrgemeinschaft zu dem Hauptverhalten
---@param vehNet number
---@param tasktype string DRIVERS_TASK
function DriversTask:SetMainTaskAction(vehNet, tasktype)
    if tasktype == DRIVERS_TASK.NONE.type then
        self.taskAction = self.DriversDoNothingTask
        print(vehNet .. ": Task set to: NONE")
    elseif tasktype == DRIVERS_TASK.GETINVEHICLE.type then
        self.taskAction = self.DriversWaitForAllPedsToEnterVehicle
        print(vehNet .. ": Task set to: GETINVEHICLE")
    elseif tasktype == DRIVERS_TASK.GETOUTOFVEHICLE.type then
        self.taskAction = self.DriversWaitForAllPedsToLeaveVehicle
        print(vehNet .. ": Task set to: GETOUTOFVEHICLE")
    elseif tasktype == DRIVERS_TASK.DRIVETOCOORDS.type then
        self.taskAction = self.DriversDriveToCoordsTask
        print(vehNet .. ": Task set to: TOCOORD")
    elseif tasktype == DRIVERS_TASK.ESCORT.type then
        if self.behaviorSwitch then
            self.taskAction = self.DriversEscortTargetSubtaskTargetOnFoot
            print(vehNet .. ": Task set to: ESCORT ON FOOT")
        else
            self.taskAction = self.DriversEscortTargetSubtaskTargetInVehicle
            print(vehNet .. ": Task set to: ESCORT IN VEHICLE")
        end
    elseif tasktype == DRIVERS_TASK.CHASE.type then
        if self.behaviorSwitch then
            self.taskAction = self.DriversChaseTargetSubtaskTargetOnFoot
            print(vehNet .. ": Task set to: CHASE ON FOOT")
        else
            self.taskAction = self.DriversChaseTargetSubtaskTargetInVehicle
            print(vehNet .. ": Task set to: CHASE IN VEHICLE")
        end
    end
end

---Hauptverhalten NONE
---@return promise
function DriversTask:DriversDoNothingTask()
    local promise = promise.new()
    return promise:resolve(true)
end

---Verhalten und Promise bis ein Charakter erfolgreich ins Fahrzeug eingestiegen ist
---@param vehNet number
---@param seatIndex number
---@param passengerHandle number
---@return promise
function DriversTask:DriversPedEnterVehicleTask(vehNet, seatIndex, passengerHandle)
    local promise = promise.new()
    local vehHandle = self.vehHandle
    if vehHandle ~= 0 and passengerHandle ~= 0 and not IsEntityDead(passengerHandle) and not IsPedInVehicle(passengerHandle, vehHandle, false) then
        local vehCoords = GetEntityCoords(vehHandle)
        local vehHeading = GetEntityHeading(vehHandle)
        local passengerCoords = GetEntityCoords(passengerHandle)
        local timeout = THREAD_TIMEOUT
        --Wenn in Gruppe ist, Gruppe entfernen und Nicht-Fahrgemeinschaft Peds zur neuer Gruppe wieder hinzufügen
        if self.groupIds[passengerHandle] ~= nil then
            RemovePedFromGroup(passengerHandle)
            RemoveGroup(self.groupIds[passengerHandle])
            self:ReapplyPlayerGroup()
        end
        -- Manuelles Einsteigen ins Fahrzeug. Wenn Fahrzeug zu weit weg, erstmal hinlaufen
        if self:VectDist(vehCoords, passengerCoords) > 10.0 and self:IsAbleToFulfillTaskAction() then
            TaskGoStraightToCoord(passengerHandle, vehCoords.x, vehCoords.y, vehCoords.z, 2.0, -1, vehHeading, 5)
            Citizen.CreateThread(function()
                local countdown = timeout
                while self:VectDist(vehCoords, passengerCoords) > 5.0 and countdown > 1000 and self:IsAbleToFulfillTaskAction() do
                    Citizen.Wait(THREAD_SLEEP_DURATION)
                    countdown = countdown - 1000
                end
                if self:IsAbleToFulfillTaskAction() then
                    TaskEnterVehicle(passengerHandle, vehHandle, timeout, seatIndex, 2.0, 8, 0)
                end
            end)
        elseif self:IsAbleToFulfillTaskAction() then
            TaskEnterVehicle(passengerHandle, vehHandle, timeout, seatIndex, 2.0, 8, 0)
        end
        -- Beim Timeout des manuellen Einsteigens wird das Ped ins Fahrzeug teleportiert
        Citizen.CreateThread(function()
            local ultimateTimeoutUntilWarp = THREAD_TIMEOUT * 2
            while self:AreVehicleAndPedExistingAndOperational(vehHandle, passengerHandle) and not IsPedInVehicle(passengerHandle, vehHandle, false) and self:IsAbleToFulfillTaskAction() do
                Citizen.Wait(THREAD_SLEEP_DURATION)
                if ultimateTimeoutUntilWarp > 0 then
                    ultimateTimeoutUntilWarp = ultimateTimeoutUntilWarp - 1000
                else
                    TaskWarpPedIntoVehicle(passengerHandle, vehHandle, seatIndex)
                    ultimateTimeoutUntilWarp = 5000
                end
            end
            -- Wenn das Ped im Fahrzeug sitzt, wird der Promise erfüllt
            promise:resolve(true)
        end)
    else
        -- Ped ist bereits im Fahrzeug
        promise:resolve(true)
    end
    return promise
end

---Verhalten und Promise bis ein Charakter das Fahrzeug verlässt
---@param vehNet number
---@param seatIndex number
---@param passengerHandle number
---@return promise
function DriversTask:DriversPedLeaveVehicleTask(vehNet, seatIndex, passengerHandle)
    local promise = promise.new()
    local vehHandle = self.vehHandle
    if vehHandle ~= 0 and passengerHandle ~= 0 and not IsEntityDead(passengerHandle) and IsPedInVehicle(passengerHandle, vehHandle, false) then
        TaskLeaveVehicle(passengerHandle, vehHandle, 0)
        if seatIndex == -1 then
            SetVehicleEngineOn(vehHandle, false, true, false)
        end
        if self.groupIds[passengerHandle] ~= nil then
            SetPedAsGroupMember(passengerHandle, self.groupIds[passengerHandle])
        end
        Citizen.CreateThread(function()
            while self:AreVehicleAndPedExistingAndOperational(vehHandle, passengerHandle) and IsPedInVehicle(passengerHandle, vehHandle, false) and self:IsAbleToFulfillTaskAction() do
                Citizen.Wait(THREAD_SLEEP_DURATION)
            end
            promise:resolve(true)
        end)
    else
        -- Ped ist bereits außerhalb des Fahrzeugs
        promise:resolve(true)
    end
    return promise
end

---Hauptverhalten und Promise bis alle Charaktere ein Fahrzeug betreten haben
---@param vehNet number
---@return promise
function DriversTask:DriversWaitForAllPedsToEnterVehicle(vehNet)
    local promiseEnter = promise.new()
    local passengers = self.passengersHandle
    self.promises = {}
    -- Für jedes Ped einen Promise zum Einsteigen anlegen
    for seatIndex, passenger in pairs(passengers) do
        table.insert(self.promises, self:DriversPedEnterVehicleTask(vehNet, seatIndex, passenger))
    end
    -- Alle Peds haben das Fahrzeug betreten
    Citizen.Await(promise.all(self.promises))
    return promiseEnter:resolve(true)
end

---Hauptverhalten und Promise bis alle Charaktere ein Fahrzeug verlassen haben
---@param vehNet number
---@return promise
function DriversTask:DriversWaitForAllPedsToLeaveVehicle(vehNet)
    local promiseLeave = promise.new()
    local passengers = self.passengersHandle
    self.promises = {}
    -- Für jedes Ped einen Promise zum Aussteigen anlegen
    for seatIndex, passenger in pairs(passengers) do
        table.insert(self.promises, self:DriversPedLeaveVehicleTask(vehNet, seatIndex, passenger))
    end
    -- Alle Peds haben das Fahrzeug verlassen
    Citizen.Await(promise.all(self.promises))
    return promiseLeave:resolve(true)
end

---Hauptverhalten und Promise damit eine Fahrgemeinschaft zu einem Punkt in der Spielwelt fährt
function DriversTask:DriversDriveToCoordsTask(vehNet)
    local promise = promise.new()
    local passengersHandle = self.passengersHandle
    local taskInfo = self.taskInfo
    local vehHandle = self.vehHandle
    local driverHandle = passengersHandle[-1]
    if not IsEntityDead(driverHandle) then
        TaskVehicleDriveToCoordLongrange(driverHandle, vehHandle, taskInfo.x, taskInfo.y, taskInfo.z, taskInfo.speed,
            taskInfo.driveMode, taskInfo.stopRange)
    end
    ---Code zur Überprüfung, ob der Zielpunkt erreicht wurde
    --local driversCoords = GetEntityCoords(driverHandle)
    --local destCoords = vector3(taskInfo.x, taskInfo.y, taskInfo.z)
    --Citizen.CreateThread(function()
    --    while AreVehicleAndPedExistingAndOperational(vehHandle, driverHandle) and VectDist(driversCoords, destCoords) <= taskInfo.stopRange and DriversRunningTasks[vehNet].taskAction == DriversDriveToCoordsTask do
    --        Citizen.Wait(THREAD_SLEEP_DURATION)
    --        driversCoords = GetEntityCoords(driverHandle)
    --    end
    --end)
    --DriversRunningTasks.taskAction = functionDoNothing()
    --DriversRunningTasks[vehNet].taskAction = DriversDoNothingTask
    return promise:resolve(true)
end

---Prüft ob zwei Entities nahe genug bei einander sind
---@param targetHandle number
---@param sourceHandle number
---@param distanceThreshold number
---@return boolean
function DriversTask:IsTargetNearSource(targetHandle, sourceHandle, distanceThreshold)
    local targetCoords = GetEntityCoords(targetHandle)
    local sourceCoords = GetEntityCoords(sourceHandle)
    local distance = Vdist(sourceCoords.x, sourceCoords.y, sourceCoords.z, targetCoords.x, targetCoords.y, targetCoords
        .z)
    if distance <= distanceThreshold then
        return true
    else
        return false
    end
end

---Prüft ob die lokalen Entities Fahrzeug und Passagier funktionstüchtig sind
---@param vehHandle number
---@param pedHandle number
---@return boolean
function DriversTask:AreVehicleAndPedExistingAndOperational(vehHandle, pedHandle)
    if DoesEntityExist(vehHandle) and GetVehicleEngineHealth(vehHandle) > 0 and DoesEntityExist(pedHandle) and not IsEntityDead(pedHandle) then
        return true
    else
        return false
    end
end

---Basierend auf den Abstand wird die Laufgeschwindigkeit bestimmt
---@param distance number
---@return number
function DriversTask:CalculateWalkSpeedBasedOnDistance(distance)
    if distance < 5.0 then
        return 1.0
    elseif distance < 10.0 then
        return 2.0
    else
        return 5.0
    end
    --return math.floor(1 + 2 * (1 - 1 / (1 + (distance / math.sqrt(distance + 100)))))
end

---Die Distanz von zwei Punkten im 3D Raum
---@param v1 table
---@param v2 table
---@return number distance
function DriversTask:VectDist(v1, v2)
    local sum = 0
    for axis, value in pairs(v1) do
        sum = sum + (v1[axis] - v2[axis]) ^ 2
    end
    return math.sqrt(sum)
end

---Die Anzahl an Elementen in einem Table
---@param T table
---@return number count
function DriversTask:GetCountOfTable(T)
    local count = 0
    for key, value in pairs(T) do
        count = count + 1
    end
    return count
end

---Hauptverhalten und Promise dafür dass die Fahrgemeinschaft das Ziel im Fahrzeug eskortiert
---@param vehNet number
---@return promise
function DriversTask:DriversEscortTargetSubtaskTargetInVehicle(vehNet)
    local promise = promise.new()
    local passengersHandle = self.passengersHandle
    local taskInfo = self.taskInfo
    local vehHandle = self.vehHandle
    local driverHandle = passengersHandle[-1]
    local targetHandle = self.targetHandle
    local targetVehHandle = GetVehiclePedIsIn(targetHandle, false)
    if self:IsAbleToFulfillTaskAction() and not self.behaviorSwitch then
        if self:AreVehicleAndPedExistingAndOperational(vehHandle, driverHandle) and DoesEntityExist(targetHandle) then
            TaskVehicleEscort(driverHandle, vehHandle, targetVehHandle, taskInfo.escortMode, taskInfo.speed,
                taskInfo.drivingMode, taskInfo.minDrivingDistance, 0, taskInfo.noRoadsDistance)
        end
    end
    return promise:resolve(true)
end

---Hauptverhalten und Promise dafür dass die Fahrgemeinschaft das Ziel zu Fuß eskortiert
function DriversTask:DriversEscortTargetSubtaskTargetOnFoot(vehNet)
    local promise = promise.new()
    local passengersHandle = self.passengersHandle
    local taskInfo = self.taskInfo
    local vehHandle = self.vehHandle
    local driverHandle = passengersHandle[-1]
    local targetHandle = self.targetHandle
    while self:IsAbleToFulfillTaskAction() and self.behaviorSwitch do
        if self:AreVehicleAndPedExistingAndOperational(vehHandle, driverHandle) and DoesEntityExist(targetHandle) then
            for _, passengerHandle in pairs(passengersHandle) do
                if self.groupIds[passengerHandle] == nil and not IsEntityDead(passengerHandle) then
                    local distanceToTarget = self:VectDist(GetEntityCoords(targetHandle),
                        GetEntityCoords(passengerHandle))
                    if distanceToTarget > 3.0 then
                        TaskGoToEntity(passengerHandle, targetHandle, taskInfo.followEntityDuration, 3.0,
                            self:CalculateWalkSpeedBasedOnDistance(distanceToTarget),
                            1073741824, 0)
                    else
                        TaskTurnPedToFaceEntity(passengerHandle, targetHandle, -1)
                    end
                end
            end
            Wait(THREAD_SLEEP_DURATION)
        end
    end
    return promise:resolve(true)
end

---Hauptverhalten und Promise das die Fahrgemeinschaft dem Ziel im Fahrzeug folgt
function DriversTask:DriversChaseTargetSubtaskTargetInVehicle(vehNet)
    local promise = promise.new()
    local passengersHandle = self.passengersHandle
    local taskInfo = self.taskInfo
    local vehHandle = self.vehHandle
    local driverHandle = passengersHandle[-1]
    local targetHandle = self.targetHandle
    local targetVehHandle = GetVehiclePedIsIn(targetHandle, false)
    if self:IsAbleToFulfillTaskAction() and not self.behaviorSwitch then
        if self:AreVehicleAndPedExistingAndOperational(vehHandle, driverHandle) and DoesEntityExist(targetHandle) then
            TaskVehicleChase(driverHandle, targetHandle)
        end
    end
    return promise:resolve(true)
end

---Hauptverhalten und Promise dafür dass die Fahrgemeinschaft dem Ziel zu Fuß folgt
function DriversTask:DriversChaseTargetSubtaskTargetOnFoot(vehNet)
    local promise = promise.new()
    local passengersHandle = self.passengersHandle
    local taskInfo = self.taskInfo
    local vehHandle = self.vehHandle
    local driverHandle = passengersHandle[-1]
    local targetHandle = self.targetHandle
    while self:IsAbleToFulfillTaskAction() and self.behaviorSwitch do
        if self:AreVehicleAndPedExistingAndOperational(vehHandle, driverHandle) and DoesEntityExist(targetHandle) then
            for _, passengerHandle in pairs(passengersHandle) do
                if self.groupIds[passengerHandle] == nil and not IsEntityDead(passengerHandle) then
                    TaskCombatPed(passengerHandle, targetHandle, 0, 16)
                end
            end
            Wait(THREAD_SLEEP_DURATION)
        end
    end
    return promise:resolve(true)
end

---Klasse für Unterbrecher von Fahrgemeinschaften Client Threads
DriversTaskInterruptor = DriversTask:new() --{ vehNet = 0, threadsActive = {} }

---Unterbricht das aktuelle Verhalten der Fahrgemeinschaft (Es sei denn sie ist im Kampf)
function DriversTaskInterruptor:Interrupt()
    local passengers = self.passengersHandle
    if self.promises ~= nil then
        for key, promise in pairs(self.promises) do
            promise:resolve(true)
        end
        self.promises = nil
        self.taskAction = nil
    end
    for seatindex, passengerHandle in pairs(passengers) do
        if not IsPedInCombat(passengerHandle) then
            ClearPedTasks(passengerHandle)
        end
    end
    Wait(THREAD_SLEEP_DURATION)
end

---Stoppt alle Unterbrecher die zu einem Hauptthread einer Fahrgemeinschaft gehören
function DriversTaskInterruptor:StopAllInterruptors()
    if self.promises ~= nil then
        for key, promise in pairs(self.promises) do
            promise:resolve(true)
        end
        self.promises = nil
    end
    for key, threadid in pairs(self.threadsActive) do
        self.threadsActive[key] = false
    end
end

---Prüft ob ein Unterbrecher funktionstüchtig ist
---@param isthreadactive boolean
---@return boolean
function DriversTaskInterruptor:IsInterruptorAbleToRun(isthreadactive)
    if not self.markedForTermination and isthreadactive then
        return true
    else
        return false
    end
end

---Erstellt Threads für die benötigten Unterbrecher
function DriversTaskInterruptor:SetUpInterruptors()
    self:SetUpBasicInterruptors()
end

---Erstellt die wesentlichen Unterbrecher
function DriversTaskInterruptor:SetUpBasicInterruptors()
    self:SetUpEliminationInterruptors()
    self:SetUpCombatInterruptors()
end

---Erstellt die Unterbrecher die den Lebenszustand von Fahrzeug und Passagieren überwachen
function DriversTaskInterruptor:SetUpEliminationInterruptors()
    CreateThread(function()
        self:VehicleDestroyedInterruptor()
    end)
    CreateThread(function()
        self:PassengerDeadInterruptor()
    end)
end

---Erstellt die Unterbrecher die den Kampfzustand der Fahrgemeinschaft überwachen
function DriversTaskInterruptor:SetUpCombatInterruptors()
    --CreateThread(function()
    --    self:SomeoneInCombatInterruptor()
    --end)
    CreateThread(function()
        self:EveryoneLeftCombatInterruptor()
    end)
end

---Unterbrecher falls Fahrzeug unbrauchbar wird
function DriversTaskInterruptor:VehicleDestroyedInterruptor()
    self.threadsActive.vehicleDestroyed = true
    local vehHandle = self.vehHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.vehicleDestroyed) do
        if DoesEntityExist(vehHandle) and GetVehicleEngineHealth(vehHandle) > 0 then
            --EverythingIsFine
            Wait(THREAD_SLEEP_DURATION - 100)
        else
            --self:Interrupt()
            self.taskAction = nil
            print(self.vehNet .. ": Interruptor VehicleDead")
            TriggerServerEvent("SEv_InformThatDriversCarIsGone", self.vehNet, GetPlayerServerId(PlayerId()))
            self:StopAllInterruptors()
        end
        Wait(1)
    end
    self.threadsActive.vehicleDestroyed = nil
end

---Unterbrecher falls Passagier unbrauchbar wird
function DriversTaskInterruptor:PassengerDeadInterruptor()
    self.threadsActive.passengerDead = true
    local passengersHandle = self.passengersHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.passengerDead) do
        for seatIndex, passengerHandle in pairs(passengersHandle) do
            if DoesEntityExist(passengerHandle) and not IsEntityDead(passengerHandle) then
                --EverythingIsFine
                Wait(THREAD_SLEEP_DURATION - 100)
            else
                --self:Interrupt()
                print(self.vehNet .. ": Interruptor PedDead")
                self.taskAction = nil
                TriggerServerEvent("SEv_InformThatDriversPedIsGone", NetworkGetNetworkIdFromEntity(passengerHandle),
                    GetPlayerServerId(PlayerId()))
                self:StopAllInterruptors()
                break
            end
        end
        Wait(1)
    end
    self.threadsActive.passengerDead = nil
end

---Unterbrecher falls jemand in einen Kampf verwickelt wird
function DriversTaskInterruptor:SomeoneInCombatInterruptor()
    self.threadsActive.someoneInCombat = true
    local passengersHandle = self.passengersHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.someoneInCombat) do
        for seatIndex, passengerHandle in pairs(passengersHandle) do
            if not IsPedInCombat(passengerHandle) then
                --EverythingIsFine
                Wait(THREAD_SLEEP_DURATION + 10)
            elseif not IsEntityDead(passengerHandle) then
                --self:Interrupt()
                self.taskAction = nil
                print(self.vehNet .. ": Interruptor InCombat")
                Wait(1000)
                self.threadsActive.someoneInCombat = false
                if self.threadsActive.everyoneLeftCombat ~= true then
                    CreateThread(function()
                        self:EveryoneLeftCombatInterruptor()
                    end)
                end
                break
            else
                break
            end
        end
        Wait(1)
    end
    self.threadsActive.someoneInCombat = nil
end

---Unterbrecher falls alle Passagiere den Kampf beendet haben
function DriversTaskInterruptor:EveryoneLeftCombatInterruptor()
    self.threadsActive.everyoneLeftCombat = true
    local passengersHandle = self.passengersHandle
    local passengerCount = self:GetCountOfTable(passengersHandle)
    local notInCombatCount = 0
    while self:IsInterruptorAbleToRun(self.threadsActive.everyoneLeftCombat) do
        notInCombatCount = 0
        for seatIndex, passengerHandle in pairs(passengersHandle) do
            if not IsEntityDead(passengerHandle) and not IsPedInCombat(passengerHandle) then
                notInCombatCount = notInCombatCount + 1
            end
        end
        if notInCombatCount >= passengerCount then
            --self:Interrupt()
            --Wait(3000)
            self.taskAction = self.previousTaskAction
            print(self.vehNet .. ": Interruptor LeftCombat")
            if self.threadsActive.someoneInCombat ~= true then
                CreateThread(function()
                    self:SomeoneInCombatInterruptor()
                end)
            end
            self.threadsActive.everyoneLeftCombat = false
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.everyoneLeftCombat = nil
end

---Klasse für erweiterte Unterbrecher die Ein- und Aussteigen überwachen
DriversAdvancedTaskInterruptor = DriversTaskInterruptor:new()

---Erstellt Threads für die benötigten Unterbrecher
function DriversAdvancedTaskInterruptor:SetUpInterruptors()
    self:SetUpBasicInterruptors()
    Wait(100)
    self:SetUpAdvancedInterruptors()
end

---Erstellt Threads für die benötigten erweiterten Unterbrecher
function DriversAdvancedTaskInterruptor:SetUpAdvancedInterruptors()
    CreateThread(function()
        self:SomeoneLeftTheVehicleInterruptor()
    end)
    CreateThread(function()
        self:EveryoneIsInVehicleInterruptor()
    end)
end

---Unterbrecher wenn jemand der Fahrgemeinschaft das Fahrzeug verlassen hat
function DriversAdvancedTaskInterruptor:SomeoneLeftTheVehicleInterruptor()
    self.threadsActive.someoneLeftTheVehicle = true
    local vehHandle = self.vehHandle
    local passengersHandle = self.passengersHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.someoneLeftTheVehicle) do
        for seatIndex, passengerHandle in pairs(passengersHandle) do
            if not IsPedInVehicle(passengerHandle, vehHandle, false) and self:IsAbleToFulfillTaskAction() then
                --self:Interrupt()
                Wait(100)
                self.taskAction = self
                    .DriversWaitForAllPedsToEnterVehicle
                self.previousTaskAction = self.taskAction
                self.threadsActive.someoneLeftTheVehicle = false
                print(self.vehNet .. ": Interruptor SomeoneLeftTheVehicleInterruptor")
                if self.threadsActive.everyoneIsInVehicle ~= true then
                    CreateThread(function()
                        self:EveryoneIsInVehicleInterruptor()
                    end)
                end
                break
            end
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.someoneLeftTheVehicle = nil
end

---Unterbrecher wenn jeder Passagier der Fahrgemeinschaft im Fahrzeug sitzt
function DriversAdvancedTaskInterruptor:EveryoneIsInVehicleInterruptor()
    self.threadsActive.everyoneIsInVehicle = true
    local vehHandle = self.vehHandle
    local passengersHandle = self.passengersHandle
    local passengerCount = self:GetCountOfTable(passengersHandle)
    local inVehicleCount = 0
    while self:IsInterruptorAbleToRun(self.threadsActive.everyoneIsInVehicle) do
        inVehicleCount = 0
        for seatIndex, passengerHandle in pairs(passengersHandle) do
            if IsPedInVehicle(passengerHandle, vehHandle, false) then
                inVehicleCount = inVehicleCount + 1
            end
        end
        if inVehicleCount >= passengerCount and self:IsAbleToFulfillTaskAction() then
            --self:Interrupt()
            self:SetMainTaskAction(self.vehNet,
                self.taskInfo.type)
            print(self.vehNet .. ": Interruptor EveryoneIsInVehicleInterruptor")
            self.previousTaskAction = self.taskAction
            if self.threadsActive.someoneLeftTheVehicle ~= true then
                CreateThread(function()
                    self:SomeoneLeftTheVehicleInterruptor()
                end)
            end
            self.threadsActive.everyoneIsInVehicle = false
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.everyoneIsInVehicle = nil
end

---Unterbrecher wenn alle Passagiere das Fahrzeug verlassen haben
function DriversAdvancedTaskInterruptor:EveryoneGotOutOfVehicleInterruptor()
    self.threadsActive.everyoneGotOutOfVehicle = true
    local vehHandle = self.vehHandle
    local passengersHandle = self.passengersHandle
    local passengerCount = self:GetCountOfTable(passengersHandle)
    local outOfVehicleCount = 0
    while self:IsInterruptorAbleToRun(self.threadsActive.everyoneGotOutOfVehicle) do
        for seatIndex, passengerHandle in pairs(passengersHandle) do
            if not IsPedInVehicle(passengerHandle, vehHandle, false) then
                outOfVehicleCount = outOfVehicleCount + 1
            end
        end
        if outOfVehicleCount >= passengerCount and self:IsAbleToFulfillTaskAction() then
            --self:Interrupt()
            self:SetMainTaskAction(self.vehNet, self.taskInfo.type)
            self.previousTaskAction = self.taskAction
            print(self.vehNet .. ": Interruptor EveryoneGotOutOfVehicleInterruptor")
            self.threadsActive.everyoneGotOutOfVehicle = false
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.everyoneGotOutOfVehicle = nil
end

---Klasse für Unterbrecher die ein Zielverfolgungscharakter haben
DriversAdvancedTargetTaskInterruptor = DriversAdvancedTaskInterruptor:new()

---Erstellt Threads für die benötigten Unterbrecher
function DriversAdvancedTargetTaskInterruptor:SetUpInterruptors()
    self:SetUpBasicInterruptors()
    Wait(100)
    self:SetUpAdvancedTargetInterruptors()
end

---Erstellt die Threads für die Überwachung des Zielcharakters durch Unterbrecher
function DriversAdvancedTargetTaskInterruptor:SetUpAdvancedTargetInterruptors()
    CreateThread(function()
        self:TargetDeadInterruptor()
    end)
    CreateThread(function()
        self:TargetLeftVehicleInterruptor()
    end)
    CreateThread(function()
        self:TargetTriesToGetInVehicleInterruptor()
    end)
    CreateThread(function()
        self:TargetInVehicleInterruptor()
    end)
end

---Unterbrecher falls das Verfolgungsziel unbrauchbar wird
function DriversAdvancedTargetTaskInterruptor:TargetDeadInterruptor()
    self.threadsActive.targetDead = true
    local targetHandle = self.targetHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.targetDead) do
        if DoesEntityExist(targetHandle) and not IsEntityDead(targetHandle) then
            --EverythingIsFine
            Wait(THREAD_SLEEP_DURATION - 100)
        else
            --self:Interrupt()
            print(self.vehNet .. ": Interruptor TargetDead")
            self.taskAction = nil
            TriggerServerEvent("SEv_InformThatDriversTargetIsGone", self.vehNet,
                GetPlayerServerId(PlayerId()), self.taskInfo.targetNet)
            self:StopAllInterruptors()
            break
        end
        Wait(1)
    end
    self.threadsActive.targetDead = nil
end

---Unterbrecher falls das Verfolgungsziel sein Fahrzeug verlassen hat
function DriversAdvancedTargetTaskInterruptor:TargetLeftVehicleInterruptor()
    self.threadsActive.targetLeftTheVehicle = true
    local vehHandle = self.vehHandle
    local passengersHandle = self.passengersHandle
    local targetHandle = self.targetHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.targetLeftTheVehicle) do
        if not IsPedSittingInVehicle(targetHandle, GetVehiclePedIsIn(targetHandle, false)) and self:IsAbleToFulfillTaskAction() then
            --self:Interrupt()
            print(self.vehNet .. ": Interruptor TargetLeftVehicleInterruptor")
            self.threadsActive.targetLeftTheVehicle = false
            if self.threadsActive.targetInGetOutReach ~= true then
                CreateThread(function()
                    self:TargetInGetOutReachInterruptor()
                end)
            end
            if self.threadsActive.targetTriesToGetInVehicle ~= true then
                CreateThread(function()
                    self:TargetTriesToGetInVehicleInterruptor()
                end)
            end
            if self.threadsActive.targetInVehicle ~= true then
                CreateThread(function()
                    self:TargetInVehicleInterruptor()
                end)
            end
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.targetLeftTheVehicle = nil
end

---Unterbrecher falls das Verfolgungsziel versucht in ein Fahrzeug einzusteigen
function DriversAdvancedTargetTaskInterruptor:TargetTriesToGetInVehicleInterruptor()
    self.threadsActive.targetTriesToGetInVehicle = true
    local targetHandle = self.targetHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.targetTriesToGetInVehicle) do
        if tonumber(GetVehiclePedIsTryingToEnter(targetHandle)) ~= 0 and self:IsAbleToFulfillTaskAction() then
            self:Interrupt()
            print(self.vehNet .. ": Interruptor TargetTriesToGetInVehicleInterruptor")
            self.taskAction = self
                .DriversWaitForAllPedsToEnterVehicle
            self.previousTaskAction = self.taskAction
            self.threadsActive.targetTriesToGetInVehicle = false
            if self.threadsActive.targetAboundedGetInVehicle ~= true then
                CreateThread(function()
                    self:TargetAboundedGetInVehicleInterruptor()
                end)
            end
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.targetTriesToGetInVehicle = nil
end

---Unterbrecher falls das Verfolgungsziel den Versuch ins Fahrzeug einzusteigen abgebrochen hat
function DriversAdvancedTargetTaskInterruptor:TargetAboundedGetInVehicleInterruptor()
    self.threadsActive.targetAboundedGetInVehicle = true
    local targetHandle = self.targetHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.targetAboundedGetInVehicle) do
        if tonumber(GetVehiclePedIsTryingToEnter(targetHandle)) == 0 and not IsPedInAnyVehicle(targetHandle, true) and self:IsAbleToFulfillTaskAction() then
            self:Interrupt()
            print(self.vehNet .. ": Interruptor TargetAboundedGetInVehicleInterruptor")
            self:SetMainTaskAction(self.vehNet,
                self.taskInfo.type)
            self.previousTaskAction = self.taskAction
            self.threadsActive.targetAboundedGetInVehicle = false
            if self.threadsActive.targetTriesToGetInVehicle ~= true then
                CreateThread(function()
                    self:TargetTriesToGetInVehicleInterruptor()
                end)
            end
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.targetAboundedGetInVehicle = nil
end

---Unterbrecher falls das Verfolgungsziel in ein Fahrzeug eingestiegen ist
function DriversAdvancedTargetTaskInterruptor:TargetInVehicleInterruptor()
    self.threadsActive.targetInVehicle = true
    local vehHandle = self.vehHandle
    local passengersHandle = self.passengersHandle
    local targetHandle = self.targetHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.targetInVehicle) do
        if IsPedSittingInVehicle(targetHandle, GetVehiclePedIsIn(targetHandle, false)) and self:IsAbleToFulfillTaskAction() then
            --self:Interrupt()
            if self.threadsActive.targetTriesToGetInVehicle ~= nil then
                self.threadsActive.targetTriesToGetInVehicle = false
            end
            if self.threadsActive.targetInGetOutReach ~= nil then
                self.threadsActive.targetInGetOutReach = false
            end
            if self.threadsActive.targetAboundedGetInVehicle ~= nil then
                self.threadsActive.targetAboundedGetInVehicle = false
            end
            Wait(THREAD_SLEEP_DURATION)
            print(self.vehNet .. ": Interruptor TargetInVehicleInterruptor")
            self.taskAction = self
                .DriversWaitForAllPedsToEnterVehicle
            self.behaviorSwitch = false
            self.previousTaskAction = self.taskAction
            self.threadsActive.targetInVehicle = false
            if self.threadsActive.targetLeftTheVehicle ~= true then
                CreateThread(function()
                    self:TargetLeftVehicleInterruptor()
                end)
            end
            if self.threadsActive.everyoneIsInVehicle ~= true then
                CreateThread(function()
                    self:EveryoneIsInVehicleInterruptor()
                end)
            end
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.targetInVehicle = nil
end

---Unterbrecher falls die Fahrgemeinschaft in Ausstiegsreichweite des Verfolgungsziels ist
function DriversAdvancedTargetTaskInterruptor:TargetInGetOutReachInterruptor()
    self.threadsActive.targetInGetOutReach = true
    local vehHandle = self.vehHandle
    local passengersHandle = self.passengersHandle
    local targetHandle = self.targetHandle
    while self:IsInterruptorAbleToRun(self.threadsActive.targetInGetOutReach) do
        if self:IsTargetNearSource(targetHandle, passengersHandle[-1], self.taskInfo.minDistance) then
            if self.threadsActive.someoneLeftTheVehicle ~= nil then
                self.threadsActive.someoneLeftTheVehicle = false
                Wait(THREAD_SLEEP_DURATION)
            end
            print(self.vehNet .. ": Interruptor TargetInGetOutReachInterruptor")
            self.taskAction = self
                .DriversWaitForAllPedsToLeaveVehicle
            self.behaviorSwitch = true
            self.previousTaskAction = self.taskAction
            self.threadsActive.targetInGetOutReach = false
            if self.threadsActive.everyoneGotOutOfVehicle ~= true then
                CreateThread(function()
                    self:EveryoneGotOutOfVehicleInterruptor()
                end)
            end
        end
        Wait(THREAD_SLEEP_DURATION)
    end
    self.threadsActive.targetInGetOutReach = nil
end
