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
