chrome.app.runtime.onLaunched.addListener ()->

	chrome.app.window.create 'index.html',
		bounds:
			# "width" : 1322,
			# "height": 826,
			# "left"  : (screen.width/2) - 661
			# "top"   : (screen.height/2) - 413
			width : 875
			height: 1024
			left  : 0
			top   : 0
		frame: "none"
	,(win)->

		# After Initialization, maximize the window
		# return win.maximize()