mqtt = require 'mqtt'

# HSLClient connects to HSL Live server (Realtime API of vehicle locations) and
# converts the received real-time data to the format used by city-navigator clients.
# HSLClient uses @callback function (defined in server.coffee) to publish the data
# to the clients.
class LIJClient
    constructor: (@callback, @args) ->

    connect: =>
        @client = mqtt.connect 'mqtt://213.138.147.225:1883'
        @client.on 'connect', =>
            console.log 'LIJClient connected'
            @client.subscribe('/hfp/journey/#')
        @client.on 'message', (topic, message) =>
            @handle_message(topic, message)

    handle_message: (topic, message) =>
        [_, _, _, mode, vehi, line, dir, headsign, start_time, next_stop, geohash...] = topic.split '/'

        info = JSON.parse(message).VP

        if dir == "undefined"
            dir = undefined
        if next_stop == "undefined"
            next_stop = undefined
        if start_time == "undefined"
            start_time = undefined

        out_info =
            vehicle:
                id: vehi
            trip:
                route: line
                operator: "HSL"
                direction: dir
                start_time: start_time
                start_date: info.oday
            position:
                latitude: info.lat
                longitude: info.long
                bearing: info.hdg
                odometer: info.odo
                next_stop: next_stop
                speed: info.spd
                delay: info.dl
                next_stop_index: info.stop_index
            timestamp: info.tsi
            source: info.source

        # Create path/channel that is used for publishing the out_info for the
        # interested navigator-proto clients via the @callback function
        route = line.replace " ", "_"
        vehicle_id = out_info.vehicle.id.replace " ", "_"
        path = "/location/helsinki/#{route}/#{vehicle_id}"
        @callback path, out_info, @args

module.exports.LIJClient = LIJClient # make LIJClient visible in server.coffee
