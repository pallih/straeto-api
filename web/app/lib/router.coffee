Location = require 'models/location'

module.exports = class Router extends Backbone.Router
    routes:
        '': 'home'
        'stops/:stopId': 'stops'
        'busses': 'busses'
        'lost': 'lost'

    initialize: ->
        @bind 'all', @_trackPageview
        @location = new Location
        @location.on 'error', (error) =>
            @navigate 'lost', { trigger: true }

    home: ->
        StopsNearView = require 'views/stops/near'
        Stops = require 'models/stop_collection'
        StopListView = require 'views/stop_list_view'

        near = new StopsNearView
        stops = new Stops
        slv = new StopListView { collection: stops }

        $('body').html near.render().el
        slv.on 'rendered', -> ($ '#stops').html slv.el

        @location.off()
        @location.on 'reset', (location) -> stops.fetch { data: location.toJSON() }
        @location.fetch()

    stops: (stopId) ->
        StopTimesView = require 'views/stops/times'
        RoutesTimes = require 'models/routes_times'

        stopTimes = new RoutesTimes { id: stopId }
        stopTimes.fetch
            success: (data) -> $('body').html (new StopTimesView { collection: data }).render().el
            data:
                range: 'now'

    busses: ->
        Busses = require 'models/busses_collection'
        BussesView = require 'views/busses'

        busses = new Busses
        view = new BussesView { collection: busses }

        @location.off()
        @location.on 'reset', (location) ->
            busses.fetch
                data:
                    latitude: location.get 'latitude'
                    longitude: location.get 'longitude'
                    accuracy: location.get 'accuracy'
                    range: 'now'

        view.on 'rendered', -> ($ 'body').html view.el

        @location.fetch()

    lost: ->
        NoLocationView = require 'views/no_location'
        ($ 'body').html (new NoLocationView).render().el

    _trackPageview: ->
        url = Backbone.history.getFragment()
        _gaq.push(['_trackPageview', "/#{url}"])
