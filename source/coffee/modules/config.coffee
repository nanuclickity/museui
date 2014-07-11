define [
	'underscore'
], (_)->

	_Defaults = {}
	_Buffer   = {}

	class MuseConfig
		
		constructor: (@_Buffer)->
			# Buffers up storage
			# '_Buffer' will act as storage for session
			@_Buffer.get null, @onStorageLoad
		
		onStorageLoad: (objects)->
			_Buffer = allContents
			@isLoaded = true
		
		get: (key)-> 
			return _Buffer if key is null
			_Buffer[key]
		
		# In case we need it somewhere
		getAll: -> _Buffer
		
		set: (key, value)-> 
			if !key then throw new Error 'Invalid arguments'
			else _Buffer[key] = value

		clear: -> 
			_Buffer = {}
			do @_Buffer.clear

		save: -> @_Buffer.set _Buffer, -> console.log 'Config:: Saved.'


	# change storage to sync later on
	Config = new MuseConfig chrome.storage.local
	
	
	return Config