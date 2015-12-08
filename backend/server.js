'use strict';

const express = require('express')
    , path = require('path');

require('./amqp');
require('./socketio');

const app = express();

/* Serve static files */
const baseDir = path.resolve(__dirname, '..')
    , publicDir = path.resolve(baseDir, 'public')
    , nodeModulesDir = path.resolve(baseDir, 'node_modules');

app.use(express.static(publicDir));
app.use('/assets', express.static(nodeModulesDir));

/*
 * Start Express server (serving static assets.
 */
const server = app.listen(3000, function () {
  let port = server.address().port;
  console.log('MicroPlode presentation service listening at port', port);
});
