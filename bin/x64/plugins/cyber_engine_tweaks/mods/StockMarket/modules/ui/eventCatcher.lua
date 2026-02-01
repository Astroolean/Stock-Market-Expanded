local utils = require("modules/utils/utils")

local catcher = {
    subscribers = {}
}

function catcher.init()
    Observe('sampleStyleManagerGameController', 'OnStyle1', function(self, evt) -- Hover in event
		local obj = catcher.getSubscriberByEventCatcher(self)
		if not obj then return end

		obj:hoverInCallback(evt:GetTarget())
	end)

	Observe('sampleStyleManagerGameController', 'OnStyle2', function(self, evt) -- Hover out event
		local obj = catcher.getSubscriberByEventCatcher(self)
		if not obj then return end

		obj:hoverOutCallback(evt:GetTarget())
	end)

	Observe('sampleStyleManagerGameController', 'OnState1', function(self, evt) -- Click event
		if not evt:IsAction("click") then return end
		local obj = catcher.getSubscriberByEventCatcher(self)
		if not obj then return end

		obj:clickCallback(evt:GetTarget())
	end)
end

function catcher.getSubscriberByEventCatcher(eventCatcher)
    for _, obj in pairs(catcher.subscribers) do
        if utils.isSameInstance(obj.eventCatcher, eventCatcher) then
            return obj
        end
    end
end

function catcher.removeSubscriber(obj)
	utils.removeItem(catcher.subscribers, obj)
end

return catcher