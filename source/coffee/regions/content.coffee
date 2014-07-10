define [
	'marionette'
], (Marionette)->

	ContentRegion = Marionette.Region.extend

		el: '.app-content'

		animation:
			onOpen : 'animated bounceInUp'
			onClose: 'animated bounceInDown'
		
		initialize: (options)->
			console.log "Initializing content region"
			if options?.animation? then @animation = options.animation

		open: (view)->
			view.$el.hide()
			@$el.html view.el
			view.$el.show().addClass @animation['onOpen']

	Region = new ContentRegion el: '.app-content'
	
	Region.on 'change:view', (url)->
		requirejs [url], (view)-> Region.show new view()
	
	
	return Region