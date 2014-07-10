define [
	'marionette'
	'regions/content'
], (Marionette, Content)->

	AppController = Marionette.Controller.extend

		renderLoading: -> Content.trigger 'change:view', 'views/loading'
		renderHome: -> Content.trigger 'change:view', 'views/home'

	Controller = new AppController()
	return Controller