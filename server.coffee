express = require 'express'
api = require './api'
IO = require 'socket.io'
http = require 'http'
app = require('express')()


server = http.createServer(app).listen(3000,"0.0.0.0");
io = IO.listen(server)
io.set('log level', 1);



io.sockets.on 'connection', (socket)->
	console.log("Connection");
	tweets = setInterval(->
  		api.getStatus (json) ->
    		socket.volatile.emit "status", json

	, 1000)

	socket.on 'play', (msg)->
		console.log("Play message received "+msg)
		api.playSong(msg)
	socket.on 'queue', (msg)->
		api.addQueue(msg)
	socket.on 'prev', (msg)->
		api.prev()
	socket.on 'skip', (msg)->
		api.next()
	socket.on 'pause', (msg)->
		api.pause()
	socket.on 'resume', (msg)->
		api.resume()
	socket.on 'volume', (msg)->
		api.volume(msg)
	socket.on 'goto', (msg)->
		api.goto(msg)





api.initialize()

app.get('/queue', api.getQueue)
app.get('/queue/lookup/',api.lookUpUri)
app.get('/status/debug', api.getStatusDebug)
app.get('/lib/search/:query', api.search)
#app.get('/queue/play/:id', api.playSong)
#app.get('/queue/add/:id', api.addQueue)
#app.get("/url/:id", api.debugUrl)
#app.get("/player/pause", api.pause)
#app.get "/player/resume", api.resume
#app.get("/player/next", api.next)
#app.get("/player/prev", api.prev)
#app.get("player/volume/:volume", api.volume)





