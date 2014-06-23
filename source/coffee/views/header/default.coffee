define [
	'marionette',
	'templates'
], (Marionette, jade)->

	class HeaderView extends Marionette.ItemView
		template: jade.templates['header']
		className: 'header-inner'

	View = new HeaderView()
	return View