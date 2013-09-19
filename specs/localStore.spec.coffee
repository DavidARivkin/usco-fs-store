'use strict'
path = require 'path'
fs = require 'fs'
LocalStore = require "../src/localStore"


deleteFolderRecursive = (uri)->
  if fs.existsSync(uri)
    fs.readdirSync(uri).forEach (file,index)->
      curPath = uri + path.sep + file
      if(fs.statSync(curPath).isDirectory())
        deleteFolderRecursive(curPath)
      else 
        fs.unlinkSync(curPath)
    fs.rmdirSync(uri)


describe "local store", ->
  localStore = null 
  
  beforeEach ->
    localStore = new LocalStore()
  
  afterEach ->
    testDir = path.resolve("./specs/data/TestFolder")
    outputDir = path.resolve("./specs/data/TestFolderFoo")
    if fs.existsSync( testDir )
      deleteFolderRecursive( testDir )
    if fs.existsSync( outputDir )
      deleteFolderRecursive( outputDir )
  
  it 'can list the contents of a directory', (done)->
    testUri = path.resolve("./specs/data/PeristalticPump")
    localStore.list( testUri )
    .then ( dirContents ) =>
      expect( dirContents ).toEqual( [ 'nema.coffee', 'PeristalticPump.coffee', 'pump.coffee' ] )
      done()
    .fail ( error ) =>
      expect(false).toBeTruthy error.message
      done()
    
  it 'handles errors correctly when listing the contents of a directory', (done)->
    testUri = path.resolve("./specs/data/invalidDir")
    localStore.list( testUri )
    .then ( dirContents ) =>
      expect(false).toBeTruthy error.message    
      done()
    .fail ( error ) =>
      expect( error.message ).toEqual( "#{testUri} does not exist" )
      done()
  
     
  it 'can read the contents of a file', (done)->
    testUri = path.resolve("./specs/data/PeristalticPump/PeristalticPump.coffee")
    
    expContent = """include("nema.coffee")
include("pump.coffee")

@config = {
           explode:1, # 0 for assembled pump 1 for exploded view
           layout:0, # 1 for assembled , 0 for single print object
           lobes: 3, # number of rollers
           pipe_od: 5, # outside diameter of pipe
           pipe_id: 4, #inside diamter of pip
           roller_outer: 12, # outerside diameter of the roller
           wall_thickness:10 # thickness of the outer wall
           }
p = new Pump(@config)

assembly.add(p)
if @config.layout
  motor = new NemaMotor()
  motor.translate([0,0,-motor.motorBody_len])
  assembly.add(motor)

"""
    localStore.read( testUri )
    .then ( fileContents ) =>
      expect( fileContents ).toEqual( expContent )
      done()
    .fail ( error ) =>
      expect(false).toBeTruthy error.message
      done()
  
  it 'handles errors correctly when reading the contents of a file', (done)->
    testUri = path.resolve("./specs/data/foo/bar.coffee")
    localStore.read( testUri )
    .then ( dirContents ) =>
      expect(false).toBeTruthy error.message    
      done()
    .fail ( error ) =>
      expect( error.message ).toEqual( "#{testUri} does not exist" )
      done()
  
  
  it 'can save data to local file system', (done)->
    testUri = path.resolve("./specs/data/TestFolder/foo.coffee")
    inputContent = """#this is a test file """
    
    localStore.write( testUri, inputContent )
    .then ( result ) =>
      obsContent = fs.readFileSync( testUri, 'utf8' )
      expect( obsContent ).toEqual( inputContent )
      done()
    .fail ( error ) =>
      expect(false).toBeTruthy error.message
      done()
  
  it 'handles errors correctly when saving data to local file system', (done)->
    testUri = ("foo\\/specs/data/TestFolder/foo.coffee")
    inputContent = """#this is a test file """
    
    localStore.write( testUri, inputContent )
    .then ( dirContents ) =>
      expect(false).toBeTruthy error.message    
      done()
    .fail ( error ) =>
      expect( error.message ).toEqual( "Failed to create directory: foo\\/specs/data/TestFolder" )
      done()
  
  it 'can move/rename folders', (done)->
    testUri = path.resolve("./specs/data/TestFolder")
    outputUri = path.resolve("./specs/data/TestFolderFoo")
    fs.mkdirSync(testUri)
    
    localStore.move( testUri, outputUri )
    .then ( result ) =>
      console.log "result",result
      movedFolderExists = fs.existsSync( outputUri )
      expect( movedFolderExists ).toBeTruthy()
      done()
    .fail ( error ) =>
      console.log "error", error
      expect(false).toBeTruthy error.message
      done()
  
  it 'can move/rename files', (done)->  
    testDir = path.resolve("./specs/data/TestFolder")
    testUri = path.resolve("./specs/data/TestFolder/fooFile.coffee")
    
    outputDir = path.resolve("./specs/data/TestFolderFoo")
    outputUri = path.resolve("./specs/data/TestFolderFoo/barFile.coffee")
    
    fs.mkdirSync(testDir)
    fs.writeFileSync(testUri, "some content")
    
    localStore.move( testUri, outputUri )
    .then ( result ) =>
      movedFolderExists = fs.existsSync( outputUri )
      expect( movedFolderExists ).toBeTruthy()
      done()
    .fail ( error ) =>
      expect(false).toBeTruthy error.message
      done()
      
  it 'can delete files', (done)->
    testDir = path.resolve("./specs/data/TestFolder")
    testUri = path.resolve("./specs/data/TestFolder/fooFile.coffee")
    
    fs.mkdirSync(testDir)
    fs.writeFileSync(testUri, "some content")
    
    localStore.delete( testUri )
    .then ( result ) =>
      deletedFileExists = fs.existsSync( testUri )
      expect( deletedFileExists ).toBeFalsy()
      done()
    .fail ( error ) =>
      console.log "error", error
      expect(false).toBeTruthy error.message
      done()
    
  it 'can delete folders (even non empty ones)', (done)->
    testDir = path.resolve("./specs/data/TestFolder")
    testUri = path.resolve("./specs/data/TestFolder/fooFile.coffee")
    
    fs.mkdirSync(testDir)
    fs.writeFileSync(testUri, "some content")
    
    localStore.delete( testDir )
    .then ( result ) =>
      deletedFolderExists = fs.existsSync( testDir )
      expect( deletedFolderExists ).toBeFalsy()
      done()
    .fail ( error ) =>
      console.log "error", error
      expect(false).toBeTruthy error.message
      done() 
  
  
  it 'resolve paths ', ->
    rootUri = path.resolve("./a")
    expAbsPath = path.resolve("./specs/data/PeristalticPump")
    obsAbsPath = localStore.resolvePath( "./specs/data/PeristalticPump" , rootUri)
    expect( obsAbsPath ).toEqual( expAbsPath )
    
    localStore.rootUri = path.resolve("./a")
    
    expAbsPath = path.resolve("./specs/data/PeristalticPump")
    obsAbsPath = localStore.resolvePath( "./specs/data/PeristalticPump" )
    expect( obsAbsPath ).toEqual( expAbsPath )
  
    
  it 'can check if a folder is a project ', (done)->
    testUri = path.resolve("./specs/data/PeristalticPump")
    obsIsProject = localStore.isProject( testUri )
    
    expect( obsIsProject ).toBeTruthy()
    done()
