tabReset = ->
	RocketChat.TabBar.reset()

FlowRouter.route '/mailer',
	name: 'mailer'
	triggersEnter: [tabReset]
	triggersExit: [tabReset]
	action: ->
		BlazeLayout.render 'main', {center: 'mailer'}

FlowRouter.route '/mailer/unsubscribe/:_id/:createdAt',
	name: 'mailer-unsubscribe'
	action: (params) ->
		Meteor.call 'Mailer:unsubscribe', params._id, params.createdAt
		BlazeLayout.render 'mailerUnsubscribe'
