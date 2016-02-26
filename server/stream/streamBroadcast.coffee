logger = new Logger 'StreamBroadcast',
	sections:
		connection: 'Connection'
		auth: 'Auth'
		stream: 'Stream'


authorizeConnection = (connection, record) ->
	logger.auth.info "Authorizing with localhost:#{record.extraInformation.port}"
	connection.call 'broadcastAuth', record._id, InstanceStatus.id(), (err, ok) ->
		connection.broadcastAuth = ok
		logger.auth.info "broadcastAuth with localhost:#{record.extraInformation.port}", ok

@connections = {}
@startStreamBroadcast = (streams) ->
	logger.info 'startStreamBroadcast'

	# connections = {}

	InstanceStatus.getCollection().find({'extraInformation.port': {$exists: true}}, {sort: {_createdAt: -1}}).observe
		added: (record) ->
			if record.extraInformation.port is process.env.PORT or connections[record.extraInformation.port]?
				return

			logger.connection.info 'connecting in', "localhost:#{record.extraInformation.port}"
			connections[record.extraInformation.port] = DDP.connect("localhost:#{record.extraInformation.port}", {_dontPrintErrors: true})
			authorizeConnection(connections[record.extraInformation.port], record);
			connections[record.extraInformation.port].onReconnect = ->
				authorizeConnection(connections[record.extraInformation.port], record);

		removed: (record) ->
			if connections[record.extraInformation.port]? and not InstanceStatus.getCollection().findOne({'extraInformation.port': record.extraInformation.port})?
				logger.connection.info 'disconnecting from', "localhost:#{record.extraInformation.port}"
				connections[record.extraInformation.port].disconnect()
				delete connections[record.extraInformation.port]

	broadcast = (streamName, args, userId) ->
		for port, connection of connections
			do (port, connection) ->
				if connection.status().connected is true
					connection.call 'stream', streamName, args, (error, response) ->
						if error?
							logger.error "Stream broadcast error", error

						switch response
							when 'self-not-authorized'
								logger.stream.error "Stream broadcast from:#{process.env.PORT} to:#{connection._stream.endpoint} with name #{streamName} to self is not authorized".red
								logger.stream.debug "    -> connection authorized".red, connection.broadcastAuth
								logger.stream.debug "    -> connection status".red, connection.status()
								logger.stream.debug "    -> arguments".red, args

							when 'not-authorized'
								logger.stream.error "Stream broadcast from:#{process.env.PORT} to:#{connection._stream.endpoint} with name #{streamName} not authorized".red
								logger.stream.debug "    -> connection authorized".red, connection.broadcastAuth
								logger.stream.debug "    -> connection status".red, connection.status()
								logger.stream.debug "    -> arguments".red, args

							when 'stream-not-exists'
								logger.stream.error "Stream broadcast from:#{process.env.PORT} to:#{connection._stream.endpoint} with name #{streamName} does not exists".red
								logger.stream.debug "    -> connection authorized".red, connection.broadcastAuth
								logger.stream.debug "    -> connection status".red, connection.status()
								logger.stream.debug "    -> arguments".red, args


	Meteor.methods
		showConnections: ->
			data = {}
			for port, connection of connections
				data[port] =
					status: connection.status()
					broadcastAuth: connection.broadcastAuth
			return data

	emitters = {}

	for streamName, stream of streams
		do (streamName, stream) ->
			emitters[streamName] = stream.emitToSubscriptions
			stream.emitToSubscriptions = (args, subscriptionId, userId) ->
				if subscriptionId isnt 'broadcasted'
					broadcast streamName, args

				emitters[streamName] args, subscriptionId, userId

	Meteor.methods
		broadcastAuth: (selfId, remoteId) ->
			check selfId, String
			check remoteId, String

			@unblock()
			if selfId is InstanceStatus.id() and remoteId isnt InstanceStatus.id() and InstanceStatus.getCollection().findOne({_id: remoteId})?
				@connection.broadcastAuth = true

			return @connection.broadcastAuth is true

		stream: (streamName, args) ->
			# Prevent call from self and client
			if not @connection?
				return 'self-not-authorized'

			# Prevent call from unauthrorized connections
			if @connection.broadcastAuth isnt true
				return 'not-authorized'

			if not emitters[streamName]?
				return 'stream-not-exists'

			emitters[streamName].call null, args, 'broadcasted'

			return undefined


Meteor.startup ->
	config =
		'RocketChat.Notifications.streamAll': RocketChat.Notifications.streamAll
		'RocketChat.Notifications.streamRoom': RocketChat.Notifications.streamRoom
		'RocketChat.Notifications.streamUser': RocketChat.Notifications.streamUser

	startStreamBroadcast config
