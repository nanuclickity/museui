#!/usr/bin/env node

_    = require 'underscore'
os   = require 'os'
fs   = require 'fs'
path = require 'path'

RunCommand = (command, args)->
  { spawn, exec } = require 'child_process'
  child = spawn command, args
  child.stdout.on 'data', (data) -> console.log data.toString().trim()


task 'compile:coffee', 'Compile .coffee files', ->
  RunCommand 'coffee', ['-cb', '-o', 'js/', 'source/coffee']

task 'compile:jade', 'Compile .jade files', ->
  RunCommand 'jade', ['source/index.jade', '-D', '-P', '-o', '.']
  { exec } = require 'child_process'
  child = exec "clientjade source/templates/ > js/templates.js", (error, stdout, stderr)->
    if error then throw error
    console.log stdout
    console.log stderr

task 'compile:stylus', 'Compile .styl files', ->
  RunCommand 'stylus', ['--import', 'node_modules/nib', 'source/stylus/style.styl', '-o', 'css/']

task 'build', 'Compiles everything', ->
  invoke 'compile:coffee'
  invoke 'compile:stylus'
  invoke 'compile:jade'

task 'deploy', 'Produces a deployment code in ./build directory.', ->
  RunCommand 'cp', ['-r', 'app/js/libs/*', 'build/js/libs']
  RunCommand 'r.js', ['-o', 'requirejs-optimization.js']
  RunCommand 'jade', ['source/jade/index.jade', '-o', 'build/'], '  '