'use strict';

const amqpConnector = require('./amqp-connector')
    , socketIoHandler = require('./socket-io-handler');

class SocketIoConnection {

  constructor(io, socket) {
    this.io = io;
    this.socket = socket;
    this.startListening();
  }

  startListening() {
    this.socket.on('message', data => {
      console.log('MicroPlode client sent:', data);
    });

    this.socket.on('click', data => {
      console.log('click:', data);
       amqpConnector.onClick(data);
      console.log('sent message to AMQP');
    });

    this.socket.on('disconnect', socket => {
      socketIoHandler.deregisterConnection(this);
      console.log('MicroPlode client disconnected.');
    });

    socketIoHandler.registerConnection(this);
  }

  send(message) {
    this.io.emit('update-board', [
        { x: 0, y: 0, charge: 0 }
      , { x: 1, y: 0, charge: 0 }
      , { x: 2, y: 0, charge: 0 }
      , { x: 0, y: 1, charge: 0 }
      , { x: 1, y: 1, charge: 0 }
      , { x: 2, y: 1, charge: 0 }
    ]);
    console.log('emitted');
  }
}

module.exports = SocketIoConnection;
