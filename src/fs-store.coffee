'use strict'
detectEnv = require "composite-detect"
Q = require "q"
fs = require "fs"
path = require "path"
#mime = require "mime"

#StoreBase = require 'usco-kernel/src/stores/storeBase'
#utils = require 'usco-kernel/src/utils'
#merge = utils.merge
if detectEnv.isModule
  Minilog=require("minilog")
  Minilog.pipe(Minilog.suggest).pipe(Minilog.backends.console.formatClean).pipe(Minilog.backends.console)
  logger = Minilog('fs-store')

if detectEnv.isNode
  Minilog.pipe(Minilog.suggest).pipe(Minilog.backends.console.formatColor).pipe(Minilog.backends.console)

if detectEnv.isBrowser
  Minilog.pipe(Minilog.suggest).pipe(Minilog.backends.console.formatClean).pipe(Minilog.backends.console)
  logger = Minilog('fs-store')
  
  
class FSStore #extends StoreBase
  constructor:(options)->
    options = options or {}
    defaults =
      enabled: (if process? then true else false)
      name:"fs"
      type:"fs",
      description: "NodeJS fs file system store"
      rootUri:if process? then process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE else null
      isDataDumpAllowed: false
      showPaths:true
    
    #options = merge defaults, options
    #super options
  
  ###-------------------file/folder manipulation methods----------------###
  
  ###*
  * list all elements inside the given uri (non recursive)
  * @param {String} uri the folder whose content we want to list
  * @return {Object} a promise, that gets resolved with the content of the uri
  ###
  list:( uri )=>
    deferred = Q.defer()
    
    #promise based, keeping for reference ...when promises have cancelation...
    promise = Q.fcall ->
      if not fs.existsSync( uri )
        throw new Error("#{uri} does not exist")
      stats = fs.statSync( uri )
      if not stats.isDirectory()
        return []
      try  
        contents = fs.readdirSync( uri )
        return contents.sort()
      catch error
        throw( error )
        
    deferred.resolve( promise )
    return deferred
  
  ###*
  * read the file at the given uri, return its content
  * @param {String} uri absolute uri of the file whose content we want
  * @param {String} encoding the encoding used to read the file
  * @return {Object} a promise, that gets resolved with the content of file at the given uri
  ###
  read:( uri , encoding )=>
    encoding = encoding or 'utf8'
    deferred = Q.defer()
    promise = Q.fcall ->    
      if not fs.existsSync( uri )
        throw new Error("#{uri} does not exist")
      stats = fs.statSync( uri )
      if stats.isDirectory()
        throw new Error("#{uri} is a directory")#TODO: not sure
      
      try
        contents = fs.readFileSync( uri, encoding )
        return contents
      catch error
        throw( error )
    
    deferred.resolve( promise )
    return deferred
  
  ###*
  * write the file at the given uri, with the given data, using given mimetype
  * @param {String} uri absolute uri of the file we want to write (if the intermediate directories do not exist, they get created)
  * @param {String} data the content we want to write to the file
  * @param {String} type the mime-type to use
  * @return {Object} a promise, that gets resolved with "true" if writing to the file was a success, the error in case of failure
  ###
  write:( uri, data, type, overwrite )=>
    type = type or 'utf8' #mime.charsets.lookup()
    overwrite = overwrite or true
    deferred = Q.defer()
    
    promise = Q.fcall ->       
      if fs.existsSync( uri )
        if not overwrite
          throw new Error("#{newUri} already exist")
      try    
        dirName = path.dirname(uri)
        if not fs.existsSync( dirName )
          fs.mkdirSync( dirName )
        fs.writeFileSync( uri, data )
        return true
      catch error
        if error.errno is 34 and error.code is 'ENOENT' and error.syscall is 'mkdir'
          throw new Error("Failed to create directory: #{error.path}")
        throw( error )
    
    deferred.resolve( promise )
    return deferred
  
  ###*
  * move/rename the item at first uri to the second uri
  * @param {String} uri absolute uri of the source file or folder
  * @param {String} newuri absolute uri of the destination file or folder
  * @param {Boolean} whether to allow overwriting or not (defaults to false)
  * @return {Object} a promise, that gets resolved with "true" if moving/renaming the file was a success, the error in case of failure
  ###
  move:( uri, newUri , overwrite)=>
    overwrite = overwrite or false
    deferred = Q.defer()
    promise = Q.fcall ->       
      if not fs.existsSync( uri )
        throw new Error("#{uri} does not exist")
      if fs.existsSync( newUri )
        if not overwrite
          throw new Error("#{newUri} already exist")
      try    
        dirName = path.dirname(newUri)
        if not fs.existsSync( dirName )
          fs.mkdirSync( dirName )
        fs.renameSync(uri, newUri)
      catch error
        throw(error)
      return true
    
    deferred.resolve( promise )
    return deferred
  
  
  ###*
  * delete the item at the given uri
  * @param {String} uri absolute uri of the file or folder to delete
  * @return {Object} a deferred, that gets resolved with "true" if deleting the file/folder was a success, the error in case of failure
  ###
  delete:( uri )=>
    deferred = Q.defer()
    
    promise = Q.fcall ->     
      
      if not fs.existsSync( uri )
        throw new Error("#{uri} does not exist")
      if not fs.statSync( uri ).isDirectory()
        fs.unlinkSync( uri )
      else 
        _deleteFolderRecursive = (uri)->
          if fs.existsSync( uri )
            fs.readdirSync( uri ).forEach (file,index)->
              curPath = uri + path.sep + file
              if(fs.statSync(curPath).isDirectory())
                _deleteFolderRecursive( curPath )
              else 
                fs.unlinkSync( curPath )
            fs.rmdirSync( uri )
            
        _deleteFolderRecursive( uri )
      return true 
      
    deferred.resolve( promise )
    return deferred
  
  
  ###-------------------Helpers----------------###
  
  ###*
  * Resolves uri to an absolute path.
  * @param {String} uri  a path
  * @return {Object} an absolute path 
  ###
  resolvePath:( uri, from )=>
    segments = uri.split( "/" )
    if segments[0] != '.' and segments[0] != '..'
      #logger.debug("fullPath (from absolute)", fileName)
      return uri
    
    #path is relative
    rootUri = from or @rootUri
    fileName = path.normalize( uri )
    
    #hack to force dirname to work on paths ending with slash
    rootUri = if rootUri[rootUri.length-1] == "/" then rootUri +="a" else rootUri
    rootUri = path.normalize(rootUri)
    rootUri = path.dirname(rootUri)
    fullPath = path.join( rootUri, uri )
      
    logger.debug("fullPath (from relative)", fullPath)
    
    return fullPath
    
  
  ###*
  *
  ###
  getStats:(uri)=>

 
module.exports = FSStore
