mongoose = require 'mongoose'
async    = require 'async'
schemas  = require '../schemas'

connection = mongoose.createConnection(env?.MONGO_URL or 'mongodb://localhost/bus')

{ StopTimes, Trip } = schemas.createSchemas connection

mapF = ->
    startStop = @trip[0].stop 
    endStop = @trip[@trip.length - 1].stop

    emitTrip = (t) =>
        key = { stop: t.stop, route: @route, endStop: endStop, days: @days }
        value = { source: t.source, times: [t.time] }
        emit(key, value)

    (emitTrip t for t in @trip)

reduceF = (key, values) ->
    times = []

    for v in values
        times = v.times.concat times

    return { times: times, source: v.source }
finalizeF = (key, value) -> { times: value.times.sort(), source: value.source }

mapData = (data, callback) ->
    { _id: {stop, route, endStop, days}, value: {times, source} } = data

    st = new StopTimes
        stop: stop
        endStop: endStop
        route: route
        days: days
        times: times
        source: source

    st.save (err) ->
        callback null, true
 

StopTimes.collection.drop ->
    Trip.collection.mapReduce mapF.toString(), reduceF.toString(), { finalize: finalizeF.toString(), out: 'byStop' }, (err, res) ->
        console.log err if err
    
        connection.db.collection 'byStop', (err, byStop) ->
            console.log err if err
            byStop.find().toArray (err, data) -> 
                console.log err if err

                async.map data, mapData, (err, res) ->
                    connection.close()

