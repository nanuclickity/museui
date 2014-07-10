define ['backbone'], (Backbone)->
	
	Model = Backbone.Model.extend
		defaults:
			appName: "Play"

	return Model