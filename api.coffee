GS = require 'grooveshark-streaming'
request = require 'request'
spawn = require('child_process').spawn
vlc = require('vlc-api')()
youtube = require 'youtube-feeds'
recentSongs = {}
playingSongs = {}
querystring = require 'querystring'

exports.initialize = ()->
	spawn("vlc", ["--extraintf", "http", "--http-host", "0.0.0.0:8080"])
	#console.log(vlc)


getLocalQueue = (cb)->
	
	#console.log("get queue")
	songs = []

	options = 
		url:"http://localhost:8080/requests/playlist.json"
		auth: 
			user:''
			password:'ruse'

	request options, (error, response, body)->
	#	console.log(body)
		json = JSON.parse body
		children = json.children;
		child = undefined
		for item in children
			if(item.name=="Playlist")
				#console.log("found")
				child = item
				break

		if(child==undefined)
			
		else
	#		console.log("Child: "+JSON.stringify(child))
			for song in child.children
				#console.log playingSongs
				selected = playingSongs[song.name]
				
				if(selected!=undefined)
					if song.hasOwnProperty('current')
						selected.current = true
					else
						selected.current = false
					
					selected.duration = song.duration
					selected.vlcid = song.id
					console.log selected
					songs.push(selected)
	#				console.log(songs)
				else
					#console.log "undefined song"
					selected = 
						SongName:song.name
						duration:song.duration
						vlcid:song.id
					if song.hasOwnProperty('current')
						selected.current = true
					else
						selected.current = false
					songs.push(selected)


			console.log songs
			cb(songs)

exports.getQueue = (req,res)->
	getLocalQueue (songs)->	
		console.log(songs)		
		res.send JSON.stringify(songs)

exports.lookUpUri = (req,res)->
	uri = req.params.uri
	song = playingSongs[uri]
	res.send(song)
	
exports.getStatus = (cb) ->
	options = 
		url:"http://localhost:8080/requests/status.json"
		auth: 
			user:''
			password:'ruse'

	request.get options, (error,response,body)->
		json = JSON.parse body
		getLocalQueue (songs)->
			json.queue = songs
			cb json;

exports.getStatusDebug = (req,res)->
	request "http://localhost:8080/requests/status.json", (error,response,body)->
		json = JSON.parse body
		getLocalQueue (songs)->
			json.queue = songs
			res.send(json)






exports.search = (req,res)->
	url = 'http://tinysong.com/s/'+req.params.query+'?limit=30&format=json&key=a5e40d9f03761fb1ae45b298098cdda1'
	request url, (error,response,body) ->
		songs = JSON.parse body

		for song in songs
			recentSongs[song.SongID] = song

		res.send(body)

exports.yousearch = (req,res) ->
	youtube.httpProtocol = 'https'
	youtube.feeds.videos {q:req.params.query, orderby: 'relevance'}, (err,data)->
		 #results = JSON.parse data
		 for item in data.items
		 	recentSongs[item.id] = item;
		 res.send data.items




exports.addQueue = (songID)->
	song = recentSongs[songID]
	getUrl songID, (url)->
		playingSongs[url] = song
		song.url = url
		query = querystring.stringify {command:'in_enqueue', input:url}
		console.log query
		options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

		request options

exports.playSong = (songID)->
	song = recentSongs[songID]
	getUrl songID, (url)->
		playingSongs[url] = song
		song.url = url
		query = querystring.stringify {command:'in_play', input:url}
		console.log query
		options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

		request options

exports.playYoutube = (songID)->
	song = recentSongs[songID]
	url = 'https://www.youtube.com/watch?v='+songID
	query = querystring.stringify {command:'in_play', input:url}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	playingSongs[url] = song;
	request options

exports.addQueueYoutube = (songID)->
	song = recentSongs[songID]
	url = 'https://www.youtube.com/watch?v='+songID
	query = querystring.stringify {command:'in_enqueue', input:url}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	playingSongs[url] = song;
	request options



getUrl = (id,callback)->
	GS.Grooveshark.getStreamingUrl id, (err,streamUrl)->
		callback streamUrl

exports.debugUrl = (req,res)->
	GS.Grooveshark.getStreamingUrl req.params.id, (err,streamUrl)->
		res.send(streamUrl)


exports.pause = ()->
	query = querystring.stringify {command:'pl_pause'}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	request options

exports.resume = ()->
	query = querystring.stringify {command:'pl_play'}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	request options
exports.next = ()->
	query = querystring.stringify {command:'pl_next'}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	request options
exports.prev = ()->
	query = querystring.stringify {command:'pl_previous'}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	request options
exports.volume = (volume)->
	query = querystring.stringify {command:'volume', val:volume}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	request options
exports.goto = (id)->
	query = querystring.stringify {command:'pl_play', id:id}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	request options

exports.seek = (sec) ->
	query = querystring.stringify {command:'seek', val:sec}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	request options

exports.delete = (id) ->
	query = querystring.stringify {command:'pl_delete', id:id}
	console.log query
	options = 
			url:"http://localhost:8080/requests/status.xml?"+query
			auth: 
				user:''
				password:'ruse'

	request options