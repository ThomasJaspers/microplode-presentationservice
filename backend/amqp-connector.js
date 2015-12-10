'use strict';

/*
 * RabbitMQ connection
 */

const util = require('util')
    , amqp = require('amqp')
    , connection = amqp.createConnection({ host: 'localhost' })
    , socketIoHandler = require('./socket-io-handler');

const mqNames = {
  boardUpdates: 'microplode.board-update-queue',
  moves: 'microplode.move-exchange',
};

const mqHandles = {};

exports.start = function() {
  establishConnection();
};

exports.onClick = function(message) {
  mqHandles.moves.publish('', message, {}, errorFlag => {
    if (!errorFlag) {
      console.log('amqp-connector#onClick published -> success', message);
    } else {
      console.log('amqp-connector#onClick published -> error', message);
    }
  });
  console.log('amqp-connector#onClick published', message);
};

function establishConnection() {
  // Wait for ready event (wait for connection to become established).
  connection.on('ready', function() {
    console.log('AMQP connection established');
    socketIoHandler.start();

    connectToBoardUpdateQueue();
    connectToMoveExchange();
    setupErrorHandler();
  });
}

function connectToBoardUpdateQueue() {
  connection.queue(mqNames.boardUpdates, function(queue) {
    console.log('Listening to AMQP queue ' + mqNames.boardUpdates);
    mqHandles.boardUpdates = queue;

    // Catch all messages
    mqHandles.boardUpdates.bind('#');

    // Receive messages
    mqHandles.boardUpdates.subscribe(message => {
      onMessage(message);
    });
  });
}

function connectToMoveExchange() {
  connection.exchange(mqNames.moves, {}, function(exchange) {
    mqHandles.moves = exchange;
    mqHandles.moves.on('open', function() {
      console.log('Connected to AMQP exchange ' + mqNames.moves);
    });
  });
}

function setupErrorHandler() {
  // Without an error handler, errors during message processing are silently
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
