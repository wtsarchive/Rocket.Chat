RocketChat.settings._sorter = 0

###
# Add a setting
# @param {String} _id
# @param {Mixed} value
# @param {Object} setting
###
RocketChat.settings.add = (_id, value, options = {}) ->
	# console.log '[functions] RocketChat.settings.add -> '.green, 'arguments:', arguments

	if not _id or not value?
		return false

	options.packageValue = value
	options.valueSource = 'packageValue'
	options.ts = new Date
	options.hidden = false
	options.sorter ?= RocketChat.settings._sorter++

	if options.enableQuery?
		options.enableQuery = JSON.stringify options.enableQuery

	if process?.env?[_id]?
		value = process.env[_id]
		options.processEnvValue = value
		options.valueSource = 'processEnvValue'

	else if Meteor.settings?[_id]?
		value = Meteor.settings[_id]
		options.meteorSettingsValue = value
		options.valueSource = 'meteorSettingsValue'

	if not options.i18nLabel?
		options.i18nLabel = _id

	# Default description i18n key will be the setting name + "_Description" (eg: LDAP_Enable -> LDAP_Enable_Description)
	if not options.i18nDescription?
		options.i18nDescription = "#{_id}_Description"

	updateOperations =
		$set: options
		$setOnInsert:
			value: value
			createdAt: new Date

	if not options.section?
		updateOperations.$unset = { section: 1 }

	return RocketChat.models.Settings.upsert { _id: _id }, updateOperations



###
# Add a setting group
# @param {String} _id
###
RocketChat.settings.addGroup = (_id, options = {}, cb) ->
	# console.log '[functions] RocketChat.settings.addGroup -> '.green, 'arguments:', arguments

	if not _id
		return false

	if _.isFunction(options)
		cb = options
		options = {}

	if not options.i18nLabel?
		options.i18nLabel = _id

	if not options.i18nDescription?
		options.i18nDescription = "#{_id}_Description"

	options.ts = new Date
	options.hidden = false

	RocketChat.models.Settings.upsert { _id: _id },
		$set: options
		$setOnInsert:
			type: 'group'
			createdAt: new Date

	if cb?
		cb.call
			add: (id, value, options = {}) ->
				options.group = _id
				RocketChat.settings.add id, value, options

			section: (section, cb) ->
				cb.call
					add: (id, value, options = {}) ->
						options.group = _id
						options.section = section
						RocketChat.settings.add id, value, options

	return


###
# Remove a setting by id
# @param {String} _id
###
RocketChat.settings.removeById = (_id) ->
	# console.log '[functions] RocketChat.settings.add -> '.green, 'arguments:', arguments

	if not _id
		return false

	return RocketChat.models.Settings.removeById _id


###
# Update a setting by id
# @param {String} _id
###
RocketChat.settings.updateById = (_id, value) ->
	# console.log '[functions] RocketChat.settings.updateById -> '.green, 'arguments:', arguments

	if not _id or not value?
		return false

	return RocketChat.models.Settings.updateValueById _id, value


###
# Update options of a setting by id
# @param {String} _id
###
RocketChat.settings.updateOptionsById = (_id, options) ->
	# console.log '[functions] RocketChat.settings.updateOptionsById -> '.green, 'arguments:', arguments

	if not _id or not options?
		return false

	return RocketChat.models.Settings.updateOptionsById _id, options


###
# Update a setting by id
# @param {String} _id
###
RocketChat.settings.clearById = (_id) ->
	# console.log '[functions] RocketChat.settings.clearById -> '.green, 'arguments:', arguments

	if not _id?
		return false

	return RocketChat.models.Settings.updateValueById _id, undefined


###
# Update a setting by id
###
RocketChat.settings.init = ->
	initialLoad = true
	RocketChat.models.Settings.find().observe
		added: (record) ->
			Meteor.settings[record._id] = record.value
			if record.env is true
				process.env[record._id] = record.value
			RocketChat.settings.load record._id, record.value, initialLoad
		changed: (record) ->
			Meteor.settings[record._id] = record.value
			if record.env is true
				process.env[record._id] = record.value
			RocketChat.settings.load record._id, record.value, initialLoad
		removed: (record) ->
			delete Meteor.settings[record._id]
			if record.env is true
				delete process.env[record._id]
			RocketChat.settings.load record._id, undefined, initialLoad
	initialLoad = false
