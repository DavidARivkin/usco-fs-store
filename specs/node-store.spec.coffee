'use strict'
NodejsStore = require("../src/nodeJsStore")

describe "nodejs-store", ->
  kernel = null
  store = null 
  
  beforeEach ->
    nodeJsStore = new NodejsStore()
  
  it 'can save a file to local file system',->
    console.log("bla")
    bla = 24
    expect( bla ).toEqual( 24 )
