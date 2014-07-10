define [
	'marionette',
	'templates'
], (Marionette, jade)->

	HeaderView = Marionette.ItemView.extend
		template: jade.templates['header']
		className: 'header-inner'

	View = new HeaderView()
	return View