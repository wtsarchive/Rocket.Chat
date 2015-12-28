Meteor.methods
	unmuteUserInRoom: (data) ->
		fromId = Meteor.userId()
		check(data, Match.ObjectIncluding({ rid: String, username: String }))

		unless RocketChat.authz.hasPermission(fromId, 'mute-user', data.rid)
			throw new Meteor.Error 'not-allowed', '[methods] unmuteUserInRoom -> Not allowed'

		room = RocketChat.models.Rooms.findOneById data.rid
		if not room
			throw new Meteor.Error 'invalid-room', '[methods] unmuteUserInRoom -> Room ID is invalid'

		if room.t not in ['c', 'p']
			throw new Meteor.Error 'invalid-room-type', '[methods] unmuteUserInRoom -> Invalid room type'

		if data.username not in (room?.usernames or [])
			throw new Meteor.Error 'not-in-room', '[methods] unmuteUserInRoom -> User is not in this room'

		unmutedUser = RocketChat.models.Users.findOneByUsername data.username

		RocketChat.models.Rooms.unmuteUsernameByRoomId data.rid, unmutedUser.username

		fromUser = RocketChat.models.Users.findOneById fromId
		RocketChat.models.Messages.createUserUnmutedWithRoomIdAndUser data.rid, unmutedUser,
			u:
				_id: fromUser._id
				username: fromUser.username

		return true
