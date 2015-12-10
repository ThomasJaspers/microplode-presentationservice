'use strict';

/*
 * RabbitMQ connection
 */

const util = require('util')
    , amqp = require('amqp')
    , connection = amqp.createConnection({ host: 'localhost' })
    , boardUpdateQueue = 'microplode-board-update-queue'
    , socketIoHandler = require('./socket-io-handler');

exports.start = function() {
  establishConnection();
};

exports.onClick = function(data) {
  console.log('amqp-connector#onClick', data);
};

function establishConnection() {
  // Wait for ready event (wait for connection to become established).
  connection.on('ready', function() {
    console.log('AMQP connection established');
    socketIoHandler.start();

    connection.queue(boardUpdateQueue, function(queue) {
      console.log('Listening to AMQP queue ' + boardUpdateQueue);

      // Catch all messages
      queue.bind('#');

      // Receive messages
      queue.subscribe(message => {
        onMessage(message);
      });
    });
  });

  // Error handler - without this, errors during message processing are silently
  // discarded the connection is simply reset.
  connection.on('error', function(err) {
    console.error('Could not process message');
    console.error(err.stack);
  });
}

function onMessage(message) {
  let content;
  if ((message.hasOwnProperty('contentType') &&
      !message.contentType) ||
    util.isBuffer(message.data)) {
    // Partners should actualy send with content type application/json so
    // this should not happen.
    content = message.data.toString('utf8');
    console.log('Received AMQP message without content type or with ' +
      'wrong content type "' + message.contentType + '": ' + content);
    return;
  } else {
    content = message;
  }
  // Print messages to stdout
  console.log('Received AMQP message:');
  console.log(content);
  socketIoHandler.send(content);
}
