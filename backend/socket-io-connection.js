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

    this.socket.on('move', data => {
      try {
        let message = JSON.parse(data);
        console.log('receiving move event from socket.io:', message);
        if (message.player && message.player >= 0 &&
            message.x && message.x >= 0 &&
            message.y && message.y >= 0) {
          amqpConnector.sendMoveEvent(message);
          console.log('sent move message to AMQP');
        } else {
          console.log('ignoring move', message);
        }
      } catch (e) {
        console.error('unparseable Socket.io message: ' + data + ' -- ', e);
      }
    });

    this.socket.on('game-event', data => {
      try {
        let message = JSON.parse(data);
        console.log('receiving game from socket.io:', message);
        if (message.event && message.event === 'new-game') {
          amqpConnector.sendNewGameEvent(message);
          console.log('sent new game message to AMQP');
        } else {
          console.log('ignoring game event', message);
        }
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
    this.io.emit('update-board', message);
    console.log('emitted');
  }
}

module.exports = SocketIoConnection;
