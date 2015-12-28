Meteor.startup ->
	RocketChat.MessageAction.addButton
		id: 'star-message'
		icon: 'icon-star-empty'
		i18nLabel: 'Star_Message'
		action: (event, instance) ->
			message = @_arguments[1]
			message.starred = Meteor.userId()
			Meteor.call 'starMessage', message, (error, result) ->
				if error
					return Errors.throw error.reason
		validation: (message) ->
			return RocketChat.settings.get('Message_AllowStarring') and not message.starred
		order: 10

	RocketChat.MessageAction.addButton
		id: 'unstar-message'
		icon: 'icon-star'
		i18nLabel: 'Unstar_Message'
		action: (event, instance) ->
			message = @_arguments[1]
			message.starred = false
			Meteor.call 'starMessage', message, (error, result) ->
				if error
					return Errors.throw error.reason
		validation: (message) ->
			return RocketChat.settings.get('Message_AllowStarring') and message.starred
		order: 10

	RocketChat.MessageAction.addButton
		id: 'jump-to-star-message'
		icon: 'icon-right-hand'
		i18nLabel: 'Jump_to_message'
		action: (event, instance) ->
			message = @_arguments[1]
			$('.message-dropdown:visible').hide()
			RoomHistoryManager.getSurroundingMessages(message, 50)
		order: 100
