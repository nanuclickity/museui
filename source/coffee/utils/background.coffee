define [
	'underscore'
], (_)->
	
	$BG = null

	Background = 
		ensureEl: -> $BG = $('.app-background')
		init: -> 
			console.log "Loaded background manager"
			do Background.ensureEl

		# Transitions
		fadeToWhite: -> $BG.animate opacity: 0.2, 300

	do Background.init
	return Background