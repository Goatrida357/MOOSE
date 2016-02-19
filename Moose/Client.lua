--- CLIENT Classes
-- @classmod CLIENT

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Cargo" )
Include.File( "Message" )

--- Clients are those Groups defined within the Mission Editor that have the skillset defined as "Client" or "Player".
-- These clients are defined within the Mission Orchestration Framework (MOF)

CLIENT = {
	ONBOARDSIDE = {
		NONE = 0,
		LEFT = 1,
		RIGHT = 2,
		BACK = 3,
		FRONT = 4
	},
	ClassName = "CLIENT",
	ClientName = nil,
	ClientAlive = false,
	ClientTransport = false,
	ClientBriefingShown = false,
	_Menus = {},
	_Cargos = {},
	_Tasks = {},
	Messages = { 
	}
}


--- Use this method to register new Clients within the MOF.
-- @tparam string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
-- @tparam string ClientBriefing Text that describes the briefing of the mission when a Player logs into the Client.
-- @treturn CLIENT
-- @usage
-- -- Create new Clients.
--	local Mission = MISSIONSCHEDULER.AddMission( 'Russia Transport Troops SA-6', 'Operational', 'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 'Russia' )
--	Mission:AddGoal( DeploySA6TroopsGoal )
--
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*HOT-Deploy Troops 1' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*RAMP-Deploy Troops 3' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*HOT-Deploy Troops 2' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*RAMP-Deploy Troops 4' ):Transport() )

function CLIENT:New( ClientName, ClientBriefing )
trace.f( self.ClassName, { ClientName, ClientBriefing } )

	-- Arrange meta tables
	local self = BASE:Inherit( self, BASE:New() )
	self.ClientName = ClientName
	self:AddBriefing( ClientBriefing )
	self.MessageSwitch = true
	
	return self
end

--- Resets a CLIENT.
-- @tparam string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
function CLIENT:Reset( ClientName )
trace.f(self.ClassName)
	self._Menus = {}
	self._Cargos = {}
end

--- ClientGroup returns the Group of a Client.
-- This function is modified to deal with a couple of bugs in DCS 1.5.3
-- @treturn Group
function CLIENT:ClientGroup()
trace.f(self.ClassName)

--  local ClientData = Group.getByName( self.ClientName )
--	if ClientData and ClientData:isExist() then
--		trace.i( self.ClassName, self.ClientName .. " : group found!" )
--		return ClientData
--	else
--		return nil
--	end

	local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
	for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
		trace.i( self.ClassName, CoalitionData )
		for UnitId, UnitData in pairs( CoalitionData ) do
			trace.i( self.ClassName, UnitData )
			if UnitData and UnitData:isExist() then

				local ClientGroup = Group.getByName( self.ClientName )
				if ClientGroup then
					trace.i( self.ClassName, "ClientGroup = " .. self.ClientName )
					if ClientGroup:isExist() and ClientGroup:getID() == UnitData:getGroup():getID() then
						trace.i( self.ClassName, "Normal logic" )
						trace.i( self.ClassName, self.ClientName .. " : group found!" )
						return ClientGroup
					else
						-- Now we need to resolve the bugs in DCS 1.5 ...
						-- Consult the database for the units of the Client Group. (ClientGroup:getUnits() returns nil)
						trace.i( self.ClassName, "Bug 1.5 logic" )
						local ClientUnits = _Database.Groups[self.ClientName].Units
						trace.i( self.ClassName, { ClientUnits[1].name, env.getValueDictByKey(ClientUnits[1].name) } )
						for ClientUnitID, ClientUnitData in pairs( ClientUnits ) do
							trace.i( self.ClassName, { tonumber(UnitData:getID()), ClientUnitData.unitId } )
							if tonumber(UnitData:getID()) == ClientUnitData.unitId then
								local ClientGroupTemplate = _Database.Groups[self.ClientName].Template
								self.ClientGroupID = ClientGroupTemplate.groupId
								self.ClientGroupUnit = UnitData
								trace.i( self.ClassName, self.ClientName .. " : group found in bug 1.5 resolvement logic!" )
								return ClientGroup
							end
						end
					end
--				else
--					error( "Client " .. self.ClientName .. " not found!" )
				end
			end
		end
	end
	
	self.ClientGroupID = nil
	self.ClientGroupUnit = nil
	
	return nil
end 


function CLIENT:GetClientGroupID()
trace.f(self.ClassName)

	ClientGroup = self:ClientGroup()
	
	if ClientGroup then
		if ClientGroup:isExist() then
			return ClientGroup:getID()
		else
			return self.ClientGroupID
		end
	end
	
	return nil
end

--- Returns the Unit of the @{CLIENT}.
-- @treturn Unit
function CLIENT:GetClientGroupUnit()
trace.f(self.ClassName)

	ClientGroup = self:ClientGroup()
	
	if ClientGroup then
		if ClientGroup:isExist() then
			return ClientGroup:getUnits()[1]
		else
			return self.ClientGroupUnit
		end
	end
	
	return nil
end


--- Returns the Position of the @{CLIENT}.
-- @treturn Position
function CLIENT:ClientPosition()
--trace.f(self.ClassName)
	local ClientData = Group.getByName( self.ClientName )
	if ClientData and ClientData:isExist() then
		trace.i( self.ClassName, self.ClientName .. " : group found!" )
		return ClientData:getUnits()[1]:getPosition()
	else
		return nil
	end
end 

--- Transport defines that the Client is a Transport.
-- @treturn CLIENT
function CLIENT:Transport()
trace.f(self.ClassName)

	self.ClientTransport = true
	return self
end

--- AddBriefing adds a briefing to a Client when a Player joins a Mission.
-- @tparam string ClientBriefing is the text defining the Mission briefing.
-- @treturn CLIENT
function CLIENT:AddBriefing( ClientBriefing )
trace.f(self.ClassName)
	self.ClientBriefing = ClientBriefing
	return self
end

--- IsTransport returns if a Client is a transport.
-- @treturn bool
function CLIENT:IsTransport()
trace.f(self.ClassName)
	return self.ClientTransport
end

--- FindCargo finds loaded Cargo within a CLIENT instance.
-- Cargo is loaded when certain PICK-UP or DEPLOY Tasks are properly executed.
-- @tparam string CargoName is the name of the cargo.
-- @treturn CARGO_TYPE
function CLIENT:FindCargo( CargoName )
trace.f(self.ClassName)
	return self._Cargos[CargoName]
end

--- ShowCargo shows the @{CARGO} within the CLIENT to the Player.
-- The @{CARGO} is shown throught the MESSAGE system of DCS World.
function CLIENT:ShowCargo()
trace.f( self.ClassName )

	local CargoMsg = ""
  
	for CargoName, Cargo in pairs( self._Cargos ) do
		if CargoMsg  ~= "" then
			CargoMsg = CargoMsg .. "\n"
		end
		CargoMsg = CargoMsg .. Cargo.CargoName .. " Type:" ..  Cargo.CargoType .. " Weight: " .. Cargo.CargoWeight
	end
  
	if CargoMsg == '' then
		CargoMsg = "empty"
	end
  
	self:Message( CargoMsg, 15, self.ClientName .. "/Cargo", "Co-Pilot: Cargo Status", 30 )

end

--- InitCargo allows to initialize @{CARGO} on the CLIENT when the client initializes.
-- @tparam string InitCargoNames is a string or a table containing the names of the @{CARGO}s initialized in the Mission.
-- @treturn CLIENT
function CLIENT:InitCargo( InitCargoNames )
trace.f(self.ClassName, { InitCargoNames } )

  local Valid = true
  
  if Valid then
	if type( InitCargoNames ) == "table" then
		self.InitCargoNames = InitCargoNames
	else
		self.InitCargoNames = { InitCargoNames }
	end
  end
  
  return self
  
end

--- AddCargo allows to add @{CARGO} on the CLIENT.
-- @tparam string Cargo is the @{CARGO}.
-- @treturn CLIENT
function CLIENT:AddCargo( Cargo )
trace.f(self.ClassName, { Cargo.CargoName } )

	local Valid = true
	  
	if Valid then
		self._Cargos[Cargo.CargoName] = Cargo
		self:ShowCargo()
	end
	  
	return self
  
end

--- RemoveCargo removes @{CARGO} from the CLIENT.
-- @tparam string CargoName is the name of the @{CARGO}.
-- @treturn Cargo
function CLIENT:RemoveCargo( Cargo )
trace.f(self.ClassName, { Cargo.CargoName } )

  local Valid = true

  if  Valid then
    trace.i( "CLIENT", "RemoveCargo: CargoName = " .. Cargo.CargoName )
	--local CargoNew = self._Cargos[Cargo.CargoName]
    self._Cargos[Cargo.CargoName] = nil
  end
  
  return Cargo
  
end

--- SwitchMessages is a local function called by the DCS World Menu system to switch off messages.
function CLIENT.SwitchMessages( PrmTable )
	PrmTable[1].MessageSwitch = PrmTable[2]
end

--- Message is the key Message driver for the CLIENT class.
-- This function displays various messages to the Player logged into the CLIENT through the DCS World Messaging system.
-- @tparam string Message is the text describing the message.
-- @tparam number MessageDuration is the duration in seconds that the Message should be displayed.
-- @tparam string MessageId is a text identifying the Message in the MessageQueue. The Message system overwrites Messages with the same MessageId
-- @tparam string MessageCategory is the category of the message (the title).
-- @tparam number MessageInterval is the interval in seconds between the display of the Message when the CLIENT is in the air.
function CLIENT:Message( Message, MessageDuration, MessageId, MessageCategory, MessageInterval )
trace.f( self.ClassName, { Message, MessageDuration, MessageId, MessageCategory, MessageInterval } )

	if not self.MenuMessages then
		if self:GetClientGroupID() then
			self.MenuMessages = MENU_SUB_GROUP:New( self:GetClientGroupID(), 'Messages' )
			self.MenuRouteMessageOn = MENU_COMMAND_GROUP:New( self:GetClientGroupID(), 'Messages On', self.MenuMessages, CLIENT.SwitchMessages, { self, true } )
			self.MenuRouteMessageOff = MENU_COMMAND_GROUP:New( self:GetClientGroupID(),'Messages Off', self.MenuMessages, CLIENT.SwitchMessages, { self, false } )
		end
	end

	if self.MessageSwitch == true then
		if MessageCategory == nil then
			MessageCategory = "Messages"
		end
		if self.Messages[MessageId] == nil then
			self.Messages[MessageId] = {}
			self.Messages[MessageId].MessageId = MessageId
			self.Messages[MessageId].MessageTime = timer.getTime()
			self.Messages[MessageId].MessageDuration = MessageDuration
			if MessageInterval == nil then
				self.Messages[MessageId].MessageInterval = 600
			else
				self.Messages[MessageId].MessageInterval = MessageInterval
			end
			MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
		else
			if self:GetClientGroupUnit() and not self:GetClientGroupUnit():inAir() then
				if timer.getTime() - self.Messages[MessageId].MessageTime >= self.Messages[MessageId].MessageDuration + 10 then
					MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
					self.Messages[MessageId].MessageTime = timer.getTime()
				end
			else
				if timer.getTime() - self.Messages[MessageId].MessageTime  >= self.Messages[MessageId].MessageDuration + self.Messages[MessageId].MessageInterval then
					MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
					self.Messages[MessageId].MessageTime = timer.getTime()
				end
			end
		end
	end
end
