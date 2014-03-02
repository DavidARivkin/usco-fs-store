require=(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

},{}],2:[function(require,module,exports){
// shim for using process in browser

var process = module.exports = {};

process.nextTick = (function () {
    var canSetImmediate = typeof window !== 'undefined'
    && window.setImmediate;
    var canPost = typeof window !== 'undefined'
    && window.postMessage && window.addEventListener
    ;

    if (canSetImmediate) {
        return function (f) { return window.setImmediate(f) };
    }

    if (canPost) {
        var queue = [];
        window.addEventListener('message', function (ev) {
            var source = ev.source;
            if ((source === window || source === null) && ev.data === 'process-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);

        return function nextTick(fn) {
            queue.push(fn);
            window.postMessage('process-tick', '*');
        };
    }

    return function nextTick(fn) {
        setTimeout(fn, 0);
    };
})();

process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];

process.binding = function (name) {
    throw new Error('process.binding is not supported');
}

// TODO(shtylman)
process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};

},{}],3:[function(require,module,exports){
(function (process,__dirname){
var path = require('path');
var fs = require('fs');

function Mime() {
  // Map of extension -> mime type
  this.types = Object.create(null);

  // Map of mime type -> extension
  this.extensions = Object.create(null);
}

/**
 * Define mimetype -> extension mappings.  Each key is a mime-type that maps
 * to an array of extensions associated with the type.  The first extension is
 * used as the default extension for the type.
 *
 * e.g. mime.define({'audio/ogg', ['oga', 'ogg', 'spx']});
 *
 * @param map (Object) type definitions
 */
Mime.prototype.define = function (map) {
  for (var type in map) {
    var exts = map[type];

    for (var i = 0; i < exts.length; i++) {
      if (process.env.DEBUG_MIME && this.types[exts]) {
        console.warn(this._loading.replace(/.*\//, ''), 'changes "' + exts[i] + '" extension type from ' +
          this.types[exts] + ' to ' + type);
      }

      this.types[exts[i]] = type;
    }

    // Default extension is the first one we encounter
    if (!this.extensions[type]) {
      this.extensions[type] = exts[0];
    }
  }
};

/**
 * Load an Apache2-style ".types" file
 *
 * This may be called multiple times (it's expected).  Where files declare
 * overlapping types/extensions, the last file wins.
 *
 * @param file (String) path of file to load.
 */
Mime.prototype.load = function(file) {

  this._loading = file;
  // Read file and split into lines
  var map = {},
      content = fs.readFileSync(file, 'ascii'),
      lines = content.split(/[\r\n]+/);

  lines.forEach(function(line) {
    // Clean up whitespace/comments, and split into fields
    var fields = line.replace(/\s*#.*|^\s*|\s*$/g, '').split(/\s+/);
    map[fields.shift()] = fields;
  });

  this.define(map);

  this._loading = null;
};

/**
 * Lookup a mime type based on extension
 */
Mime.prototype.lookup = function(path, fallback) {
  var ext = path.replace(/.*[\.\/\\]/, '').toLowerCase();

  return this.types[ext] || fallback || this.default_type;
};

/**
 * Return file extension associated with a mime type
 */
Mime.prototype.extension = function(mimeType) {
  var type = mimeType.match(/^\s*([^;\s]*)(?:;|\s|$)/)[1].toLowerCase();
  return this.extensions[type];
};

// Default instance
var mime = new Mime();

// Load local copy of
// http://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types
mime.load(path.join(__dirname, 'types/mime.types'));

// Load additional types from node.js community
mime.load(path.join(__dirname, 'types/node.types'));

// Default type
mime.default_type = mime.lookup('bin');

//
// Additional API specific to the default instance
//

mime.Mime = Mime;

/**
 * Lookup a charset based on mime type.
 */
mime.charsets = {
  lookup: function(mimeType, fallback) {
    // Assume text types are utf8
    return (/^text\//).test(mimeType) ? 'UTF-8' : fallback;
  }
};

module.exports = mime;

}).call(this,require("/home/mmoissette/dev/projects/coffeescad/stores/usco-fs-store/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"),"/../../node_modules/mime")
},{"/home/mmoissette/dev/projects/coffeescad/stores/usco-fs-store/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":2,"fs":1,"path":false}],"6aToiT":[function(require,module,exports){
(function (process){
'use strict';
var FSStore, Minilog, Q, detectEnv, fs, logger, mime, path,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

detectEnv = require("composite-detect");

Q = require("q");

fs = require("fs");

path = require("path");

mime = require("mime");

if (detectEnv.isModule) {
  Minilog = require("minilog");
  Minilog.pipe(Minilog.suggest).pipe(Minilog.backends.console.formatClean).pipe(Minilog.backends.console);
  logger = Minilog('fs-store');
}

if (detectEnv.isNode) {
  Minilog.pipe(Minilog.suggest).pipe(Minilog.backends.console.formatColor).pipe(Minilog.backends.console);
}

if (detectEnv.isBrowser) {
  Minilog.pipe(Minilog.suggest).pipe(Minilog.backends.console.formatClean).pipe(Minilog.backends.console);
  logger = Minilog('fs-store');
}

FSStore = (function() {
  function FSStore(options) {
    this.getStats = __bind(this.getStats, this);
    this.resolvePath = __bind(this.resolvePath, this);
    this["delete"] = __bind(this["delete"], this);
    this.move = __bind(this.move, this);
    this.write = __bind(this.write, this);
    this.read = __bind(this.read, this);
    this.list = __bind(this.list, this);
    var defaults;
    options = options || {};
    defaults = {
      enabled: (typeof process !== "undefined" && process !== null ? true : false),
      name: "fs",
      type: "fs",
      description: "NodeJS fs file system store",
      rootUri: typeof process !== "undefined" && process !== null ? process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE : null,
      isDataDumpAllowed: false,
      showPaths: true
    };
  }


  /*-------------------file/folder manipulation methods---------------- */


  /**
  * list all elements inside the given uri (non recursive)
  * @param {String} uri the folder whose content we want to list
  * @return {Object} a promise, that gets resolved with the content of the uri
   */

  FSStore.prototype.list = function(uri) {
    var deferred, promise;
    deferred = Q.defer();
    promise = Q.fcall(function() {
      var contents, error, stats;
      if (!fs.existsSync(uri)) {
        throw new Error("" + uri + " does not exist");
      }
      stats = fs.statSync(uri);
      if (!stats.isDirectory()) {
        return [];
      }
      try {
        contents = fs.readdirSync(uri);
        return contents.sort();
      } catch (_error) {
        error = _error;
        throw error;
      }
    });
    deferred.resolve(promise);
    return deferred;
  };


  /**
  * read the file at the given uri, return its content
  * @param {String} uri absolute uri of the file whose content we want
  * @param {String} encoding the encoding used to read the file
  * @return {Object} a promise, that gets resolved with the content of file at the given uri
   */

  FSStore.prototype.read = function(uri, encoding) {
    var deferred, promise;
    encoding = encoding || 'utf8';
    deferred = Q.defer();
    promise = Q.fcall(function() {
      var contents, error, stats;
      if (!fs.existsSync(uri)) {
        throw new Error("" + uri + " does not exist");
      }
      stats = fs.statSync(uri);
      if (stats.isDirectory()) {
        throw new Error("" + uri + " is a directory");
      }
      try {
        contents = fs.readFileSync(uri, encoding);
        return contents;
      } catch (_error) {
        error = _error;
        throw error;
      }
    });
    deferred.resolve(promise);
    return deferred;
  };


  /**
  * write the file at the given uri, with the given data, using given mimetype
  * @param {String} uri absolute uri of the file we want to write (if the intermediate directories do not exist, they get created)
  * @param {String} data the content we want to write to the file
  * @param {String} type the mime-type to use
  * @return {Object} a promise, that gets resolved with "true" if writing to the file was a success, the error in case of failure
   */

  FSStore.prototype.write = function(uri, data, type, overwrite) {
    var deferred, promise;
    type = type || 'utf8';
    overwrite = overwrite || true;
    deferred = Q.defer();
    promise = Q.fcall(function() {
      var dirName, error;
      if (fs.existsSync(uri)) {
        if (!overwrite) {
          throw new Error("" + newUri + " already exist");
        }
      }
      try {
        dirName = path.dirname(uri);
        if (!fs.existsSync(dirName)) {
          fs.mkdirSync(dirName);
        }
        fs.writeFileSync(uri, data);
        return true;
      } catch (_error) {
        error = _error;
        if (error.errno === 34 && error.code === 'ENOENT' && error.syscall === 'mkdir') {
          throw new Error("Failed to create directory: " + error.path);
        }
        throw error;
      }
    });
    deferred.resolve(promise);
    return deferred;
  };


  /**
  * move/rename the item at first uri to the second uri
  * @param {String} uri absolute uri of the source file or folder
  * @param {String} newuri absolute uri of the destination file or folder
  * @param {Boolean} whether to allow overwriting or not (defaults to false)
  * @return {Object} a promise, that gets resolved with "true" if moving/renaming the file was a success, the error in case of failure
   */

  FSStore.prototype.move = function(uri, newUri, overwrite) {
    var deferred, promise;
    overwrite = overwrite || false;
    deferred = Q.defer();
    promise = Q.fcall(function() {
      var dirName, error;
      if (!fs.existsSync(uri)) {
        throw new Error("" + uri + " does not exist");
      }
      if (fs.existsSync(newUri)) {
        if (!overwrite) {
          throw new Error("" + newUri + " already exist");
        }
      }
      try {
        dirName = path.dirname(newUri);
        if (!fs.existsSync(dirName)) {
          fs.mkdirSync(dirName);
        }
        fs.renameSync(uri, newUri);
      } catch (_error) {
        error = _error;
        throw error;
      }
      return true;
    });
    deferred.resolve(promise);
    return deferred;
  };


  /**
  * delete the item at the given uri
  * @param {String} uri absolute uri of the file or folder to delete
  * @return {Object} a deferred, that gets resolved with "true" if deleting the file/folder was a success, the error in case of failure
   */

  FSStore.prototype["delete"] = function(uri) {
    var deferred, promise;
    deferred = Q.defer();
    promise = Q.fcall(function() {
      var _deleteFolderRecursive;
      if (!fs.existsSync(uri)) {
        throw new Error("" + uri + " does not exist");
      }
      if (!fs.statSync(uri).isDirectory()) {
        fs.unlinkSync(uri);
      } else {
        _deleteFolderRecursive = function(uri) {
          if (fs.existsSync(uri)) {
            fs.readdirSync(uri).forEach(function(file, index) {
              var curPath;
              curPath = uri + path.sep + file;
              if (fs.statSync(curPath).isDirectory()) {
                return _deleteFolderRecursive(curPath);
              } else {
                return fs.unlinkSync(curPath);
              }
            });
            return fs.rmdirSync(uri);
          }
        };
        _deleteFolderRecursive(uri);
      }
      return true;
    });
    deferred.resolve(promise);
    return deferred;
  };


  /*-------------------Helpers---------------- */


  /**
  * Resolves uri to an absolute path.
  * @param {String} uri  a path
  * @return {Object} an absolute path
   */

  FSStore.prototype.resolvePath = function(uri, from) {
    var fileName, fullPath, rootUri, segments;
    segments = uri.split("/");
    if (segments[0] !== '.' && segments[0] !== '..') {
      return uri;
    }
    rootUri = from || this.rootUri;
    fileName = path.normalize(uri);
    rootUri = rootUri[rootUri.length - 1] === "/" ? rootUri += "a" : rootUri;
    rootUri = path.normalize(rootUri);
    rootUri = path.dirname(rootUri);
    fullPath = path.join(rootUri, uri);
    logger.debug("fullPath (from relative)", fullPath);
    return fullPath;
  };


  /**
  *
   */

  FSStore.prototype.getStats = function(uri) {};

  return FSStore;

})();

module.exports = FSStore;


}).call(this,require("/home/mmoissette/dev/projects/coffeescad/stores/usco-fs-store/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js"))
},{"/home/mmoissette/dev/projects/coffeescad/stores/usco-fs-store/node_modules/browserify/node_modules/insert-module-globals/node_modules/process/browser.js":2,"composite-detect":false,"fs":1,"mime":3,"minilog":false,"path":false,"q":false}],"fs-store":[function(require,module,exports){
module.exports=require('6aToiT');
},{}]},{},["6aToiT"])