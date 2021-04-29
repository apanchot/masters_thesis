module SimulationStep
	include("carmovement.jl")

	function checkdeptimes(agents, currenttime, config)
		runn = false
		Threads.@threads for agentid in 1:config.numagents
			if ! agents[agentid].running 
				if currenttime == agents[agentid].departuretimes[agents[agentid].subroute]
					agents[agentid].roadtoplace = 2
					agents[agentid].running = true
				end
			else
				runn = true
			end
		end

		return (agents,runn)
	end

	function step!(currenttime, roads, roadskeys, agents, mapdata, cardismx, config, onewaygraph,timecardismx,timecardismxct)
		ceiltime = ceil(Int, currenttime/900)
		Threads.@threads for roadid in 1:length(roads)
			if ! isempty(roads[roadid].carqueue)
				carstep!(currenttime, roads,roadskeys, roadid, agents, mapdata, cardismx, config,timecardismx,timecardismxct,ceiltime)
			end

		end
		
		roadplacer!(agents, roads, roadskeys,config)
	end

##################################################################################################################

	function carstep!(currenttime, roads,roadskeys, key, agents, mapdata, cardismx, config,timecardismx,timecardismxct,ceiltime)
		newqueue = []
		carssec = length(roads[key].carqueue)
		if roads[key].carspersec < carssec
			carssec = roads[key].carspersec
		end
		isfront = true
		for carno in roads[key].carqueue[1:carssec] #running thru queue for each car allowed per sec; 1000 is arbitrary with if statement below
			#### allow each car to move # index for first car is always 1 as we remove each car as they move. Thus car 2 becomes 1 when 1 moves
			agents[carno].actualtime += config.timemultiplier
			agents[carno], hascarmoved = CarMovement.carmovement(currenttime, agents[carno], key, mapdata, roads,roadskeys, cardismx, config, isfront) # let the first car in the queue do something
			
			if hascarmoved #did the agent move

				timecardismx[ceiltime][key] += agents[carno].timespentinloc
				timecardismxct[ceiltime][key] += 1
				agents[carno].timespentinloc = 0
				if agents[carno].running # if agent is still running add it to current road
					agents[carno].roadtoplace = 2
				else
					agents[carno].roadtoplace = 0
				end
			else



				push!(newqueue, carno)
				agents[carno].roadtoplace = 0
			end

		end
		for carno in roads[key].carqueue[carssec+1:end]
			agents[carno].actualtime += config.timemultiplier
			agents[carno].timespentinloc += config.timemultiplier
			push!(newqueue, carno)
			agents[carno].roadtoplace = 0
		end
		roads[key].carqueue = newqueue

	end

##################################################################################################################
	function roadplacer!(agents, roads, roadskeys, config)
		for agentno in 1:config.numagents
			if agents[agentno].roadtoplace == 0
				continue
			elseif agents[agentno].roadtoplace == 2
		
				roadskeys[agents[agentno].route[agents[agentno].subroute][agents[agentno].pos],agents[agentno].route[agents[agentno].subroute][agents[agentno].pos+1]]
				roads[roadskeys[agents[agentno].route[agents[agentno].subroute][agents[agentno].pos], agents[agentno].route[agents[agentno].subroute][agents[agentno].pos+1]]].carqueue
				
				push!(roads[roadskeys[agents[agentno].route[agents[agentno].subroute][agents[agentno].pos], agents[agentno].route[agents[agentno].subroute][agents[agentno].pos+1]]].carqueue, agentno)
			end
			agents[agentno].roadtoplace = 0
		end
	end

end 