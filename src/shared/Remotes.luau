--!strict
-- Names of the RemoteEvents / RemoteFunctions used between server and client.
-- The server creates them in ReplicatedStorage.Remotes (server/Net.luau);
-- clients find them with ReplicatedStorage.Remotes:WaitForChild(name).

local Remotes = {
	FOLDER = "Remotes",

	NOTIFY = "Notify", -- RemoteEvent, server → client: (text: string, kind: string) shows a toast
	SHOP_REQUEST = "ShopRequest", -- RemoteFunction, client → server: (action: string, itemId: string) → (ok, message)
}

return table.freeze(Remotes)
