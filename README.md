MicroPlode Frontend
===================

Setup
-----
* `npm install` to install the Elm platform from npm as a local dependency. This also runs `elm-make` once to build `microplode.js`.


Development Mode
----------------

* `npm run dev` starts elm-reactor with the correct ELM_HOME set (alternatively, you could do `ELM_HOME=node_modules/elm/share node_modules/.bin/elm-reactor` manually).
* Go to <http://localhost:8000/index.debug.html>.
* You now see the Elm app including your custom HTML and CSS.
    * Live reload should work (but unfortunately it doesn't seems Elm 0.16 broke it to some extent?)
    * Live reload does *not* work for changes in the static HTML or CSS, you'll have to do trigger a browser refresh manually for those.
    * You can use the integrated Elm debugger.


Pseudo Production Mode
----------------------

* `npm start` starts the frontend in "production mode" by simply building it with `elm-make` and then serving it via [http-server](https://github.com/indexzero/http-server).
* Go to <http://localhost:8080/index.html>.
    * This is the production view. No live reload, no debugger.
    * If you change the code, you need to rebuild `microplode.js` by executing `npm run make` or by stopping the running http-server and execute `npm start` again (which will also trigger `npm run make`).
