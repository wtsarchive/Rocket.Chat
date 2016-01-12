Package.describe({
	name: 'rocketchat:channel-settings-mail-messages',
	version: '0.0.1',
	summary: 'Channel Settings - Mail Messages',
	git: ''
});

Package.onUse(function(api) {
	api.versionsFrom('1.0');

	api.use([
		'coffeescript',
		'templating',
		'reactive-var',
		'less@2.5.0',
		'rocketchat:lib',
		'rocketchat:channel-settings',
		'momentjs:moment'
	]);

	api.addFiles([
		'client/lib/startup.coffee',
		'client/stylesheets/mail-messages.less',
		'client/views/channelSettingsMailMessages.html',
		'client/views/channelSettingsMailMessages.coffee',
		'client/views/mailMessagesInstructions.html',
		'client/views/mailMessagesInstructions.coffee'
	], 'client');


	api.addFiles([
		'server/lib/startup.coffee',
		'server/methods/mailMessages.coffee'
	], 'server');

	// TAPi18n
	var _ = Npm.require('underscore');
	var fs = Npm.require('fs');
	tapi18nFiles = _.compact(_.map(fs.readdirSync('packages/rocketchat-channel-settings-mail-messages/i18n'), function(filename) {
		if (fs.statSync('packages/rocketchat-channel-settings-mail-messages/i18n/' + filename).size > 16) {
			return 'i18n/' + filename;
		}
	}));
	api.use('tap:i18n');
	api.addFiles(tapi18nFiles);
});

Package.onTest(function(api) {

});
