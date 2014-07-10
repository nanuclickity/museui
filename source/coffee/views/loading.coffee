define ['marionette', 'templates'], (Marionette, jade)->
	LoadingView = Marionette.ItemView.extend
		template: jade.templates['loading']
		className: 'layer'
		events:
			'click .navigate-home' : 'toHome'
		initialize: -> 
			console.log 'Loading MuseUI...'

		onRender: -> 
			window.setTimeout ->
				Backbone.history.navigate 'home', {trigger: true}
			, 3000
	
	return LoadingView