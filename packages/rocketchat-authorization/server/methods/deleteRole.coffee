Meteor.methods
	'authorization:deleteRole': (_id) ->
		if not Meteor.userId() or not RocketChat.authz.hasPermission Meteor.userId(), 'access-permissions'
			throw new Meteor.Error "not-authorized"

		role = Meteor.roles.findOne _id

		if role.protected
			throw new Meteor.Error 'protected-role', 'Cannot_delete_a_protected_role'

		someone = Meteor.users.findOne { "roles.#{Roles.GLOBAL_GROUP}": role.name }

		if someone?
			throw new Meteor.Error 'role-in-use', 'Cannot_delete_role_because_its_in_use'

		return Roles.deleteRole role.name
