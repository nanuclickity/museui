define [
	'modules/config'
	'routers/app_router'
	'regions/header'
	'regions/content'
	'utils/background'
	'views/loading'
	'modules/scanner'
], (Config, Router, Region_Header, Region_Content, Background, View, Scanner)->	
	
	App = new Marionette.Application()
	
	App.Config = Config
	App.Router = Router
	App.Background = Background
	
	App.addInitializer -> 

	App.addInitializer ->
		App.addRegions
			Header : Region_Header
			Content: Region_Content
		
	App.addInitializer -> App.Content.show new View()

	App.on 'start', ->
		unless Backbone.History.started
			Backbone.history.start pushState: false, hashChange: true

	return App