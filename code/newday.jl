module NewDay
    import OpenStreetMapX

    function newday!(agents, config,graph,onewaygraph, distmxtemp)
        diff = [agents[i].actualtime - agents[i].expectedtime for i in 1:config.numagents]
        tochange = sortperm(diff)[end+1-round(Int,config.numagents/10):end] # top 10% slowest routes indices (biggest diff between actual and expected)

        println("10% ",length(tochange))
        @time Threads.@threads for agentid in tochange
            agents[agentid].expectedtime = 0
            for i in 1:length(agents[agentid].route)
                
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
    ####################################################
end
