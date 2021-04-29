import CSV
import FileIO
import Dates
import Random
import SparseArrays

include("config.jl")
include("code/structs.jl")
include("code/getmapdata.jl")
include("code/agentmaker.jl")
include("code/simulationstep.jl")
include("code/newday.jl")

#####################
function day(dayno, roads,roadskeys, agents, mapdata, cardismx, config, directoryname, onewaygraph,timecardismx,timecardismxct,distmxtemp)
	
	anyagentrunning = true
	### sim
	for currenttime in config.starttime:config.timemultiplier:config.finishtime
		if currenttime % config.releasecarsevery == 0
			agents,anyagentrunning = SimulationStep.checkdeptimes(agents, currenttime, config) # make agents running if time is right; 50-300 μs for each use
		end
		if anyagentrunning
			SimulationStep.step!(currenttime, roads, roadskeys, agents, mapdata, cardismx, config, onewaygraph,timecardismx,timecardismxct) # sim that runs every second
		end
	end

	Threads.@threads for ii in 1:length(timecardismx)
		for (x,y,v) in zip(SparseArrays.findnz(cardismx)...)
			distmxtemp[ii][x,y]=v
		end
		for i in 1:length(timecardismx[ii])
			if timecardismxct[ii][i] > 0
				distmxtemp[ii][ roads[i].firstid,roads[i].secondid ] = timecardismx[ii][i] / timecardismxct[ii][i]
			end
		end
		for j in 1:length(config.roadtobreak)
			distmxtemp[ii][config.roadtobreak[j][1],config.roadtobreak[j][2]]=0.0
			try
				distmxtemp[ii][config.roadtobreak[j][2],config.roadtobreak[j][1]]=0.0
			catch
			end
		end
	end
	if dayno == 1 || dayno == config.numofdays || dayno == 2 || dayno == 5
		mkdir(string("iters/$(directoryname)/",dayno))
		FileIO.save("iters/$(directoryname)/$(dayno)/distmxtemp.jld2",Dict("distmxtemp" => distmxtemp,"timecardismxct"=>timecardismxct, "roads" => roads, "roadskeys"=>roadskeys,"cardismx"=>cardismx))
	end
	for ii in 1:length(timecardismx)
		for j in 1:length(config.roadtobreak)
			distmxtemp[ii][config.roadtobreak[j][1],config.roadtobreak[j][2]]=9.9e99
			try
				distmxtemp[ii][config.roadtobreak[j][2],config.roadtobreak[j][1]]=9.9e99
			catch
			end
		end
	end

	Threads.@threads for agentid in 1:config.numagents
		agents[agentid].running = false
		agents[agentid].pos = 1
		agents[agentid].subroute = 1
		agents[agentid].actualtime = 0
		agents[agentid].roadtoplace = 0
	end


	return (agents, roads, distmxtemp,timecardismx,timecardismxct)
end

function main()
	config = Config.getconfig(590000) # create configuration with number of agents
	Random.seed!(config.seed); # set global RNG seed
	
	
	mapdata, onewaygraph = GetMapData.getmap(config.mapsize) # mapdata is a OSMX.jl struct; create map and weight matrices; see "code/getmapdata"
	
	roads,cardismx,roadskeys,timecardismx,timecardismxct = GetMapData.createedges(mapdata,Structs.road,config) # roads is a dict ["string id", road struct]; roads, theoretical distance matrix, vectors to store jam times; see "code/getmapdata"
	
	
	networklength = 0
	
	for road in roads
		networklength+=road.maxqueuesize
	end
	
	if ! isdir("iters")  # check if directory exists and make it if not
		mkdir("iters")
	end
	timetemp=string(Dates.now()) # get exact time with seconds
	directoryname = string(timetemp[6:7],timetemp[9:10],"_",timetemp[12:13],timetemp[15:16],timetemp[18:19]) 
	mkdir(string("iters/",directoryname)) # create directory name with time
	cp("config.jl",string("iters/",directoryname,"/config.jl")) # copy config file to new directory


	
	try
		if ! config.reuseagents # can reuse existing agents to save time
			print(asfasdflajsdf) # if reuse off then error print to force catch
		end
		agents=AgentMaker.loadagents(config.initagents)
		distmxtemp = FileIO.load("distmxtempday300.jld2", "distmxtemp") # existing time matrix
	catch
		agents = AgentMaker.initagents(mapdata, Structs.agent, config, cardismx, onewaygraph) # create agents from scratch; see "code/agentmaker"
		AgentMaker.saveagents(config.initagents,agents) 
		distmxtemp=[deepcopy(cardismx) for i in 1:length(timecardismx)]
	end

	agents, distmxtemp = AgentMaker.roadoutchange(agents,mapdata.g,onewaygraph,distmxtemp,config) # if a road is broken then this will reroute all affected agents; see "code/agentmaker"

	#### SIMULATION
	
	for dayo in 1:config.numofdays
		Threads.@threads for agentid in 1:config.numagents # zero out agents
			agents[agentid].running = false
			agents[agentid].pos = 1
			agents[agentid].subroute = 1
			agents[agentid].actualtime = 0
			agents[agentid].roadtoplace = 0
		end
		agents, roads, distmxtemp, timecardismx, timecardismxct = day(dayo, roads,roadskeys, agents, mapdata, cardismx, config, directoryname, onewaygraph,timecardismx,timecardismxct,distmxtemp) # single whole day of simulation; see above function
		### resets agents for new day
		if dayo < config.numofdays
			NewDay.newday!(agents, config,mapdata.g,onewaygraph, distmxtemp) # get agents ready for new day (change routes) ; see "code/newday"
			###
			r = Threads.@spawn for roadid in 1:length(roads)
				roads[roadid].carqueue = []
			end

			t = Threads.@spawn for ii in 1:length(timecardismx)
				for i in 1:length(timecardismx[ii])
					timecardismx[ii][i] = 0
					timecardismxct[ii][i] = 0
				end
			end
			wait(r)
			wait(t)
		end
	end
	####
	return nothing
end

a=main()