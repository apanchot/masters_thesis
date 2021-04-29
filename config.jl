module Config 
    config = Dict{}()
    config["seed"] = 0 # random seed
    config["mapsize"] = "maps/a9-a40-a36.osm" # map
    config["timemultiplier"] = 1 # int, how much should time move between each step. Higher is faster but less accurate, especially for cars
    config["reuseagents"] = true # reuse agents
    config["initagents"] = "initagentsday300.jld2" # initial agents if used
    config["reusemap"] = true # reuse map data / roads
    config["useday200"] = true # create agents from existing agents

    #if greater than 0, that road id will be removed by means of increasing the weight of the road for A*
    config["roadtobreakcoords"] = (0.0,0.0,0.0,0.0) # nothing removed
    config["roadtobreak"] = []
    # config["roadtobreak"] = [(35751, 35191),(5955, 5956)] # remove bridge

    # config["roadtobreakcoords"] = (38.72239217529192, -9.170786817416435, 38.72381276481011, -9.178426426915319) # Viaduto Duarte Pacheco
    # config["roadtobreak"] = [(31449,11108),(32677,32678),(31904,32677)]

    # config["roadtobreakcoords"] = (38.7232308301572, -9.14820206295498, 38.72207231320948, -9.147201231419428) # Avenida da Liberdade
    # config["roadtobreak"] = [(11164,11163),(33391,21745)]
    
    config["saveagents"] = false # save agents after each day for certain stats
    config["saveroads"] = false # save roads after each day for certain stats


    config["starttime"] = 3600 * 0 # 4 hr start
    config["finishtime"] = 3600 * 27 # 21 hr end

    config["oneway"] = true # enable oneway roads for cars

    config["numofdays"] = 5 # number of days of sim
  
    config["releasecarsevery"] = 10 # Int(config["timemultiplier"] * 12) # force cars to leave at a rounded time (s) and then only check every X seconds
 
    config["roadqueuesizemodifier"] = 0.0
    config["roadtimesizemodifier"] = 0.0
    config["roadnormalizermodifier"] = 0.0 # CAR modifiers; to switch route
    config["newrouteextralengthmodifier"] = 1.0 # ratio
    config["teleporttime"] = 300 # teleport cars to their next road if they get jammed (s)
   
    config["speedroads"] = Dict{Int,Float64}( # road speed limits
        1 => 100/3.6, # kmh / 3.6 = m/s
        2 => 80/3.6,
        3 => 50/3.6,
        4 => 35/3.6,
        5 => 30/3.6,
        6 => 25/3.6,
        7 => 15/3.6,
        8 => 15/3.6)

    config["carspersec"] = Dict{Int,Int}( # amount of cars allowed thru each intersection per second
        1 => 16,
        2 => 12,
        3 => 8,
        4 => 5,
        5 => 3,
        6 => 1,
        7 => 1,
        8 => 1)

    config["roadlanes"] = Dict{Int,Int}( # number of lanes each road has
        1 => 3,
        2 => 2,
        3 => 2,
        4 => 1,
        5 => 1,
        6 => 1,
        7 => 1,
        8 => 1)

    struct configstruct
        seed::Int
        mapsize::String
        timemultiplier::Int
        reuseagents::Bool
        initagents::String
        reusemap::Bool
        useday200::Bool

        roadtobreak::Vector{Tuple{Int,Int}}
        roadtobreakcoords::Tuple{Float64,Float64,Float64,Float64}
        saveagents::Bool
        saveroads::Bool

        numagents::Int
        starttime::Int
        finishtime::Int

        oneway::Bool
        numofdays::Int
        releasecarsevery::Int

        roadqueuesizemodifier::Float64
        roadtimesizemodifier::Float64
        roadnormalizermodifier::Float64
        newrouteextralengthmodifier::Float64
        teleporttime::Int

        speedroads::Vector{Float64}
        carspersec::Vector{Int}
        roadlanes::Vector{Int}
    end

    function getconfig(numags) # turn dictionary into struct

        a = configstruct(config["seed"],config["mapsize"],config["timemultiplier"],config["reuseagents"],config["initagents"],config["reusemap"],config["useday200"],
        config["roadtobreak"], config["roadtobreakcoords"],config["saveagents"],config["saveroads"],numags, config["starttime"],config["finishtime"] ,
       config["oneway"] ,config["numofdays"] ,config["releasecarsevery"] ,config["roadqueuesizemodifier"],config["roadtimesizemodifier"],
        config["roadnormalizermodifier"] ,config["newrouteextralengthmodifier"] ,config["teleporttime"] ,[],[],[])
        for i in 1:length(config["speedroads"])
            push!(a.speedroads, config["speedroads"][i])
        end
        for i in 1:length(config["carspersec"])
            push!(a.carspersec, config["carspersec"][i])
        end
        for i in 1:length(config["roadlanes"])
            push!(a.roadlanes, config["roadlanes"][i])
        end
      
        return a
    end
end 
