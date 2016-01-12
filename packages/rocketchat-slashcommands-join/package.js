Package.describe({
	name: 'rocketchat:slashcommands-join',
	version: '0.0.1',
	summary: 'Command handler for the /join command',
	git: ''
});

Package.onUse(function(api) {

	api.versionsFrom('1.0');

	api.use([
		'coffeescript',
		'check',
		'rocketchat:lib'
	]);

	api.addFiles('client.coffee', 'client');
	api.addFiles('server.coffee', 'server');

	// TAPi18n
	api.use('templating', 'client');
	var _ = Npm.require('underscore');
	var fs = Npm.require('fs');
	tapi18nFiles = _.compact(_.map(fs.readdirSync('packages/rocketchat-slashcommands-join/i18n'), function(filename) {
		if (fs.statSync('packages/rocketchat-slashcommands-join/i18n/' + filename).size > 16) {
			return 'i18n/' + filename;
		}
	}));
	api.use('tap:i18n');
	api.addFiles(tapi18nFiles);
});

Package.onTest(function(api) {

});
