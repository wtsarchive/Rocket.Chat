/**
 * Sets an user as (non)operator
 * @param {string} _id - User's _id
 * @param {boolean} operator - Flag to set as operator or not
 */
RocketChat.models.Users.setOperator = function(_id, operator) {
	var update = {
		$set: {
			operator: operator
		}
	};

	return this.update(_id, update);
};

/**
 * Gets all online agents
 * @return
 */
RocketChat.models.Users.findOnlineAgents = function() {
	var query = {
		status: 'online',
		roles: {}
	};

	query.roles[Roles.GLOBAL_GROUP] = 'livechat-agent';

	return this.find(query);
};

/**
 * Find online users from a list
 * @param {array} userList - array of usernames
 * @return
 */
RocketChat.models.Users.findOnlineUserFromList = function(userList) {
	var query = {
		status: 'online',
		username: {
			$in: [].concat(userList)
		}
	};

	return this.find(query);
};

/**
 * Get next user agent in order
 * @return {object} User from db
 */
RocketChat.models.Users.getNextAgent = function() {
	var query = {
		status: 'online'
	};

	query['roles.' + Roles.GLOBAL_GROUP] = 'livechat-agent';

	var collectionObj = this.model.rawCollection();
	var findAndModify = Meteor.wrapAsync(collectionObj.findAndModify, collectionObj);

	var sort = {
		livechatCount: 1,
		username: 1
	};

	var update = {
		$inc: {
			livechatCount: 1
		}
	};

	return findAndModify(query, sort, update);
};

/**
 * Gets visitor by token
 * @param {string} token - Visitor token
 */
RocketChat.models.Users.getVisitorByToken = function(token, options) {
	var query = {
		"profile.guest": true,
		"profile.token": token
	};

	return this.findOne(query, options);
};
