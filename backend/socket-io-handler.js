'use strict';

const connections = []
    , io = require('socket.io')(3001)
    , SocketIoConnection = require('./socket-io-connection');

exports.start = function() {
  io.on('connection', function(socket) {
    console.log('MicroPlode client connected.');
    new SocketIoConnection(io, socket);
  });
};

exports.registerConnection = function(connection) {
  connections.push(connection);
  console.log('Client connected. ' + connections.length + ' connected ' +
      'clients in.total.');
};

exports.deregisterConnection = function(connection) {
  let idx = connections.indexOf(connection);
  if (idx >= 0) {
    connections.splice(idx, 1);
  }
  console.log('Client left. ' + connections.length + ' clients left.');
};

exports.send = function(message) {
  // For now, we just broadcast to all registered clients
  console.log('Broadcasting message to ' + connections.length + ' clients');
  connections.forEach(connection => {
    connection.send(message);
  });
};
