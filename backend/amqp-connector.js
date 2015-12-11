'use strict';

/*
 * RabbitMQ connection
 */

const amqp = require('amqp')
    , connection = amqp.createConnection({ host: 'localhost' })
    , socketIoHandler = require('./socket-io-handler')
    , util = require('util');

const mqNames = {
  boardUpdates: 'microplode.boardservice.presentationservice.queue',
  moves: 'microplode.presentationservice.gameservice.exchange',
};

const mqHandles = {};

exports.start = function() {
  establishConnection();
};

exports.sendMoveEvent = function(move) {
  console.log('move in', move);
  let moveEvent = {
    event: {
      type: 'move',
      playerId: move.player,
      'field-row': move.y,
      'field-col': move.x,
    }
  };
  console.log('move event', moveEvent);
  mqHandles.moves.publish('', moveEvent, {}, errorFlag => {
    if (!errorFlag) {
      console.log('amqp-connector#onClick published -> success');
    } else {
      console.log('amqp-connector#onClick published -> error');
    }
  });
  console.log('amqp-connector#onClick published', moveEvent);
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
  connection.queue(mqNames.boardUpdates, {
      autoDelete: false,
    }, function(queue) {
    console.log('listening to AMQP queue ' + mqNames.boardUpdates);
    mqHandles.boardUpdates = queue;

    // Catch all messages
    mqHandles.boardUpdates.bind('#');

    // Receive messages
    mqHandles.boardUpdates.subscribe(boardUpdateEvent => {
      onBoardUpdate(boardUpdateEvent);
    });
  });
}

function connectToMoveExchange() {
  connection.exchange(mqNames.moves, {}, function(exchange) {
    mqHandles.moves = exchange;
    mqHandles.moves.on('open', function() {
      console.log('connected to AMQP exchange ' + mqNames.moves);
    });
  });
}

function setupErrorHandler() {
  // Without an error handler, errors during message processing are silently
  // discarded the connection is simply reset.
  connection.on('error', function(err) {
    console.error('could not process message');
    console.error(err.stack);
  });
}

function onBoardUpdate(boardUpdateEvent) {
  let boardUpdateContent;
  if ((boardUpdateEvent.hasOwnProperty('contentType') &&
      !boardUpdateEvent.contentType) ||
    util.isBuffer(boardUpdateEvent.data)) {
    // Partners should actualy send with content type application/json so
    // this should not happen.
    boardUpdateContent = boardUpdateEvent.data.toString('utf8');
    console.log('received AMQP message without content type or with ' +
      'wrong content type "' + boardUpdateEvent.contentType + '": ' +
      boardUpdateContent);
    return;
  } else {
    boardUpdateContent = boardUpdateEvent;
  }
  console.log('received board changed event via AMQP.');

  if (!boardUpdateContent.event ||
      !boardUpdateContent.event.type ||
      boardUpdateContent.event.type !== 'board-changed' ||
      !util.isArray(boardUpdateContent.event.fieldList)) {
    console.log('ignoring invalid board changed message');
    console.log(boardUpdateContent);
    return;
  }

  // create empty board as default in case the board service only sends
  // partial board data.
  let newBoard = [];
  for (let row = 0; row < 10; row++) {
    let rowData = [];
    for (let column = 0; column < 10; column++) {
      rowData.push({ x: column, y: row, load: 0 });
    }
    newBoard.push(rowData);
  }

  boardUpdateContent.event.fieldList.forEach(field => {
    if (field.playerId && field.playerId === '') {
      delete field.playerId;
    }
    newBoard[field.row][field.col] = {
      x: field.col,
      y: field.row,
      load: field.load,
    };
    if (field.playerId) {
      newBoard[field.row][field.col].playerId = parseInt(field.playerId, 10);
    }
  });

  socketIoHandler.send({
    event: 'update-board',
    board: newBoard,
  });
}
