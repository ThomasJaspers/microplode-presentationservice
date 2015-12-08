'use strict';

const util = require('util');

/*
 * RabbitMQ connection
 */
const amqp = require('amqp');

const connection = amqp.createConnection({ host: 'localhost' });

// Wait for connection to become established.
connection.on('ready', function() {
  console.log('AMQP connection ready');

  // Use the default 'amq.topic' exchange
  connection.queue('my-queue', function(q) {

    console.log('listening to AMQP queue');

    // Catch all messages
    q.bind('#');

    // Receive messages
    q.subscribe(function(message) {
      debugger;
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
        console.log('Received AMQP message:');
        content = message;
      }
      // Print messages to stdout
      console.log(content);
    });
  });
});

