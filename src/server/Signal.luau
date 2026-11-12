--!strict
-- Minimal signal (event). Lets other server modules react to round events
-- without the round code knowing about them.
--
--   local disconnect = signal:Connect(function(players) ... end)
--   signal:Fire(players)
--   disconnect()

type Handler = (...any) -> ()

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable({} :: { _handlers: { Handler } }, Signal))

function Signal.new(): Signal
	return setmetatable({ _handlers = {} :: { Handler } }, Signal)
end

-- Returns a function that removes the handler again.
function Signal.Connect(self: Signal, handler: Handler): () -> ()
	table.insert(self._handlers, handler)
	return function()
		local index = table.find(self._handlers, handler)
		if index then
			table.remove(self._handlers, index)
		end
	end
end

-- Calls every handler in its own thread, so one slow or failing handler doesn't block the others.
function Signal.Fire(self: Signal, ...: any)
	for _, handler in table.clone(self._handlers) do
		task.spawn(handler, ...)
	end
end

return Signal
