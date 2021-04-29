module CarMovement
    import LightGraphs
    import OpenStreetMapX

    function setnewcurrentroute(agent,currenttime)
        agent.subroute += 1
        agent.roadtoplace = 0
        agent.pos = 1
        agent.running = false
        return agent
    end 

    ##################################################################################################################

    function carmovement(currenttime,agent,roadkey,mapdata,roads,roadskeys,distmx,config,isfront)
        hascarmoved=false
        agent.timespentinloc += config.timemultiplier
        if roads[roadkey].speed * agent.timespentinloc > roads[roadkey].length # is the car at the end of the road
            
            if agent.extratimect == 0
                agent.extratime = rand(roads[roadkey].delay[1]:roads[roadkey].delay[2])        
            end
            agent.extratimect += config.timemultiplier
            if isfront  
                if agent.timespentinloc > config.teleporttime
                    hascarmoved = true
                    agent.extratimect = 0
                    agent.pos += 1
                elseif length(roads[roadskeys[agent.route[agent.subroute][agent.pos+1],agent.route[agent.subroute][agent.pos+2]]].carqueue) < roads[roadskeys[agent.route[agent.subroute][agent.pos+1],agent.route[agent.subroute][agent.pos+2]]].maxqueuesize # if more time than X min on a road then teleport; has the car gone far enough and is the next road open
             
                    if agent.extratimect > agent.extratime
                        hascarmoved = true
                        agent.extratimect = 0

                        agent.pos += 1
                    end
                
                end
            end
        end


        if agent.pos > length(agent.route[agent.subroute]) - 2

            agent.running = false
            agent.roadtoplace = 0
            agent.extratimect = 0
            agent.pos = 1
            if agent.subroute < length(agent.route)
                agent.subroute += 1
            end
            hascarmoved = true
        end
        if agent.subroute < length(agent.route) && currenttime == agent.departuretimes[agent.subroute+1]
            agent.running = true
            agent.roadtoplace = 2
            agent.extratimect = 0
            agent.pos = 1
            agent.subroute += 1
            hascarmoved = true
        end
        return (agent,hascarmoved)
    end


end 
