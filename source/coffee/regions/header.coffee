define [
	'marionette',
	'views/header/default'
], (Marionette, HeaderView)->

	class HeaderRegion extends Marionette.Region
		open: (view)->
			view.$el.hide()
			this.$el.html view.el
			view.$el.show().addClass 'animated bounceInDown'
		initialize: ->
			console.log 'Staring Header Region'

	Region = new HeaderRegion
		el: 'header.app-header'

	Region.show HeaderView

	return Region