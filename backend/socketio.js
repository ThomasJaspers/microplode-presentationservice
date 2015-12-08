'use strict';

const io = require('socket.io')(3001);

/*
 * Socket.io connection.
 */
io.on('connection', function(socket) {
  console.log('MicroPlode client connected.');

  socket.on('message', function(data) {
    console.log('MicroPlode client sent:', data);
  });

  socket.on('click', function(data) {
    console.log('click:', data);
    io.emit('update-board', [
        { x: 0, y: 0, charge: 0 }
      , { x: 1, y: 0, charge: 0 }
      , { x: 2, y: 0, charge: 0 }
      , { x: 0, y: 1, charge: 0 }
      , { x: 1, y: 1, charge: 0 }
      , { x: 2, y: 1, charge: 0 }
    ]);
    console.log('emitted');
  });

  socket.on('disconnect', function(socket) {
    console.log('MicroPlode client disconnected.');
  });
});


