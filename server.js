var express = require('express')
  , app = express()
  , io = require('socket.io')(3001);

// TODO Move static assets to sub directory
app.use(express.static('.'));

app.get('/', function (req, res) {
  res.send('Hello World!');
});

io.on('connection', function(socket) {
  console.log('MicroPlode client connected.');

  socket.on('message', function(data) {
    console.log('MicroPlode client sent:', data);
  });

  socket.on('click', function(data) {
    console.log('click:', data);
  });

  socket.on('disconnect', function(socket) {
    console.log('MicroPlode client disconnected.');
  });

  socket.send('Hey there, I am the MicroPlode websockets server. \'Sup?');
});

var server = app.listen(3000, function () {
  var port = server.address().port;
  console.log('MicroPlode presentation service listening at port', port);
});
