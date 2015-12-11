MicroPlode Frontend
===================

This service connects the other MicroPlode services to the frontend. It is implemented in Node.js and has a frontend part written in Elm. You need to have Node.js version 4 or later installed.

The services has two responsibilities:

* Serving the static assets (HTML, CSS, JavaScript)
* Receive AMQP messages from other services and forward them to the frontend via Socket.io.

Setup
-----

* `npm install` to install all dependencies. This also installs the Elm platform (which is needed to build the frontend assets) from npm as a local dependency. Finally, npm install runs`elm-make` as a post install hook once to build the `public/microplode.js`.
* `npm start` starts the service.
* The service is then available at <http://localhost:3000>.

npm run scripts
----------------

* `npm run make` compiles the Elm sources into JavaScript.
* `npm run clean` removes artifacts from a previous build.
* `npm run clean-make` triggers `npm run clean` first, then `npm run make`.
* `npm run start` compiles the Elm sources once and then starts the service.
* `npm run dev` starts the server in dev mode. In particular:
    * Starts nodemon to watch the Node.js sources (which will restart the server when the sources change) and, simultaneously,
    * starts a script that watches the Elm sources via entr, which will recompile the Elm stuff when it changes.
    * You need to have nodemon and entr installed for this to work.


