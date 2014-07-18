define [
	'backbone'
	'config'
	'underscore'
], (Backbone, Config, _)->

	LIB = []

	# Generates a random uuid in 8-4-4-4-12 fashion
	generateUUID = ->
		s4 = ->
			Math
				.floor((1 + Math.random()) * 0x10000)
				.toString(16)
				.substring(1)
		return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()

	class LibraryItem extends Backbone.Model
		defaults:
			fileEntry: null
		
		initialize: (fileEntry)->
			@set 'uuid', generateUUID()
			fileEntry.file (file)->
				chrome
					.mediaGalleries
					.getMetadata file, metadataType: 'all', (metadata)=>
						_.each metadata, (key, val)=> @set key, val
						@set 'fileEntry', fileEntry

		

	class MuseLibrary extends Backbone.Collection.extend
		model: LibraryItem


	Library = new MuseLibrary()
	return Library