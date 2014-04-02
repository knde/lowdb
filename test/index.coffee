fs     = require 'fs'
assert = require 'assert'
sinon  = require 'sinon'
low    = require '../src'

sinon.spy low.ee, 'emit'
sinon.stub fs, 'writeFileSync'
sinon.stub(fs, 'readFileSync').returns('{}')

insertSong = ->
  low('songs').insert(title: 'foo').value()

describe 'low', ->

  beforeEach ->
    low.db = {}
    low.ee.emit.reset()

  it 'create', ->
    assert.deepEqual low('songs').value(), []
    assert.deepEqual low.db, songs: []

  it 'insert', ->
    song = insertSong()

    assert low.ee.emit.calledWith('add', song, low('songs').value())
    assert low('songs').size(), 1

  it 'get', ->
    song = insertSong()

    assert low('songs').get song.id

  it 'update', ->
    song = insertSong()
    low('songs').update song.id, title: 'bar'

    assert low.ee.emit.calledWith('update', song, low('songs').value())

    low.ee.emit.reset()
    low('songs').update 9999, {}
    assert not low.ee.emit.called

  it 'updateWhere', ->
    song = insertSong()
    low('songs').updateWhere title: 'foo', {}

    assert low.ee.emit.calledWith('update', [song], low('songs').value())

    low.ee.emit.reset()
    low('songs').updateWhere title: 'qux', {}
    assert not low.ee.emit.called

  it 'remove', ->
    song = insertSong()
    low('songs').remove song.id

    assert low.ee.emit.calledWith('remove', song, low('songs').value())
    assert.equal low('songs').size(), 0

    low.ee.emit.reset()
    low('songs').remove 9999, {}
    assert not low.ee.emit.called

  it 'removeWhere', ->
    song = insertSong()
    low('songs').removeWhere title: 'foo'

    assert low.ee.emit.calledWith('remove', [song], low('songs').value())
    assert.equal low('songs').size(), 0

    low.ee.emit.reset()
    low('songs').removeWhere title: 'qux'
    assert not low.ee.emit.called

  it 'load', ->
    low.load()
    assert fs.readFileSync.calledWith('db.json')

    low.path = 'foo.json'
    low.load()
    assert fs.readFileSync.calledWith('foo.json')

    low.load('bar.json')
    assert fs.readFileSync.calledWith('bar.json')

  it 'save', ->
    insertSong()
    assert fs.writeFileSync.calledWith('db.json')

    low.save()
    assert fs.writeFileSync.calledWith('db.json')

    low.path = 'foo.json'
    insertSong()
    assert fs.writeFileSync.calledWith('foo.json')

    low.save()
    assert fs.writeFileSync.calledWith('foo.json')

    low.save 'bar.json'
    assert fs.writeFileSync.calledWith('bar.json')

  it 'index', ->
    song = insertSong()

    assert.equal low.db['songs'][0].title, 'foo'
    assert.equal low.db['songs']._index[song.id].title, 'foo'
    assert.equal low('songs').get(song.id).value().title, 'foo'

    low('songs').update song.id, title: 'bar'
    
    assert.equal low.db['songs'][0].title, 'bar'
    assert.equal low.db['songs']._index[song.id].title, 'bar'
    assert.equal low('songs').get(song.id).value().title, 'bar'

    low('songs').remove song.id

    assert.equal low.db['songs'].length, 0
    assert.equal Object.keys(low.db['songs']._index).length, 0

describe 'short syntax', ->

  beforeEach ->
    low.db = {}
    @song = insertSong()

  it 'get', ->
    assert.deepEqual low('songs', @song.id),
                     low('songs').get(@song.id).value()

  it 'where', ->
    assert.deepEqual low('songs', title: 'foo'),
                     low('songs').where(title: 'foo').value()

  it 'remove', ->
    assert.deepEqual low('songs', @song.id, -1), @song
    assert.equal low('songs').size(), 0

  it 'create', ->
    newSong = low 'songs', title: 'bar', 1
    assert.deepEqual low('songs').get(newSong.id).value(), newSong
    assert.equal low('songs').size(), 2

  it 'updateWhere', ->
    low 'songs', {title: 'foo'}, {title: 'bar'}
    assert low('songs').find title: 'bar'

  it 'removeWhere', ->
    low 'songs', title: 'foo', -1
    assert.equal low('songs').size(), 0