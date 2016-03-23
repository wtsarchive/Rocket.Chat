Importer.HipChat = class Importer.HipChat extends Importer.Base
	@RoomPrefix = 'hipchat_export/rooms/'
	@UsersPrefix = 'hipchat_export/users/'

	constructor: (name, descriptionI18N, fileTypeRegex) ->
		super(name, descriptionI18N, fileTypeRegex)
		@userTags = []

	prepare: (dataURI, sentContentType, fileName) =>
		super(dataURI, sentContentType, fileName)

		# try
		{image, contentType} = RocketChatFile.dataURIParse dataURI
		zip = new @AdmZip(new Buffer(image, 'base64'))
		zipEntries = zip.getEntries()

		tempRooms = []
		tempUsers = []
		tempMessages = {}
		for entry in zipEntries
			do (entry) =>
				if not entry.isDirectory
					if entry.entryName.indexOf(Importer.HipChat.RoomPrefix) > -1
						roomName = entry.entryName.split(Importer.HipChat.RoomPrefix)[1]
						if roomName is 'list.json'
							@updateProgress Importer.ProgressStep.PREPARING_CHANNELS
							tempRooms = JSON.parse(entry.getData().toString()).rooms
							for room in tempRooms
								room.name = _.slugify room.name
						else if roomName.indexOf('/') > -1
							item = roomName.split('/')
							roomName = _.slugify item[0] #random
							msgGroupData = item[1].split('.')[0] #2015-10-04
							if not tempMessages[roomName]
								tempMessages[roomName] = {}
							# For some reason some of the json files in the HipChat export aren't valid JSON
							# files, so we need to catch those and just ignore them (sadly).
							try
								tempMessages[roomName][msgGroupData] = JSON.parse entry.getData().toString()
							catch
								console.warn "#{entry.entryName} is not a valid JSON file! Unable to import it."
					else if entry.entryName.indexOf(Importer.HipChat.UsersPrefix) > -1
						usersName = entry.entryName.split(Importer.HipChat.UsersPrefix)[1]
						if usersName is 'list.json'
							@updateProgress Importer.ProgressStep.PREPARING_USERS
							tempUsers = JSON.parse(entry.getData().toString()).users
						else
							console.warn "Unexpected file in the #{@name} import: #{entry.entryName}"

		# Insert the users record, eventually this might have to be split into several ones as well
		# if someone tries to import a several thousands users instance
		usersId = @collection.insert { 'import': @importRecord._id, 'importer': @name, 'type': 'users', 'users': tempUsers }
		@users = @collection.findOne usersId
		@updateRecord { 'count.users': tempUsers.length }
		@addCountToTotal tempUsers.length

		# Insert the rooms records.
		channelsId = @collection.insert { 'import': @importRecord._id, 'importer': @name, 'type': 'channels', 'channels': tempRooms }
		@channels = @collection.findOne channelsId
		@updateRecord { 'count.channels': tempRooms.length }
		@addCountToTotal tempRooms.length

		# Insert the messages records
		@updateProgress Importer.ProgressStep.PREPARING_MESSAGES
		messagesCount = 0
		for channel, messagesObj of tempMessages
			do (channel, messagesObj) =>
				if not @messages[channel]
					@messages[channel] = {}
				for date, msgs of messagesObj
					messagesCount += msgs.length
					@updateRecord { 'messagesstatus': "#{channel}/#{date}" }

					if Importer.Base.getBSONSize(msgs) > Importer.Base.MaxBSONSize
						for splitMsg, i in Importer.Base.getBSONSafeArraysFromAnArray(msgs)
							messagesId = @collection.insert { 'import': @importRecord._id, 'importer': @name, 'type': 'messages', 'name': "#{channel}/#{date}.#{i}", 'messages': splitMsg }
							@messages[channel]["#{date}.#{i}"] = @collection.findOne messagesId
					else
						messagesId = @collection.insert { 'import': @importRecord._id, 'importer': @name, 'type': 'messages', 'name': "#{channel}/#{date}", 'messages': msgs }
						@messages[channel][date] = @collection.findOne messagesId

		@updateRecord { 'count.messages': messagesCount, 'messagesstatus': null }
		@addCountToTotal messagesCount

		if tempUsers.length is 0 or tempRooms.length is 0 or messagesCount is 0
			@updateProgress Importer.ProgressStep.ERROR
			return @getProgress()

		selectionUsers = tempUsers.map (user) ->
			#HipChat's export doesn't contain bot users, from the data I've seen
			return new Importer.SelectionUser user.user_id, user.name, user.email, user.is_deleted, false, !user.is_bot
		selectionChannels = tempRooms.map (room) ->
			return new Importer.SelectionChannel room.room_id, room.name, room.is_archived, true

		@updateProgress Importer.ProgressStep.USER_SELECTION
		return new Importer.Selection @name, selectionUsers, selectionChannels
		# catch error
		# 	@updateRecord { 'failed': true, 'error': error }
		# 	console.error Importer.ProgressStep.ERROR
		# 	throw new Error 'import-hipchat-error', error

	startImport: (importSelection) =>
		super(importSelection)
		start = Date.now()

		for user in importSelection.users
			for u in @users.users when u.user_id is user.user_id
				u.do_import = user.do_import
		@collection.update { _id: @users._id }, { $set: { 'users': @users.users }}

		for channel in importSelection.channels
			for c in @channels.channels when c.room_id is channel.channel_id
				c.do_import = channel.do_import
		@collection.update { _id: @channels._id }, { $set: { 'channels': @channels.channels }}

		startedByUserId = Meteor.userId()
		Meteor.defer =>
			# try
			@updateProgress Importer.ProgressStep.IMPORTING_USERS
			for user in @users.users when user.do_import
				do (user) =>
					Meteor.runAsUser startedByUserId, () =>
						existantUser = RocketChat.models.Users.findOneByEmailAddress user.email
						if existantUser
							user.rocketId = existantUser._id
							@userTags.push
								hipchat: "@#{user.mention_name}"
								rocket: "@#{existantUser.username}"
						else
							userId = Accounts.createUser { email: user.email, password: Date.now() + user.name + user.email.toUpperCase() }
							user.rocketId = userId
							@userTags.push
								hipchat: "@#{user.mention_name}"
								rocket: "@#{user.mention_name}"
							Meteor.runAsUser userId, () =>
								Meteor.call 'setUsername', user.mention_name
								Meteor.call 'joinDefaultChannels', true
								Meteor.call 'setAvatarFromService', user.photo_url, null, 'url'
								Meteor.call 'updateUserUtcOffset', parseInt moment().tz(user.timezone).format('Z').toString().split(':')[0]

							if user.name?
								RocketChat.models.Users.setName userId, user.name

							#Deleted users are 'inactive' users in Rocket.Chat
							if user.is_deleted
								Meteor.call 'setUserActiveStatus', userId, false
						@addCountCompleted 1
			@collection.update { _id: @users._id }, { $set: { 'users': @users.users }}

			@updateProgress Importer.ProgressStep.IMPORTING_CHANNELS
			for channel in @channels.channels when channel.do_import
				do (channel) =>
					Meteor.runAsUser startedByUserId, () =>
						channel.name = channel.name.replace(/ /g, '')
						existantRoom = RocketChat.models.Rooms.findOneByName channel.name
						if existantRoom
							channel.rocketId = existantRoom._id
						else
							userId = ''
							for user in @users.users when user.user_id is channel.owner_user_id
								userId = user.rocketId

							if userId isnt ''
								Meteor.runAsUser userId, () =>
									returned = Meteor.call 'createChannel', channel.name, []
									channel.rocketId = returned.rid
								RocketChat.models.Rooms.update { _id: channel.rocketId }, { $set: { 'ts': new Date(channel.created * 1000) }}
							else
								console.warn "Failed to find the channel creator for #{channel.name}."
						@addCountCompleted 1
			@collection.update { _id: @channels._id }, { $set: { 'channels': @channels.channels }}

			@updateProgress Importer.ProgressStep.IMPORTING_MESSAGES
			nousers = {};
			for channel, messagesObj of @messages
				do (channel, messagesObj) =>
					Meteor.runAsUser startedByUserId, () =>
						hipchatChannel = @getHipChatChannelFromName channel
						if hipchatChannel?.do_import
							room = RocketChat.models.Rooms.findOneById hipchatChannel.rocketId, { fields: { usernames: 1, t: 1, name: 1 } }
							for date, msgs of messagesObj
								@updateRecord { 'messagesstatus': "#{channel}/#{date}.#{msgs.messages.length}" }
								for message in msgs.messages
									if message.from?
										user = @getRocketUser(message.from.user_id)
										if user?
											msgObj =
												msg: @convertHipChatMessageToRocketChat(message.message)
												ts: new Date(message.date)
												u:
													_id: user._id
													username: user.username

											RocketChat.sendMessage user, msgObj, room
										else
											if not nousers[message.from.user_id]
												nousers[message.from.user_id] = message.from
									else
										if not _.isArray message
											console.warn 'Please report the following:', message
									@addCountCompleted 1
			console.warn 'The following did not have users:', nousers

			@updateProgress Importer.ProgressStep.FINISHING
			for channel in @channels.channels when channel.do_import and channel.is_archived
				do (channel) =>
					Meteor.runAsUser startedByUserId, () =>
						Meteor.call 'archiveRoom', channel.rocketId

			@updateProgress Importer.ProgressStep.DONE
			timeTook = Date.now() - start
			console.log "Import took #{timeTook} milliseconds."
			# catch error
			# 	@updateRecord { 'failed': true, 'error': error }
			# 	console.error Importer.ProgressStep.ERROR
			# 	throw new Error 'import-hipchat-error', error

		return @getProgress()

	getHipChatChannelFromName: (channelName) =>
		for channel in @channels.channels when channel.name is channelName
			return channel

	getRocketUser: (hipchatId) =>
		for user in @users.users when user.user_id is hipchatId
			return RocketChat.models.Users.findOneById user.rocketId, { fields: { username: 1 }}

	convertHipChatMessageToRocketChat: (message) =>
		if message?
			for userReplace in @userTags
				message = message.replace userReplace.hipchat, userReplace.rocket
			return message

	getSelection: () =>
		selectionUsers = @users.users.map (user) ->
			#HipChat's export doesn't contain bot users, from the data I've seen
			return new Importer.SelectionUser user.user_id, user.name, user.email, user.is_deleted, false, !user.is_bot
		selectionChannels = @channels.channels.map (room) ->
			return new Importer.SelectionChannel room.room_id, room.name, room.is_archived, true

		return new Importer.Selection @name, selectionUsers, selectionChannels
