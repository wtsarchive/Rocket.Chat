this.Triggers = (function() {
	var triggers = [];
	var initiated = false;
	var requests = [];

	var init = function() {
		initiated = true;
		Tracker.autorun(function() {
			triggers = Trigger.find().fetch();

			if (requests.length > 0 && triggers.length > 0) {
				requests.forEach(function(request) {
					processRequest(request);
				});

				requests = [];
			}
		});
	};

	var fire = function(actions) {
		if (Meteor.userId()) {
			console.log('already logged user - does nothing');
			return;
		}
		actions.forEach(function(action) {
			if (action.name === 'send-message') {
				var roomId = visitor.getRoom();

				if (!roomId) {
					roomId = Random.id();
					visitor.setRoom(roomId);
				}

				Session.set('triggered', true);
				ChatMessage.insert({
					msg: action.params.msg,
					rid: roomId,
					u: {
						username: action.params.name
					}
				});

				parentCall('openWidget');
			}
		});
	};

	var processRequest = function(request) {
		if (!initiated) {
			return requests.push(request);
		}
		triggers.forEach(function(trigger) {
			trigger.conditions.forEach(function(condition) {
				switch (condition.name) {
					case 'page-url':
						if (request.location.href.match(new RegExp(condition.value))) {
							fire(trigger.actions);
						}
						break;

					case 'time-on-site':
						if (trigger.timeout) {
							clearTimeout(trigger.timeout);
						}
						trigger.timeout = setTimeout(function() {
							fire(trigger.actions);
						}, parseInt(condition.value) * 1000);
						break;
				}
			});
		});
	};

	return {
		init: init,
		processRequest: processRequest
	};
})();
