define [
	'marionette'
	'controllers/app_controller'
], (Marionette, AppController)->
	
	class AppRouter extends Marionette.AppRouter
		controller: AppController
		appRoutes:
			'': 'renderLoading'
		initialize: ->
			console.log 'Starting App Router'

	Router = new AppRouter()
	console.log 'Started AppRouter'
	return Router