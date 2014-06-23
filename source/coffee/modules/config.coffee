define [
	'underscore'
], (_)->

	Store = {}

	Config =
		init: ->
		isLoaded: false

	Config.init() if !Config.isLoaded
	return Config