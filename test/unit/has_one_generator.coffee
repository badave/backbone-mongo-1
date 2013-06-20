util = require 'util'
_ = require 'underscore'
Backbowner = require 'backbone'
Queue = require 'queue-async'

Fabricator = require 'backbone-orm/fabricator'
Utils = require 'backbone-orm/utils'
adapters = Utils.adapters

class Flat extends Backbowner.Model
  url: "#{require('../config/database')['test']}/flats"
  sync: require('../../backbone_sync')(Flat)

class Reverse extends Backbowner.Model
  url: "#{require('../config/database')['test']}/reverses"
  @schema:
    owner: -> ['belongsTo', Owner]
  sync: require('../../backbone_sync')(Reverse)

class Owner extends Backbowner.Model
  url: "#{require('../config/database')['test']}/owners"
  @schema:
    flat: -> ['belongsTo', Flat]
    reverse: -> ['hasOne', Reverse]
  sync: require('../../backbone_sync')(Owner)

BASE_COUNT = 1

test_parameters =
  model_type: Owner
  route: 'mocks'
  beforeEach: (callback) ->
    MODELS = {}

    queue = new Queue(1)

    # destroy all
    queue.defer (callback) ->
      destroy_queue = new Queue()

      destroy_queue.defer (callback) -> Flat.destroy callback
      destroy_queue.defer (callback) -> Reverse.destroy callback
      destroy_queue.defer (callback) -> Owner.destroy callback

      destroy_queue.await callback

    # create all
    queue.defer (callback) ->
      create_queue = new Queue()

      create_queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.flat = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(Reverse, BASE_COUNT, {
        name: Fabricator.uniqueId('reverse_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.reverse = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
        name: Fabricator.uniqueId('owner_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.owner = models; callback(err))

      create_queue.await callback

    # link and save all
    queue.defer (callback) ->
      save_queue = new Queue()

      for owner in MODELS.owner
        do (owner) ->
          owner.set({flat: flat = MODELS.flat.pop(), reverse: reverse = MODELS.reverse.pop()})
          save_queue.defer (callback) -> owner.save {}, adapters.bbCallback callback
          save_queue.defer (callback) -> flat.save {}, adapters.bbCallback callback
          save_queue.defer (callback) -> reverse.save {}, adapters.bbCallback callback

      save_queue.await callback

    queue.await (err) ->
      callback(err, _.map(MODELS.owner, (test) -> test.toJSON()))

require('backbone-orm/lib/test_generators/relational/has_one')(test_parameters)
