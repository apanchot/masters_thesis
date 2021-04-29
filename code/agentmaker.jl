module AgentMaker
    import OpenStreetMapX
    import FileIO
    import ProgressBars

    function saveagents(filename,agents)
        FileIO.save(filename,"agents",agents)
        return nothing
    end

    function loadagents(filename)
        return FileIO.load(filename,"agents")
    end

    function agentmaker(agentstruct, config)
        agents = Vector{agentstruct}(undef,config.numagents)
        for i in 1:config.numagents
            agents[i] = agentstruct(i,1,[],[],[],1,0,false,0,0,0 ,0,0)
        end

        return agents
    end

    function initagents(mapdata, agentstruct, config, cardismx, onewaygraph)
        agents = agentmaker(agentstruct, config)
  
        if config.oneway
            @time generic!(agents,config,mapdata.g,cardismx,mapdata)
        else
            generic!(agents,config,onewaygraph,cardismx,mapdata)
        end
        return agents
    end



    function generic!(agents,config,graph,cardismx,mapdata)

        @time agentsraw = FileIO.load("590agents.jld2","agents")

        distmxtemp = nothing
        if config.useday200
            distmxtemp = FileIO.load("distmxtempday300.jld2", "distmxtemp");
            if config.roadtobreak[1] > 0
                for i in 1:length(distmxtemp)
                    distmxtemp[i][config.roadtobreak[2],config.roadtobreak[3]] = 9.9e99
                    try
                        distmxtemp[i][config.roadtobreak[3],config.roadtobreak[2]] = 9.9e99
                    catch
                    end
                end
            end
        else
            cardismx[config.roadtobreak[2],config.roadtobreak[3]] = 9.9e99
            try
                cardismx[config.roadtobreak[3],config.roadtobreak[2]] = 9.9e99
            catch
            end
        end
        Threads.@threads for i in ProgressBars.ProgressBar(1:length(agents))
            
            locs=Vector{Int}(undef,length(agentsraw[i]) )
            for j in 1:length(agentsraw[i])-1
                locs[j] = mapdata.v[OpenStreetMapX.point_to_nodes(agentsraw[i][j][2:3],mapdata)]
            end
            locs[end] = locs[1]

            for j in 2:length(agentsraw[i])    
                push!(agents[i].destinations, (locs[j-1],locs[j] ))
                deptime = agentsraw[i][j][4]
                deptime -= deptime%config.releasecarsevery
                push!(agents[i].departuretimes, deptime)

                if config.useday200
                    route, t = OpenStreetMapX.a_star_algorithm(graph,locs[j-1],locs[j], distmxtemp[ceil(Int,agents[i].departuretimes[end]/900)]  )
                else
                    route, t = OpenStreetMapX.a_star_algorithm(graph,locs[j-1],locs[j],cardismx)
                end

                agents[i].expectedtime += round(Int,t)
                push!(agents[i].route, route)
            
            end
        end
        
    end


    function dfreader!(mapdata, agents, df, cardismx, config, onewaygraph)
        locmap = FileIO.load("locmapper.jld2","locmap")
        if config.oneway
            graph = onewaygraph
        else 
            graph = mapdata.g
        end
        ct = 0
        roind=1
        for i in 1:config.numagents
            if ct == df[roind,:value]
                roind += 1
                ct = 0
            end
            agents[i].dfrownum = roind
            ct += 1
        end

        Threads.@threads for i in 1:config.numagents
            src = mapdata.v[OpenStreetMapX.point_to_nodes(locmap[df[agents[i].dfrownum,:A]],mapdata)]
            dst = mapdata.v[OpenStreetMapX.point_to_nodes(locmap[df[agents[i].dfrownum,:B]],mapdata)]
            route, _ = OpenStreetMapX.a_star_algorithm(graph,src,dst,cardismx)
            if length(route) > 3
                agents[i].route = route
                time1 = df[agents[i].dfrownum,:hora] * 3600 + rand(0:3600)
                time1 -= time1 % config.releasecarsevery
                if time1 < config.releasecarsevery
                    time1 = config.releasecarsevery
                end
                agents[i].departuretimes = time1
                agents[i].destinations = (src,dst)
            end
        end
        return (agents, df)
    end

    function roadoutchange(agents,graph,onewaygraph,distmxtemp,config)
        changed = zeros(Int,config.numagents)
        for i in 1:length(distmxtemp)
            for j in 1:length(config.roadtobreak)
                distmxtemp[i][config.roadtobreak[j][1],config.roadtobreak[j][2]] = 9.9e99
                try
                    distmxtemp[i][config.roadtobreak[j][2],config.roadtobreak[j][1]] = 9.9e99
                catch
                end
            end
        end
        Threads.@threads for agentid in ProgressBars.ProgressBar(1:config.numagents)
            for i in 1:length(agents[agentid].route)
                for j in config.roadtobreak
                    if j[1] in agents[agentid].route[i] || j[2] in agents[agentid].route[i]
                        changed[agentid]=1
                        if config.oneway
                            route, t = OpenStreetMapX.a_star_algorithm(graph,agents[agentid].destinations[i][1],agents[agentid].destinations[i][2], distmxtemp[ceil(Int,agents[agentid].departuretimes[i]/900)] )
                        else
                            route, t = OpenStreetMapX.a_star_algorithm(onewaygraph,agents[agentid].destinations[i][1],agents[agentid].destinations[i][2], distmxtemp[ceil(Int,agents[agentid].departuretimes[i]/900)] )
                        end
                        agents[agentid].expectedtime += round(Int,t)
                        agents[agentid].route[i] = route
                    end
                end
            end
        end
        println("changed: ",sum(changed))
        return (agents,distmxtemp)
    end


end


