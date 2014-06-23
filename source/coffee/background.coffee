chrome.app.runtime.onLaunched.addListener ()->

	chrome.app.window.create 'index.html', {
		"bounds": {
			"width": 1000,
			"height": 540,
			"left": (screen.width/2) - 500
			"top": (screen.height/2) - 270
		},
		"frame": "none"
	},(win)->

		# After Initialization, maximize the window
		# return win.maximize()