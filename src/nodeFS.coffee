FSBase = require 'usco-kernel/src/stores/fsBase'
#we use the nodeRequire alias to avoid clash of requirejs and node's require
try
  fs = require('fs')
  pathMod = require('path')
catch error

#deferred library: which one to use ?
Q = require('kew')


class NodeFS extends FSBase
  constructor:(sep)->
    super(sep or "/")
    
  mkdir:( path )->
    deferred = Q.defer()
    callback = deferred.resolve
    fs.mkdir( path, callback )
    return deferred
  
  readdir: ( path )->
    console.log("reading path", path)
    deferred = Q.defer()
    callback = deferred.resolve
    
    fs.readdir( path, callback )
    
    return deferred
  
  rmdir: ( path )->
    deferred = Q.defer()
    callback = deferred.resolve
    fs.rmdir( path, callback )
    
    return deferred
  
  writefile:(path, content, options)->
    options = {} #ignoring passed options
    fs.writeFileSync( path, content, options)
  
  isDir: (path) ->
    if fs.existsSync( path )
      fs.lstatSync(path).isDirectory()  
  
  isProj: (path) ->
    #check if the specified path is a coffeescad project (ie, a directory, with a .coffee file with the same name
    #as the folder)
    if @isDir( path )
      filesList = fs.readdirSync( path )
      projectMainFileName = pathMod.basename + ".coffee"
      if projectMainFileName in filesList
        return true
    return false
  
  exists: (path) ->
    return fs.existsSync( path )
  
  listProjs: ( path ) ->
    #return a list of all projects in a given path: FIXME: should this be here or in the store ??
  
  basename : (path) ->
    return pathMod.basename( path )
    
  getType : ( path ) ->
    result = {name: @basename( path ),
    path : path
    }
    stat = fs.statSync(path)
    if stat.isDirectory()
      result.type = 'folder'
    else
      result.type = 'file'
    return result

module.exports = NodeFS