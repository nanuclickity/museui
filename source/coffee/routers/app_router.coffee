define [
	'marionette'
	'controllers/app_controller'
], (Marionette, AppController)->
	
	AppRouter = Marionette.AppRouter.extend
		controller: AppController
		appRoutes:
			'/'    : 'renderLoading'
			'home': 'renderHome'
		
		initialize: ->
			console.log 'Starting App Router'

	Router = new AppRouter()
	console.log 'Started AppRouter'
	return Router