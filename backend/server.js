'use strict';

const express = require('express')
    , path = require('path')
    , amqpConnector = require('./amqp-connector');

amqpConnector.start();

const app = express();

/* Serve static files */
const baseDir = path.resolve(__dirname, '..')
    , publicDir = path.resolve(baseDir, 'public')
    , nodeModulesDir = path.resolve(baseDir, 'node_modules');

app.use(express.static(publicDir));
app.use('/assets', express.static(nodeModulesDir));

// TODO Remove dummy post handler
app.post('/game', function(req, res) {
  res.status(303).location('/game/1').send();
});

/*
 * Start Express server (serving static assets.
 */
const server = app.listen(3000, function () {
  let port = server.address().port;
  console.log('MicroPlode presentation service listening at port', port);
});
