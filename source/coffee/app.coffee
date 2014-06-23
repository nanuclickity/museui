define [
	'modules/config'
	'routers/app_router'
	'regions/header'
	'regions/content'
	'views/loading'
], (Config, Router, Region_Header, Region_Content, View)->	
	
	App = new Marionette.Application()
	
	App.Config = Config

	App.addRegions
		Header : Region_Header
		Content: Region_Content

	App.Content.show new View()

	App.addInitializer ->
		App.Router = Router


	App.on 'start', ->
		if !Backbone.History.started
			Backbone.history.start pushState: true, hashChange: false

	return App