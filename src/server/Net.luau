--!strict
-- Creates the RemoteEvents / RemoteFunctions (names in shared/Remotes) once, when first required.
-- Server modules use them through this module.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local folder = Instance.new("Folder")
folder.Name = Remotes.FOLDER
folder.Parent = ReplicatedStorage

local function remoteEvent(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local function remoteFunction(name: string): RemoteFunction
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local Net = {
	Notify = remoteEvent(Remotes.NOTIFY),
	ShopRequest = remoteFunction(Remotes.SHOP_REQUEST),
}

-- Kinds of toast the client knows: "info", "coins", "success", "error".
function Net.notify(player: Player, text: string, kind: string?)
	Net.Notify:FireClient(player, text, kind or "info")
end

return Net
