define [
	'underscore'
	'config'
	'library'
], (_, Config, Library)->
	# Based on chrome-app-samples/mediagalleries
	


	class GalleryData
		constructor: (id)->
			@_id = id
			@path  = ''
			@size  = 0
			@files = 0
			@dirs  = 0

	class MuseScanner
		current = 0
		g_list = []
		g_data = []
		g_dirs = []
		reader = null
		gmetas = []

		items = []

		getLists: -> console.log g_list, g_data, g_dirs, current
		report  = (custom)-> 
			(e)->
				e.msg = "  #{custom}:: #{e.msg}"
				throw e

		constructor: (@factory)-> console.log 'Scanner:: Starting...'
			
		start: -> 
			items = []
			@factory.getMediaFileSystems @processFSList

			# Store a reference to accesible galleries
			@factory
				.getAllMediaFileSystemMetadata (metas)-> 
					Config.set 'Galleries', metas
					gmetas = metas


		processFSList: (results)=>
			return if not results.length
			_.each results, (fs, ind, fslist)=>
				if fs and fs.root
					meta   = @factory.getMediaFileSystemMetadata fs
					reader = do fs.root.createReader
					reader.readEntries @processEntries, report('Scanerror, from:FS')
					
					g_data[ind] = new GalleryData meta.id
					console.log "Scanner::Found Filesystem:: #{meta.name}"	
				else
					console.log "Error type: #{fs.fullPath}"
			g_list = results

		processEntries: (entries)=>
			unless entries.length
				unless g_dirs.length 
					dir    = do g_dirs.shift
					
					reader = do dir.createReader
					reader.readEntries @processEntries, report('Scanerror, from:PE')
					
					console.log "  Scanning::subdir:: #{dir.fullPath}"
				else
					current++
					if current < g_list.length
						console.log "  Scanning::Gallery:: #{g_list[current].name}"
						@processFSList g_list[current]
				return
			
			for entry in entries
				if entry.isFile
					g_data[current].files++
					
					# Add to library
					Library.addItem entry
					items.push entry
				
				# If it's a directory append it to directories array
				else if entry.isDirectory
					g_dirs.push entry
				
				else 
					console.log "Something other than file or directory"
		
		reset: ->
			current = 0
			g_list = g_data = []

		getItems: -> return items
		getItunesXML: -> _.findWhere items, fullPath:'/iTunes Music Library.xml'


	Scanner = new MuseScanner chrome.mediaGalleries
	return Scanner