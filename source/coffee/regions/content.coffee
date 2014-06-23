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
			view.$el.show().addClass  @animation['onOpen']
			console.log 'Region:Content: Open.'

	Region = new ContentRegion el: '.app-content'
	
	return Region