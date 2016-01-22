Package.describe({
  name: 'rocketchat:integrations',
  version: '0.0.1',
  summary: 'Integrations with services and WebHooks',
  git: '',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');

  api.use('coffeescript');
  api.use('underscore');
  api.use('simple:highlight.js');
  api.use('rocketchat:lib');
  api.use('rocketchat:authorization');
  api.use('rocketchat:api');

  api.use('kadira:flow-router', 'client');
  api.use('templating', 'client');

  api.addFiles('lib/rocketchat.coffee', ['server','client']);
  api.addFiles('client/collection.coffee', ['client']);
  api.addFiles('client/startup.coffee', 'client');
  api.addFiles('client/route.coffee', 'client');

  // views
  api.addFiles('client/views/integrations.html', 'client');
  api.addFiles('client/views/integrations.coffee', 'client');
  api.addFiles('client/views/integrationsNew.html', 'client');
  api.addFiles('client/views/integrationsNew.coffee', 'client');
  api.addFiles('client/views/integrationsIncoming.html', 'client');
  api.addFiles('client/views/integrationsIncoming.coffee', 'client');
  api.addFiles('client/views/integrationsOutgoing.html', 'client');
  api.addFiles('client/views/integrationsOutgoing.coffee', 'client');

  // stylesheets
  api.addAssets('client/stylesheets/integrations.less', 'server');
  api.addFiles('client/stylesheets/load.coffee', 'server');

  api.addFiles('server/models/Integrations.coffee', 'server');

  // publications
  api.addFiles('server/publications/integrations.coffee', 'server');

  // methods
  api.addFiles('server/methods/incoming/addIncomingIntegration.coffee', 'server');
  api.addFiles('server/methods/incoming/updateIncomingIntegration.coffee', 'server');
  api.addFiles('server/methods/incoming/deleteIncomingIntegration.coffee', 'server');
  api.addFiles('server/methods/outgoing/addOutgoingIntegration.coffee', 'server');
  api.addFiles('server/methods/outgoing/updateOutgoingIntegration.coffee', 'server');
  api.addFiles('server/methods/outgoing/deleteOutgoingIntegration.coffee', 'server');

  // api
  api.addFiles('server/api/api.coffee', 'server');


  api.addFiles('server/triggers.coffee', 'server');

  api.addFiles('server/processWebhookMessage.js', 'server');

  var _ = Npm.require('underscore');
  var fs = Npm.require('fs');
  tapi18nFiles = _.compact(_.map(fs.readdirSync('packages/rocketchat-integrations/i18n'), function(filename) {
    if (fs.statSync('packages/rocketchat-integrations/i18n/' + filename).size > 16) {
      return 'i18n/' + filename;
    }
  }));
  api.use('tap:i18n');
  api.addFiles(tapi18nFiles);
});
