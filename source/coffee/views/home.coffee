define [
	'marionette'
	'models/home'
	'utils/background'
], (Marionette, Model, Background)->

	HomeView = Marionette.ItemView.extend
		model: new Model()
		
		template: jade.templates['home']
		
		initialize: -> 
			console.log "Init Home View"
			Background.fadeToWhite()
			
	return HomeView