requirejs.config
	baseUrl: "/js/"
	paths:
		underscore  :	"/vendor/underscore/underscore"
		jquery      :	"/vendor/jquery/dist/jquery.min"
		backbone    :	"/vendor/backbone/backbone"
		marionette  :	"/vendor/backbone.marionette/lib/backbone.marionette.min"
		templates   :	"./templates"
		app         :	"./app"
		vent        :	"./utils/vent"

	shim:
		jquery :
			exports : "$"
		underscore :
			exports : "_"
		templates:
			exports: "jade"
		backbone:
		  deps: ["jquery", "underscore"]
		  exports: "Backbone"
		marionette:
		  deps: ["backbone", "templates"]
		  exports: "Marionette"
		app:
			deps: ["marionette"]
			exports: "App"


# Initiation Code
requirejs ["jquery", "app", "templates"], ($, App, jade)->
	window.$ = window.jQuery = $

	# Hack to enable use of jade templates
	Marionette.Renderer.render = (tpl, data)->
		if typeof tpl is "function"
			tplFn = tpl
		else
			tplFn = jade.templates[tpl]
		return tplFn data

	Muse = App
	do Muse.start