Meteor.methods
	'authorization:removeUserFromRole': (roleName, username) ->
		if not Meteor.userId() or not RocketChat.authz.hasPermission Meteor.userId(), 'access-permissions'
			throw new Meteor.Error "not-authorized"

		if not roleName or not _.isString(roleName) or not username or not _.isString(username)
			throw new Meteor.Error 'invalid-arguments'

		user = Meteor.users.findOne { username: username }, { fields: { _id: 1 } }

		if not user?._id?
			throw new Meteor.Error 'user-not-found'

		return RocketChat.models.Roles.removeUserRoles user._id, roleName
