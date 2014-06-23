define ['marionette', 'templates'], (Marionette, jade)->
	LoadingView = Marionette.ItemView.extend
		template: jade.templates['loading']
		className: 'layer'
		initialize: -> 
			console.log 'Loading MuseUI...'

	return LoadingView