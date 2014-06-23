define ['backbone/assets',
		'backbone/bootstrap/collapse',
		'backbone/templates/website/_list_view',
		'backbone/templates/website/_list_view_item',
		'backbone/templates/website/_stub_suggestions'], (Housing) ->

	class ListView extends Backbone.View
		el: '#main-content'

		template:
			main: window.JST['website/list_view']
			list_item_view: window.JST['website/list_view_item']
			stub_suggestions: window.JST['website/stub_suggestions']

		events:
			# 'click' : 'footer_visibility'
			'click .list-item-container': 'handle_click'
			'click .list-item-container .shortlist': 'toggle_shortlist'
			'click .pyr-btn': 'open_need_flat'
			'click .related-localities .link': 'open_related_locality'
			'click .popular-localities .link': 'open_popular_locality'
			'click .other-suggestions .link' : 'open_other_suggestions'
			'click .sugg-accordion-head': 'toggle_suggestions'
			'mouseenter .list-item-container': 'highlight'
			'mouseleave .list-item-container': 'unhighlight'
			'click #footer-card .feedback-btn': 'on_feedback_click'

		initialize: () =>
			@render()
			@bind_events(true)
			@document_append_completed = false

		render: () => ## renders template
			@filtered_collection = @options.collection.where({visibility:true, fromFilter: true})
			if Housing.Util.is_service('rent') or Housing.Util.is_service('buy')
				@show_other_suggestions = true
				@get_other_suggestions()

			related_localities = Housing.related_localities.models
			popular_locality_ids = Housing.selected_city.get('popular_locality_ids')
			localities = []
			if popular_locality_ids and popular_locality_ids.length
				for popular_locality_id in popular_locality_ids
					locality = Housing.localities.get(popular_locality_id)
					localities.push(locality)

			city_breadcrum     = Housing.selected_city.get('url_name').capitalize()
			service_breadcrum  = Housing.selected_service.get('url_name').capitalize()
			
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
					country: Housing.selected_country
					city: Housing.selected_city.get('url_name')
					city_breadcrum: city_breadcrum
					service:  Housing.selected_service.get('url_name')
					service_breadcrum: service_breadcrum
					print_list: false
					cities: Housing.cities.toJSON()
					services: Housing.services.toJSON()
					mode: 'list'
				@$el.append(@template['main'](template_vars))

			Housing.event.on "navigate:listings:tiling", @bring_item_into_view

			@$el.find('.list-view').html('') if @$el.find('.list-view').length
			@$el.find('.list-view').html(@template['list_item_view'](template_variables))

			@$el.find('.list-item-container').remove() if @$el.find('.list-item-container').length ## removing list-item-containers appended through haml
			if Housing.Util.is_service('pg')
				"<div class='list-end-pyr'><span class='heading'>We're adding 100's of pgs everyday! <br/> Let us find them for you.<br/></span><a href='#' class='btn btn-blue' data-toggle='modal' data-bypass='true'>Post your requirements</a></div>"

			@_post_render()

		_post_render: () =>
			## after render function calls
			@_init_variables()
			@bind_events(false,true)
			@toggle_suggestions()

		bind_events: (init=false,render=false) =>
			if init
				@options.filters.on "completed:filtering", @scroll_to_top
				@options.filters.on "completed:filtering", @refresh_on_filtering
				@options.shortlist.on "added:shortlist removed:shortlist cleared:shortlist", @refresh_on_filtering
				@refresh_on_filtering()

				Housing.event.on 'finished:fetching_related_localties', @handle_suggestions
				Housing.event.on 'fetched:localities', @append_popular_localities

				Housing.event.on 'shortlist:show', @hide_list_view
				Housing.event.on 'shortlist:hide', @show_list_view
				Housing.event.on 'shown:form', @unbind_key_listener
				Housing.event.on 'hidden:form', @bind_key_listener
				@bind_key_listener()

				@options.collection.on 'id:selected', @render_selected
				@options.collection.on 'reset', @on_collection_reset
				@options.collection.on 'change:seen', @refresh_on_filtering

				$(window).bind 'resize', @load_images_in_view

				# event for positoining and styling footer
				# Housing.event.trigger 'init:map_view:footer', {el: $('#main-content'), type: 'margin'}

			if render
				@$el.find('.js-list-subscribe').on "click",@show_subscribe_modal
				@$list_view.bind 'scroll', @load_images_in_view

		bind_key_listener: () =>
			if !@_key_listenter_bound
				$(document).bind 'keyup keydown keypress', @suppress_keys
				@_key_listenter_bound = true

		on_feedback_click: (e)=>
			Housing.event.trigger 'clicked:feedback', e

		_init_variables: () =>
			@_views = []
			@loaded_image = []
			max_count = @filtered_collection.length
			@loaded_image[i] = false for i in [0..max_count]
			@prev_top_visible_index = -1
			@list_item_height = 81 ## 80- height of item, 1- border-bottom
			@$open_footer_btn = $('footer .open-footer')

			## jquery variables
			@$list_view = @$el.find('.list-view') if @$el
			@container = @$list_view.find(".container") if @$list_view?
			@sugg_head = @$list_view.find('.sugg-accordion-head') if @$list_view?

		toggle_suggestions: (e) =>
			if not e
				@$list_view.find('#collapse01').css('height','auto')
				@sugg_head.removeClass('selected')
				@$list_view.find('#collapse02,#collapse03').css('height','0px')
				@$list_view.find('.sugg-accordion-head[data-head="1"]').addClass('selected')
				return
			head_index = $(e.currentTarget).data('head')
			if @$list_view.find('.sugg-accordion-head[data-head=' + head_index + ']').hasClass('selected')
				@$list_view.find('#collapse0'+head_index).css('height','0px')
				@sugg_head.removeClass('selected')
			else
				@$list_view.find('.panel-collapse').css('height','0px')
				@$list_view.find('#collapse0'+head_index).css('height','auto')
				@sugg_head.removeClass('selected')
				@$list_view.find('.sugg-accordion-head[data-head=' + head_index + ']').addClass('selected')

		get_other_suggestions: () =>
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

		# footer_visibility: () =>
		# 	if @$el.hasClass('show_footer')
		# 		Housing.event.trigger 'hide:footer_via_main', {el: $('#main-content'), type: 'margin'}
		# 		@$el.removeClass('show_footer')
		# 		@$open_footer_btn.removeClass('open')
		get_other_suggestions_html: ()=>
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

		handle_suggestions: () =>
			if @show_other_suggestions
				@$el.find('.other-suggestions .panel-collapse').html(@get_other_suggestions_html())
			@append_related_localities()

		append_related_localities: () =>
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

		get_popular_localities: () =>
			popular_locality_ids = Housing.selected_city.get('popular_locality_ids')
			if popular_locality_ids and popular_locality_ids.length
				popular_localities_div = ''
				_.each popular_locality_ids, (popular_locality_id) ->
					locality = Housing.localities.get(popular_locality_id)
					if locality
						str = '<h2><a class="link" href="' + Housing.router.get_url_till_service() + '/' + locality.get('url_name') + '" data-id="' + locality.get('id') + '" data-href="' + Housing.router.get_url_till_service() + '/search?f=' + locality.get('filter_param') + '">' + locality.get('name') + '</a></h2>'
						popular_localities_div += str
				return popular_localities_div
			else
				return ''

		hide_list_view:() =>
			@$list_view.addClass('hide')

		show_list_view:() =>
			@$list_view.removeClass('hide')

		show_subscribe_modal:(e)=>
			@suppress(e)
			Housing.event.trigger "load:subscribe:modal"
			Housing.event.trigger 'track:subscribe_alert', 'open', 'list-view'

		open_other_suggestions: (e)=>
			Housing.filters.trigger 'change'

		open_related_locality: (e) =>
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
				curr_nearby_obj = Housing.filters.get('nearby')
				nearby_circle.rad = curr_nearby_obj.rad || rad
				nearby_circle.name = item.get('name')

				Housing.filters.set('nearby', nearby_circle, {silent:true})
				Housing.filters.trigger 'change:nearby'
				Housing.filters.trigger 'change'
				Housing.event.trigger 'track:related_localities_links', $(e.target).html()
				@suppress(e)

		on_collection_reset: (collection, options) =>
			_.each @_views, (view) =>
				view.destroy() if view
			@_views = []
			max_count = @filtered_collection.length
			@loaded_image[i] = false for i in [0..max_count]

		get_list_end_pyr: () ->
			"<div class='list-end-pyr'><span class='heading'>We're adding 100's of flats everyday! <br/> Let us find them for you.<br/></span><a href='#' class='btn list-subscribe-btn js-list-subscribe' data-bypass='true'>Subscribe to this search</a><a href='#' class='btn btn-blue' data-toggle='modal' data-bypass='true'>Post your requirements</a></div>"

		open_need_flat: () ->
			service_name = "not_selected"
			Housing.event.trigger 'track:pyr','opened_pyr_side'
			Housing.router.goto_url('/post-requirement')

		scroll_to_top: =>
			setTimeout(() =>
				@$list_view.scrollTop 0
			,0)

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
				track_action = 'removed'
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

		scroll_to_index: (index, top = true) => # on passing false as second parameter, the list is scrolled to the listing at the bottom
			if index > -1
				new_top = @list_item_height * (index)
				if not top
					new_top = new_top - (@$list_view.height() - @list_item_height - 10)
				setTimeout(() =>
					@$list_view.animate({scrollTop: new_top})
				,0)
			else
				@scroll_to_top()

		load_images_in_view: (e) =>
			top_visible_index = parseInt(Math.floor(@$list_view.scrollTop()/@list_item_height)) - 4
			bottom_visible_index = parseInt(Math.ceil((@$list_view.scrollTop() + @$list_view.height())/@list_item_height)) + 4
			index = top_visible_index
			while index <= bottom_visible_index
				if @_views[index] and not @loaded_image[index]
					@_views[index].load_image()
					@loaded_image[index] = true
				index++
			@suppress(e)

			# Tracking Impressions after Scroll
			#==================================
			clearTimeout @scroll_stop_listener
			@scroll_stop_listener = setTimeout () =>
				Housing.event.trigger 'track:push_lv_impressions'
			, 250

			if !Housing.Util.is_tiling_service() or Housing.Util.get_view_type_id() == 1
				return

			viewScrollHeight = @$list_view[0].scrollHeight
			viewScrollTop = @$list_view.scrollTop()
			viewHeight = @$list_view.outerHeight()
			if Housing.promoted_listings then promoted_listings_length = Housing.promoted_listings.length else promoted_listings_length = 0
			filtered_results = @options.collection.where({fromFilter:true}).length - promoted_listings_length
			if !Housing.required_page and viewScrollHeight and viewScrollHeight - viewScrollTop - viewHeight < 600 and filtered_results < (Housing.total_results - promoted_listings_length)
				req_page = Math.ceil(filtered_results/40) + 1
				if req_page > 1
					@$el.find('.grid-loading-message').removeClass('hide')
					@append_list_elems(req_page)

		append_list_elems: (req_page) =>
			if !@document_append_completed
				return
			@document_append_completed = false
			Housing.required_page = req_page
			if @last_call_page and @last_call_page == Housing.required_page
				herr "issue in esapi"
				return

			filter_api_url = Housing.filters.get_filter_api_url()

			self = this
			if @current_filter_api_call?
				@current_filter_api_call.abort()
				@current_filter_api_call = null

			@current_filter_api_call = $.get(filter_api_url,(data) ->

				if !data
					return

				if data and data.captcha_required
					Housing.Util.api_captcha_reroute(data)
				else
					if !Housing.Util.is_service('pg') and !Housing.Util.different_response_service()
						data = data.result.listings
					else
						data = data.hits.hits if data.hits

					listings = []

					_.each data, (listing) ->
						if Housing.Util.is_service('pg') or Housing.Util.different_response_service()
							listing = listing._source
						listing.visibility = true
						listing.fromFilter = true
						if !Housing.promoted_listings or !Housing.promoted_listings.get(listing.id) # removing promoted listings from p=2 onwards
							listings.push(listing)

					shortlisted_items_not_from_filter = []
					self.options.collection.each (l) =>
						if l and l.get('isShortlisted') and !l.get('fromFilter')
							shortlisted_items_not_from_filter.push(l.attributes)
							self.options.collection.remove(l,{silent:true})

					self.options.collection.add(listings,{merge: true})
					self.options.collection.add(shortlisted_items_not_from_filter,{merge:true})

					self.refresh_on_filtering()
					Housing.required_page = null
					# self.$list_view.find('.list-loading-message').addClass('hide')
					self.$list_view.find('.list-loading-message').hide()
					self.last_call_page = Housing.required_page


			)
			.complete(() => @current_filter_api_call = null;)
			.fail(() => filter_api_url = null; hlog "ERROR IN GETTING FILTERED RESULTS"; )

		refresh_on_filtering: (params) =>
			if !Housing.required_page
				@last_call_page = undefined
			@filtered_collection = @options.collection.where({visibility:true, fromFilter: true})
			results_count = Housing.total_results
			if not results_count
				results_count = @filtered_collection.length

			if results_count == 1
				$('.list-header-tabs > .result-summary > .text').text('Result')
				$('.list-header-tabs > .result-summary > .summary').text(results_count)
			else
				$('.list-header-tabs > .result-summary > .text').text('Results')
				$('.list-header-tabs > .result-summary > .summary').text(results_count)
			if !@filtered_collection.length
				return

			document_list = document.createDocumentFragment()

			self = this
			_.each @filtered_collection, (listing) ->
				already_rendered = false
				rendered_list_item = null
				_.each self._views, (view) ->
					if view.model.id == listing.id
						rendered_list_item = view
						already_rendered = true
				promoted = false
				if listing.get('promoted')
					promoted = true
				if not already_rendered
					list_item = new self.list_item
						model: listing
						shortlist: self.options.shortlist
						show_image_count: true
						service: Housing.selected_service.get('url_name')
						img_prefix: 'small_'
						promoted: promoted
					$(list_item.el).addClass('promoted') if listing.get('promoted')
					self._views.push list_item
					document_list.appendChild(list_item.render(false).el)
				else
					rendered_list_item.render()
			self.container.append(document_list)
			if Housing.Util.is_tiling_service()
				@document_append_completed = true
			Housing.Util.EllipsisOnHover(@$el.find('.list-view'), 'bottom' )
			# @list_item_container = @$list_view.find('.list-item-container')
			@load_images_in_view()

			if params
				@$list_view.find('.list-end-pyr').removeClass('animate')
				if params.count < 7
					setTimeout(() =>
						@$list_view.find('.list-end-pyr').addClass('animate')
					,50)

		render_selected: (params) =>
			new_listing = null
			old_listing = null
			if params.new?
				new_listing = @options.collection.get(params.new)
				if new_listing = @options.collection.get(params.new)
					_.each @_views, (view) ->
						if view.model.id == params.new
							view.$el.addClass 'selected'
			if params.old?
				if old_listing = @options.collection.get(params.old)
					_.each @_views, (view) ->
						if view.model.id == params.old
							view.render()
							view.$el.removeClass 'selected'

			@bring_item_into_view(new_listing)

		suppress: (e) ->
			if e
				e.preventDefault()
				e.stopPropagation()

		suppress_keys: (e) ->
			if e.keyCode is 38 or e.keyCode is 40 or e.keyCode is 32
				e.preventDefault()
				e.stopPropagation()

		unbind_key_listener: =>
			$(document).unbind 'keyup keydown keypress', @suppress_keys
			@_key_listenter_bound = false

		unbind_events: ()=>
			@options.filters.off "completed:filtering", @refresh_on_filtering
			@options.filters.off "completed:filtering", @scroll_to_top
			@options.shortlist.off "added:shortlist removed:shortlist cleared:shortlist", @refresh_on_filtering
			@options.collection.off 'id:selected', @render_selected
			@options.collection.off 'reset', @on_collection_reset
			@options.collection.off 'change:seen', @refresh_on_filtering

			Housing.event.off 'finished:fetching_related_localties', @handle_suggestions
			Housing.event.off 'fetched:localities', @append_popular_localities

			$(window).unbind 'resize', @load_images_in_view

			Housing.event.off 'shortlist:show', @hide_list_view
			Housing.event.off 'shortlist:hide', @show_list_view
			Housing.event.off 'shown:form', @unbind_key_listener
			Housing.event.off 'hidden:form', @bind_key_listener

			Housing.event.off "navigate:listings:tiling", @bring_item_into_view

			@unbind_key_listener()

			@$el.find('.js-list-subscribe').off "click",@show_subscribe_modal
			@$list_view.unbind 'scroll', @load_images_in_view

		destroy: () =>
			@unbind_events()
			@on_collection_reset()
			# _.each @_views, (v) ->
			# 	v.destroy()
			@$el.removeData().unbind()
			@$el.find('.list-view').attr('style', '').removeData().unbind()
		_views: []

	return ListView