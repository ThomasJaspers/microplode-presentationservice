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
      try {
        let clickMessage = JSON.parse(data);
        console.log('click:', clickMessage);
        amqpConnector.sendMoveEvent(clickMessage);
        console.log('sent message to AMQP');
      } catch (e) {
        console.error('unparseable Socket.io message: ' + data + ' -- ', e);
      }
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
