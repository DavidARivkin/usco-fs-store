'use strict'
Q = require "q"
fs = require "fs"
path = require "path"
mime = require "mime"

StoreBase = require 'usco-kernel/src/stores/storeBase'
utils = require 'usco-kernel/src/utils'
merge = utils.merge
  
  
class LocalStore extends StoreBase
  constructor:(options)->
    options = options or {}
    defaults =
      enabled: (if process? then true else false)
      name:"local"
      type:"local",
      description: "NodeJS local file system store"
      rootUri:if process? then process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE else null
      isDataDumpAllowed: false
      showPaths:true
    
    options = merge defaults, options
    super options
  
  ###-------------------file/folder manipulation methods----------------###
  
  ###*
  * list all elements inside the given uri (non recursive)
  * @param {String} uri the folder whose content we want to list
  * @return {Object} a promise, that gets resolved with the content of the uri
  ###
  list:( uri )=>
    deferred = Q.defer()
    
    if not fs.existsSync( uri )
      deferred.reject new Error("#{uri} does not exist")
    stats = fs.statSync( uri )
    if not stats.isDirectory()
      deferred.resolve( [] )
      
    try  
      contents = fs.readdirSync( uri )
      deferred.resolve( contents )
    catch error
      deferred.reject( error )
    
    return deferred.promise
  
  ###*
  * read the file at the given uri, return its content
  * @param {String} uri absolute uri of the file whose content we want
  * @param {String} encoding the encoding used to read the file
  * @return {Object} a promise, that gets resolved with the content of file at the given uri
  ###
  read:( uri , encoding )=>
    encoding = encoding or 'utf8'
    deferred = Q.defer()
    
    if not fs.existsSync( uri )
      deferred.reject new Error("#{uri} does not exist")
    stats = fs.statSync( uri )
    if stats.isDirectory()
      deferred.reject new Error("#{uri} is a directory")#TODO: not sure
    
    try
      contents = fs.readFileSync( uri, encoding )
      deferred.resolve( contents )
    catch error
      deferred.reject( error )
    
    return deferred.promise
  
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
    
    if fs.existsSync( uri )
      if not overwrite
        deferred.reject new Error("#{newUri} already exist")
    try    
      dirName = path.dirname(uri)
      if not fs.existsSync( dirName )
        fs.mkdirSync( dirName )
        
      fs.writeFileSync( uri, data )
      deferred.resolve( true )
    catch error
      deferred.reject(error)
    
    return deferred.promise
  
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
    
    if not fs.existsSync( uri )
      deferred.reject new Error("#{uri} does not exist")
    if fs.existsSync( newUri )
      if not overwrite
        deferred.reject new Error("#{newUri} already exist")
    try    
      dirName = path.dirname(newUri)
      if not fs.existsSync( dirName )
        fs.mkdirSync( dirName )
      fs.renameSync(uri, newUri)
    catch error
      deferred.reject(error)
      
    deferred.resolve( true )
    
    return deferred.promise
  
  ###-------------------Helpers----------------###
  
  ###*
  * checks if specified uri is the uri of a project: the folder needs to exist, and to contain a file with the same name as the folder + one of the "code extensions"
  * to qualitfy
  * @param {String} uri absolute uri of the path to check
  * @return {Object} "true" if given uri is a project, "false" otherwise
  ###
  isProject:( uri )=>
    if fs.existsSync( uri )
      stats = fs.statSync( uri )
      if stats.isDirectory()
        codeExtensions = ["coffee", "litcoffee", "js", "usco", "ultishape"] #TODO: REDUNDANT with modules! where to put this
        for ext in codeExtensions
          baseName = path.basename( uri )
          mainFile = path.join( uri, baseName + "." + ext )
          if fs.existsSync( mainFile )
            return true
    return false
    
  
  #OLD #TODO: should project "class" instanciation take place here or else where ?????
  ### 
  saveProject:( project, path )=> 
    super()
    @fs.mkdir(project.uri)
    
    for index, file of project.getFiles()
      fileName = file.name
      filePath = @fs.join([projectUri, fileName])
      ext = fileName.split('.').pop()
      content = file.content
      if ext == "png"
        #save thumbnail
        dataURIComponents = content.split(',')
        mimeString = dataURIComponents[0].split(':')[1].split(';')[0]
        if(dataURIComponents[0].indexOf('base64') != -1)
          console.log "base64 v1"
          data =  atob(dataURIComponents[1])
          array = []
          for i in [0...data.length]
            array.push(data.charCodeAt(i))
          content = new Blob([new Uint8Array(array)], {type: 'image/png'})
        else
          console.log "other v2"
          byteString = unescape(dataURIComponents[1])
          length = byteString.length
          ab = new ArrayBuffer(length)
          ua = new Uint8Array(ab)
          for i in [0...length]
            ua[i] = byteString.charCodeAt(i)
      
      @fs.writefile(filePath, content, {toJson:false})
      #file.trigger("save")
    @_dispatchEvent( "project:saved",project )
    
  loadProject:( projectUri , silent=false)=>
    super
    
    projectName = projectUri.split(@fs.sep).pop()
    #projectUri = @fs.join([@rootUri, projectUri])
    project = new Project
        name : projectName
    project.dataStore = @
    
    onProjectLoaded=()=>
      project._clearFlags()
      if not silent
        @_dispatchEvent("project:loaded",project)
      d.resolve(project)
    
    loadFiles=( filesList ) =>
      promises = []
      for fileName in filesList
        filePath = @fs.join( [projectUri, fileName] )
        promises.push( @fs.readfile( filePath ) )
      $.when.apply($, promises).done ()=>
        data = arguments
        for fileName, index in filesList #todo remove this second iteration
          project.addFile 
            name: fileName
            content: data[index]
        onProjectLoaded()
    
    @fs.readdir( projectUri ).done(loadFiles)
    return d

  #helpers
  projectExists: ( uri )=>
    #checks if specified project /project uri exists
    return @fs.exists( uri )
  ###
module.exports = LocalStore