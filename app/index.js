// Generated by CoffeeScript 1.4.0
var Campfire, Q, addUser, app, assets, async, crypto, express, http, io, port, server, stylus, underscoreKeys, underscoreMessage,
  __hasProp = {}.hasOwnProperty;

String.prototype.toUnderscore = function() {
  return this.replace(/([A-Z])/g, function($1) {
    return "_" + $1.toLowerCase();
  });
};

underscoreKeys = function(obj) {
  var key, ret, value;
  ret = {};
  for (key in obj) {
    if (!__hasProp.call(obj, key)) continue;
    value = obj[key];
    ret[key.toUnderscore()] = value;
  }
  return ret;
};

express = require('express');

stylus = require('stylus');

assets = require('connect-assets');

http = require('http');

async = require('async');

crypto = require('crypto');

Q = require('q');

Q.map = Q.nfbind(async.map);

app = express();

server = http.createServer(app);

io = require('socket.io').listen(server);

Campfire = require('ranger').createClient('hungrymachine', 'e596ccc950889fe695ba159fd3adaa2af15eaee5');

app.use(assets());

app.use(express["static"](process.cwd() + '/public'));

app.set('view engine', 'jade');

app.get('/', function(req, resp) {
  return resp.render('index');
});

port = process.env.PORT || process.env.VMC_APP_PORT || 3000;

server.listen(port, function() {
  return console.log("Listening on " + port + "\nPress CTRL-C to stop server.");
});

io.sockets.on('connection', function(socket) {
  console.log('A socket connected!');
  Campfire.presence(function(rooms) {
    return socket.emit('rooms', rooms);
  });
  console.log("Connecting to room " + (+process.env.ROOM_ID));
  return Campfire.room(+process.env.ROOM_ID, function(room) {
    room.recentMessages(function(data) {
      return Q.map(data.messages, addUser).then(function(messages) {
        return socket.emit('recent', messages);
      });
    });
    return room.listen(function(message) {
      message = underscoreKeys(message);
      return addUser(message, function(err, message) {
        return socket.emit('message', message);
      });
    });
  });
});

underscoreMessage = function(message, callback) {
  return callback(null, underscoreKeys(message));
};

addUser = function(message, callback) {
  if (message.user_id) {
    return Campfire.user(message.user_id, function(user) {
      var md5;
      md5 = crypto.createHash('md5');
      md5.update(user.emailAddress);
      user.emailHash = md5.digest('hex');
      message.user = user;
      return callback(null, message);
    });
  } else {
    return callback(null, message);
  }
};
