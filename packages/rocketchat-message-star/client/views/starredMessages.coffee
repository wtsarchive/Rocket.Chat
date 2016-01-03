Template.starredMessages.helpers
	hasMessages: ->
		return StarredMessage.find({ rid: @rid }, { sort: { ts: -1 } }).count() > 0

	messages: ->
		return StarredMessage.find { rid: @rid }, { sort: { ts: -1 } }

	hasMore: ->
		return Template.instance().hasMore.get()

Template.starredMessages.onCreated ->
	@hasMore = new ReactiveVar true
	@limit = new ReactiveVar 50
	@autorun =>
		sub = @subscribe 'starredMessages', @data.rid, @limit.get()
		if sub.ready()
			if StarredMessage.find({ rid: @data.rid }).count() < @limit.get()
				@hasMore.set false

Template.starredMessages.events
	'click .message-cog': (e) ->
		e.stopPropagation()
		e.preventDefault()
		message_id = $(e.currentTarget).closest('.message').attr('id')
		$('.message-dropdown:visible').hide()
		$(".starred-messages-list \##{message_id} .message-dropdown").remove()
		message = StarredMessage.findOne message_id
		actions = RocketChat.MessageAction.getButtons message
		el = Blaze.toHTMLWithData Template.messageDropdown, { actions: actions }
		$(".starred-messages-list \##{message_id} .message-cog-container").append el
		dropDown = $(".starred-messages-list \##{message_id} .message-dropdown")
		dropDown.show()

	'scroll .content': _.throttle (e, instance) ->
		if e.target.scrollTop >= e.target.scrollHeight - e.target.clientHeight
			instance.limit.set(instance.limit.get() + 50)
	, 200
