define [
	'backbone/assets',
	'backbone/bootstrap/collapse',
	'backbone/templates/website/_list_view',
	'backbone/templates/website/_list_view_item',
	'backbone/templates/website/_stub_suggestions'	
	], (Housing) ->

	class ParentListView extends Backbone.View
		el: '#main-content .list-view'
		
		template:
			main: window.JST['website/list_view']
			list_item_view: window.JST['website/list_view_item']
			stub_suggestions: window.JST['website/stub_suggestions']

		events:
			'click .pyr-btn'                  : 'open_need_flat'
			'click .list-item-container'      : 'handle_click'
			'click .related-localities .link' : 'open_related_locality'
			'click .popular-localities .link' : 'open_popular_locality'
			'mouseenter .list-item-container' : 'highlight'
			'mouseleave .list-item-container' : 'unhighlight'

		initialize: (options)->
			@document_append_completed = false

			if !$('#main-content').find('.list-box').length
				template_vars = @get_template_variables
					mode: 'grid'

				$('#main-content').append @template['main'](template_vars)
				@$el = $('#main-content').find('.list-view')
			
			# Namespace mostly used divs
			@$main_content = $("#main-content")
			@$container    = @$el.find('.container')
			@$el.empty

			@bind_events()

		get_template_variables: (options)->
			defaults = 
				country  : Housing.selected_country
				city     : Housing.selected_city.get('url_name')
				service  : Housing.selected_service.get('url_name')
				cities   : Housing.cities.toJSON()
				services : Housing.services.toJSON()
				city_breadcrum    : Housing.selected_city.get('url_name').capitalize()
				service_breadcrum : Housing.selected_service.get('url_name').capitalize()

			if options? then return _.extend {}, defaults, options
			else return defaults

		bind_events: =>
			@listenTo @options.filters, "completed:filtering", @refresh_on_filtering
			@listenTo @options.filters, "completed:filtering", @scroll_to_top
			@listenTo @options.shortlist, "added:shortlist removed:shortlist cleared:shortlist", @refresh_on_filtering
			@listenTo @options.collection, 'id:selected', @render_selected
			@listenTo @options.collection, 'reset', @on_collection_reset
			@listenTo @options.collection, 'change:seen', @refresh_on_filtering

			@listenTo Housing.event, 'shown:form', @unbind_key_listener
			@listenTo Housing.event, 'hidden:form', @bind_key_listener
			
			@listenTo Housing.event, 'going-to:shortlist', @close_expanded_view
			@listenTo Housing.event, 'shortlist:show', @hide_list_view
			@listenTo Housing.event, 'shortlist:hide', @show_list_view

			@listenTo Housing.event, 'finished:fetching_related_localties', @handle_suggestions
			@listenTo Housing.event, 'fetched:localities', @append_popular_localities

			@listenTo window, 'resize', @load_images_in_view

		handle_suggestions: ->
			if @show_other_s
				@$el.find('.other-suggestions .panel-collapse').html @get_other_suggestions_html()
			@append_related_localities()

		handle_click: (e) ->
			@supress()
			Housing.event.trigger 'track:open_info_window', id ,'list'
			if @$el.find('.controls .dropdown.more-filters-dropdown').hasClass('open')
				Housing.event.trigger "toggle:more-filters-dropdown"

		close_expanded_view:()->
			@expanded_view.close_view() if @expanded_view

		hide_list_view:-> @$el.addClass('hide')
		show_list_view:-> @$el.removeClass('hide')

		highlight: (e) ->
			id = parseInt( $(e.currentTarget).data('id') )
			Housing.event.trigger 'highlighted:id',id

		unhighlight: (e) ->
			id = parseInt($(e.currentTarget).data('id'))
			Housing.event.trigger 'unhighlighted:id',id

		suppress: (e) ->
			if e
				e.preventDefault()
				e.stopPropagation()
		
		suppress_keys: (e)->
			if e.keyCode is 32 then @suppress()

		# UnFiltered
		open_need_flat:  ->
			service_name = "not_selected"
			Housing.event.trigger 'track:pyr','opened_pyr_side'
			Housing.router.goto_url('/post-requirement')

		open_related_locality: (e) ->
			Housing.filters.is_zoom_to_fit_required = true
			id = $(e.currentTarget).data('id')
			item = Housing.related_localities.get(id) if id
			if item
				nearby_circle = {}
				nearby_circle.lat = item.get('lat')
				nearby_circle.lng = item.get('lng')
				if Housing.selected_city.get('filter_radius')
					rad = parseInt Housing.selected_city.get('filter_radius')
				rad = 2000 if not rad
				curr_nearby_obj = Housing.filters.get('nearby')
				nearby_circle.rad = curr_nearby_obj.rad || rad
				nearby_circle.name = item.get('name')

				Housing.filters.set('nearby', nearby_circle, {silent:true})
				Housing.filters.trigger 'change:nearby'
				Housing.filters.trigger 'change'

				Housing.event.trigger 'track:related_localities_links', $(e.target).html()
				@supress()

		open_popular_locality: (e) ->
			Housing.filters.is_zoom_to_fit_required = true
			id = $(e.currentTarget).data('id')
			locality = Housing.lsocalities.get(id) if id
			if locality
				nearby_circle = {}
				nearby_circle.lat = locality.get('latitude')
				nearby_circle.lng = locality.get('longitude')
				if Housing.selected_city.get('filter_radius')
					rad = parseInt Housing.selected_city.get('filter_radius')
				rad = 2000 if not rad
				curr_nearby_obj = Housing.filters.get('nearby')
				nearby_circle.rad = curr_nearby_obj.rad || rad
				nearby_circle.name = locality.get('name')

				Housing.filters.set('nearby', nearby_circle, {silent:true})
				Housing.filters.trigger 'change:nearby'
				Housing.filters.trigger 'change'

				Housing.event.trigger 'track:popular_localities_links', $(e.target).html()
				@suppress(e)	
		
		get_locality_bhk_filter_param: (loc_item, apartment_id) ->
			f = JSON.parse(Housing.Util.base64Decode(loc_item.get('filter_param')))
			if apartment_id == 'no-brokerage'
				f.owner_types = [2]
			else if apartment_id == 'house'
				f.property_types = [2]
			else
				f.apartment_types = [apartment_id]
			filter_url = Housing.Util.base64Encode(JSON.stringify(f))

		scroll_to_index: (index, top = true) -> # on passing false as second parameter, the list is scrolled to the listing at the bottom
			if index > -1
				new_top = @list_item_height * (index)
				if not top
					new_top = new_top - (@$el.height() - @list_item_height - 10)
				setTimeout(() ->
					@$el.animate({scrollTop: new_top})
				,0)
			else
				@scroll_to_top()



		destroy: ->
			@stopListening()


	return ParentListView