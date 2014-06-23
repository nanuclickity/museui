define [
	'marionette'
	'regions/content'
], (Marionette, Content)->
	
	
	class AppController extends Marionette.Controller
		renderLoading: -> 
			console.log 'Controller...'
			requirejs ['views/loading'], (view)-> 
				console.log 'Showing'
				Content.show new view()
	Controller = new AppController()
	console.log 'Controller..'
	return Controller