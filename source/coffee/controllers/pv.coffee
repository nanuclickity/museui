define [
	'backbone/assets'
	'backbone/templates/website/_list_view'
	'backbone/templates/website/_list_view_item'
	'backbone/templates/website/_stub_suggestions'
], (Housing)->

	class ParentListView extends Backbone.View
		el: "#main-content"

		template:
			main: window.JST["website/list_view"]
			list_item_view: window.JST['website/list_view_item']
			stub_suggestions: window.JST['website/stub_suggestions']

		events:
			'click .pyr-btn': 'open_need_flat'
			'click .list-item-container': 'handle_click'
			'click .list-item-container .shortlist': 'toggle_shortlist'
			
			'click .related-localities .link': 'open_related_locality'
			'click .popular-localities .link': 'open_popular_locality'

			'mouseenter .list-item-container': 'highlight'
			'mouseleave .list-item-container': 'unhighlight'

			'click .other-suggestions .link' : 'open_other_suggestions'
			'click .sugg-accordion-head': 'toggle_suggestions'
			
			'click #footer-card .feedback-btn': 'on_feedback_click'
		
		initialize: ->
			@render()
			@bind_events true
			@document_append_completed = false

		render: ->
			@filtered_collection = @options.collection.where {visibility: true, fromFilter: true}
			if Housing.Util.is_service('rent') or Housing.Util.is_service('buy')
				@show_other_suggestions = true
				@get_other_suggestions()

			related_localities = Housing.related_localities.models
			popular_locality_ids = Housing.selected_city.get('popular_locality_ids')

			localities = []
			if popular_locality_ids and popular_locality_ids.length
				for popular_locality_id in popular_locality_ids
					locality = Housing.localities.get popular_locality_id
					localities.push locality

			city_breadcrumb    = Housing.selected_city.get('url_name').capitalize()
			service_breadcrumb = Housing.selected_service.get('url_name').capitalize()
			
			template_variables =
				country : Housing.selected_country
				city    : Housing.selected_city.get('url_name')
				service : Housing.selected_service.get('url_name')
	
				list_item     : @filtered_collection
				city_breadcrum: city_breadcrum
				service_breadcrum: service_breadcrum
				
				services: Housing.services
				cities  : Housing.cities
				is_touch: false
				mode    : 'list'

				related_localities: related_localities
				popular_localities: localities

				other_suggestions     : @other_suggestions
				show_other_suggestions: @show_other_suggestions

			if !@$el.find('.list-box').length
				template_vars = 
					country  : Housing.selected_country
					city     : Housing.selected_city.get('url_name')
					service  : Housing.selected_service.get('url_name')
					cities   : Housing.cities.toJSON()
					services : Housing.services.toJSON()
					
					city_breadcrum    : city_breadcrum
					service_breadcrum : service_breadcrum
					
					print_list: false
					mode: 'list'
				@$el.append @template['main'](template_vars)

			@listenTo Housing.event, "navigate:listings:tiling", @bring_item_into_view

			listview = @$el.find('.list-view')
			if listview.length then listview.html '' 
			listview.html @template['list_item_view'](template_variables)

			list_item_container = @$el.find('.list-item-container')
			if list_item_container.length then list_item_container.remove()

			# Check if this returns
			#if Housing.Util.is_service('pg')
			#	"<div class='list-end-pyr'><span class='heading'>We're adding 100's of pgs everyday! <br/> Let us find them for you.<br/></span><a href='#' class='btn btn-blue' data-toggle='modal' data-bypass='true'>Post your requirements</a></div>"

			do @_post_render

		_post_render: ->
			@_init_variables()
			@bind_events(false, true)
			@toggle_suggestions()

		bind_events: (options)->
			if options.init
				@listenTo @options.filters, 'completed:filtering', @scroll_to_top
				@listenTo @options.filters, 'completed:filtering', @refresh_on_filtering

				@listenTo @options.shortlist, "added:shortlist removed:shortlist cleared:shortlist", @refresh_on_filtering
				@refresh_on_filtering()

				@listenTo Housing.event, 'finished:fetching_related_localities', @handle_suggestions
				@listenTo Housing.event, 'fetched:localities', @append_popular_localities

				@listenTo Housing.event, 'shortlist:show', @hide_list_view
				@listenTo Housing.event, 'shortlist:hide', @show_list_view

				@listenTo Housing.event, 'shown:form', @unbind_key_listener
				@listenTo Housing.event, 'hidden:form', @bind_key_listener
				@bind_key_listener()

				@listenTo @options.collection, 'id:selected', @render_selected
				@listenTo @options.collection, 'reset', @on_collection_reset
				@listenTo @options.collection, 'change:seen', @refresh_on_filtering

				@listenTo window, 'resize', @load_images_in_view

			if options.render
				@listenTo @$el.find('.js-list-subscribe'), 'click', @show_subscribe_model
				@listenTo @$list_view, 'scroll', @load_images_in_view
		
		bind_key_listener: ->
			if !@_key_listener_bound 
				$(document).bind 'keyup keydown keypress', @suppress_keys
				@_key_listener_bound = true

		on_feedback_click: -> Housing.event.trigger 'clicked:feedback', e

		_init_variables: ->
			@_views = []
			@loaded_image = []
			max_count = @filtered_collection.length
			@loaded_image[i] = false for i in [0..max_count]

			@prev_top_visible_index = -1
			@list_item_height = 81

			@$open_footer_btn = $("footer .open-footer")

			@$list_view = @$el.find('.list-view') if @$el
			@container = @$list_view.find(".container") if @$list_view?
			@sugg_head = @$list_view.find(".sugg-accordion-head") if @$list_view?

		toggle_suggestions: (e)->
			if not e
				@$list_view.find('#collapse01').css 'height', 'auto'
				@sugg_head.removeClass 'selected'

				@$list_view.find("#collapse02, #collapse03").css 'height', '0px'
				@$list_view.find('.sugg-accordion-head[data-head="1"]').addClass 'selected'
				return

			head_index = $(e.currentTarget).data 'head'
			if @$list_view.find('.sugg-accordion-head[data-head=' + head_index + ']').hasClass('selected')
				@$list_view.find('#collapse0'+head_index).css('height','0px')
				@sugg_head.removeClass('selected')
			else
				@$list_view.find('.panel-collapse').css('height', '0px')
				@$list_view.find('#collapse0'+head_index).css('height', 'auto')
				@sugg_head.removeClass('selected')
				@$list_view.find('.sugg-accordion-head[data-head=' + head_index + ']').addClass('selected')

		get_other_suggestions: ->
			sugg_locn_url_name = ''
			sugg_locn_name = ''
			f = {}

			loc_id = Housing.filters.get_nearest_locality_by_displacement()
			
			_.each Housing.localities.models, (model) =>
				datobj = JSON.parse(Housing.Util.base64Decode(model.attributes.filter_param))
				if Housing.filters.attributes.nearby.name == datobj.nearby.name
					sugg_locn_url_name = model.get('url_name')
					sugg_locn_name = model.get('name')
					loc_id = model.id
			if not loc_id
				herr 'loc_id NOT FOUND'
				return

			loc_id = Housing.filters.get_nearest_locality_by_displacement()
			loc_item = Housing.localities.get(loc_id)
			loc_url_name = loc_item.get('url_name')
			loc_name = loc_item.get('name')

			url_till_service = Housing.router.get_url_till_service()
			url_till_filter = Housing.router.get_url_till_filter()
			url_till_city = Housing.router.get_url_till_city()

			filter_array = (@get_locality_bhk_filter_param(loc_item, i) for i in [1..5])
			filter_array.push (@get_locality_bhk_filter_param(loc_item,'no-brokerage'))
			filter_array.push (@get_locality_bhk_filter_param(loc_item,'house'))

			f.nearby = Housing.filters.attributes.nearby
			filter_url = Housing.Util.base64Encode(JSON.stringify(f))

			@other_suggestions =
				url_till_service: url_till_service
				url_till_filter: url_till_filter
				url_till_city: url_till_city
				loc_id: loc_id
				loc_item: loc_item
				loc_url_name: loc_url_name
				loc_name: loc_name
				filter_url: filter_url
				filter_array: filter_array

		get_locality_bhk_filter_param: (loc_item,apartment_id) ->
			f = JSON.parse(Housing.Util.base64Decode(loc_item.get('filter_param')))
			if apartment_id == 'no-brokerage'
				f.owner_types = [2]
			else if apartment_id == 'house'
				f.property_types = [2]
			else
				f.apartment_types = [apartment_id]
			filter_url = Housing.Util.base64Encode(JSON.stringify(f))

		get_other_suggestions_html: =>
			@get_other_suggestions()
			loc_name = @other_suggestions.loc_name
			service_url = @other_suggestions.url_till_service
			url_till_filter = @other_suggestions.url_till_filter
			filter_url = @other_suggestions.filter_url
			url_till_city = @other_suggestions.url_till_city
			filter_array = @other_suggestions.filter_array
			loc_url_name = @other_suggestions.loc_url_name
			bhk_array = [{url: '1rk', name: '1 RK'}, {url: '1bhk', name: '1 BHK'}, {url: '2bhk', name: '2 BHK'}, {url: '3bhk', name: '3 BHK'},{url: '3+bhk' , name: '3+ BHK'}, {url: 'no-brokerage', name: 'Flats without brokerage'}, {url: 'house', name: 'Independent houses'}]
			str = ''

			for i in [0..6]
				str += '<h2><a class="link" href="'+ service_url + '/' + loc_url_name + '/' + bhk_array[i].url + '" data-href ="' + url_till_filter + '?f=' + filter_array[i] + '" data-url-name="' + bhk_array[i].url + '">' + bhk_array[i].name + ' in ' + loc_name + '</a></h2>'
			str+='<h2><a class="link" href="' + url_till_city + '/agents/search?f=' + filter_url + '" data-href = "' + url_till_city + '/agents/search?f=' + filter_url + '" data-url-name = "agents"> Find Agents in ' + loc_name + '</a></h2>'
			return str

		handle_suggestions: =>
			if @show_other_suggestions
				@$el.find('.other-suggestions .panel-collapse').html(@get_other_suggestions_html())
			@append_related_localities()

		append_related_localities: =>
			if Housing.related_localities and not Housing.related_localities.length
				@$el.find('.related-localities').hide()
			else
				@$el.find('.related-localities .panel-collapse').html(@get_related_localities)

		get_related_localities: () =>
			related_localities_div = ''
			str = Housing.related_localities.map (item) =>
				'<h2><a class="link" href="' + Housing.router.get_url_till_service() + '/' + item.get('url_name') + '" data-id="' + item.get('id') + '" data-href="' + Housing.router.get_url_till_service() + '/search?f=' + item.get('filter_param') + '">' + item.get('name') + '</a></h2>'
			related_localities_div += str.join('')
			return related_localities_div

		append_popular_localities: () =>
			@$el.find('.popular-localities .panel-collapse').html(@get_popular_localities)

		get_popular_localities: =>
			ids = Housing.selected_city.get('popular_locality_ids')
			if ids and ids.length
				elem = ''
				_.each ids, (id) ->
					locality = Housing.localities.get id
					if locality
						url  = Housing.router.get_url_till_service()
						elem += '<h2><a class="link" href="' + url 
						elem +=   '/' +  locality.get('url_name') 
						elem +=   ' data-id="' + locality.get('id') 
						elem +=   ' data-href="' + url 
						elem +=   '/search?f=' + locality.get('filter_param') 
						elem += '">' + locality.get('name') + '</a></h2>'
				return elem
			else
				return ''

		hide_list_view : => @$list_view.addClass 'hide'
		show_list_view : => @$list_view.removeClass 'hide'

		show_subscribe_modal:(e)=>
			@suppress(e)
			Housing.event.trigger "load:subscribe:modal"
			Housing.event.trigger 'track:subscribe_alert', 'open', 'list-view'

		open_other_suggestions: => Housing.filters.trigger 'change'

		open_related_locality : (e)=>
			Housing.filters.is_zoom_to_fit_required = true
			id = $(e.currentTarget).data('id')
			item = Housing.related_localities.get(id) if id
			@open_locality(item,e)

		open_popular_locality: (e) =>
			Housing.filters.is_zoom_to_fit_required = true
			id = $(e.currentTarget).data('id')
			locality = Housing.localities.get(id) if id
			@open_locality(locality,e)

		open_locality: (item,e) =>
			if item
				lat = item.get('lat') if item.get('lat')?
				lng = item.get('lng') if item.get('lng')?
				
				if item? and item.get('latitude')? and item.get('longitude')?
					lat = item.get('latitude')
					lng = item.get('longitude')
				nearby_circle = {}
				nearby_circle.lat = lat
				nearby_circle.lng = lng
				
				if Housing.selected_city.get('filter_radius')
					rad = parseInt Housing.selected_city.get('filter_radius')
				rad = 2000 if not rad
				curr_nearby_obj    = Housing.filters.get('nearby')
				nearby_circle.rad  = curr_nearby_obj.rad || rad
				nearby_circle.name = item.get('name')

				Housing.filters.set 'nearby', nearby_circle, {silent:true}
				Housing.filters.trigger 'change:nearby'
				Housing.filters.trigger 'change'
				Housing.event.trigger 'track:related_localities_links', $(e.target).html()
				@suppress(e)

		on_collection_reset: (collection, options) =>
			_.each @_views, (child_view) => child_view.destroy() if child_view
			@_views = []
			max_count = @filtered_collection.length
			@loaded_image[i] = false for i in [0..max_count]

		get_list_end_pyr: () ->
			elem  = "<div class='list-end-pyr'>"
			elem +=   "<span class='heading'>"
			elem +=     "We're adding 100's of flats everyday! <br/> Let us find them for you.<br/>"
			elem +=   "</span>"
			elem +=   "<a href='#' class='btn list-subscribe-btn js-list-subscribe' data-bypass='true'>"
			elem +=   "  Subscribe to this search</a><a href='#' class='btn btn-blue' data-toggle='modal' data-bypass='true'>Post your requirements</a>"
			elem += "</div>"
			return elem

		open_need_flat: () ->
			service_name = "not_selected"
			Housing.event.trigger 'track:pyr','opened_pyr_side'
			Housing.router.goto_url('/post-requirement')

		scroll_to_top: => _.defer @$list_view.scrollTop(0)
		scroll_from_top: (index=0)=> _.defer @$list_view.animate({scrollTop: index})

		highlight: (e) =>
			id = parseInt($(e.currentTarget).data('id'))
			Housing.event.trigger 'highlighted:id',id

		unhighlight: (e) =>
			id = parseInt($(e.currentTarget).data('id'))
			Housing.event.trigger 'unhighlighted:id',id

		toggle_shortlist: (e) =>
			id = parseInt($(e.currentTarget).closest('.list-item-container').data('id'))
			if Housing.shortlist and id
				Housing.shortlist.toggle(id)

			if Housing.shortlist.getFlats().indexOf(id) == -1
				track_action = 'added'
			else
				trac=k_action = 'removed'
			Housing.event.trigger 'track:shortlist_actions',id,track_action
			@suppress(e)

		handle_click: (e) =>
			id = parseInt($(e.currentTarget).data('id'))
			if id != @options.collection.getSelected()
				$(e.currentTarget).addClass('selected')
				url = Housing.router.get_url_till_flat_id(id)
				Housing.router.goto_url url

			Housing.event.trigger 'track:open_info_window',id,'list'
			@suppress(e)

			if $('.controls .dropdown.more-filters-dropdown').hasClass('open')
				Housing.event.trigger "toggle:more-filters-dropdown"

		bring_item_into_view: (listing, navigate_only_with_key=false) => # Only navigation with keys and not on listing change, from route.
			if !@_views or !listing then return
			if Housing.Util.is_tiling_service() and !navigate_only_with_key then return # no interaction from map to list in tiling
			i = -1
			_.each @_views, (v,index) =>
				if v.model==listing
					i = index
					return
			if i != -1
				top_complete_visible_index = parseInt(Math.ceil(@$list_view.scrollTop()/@list_item_height))
				bottom_complete_visible_index = parseInt(Math.floor((@$list_view.scrollTop() + @$list_view.height())/@list_item_height))-1
				if i >= top_complete_visible_index and i <= bottom_complete_visible_index
					return
				else if i < top_complete_visible_index
					@scroll_to_index(i, true)
				else
					@scroll_to_index(i, false)


		




