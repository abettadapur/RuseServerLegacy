GS = require 'grooveshark-streaming'
request = require 'request'
spawn = require('child_process').spawn
vlc = require('vlc-api')()
recentSongs = {}
playingSongs = {}

exports.initialize = ()->
	spawn("vlc", ["--extraintf", "http", "--http-host", "0.0.0.0:8080"])
	console.log(vlc)


getLocalQueue = (cb)->
	
	#console.log("get queue")
	songs = []
	request "http://localhost:8080/requests/playlist.json", (error, response, body)->
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
					songs.push(selected)
	#				console.log(songs)

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
	request "http://localhost:8080/requests/status.json", (error,response,body)->
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

exports.addQueue = (songID)->
	song = recentSongs[songID]
	getUrl songID, (url)->
		playingSongs[url]=song
		song.url = url
		spawn("vlc",[url])

exports.playSong = (songID)->
	song = recentSongs[songID]
	getUrl songID, (url)->
		playingSongs[url] = song
		song.url = url
		vlc.status.play url, (err) ->
			#res.send("Playing")


getUrl = (id,callback)->
	GS.Grooveshark.getStreamingUrl id, (err,streamUrl)->
		callback streamUrl

exports.debugUrl = (req,res)->
	GS.Grooveshark.getStreamingUrl req.params.id, (err,streamUrl)->
		res.send(streamUrl)


exports.pause = ()->
	vlc.status.pause()
exports.resume = ()->
	vlc.status.resume()
exports.next = ()->
	vlc.status.next()
exports.prev = ()->
	vlc.status.prev()
exports.volume = (volume)->
	vlc.status.volume volume, (err)->
exports.goto = (id)->
	console.log("GOTO "+id)
	vlc.status.goto id, (err)->
		console.log(err)