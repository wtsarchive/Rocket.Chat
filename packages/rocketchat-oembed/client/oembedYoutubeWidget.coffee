Template.oembedYoutubeWidget.events
	'click .join': (event) ->
		$(this).on 'click', ->
			$(this).find('iframe').css
 				'pointer-events': ''
				width: '80%'
			$(this).find('iframe').css
				width: $(this).find('iframe').width()
				'height': $($0).find('iframe').width() / 1.335
			return
