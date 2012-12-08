String::toUnderscore = ->
  @replace /([A-Z])/g, ($1) -> "_" + $1.toLowerCase()

underscoreKeys = (obj) ->
  ret = {}
  for own key, value of obj
    ret[key.toUnderscore()] = value
  ret

express = require 'express'
stylus  = require 'stylus'
assets  = require 'connect-assets'
http    = require 'http'
async   = require 'async'
crypto  = require 'crypto'
Q       = require 'q'

Q.map = Q.nfbind(async.map)

app    = express()
server = http.createServer app
io     = require('socket.io').listen server

Campfire = require('ranger').createClient 'hungrymachine', 'e596ccc950889fe695ba159fd3adaa2af15eaee5'

app.use assets()
app.use express.static(process.cwd() + '/public')

app.set 'view engine', 'jade'
app.get '/', (req, resp) -> resp.render 'index'

port = process.env.PORT or process.env.VMC_APP_PORT or 3000

server.listen port, -> console.log "Listening on #{port}\nPress CTRL-C to stop server."

io.sockets.on 'connection', (socket) ->
  console.log 'A socket connected!'

  Campfire.presence (rooms) ->
    socket.emit 'rooms', rooms

  console.log "Connecting to room #{+process.env.ROOM_ID}"

  Campfire.room +process.env.ROOM_ID, (room) ->
    room.recentMessages (data) ->
      Q.map(data.messages, addUser)
       .then (messages) -> socket.emit 'recent',  messages

    room.listen (message) ->
      message = underscoreKeys message
      addUser message, (err, message) ->
        socket.emit 'message', message

underscoreMessage = (message, callback) ->
  callback null, underscoreKeys message

addUser = (message, callback) ->
  if message.user_id
    Campfire.user message.user_id, (user) ->
      md5 = crypto.createHash('md5')
      md5.update user.emailAddress
      user.emailHash = md5.digest('hex')
      message.user = user
      callback null, message
  else
    callback null, message
