Meteor.methods
	updateIncomingIntegration: (integrationId, integration) ->
		if not RocketChat.authz.hasPermission @userId, 'manage-integrations'
			throw new Meteor.Error 'not_authorized'

		if not _.isString(integration.channel)
			throw new Meteor.Error 'invalid_channel', '[methods] updateIncomingIntegration -> channel must be string'

		if integration.channel.trim() is ''
			throw new Meteor.Error 'invalid_channel', '[methods] updateIncomingIntegration -> channel can\'t be empty'

		if integration.channel[0] not in ['@', '#']
			throw new Meteor.Error 'invalid_channel', '[methods] updateIncomingIntegration -> channel should start with # or @'

		currentIntegration = RocketChat.models.Integrations.findOne(integrationId)
		if not currentIntegration?
			throw new Meteor.Error 'invalid_integration', '[methods] updateIncomingIntegration -> integration not found'

		record = undefined
		channelType = integration.channel[0]
		channel = integration.channel.substr(1)

		switch channelType
			when '#'
				record = RocketChat.models.Rooms.findOne
					$or: [
						{_id: channel}
						{name: channel}
					]
			when '@'
				record = RocketChat.models.Users.findOne
					$or: [
						{_id: channel}
						{username: channel}
					]

		if record is undefined
			throw new Meteor.Error 'channel_does_not_exists', "[methods] updateIncomingIntegration -> The channel does not exists"

		user = RocketChat.models.Users.findOne({username: currentIntegration.username})
		RocketChat.models.Roles.addUserRoles user._id, 'bot'

		RocketChat.models.Integrations.update integrationId,
			$set:
				name: integration.name
				avatar: integration.avatar
				emoji: integration.emoji
				alias: integration.alias
				channel: integration.channel
				_updatedAt: new Date
				_updatedBy: RocketChat.models.Users.findOne @userId, {fields: {username: 1}}

		return RocketChat.models.Integrations.findOne(integrationId)
