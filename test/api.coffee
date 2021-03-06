vows    = require 'vows'
assert  = require 'assert'
moment  = require 'moment'
_       = require 'underscore'

api     = require '../lib/api'

dateMonday =
    from: moment('2012-08-13T00')
    to: moment('2012-08-13T23:59:59')

vows.describe('api').addBatch 
    'when at Austurvöllur':
        topic: ->
            api.nearest 64.14753259999999, -21.9385416, {}, @callback
            return

        'the nearest stops are MR, Ráðhúsið and Lækjartorg': (err, nearest) ->
            stops = (n.shortName for n in nearest)
            assert.include stops, 'MR'
            assert.include stops, 'Lækjartorg'

    'when near Laugarnestangi':
        topic: ->
            api.nearest 64.151094, -21.881762, {}, @callback
            return

        'the nearest stops contains Laugarnestangi, Héðinsgata and Kirkjusandur': (err, nearest) ->
            stops = (n.shortName for n in nearest)
            assert.include stops, 'Laugarnestangi'
            assert.include stops, 'Héðinsgata'
            assert.include stops, 'Kirkjusandur'

    'when querying for all stops':
        topic: ->
            api.stops @callback
            return

        'we *no* error occurred': (err, stops) -> assert.isNull err
        'we get loads of stops': (err, stops) -> assert.isTrue stops.length > 1

    'when querying for a non existing stop':
        topic: ->
            api.stop '123', {}, @callback
            return
    
        'an error is returned': (err, stop) ->
            assert.isNotNull err
            assert.isUndefined stop

    'when querying for Laugarnestangi':
        topic: ->
            api.stop '90000162', dateMonday, @callback
            return

        'that *no* error occurred': (err, stop) -> assert.isNull err
        'only route 12 stops': (err, stop) ->
            assert.lengthOf stop, 1
            assert.equal stop[0].route, 12

    'when querying for MR':
        topic: ->
            api.stop '90000004', dateMonday, @callback
            return

        'that *no* error occurred': (err, stop) -> assert.isNull err
        'that 7 different routes stop': (err, stop) ->
            assert.lengthOf stop, 7

    'when querying for Hlemmur':
        topic: ->
            api.stop '90000295', dateMonday, @callback
            return

        'that *no* error occurred': (err, stop) -> assert.isNull err
        'that route 6 has 3 different end stops': (err, stop) ->
            route = (s for s in stop when s.route == 6)
            assert.lengthOf route, 3

        'that 14 different routes stop in both directions (all in all 29)': (err, stop) ->
            assert.lengthOf stop, 29


    'when querying for nearest busses at home':
        topic: ->
            opts = _.defaults dateMonday, { radius: 350 }
            api.nearestRoutes 64.13205119999999, -21.9098598, opts, @callback
            return

        'it returns routes 13 and 18': (err, routes) ->
            rs = routes.map (r) -> r.route
            assert.include rs, 13
            assert.include rs, 18

.export module
