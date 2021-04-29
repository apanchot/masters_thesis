module GetMapData
    import LightGraphs
    import OpenStreetMapX
    import FileIO
    import SparseArrays

    function saveroads(filename,roads)
        FileIO.save(filename,"roads",roads)
        return nothing
    end

    function getmap(file)
        map = OpenStreetMapX.get_map_data(file,trim_to_connected_graph=true)
        return (map, LightGraphs.SimpleGraph(map.g))
    end
###########
        
    function createedges(mapdata,roadstruct,config)
        try
            if ! config.reusemap
                println(asdfasdasdfaf)
            end
            roads,cardismx,roadskeys,timecardismx,timecardismxct = FileIO.load(string(config.mapsize[1:end-4],".jld2"),"roads","cardismx","roadskeys","timecardismx","timecardismxct")
            return (roads,cardismx,roadskeys,timecardismx,timecardismxct)
        catch
            cardismx=deepcopy(mapdata.w) 
            roads = Vector{roadstruct}()
            slope = FileIO.load("slopes.jld2","slope")
            vals=Vector{Tuple{Tuple{Int,Int},Float64}}()
            for i in 1:length(slope)
                push!(vals, ( (mapdata.v[OpenStreetMapX.point_to_nodes((slope[i][1][1],slope[i][1][2]),mapdata) ],mapdata.v[OpenStreetMapX.point_to_nodes((slope[i][1][3],slope[i][1][4]),mapdata)] ), slope[i][2] ) ) 
            end
  
            roadskeys = SparseArrays.spzeros(Int, length(mapdata.w[1,:]),length(mapdata.w[1,:]))
            iter = 1
            for i in 1:length(mapdata.e) # create each road
                if roadskeys[mapdata.v[ mapdata.e[i][1]] , mapdata.v[mapdata.e[i][2]] ] == 0 && roadskeys[mapdata.v[ mapdata.e[i][2]] , mapdata.v[mapdata.e[i][1]] ] == 0
                    leng=mapdata.w[mapdata.v[mapdata.e[i][1] ], mapdata.v[mapdata.e[i][2]] ]
                    if leng<1
                        leng=mapdata.w[mapdata.v[mapdata.e[i][2] ], mapdata.v[mapdata.e[i][1]] ]
                    end
                    if leng / config.speedroads[mapdata.class[i]] < 1
                        leng = (config.speedroads[mapdata.class[i]]-0.0001)*config.timemultiplier
                    end
                    roadcap=round( Int, leng / 3 * config.roadlanes[mapdata.class[i]] ) # ~ each car is 4m long for single lane road
                    if roadcap < config.carspersec[mapdata.class[i]]
                        roadcap = config.carspersec[mapdata.class[i]]
                    end
                    if roadcap < 4
                        roadcap = 4
                    end
                    lat1,lon1=OpenStreetMapX.latlon(mapdata,mapdata.v[mapdata.e[i][1]]) 
                    lat2,lon2=OpenStreetMapX.latlon(mapdata,mapdata.v[mapdata.e[i][2]]) 

                    slopepercent1 = 0.0
                    slopeheight1 = 0.0
                    slopepercent2 = 0.0
                    slopeheight2 = 0.0
                    second = false
                    a=findfirst(x->x[1]==(mapdata.v[mapdata.e[i][1] ], mapdata.v[mapdata.e[i][2]]), vals)
                    if a===nothing
                        a=findfirst(x->x[1]==(mapdata.v[mapdata.e[i][2] ], mapdata.v[mapdata.e[i][1]]), vals)
                        if a!== nothing
                            second = true
                        end
                    end
                    if a!==nothing
                        if second == false
                            slopepercent1 = vals[a][2]
                            slopeheight1 = vals[a][2] * leng / 100
                            slopepercent2 = -vals[a][2]
                            slopeheight2 = -vals[a][2] * leng / 100
                        else
                            slopepercent1 = -vals[a][2]
                            slopeheight1 = -vals[a][2] * leng / 100
                            slopepercent2 = vals[a][2]
                            slopeheight2 = vals[a][2] * leng / 100
                        end
                    end
                    upp = 0 
                    lww = 0

                    push!(roads, roadstruct(leng, [],mapdata.class[i], roadcap, config.speedroads[mapdata.class[i]], config.carspersec[mapdata.class[i]], round(lat1,digits=6),round(lon1,digits=6),round(lat2,digits=6),round(lon2,digits=6), mapdata.v[ mapdata.e[i][1]],mapdata.v[mapdata.e[i][2]],slopepercent1,slopeheight1,(lww,upp)))
                    push!(roads, roadstruct(leng, [],mapdata.class[i], roadcap, config.speedroads[mapdata.class[i]], config.carspersec[mapdata.class[i]], round(lat2,digits=6),round(lon2,digits=6),round(lat1,digits=6),round(lon1,digits=6), mapdata.v[ mapdata.e[i][2]],mapdata.v[mapdata.e[i][1]],slopepercent2,slopeheight2,(lww,upp)))
                    
                    roadskeys[mapdata.v[ mapdata.e[i][1]] , mapdata.v[mapdata.e[i][2]] ] =  2*iter-1
                    roadskeys[mapdata.v[ mapdata.e[i][2]] , mapdata.v[mapdata.e[i][1]] ] =  2*iter
                    iter += 1
                end
            end
            ####
            for j in 1:size(mapdata.w)[1]
                for i in 1:size(mapdata.w)[1]
                    if mapdata.w[i,j] != 0 || mapdata.w[j,i] != 0
                        dism=mapdata.w[i,j]
                        if dism == 0
                            dism=mapdata.w[j,i]
                        end
                        if dism / roads[roadskeys[i,j]].speed < 1
                            dism = roads[roadskeys[i,j]].speed + 0.0001
                        end
                        vvv = dism / roads[roadskeys[ i,j ]].speed * config.timemultiplier + roads[roadskeys[ i,j ]].delay[2]/2 # - roads[roadskeys[ i,j ]].delay[1]
                        if vvv < 1.0
                            vvv = 1.0
                        end
                        cardismx[i,j] = vvv
                    end
                end
            end
        
            timecardismx=[zeros(Int, length(roads)) for i in 1:(config.finishtime/900)]
            timecardismxct=[zeros(Int, length(roads)) for i in 1:(config.finishtime/900)]
            FileIO.save(string(config.mapsize[1:end-4],".jld2"), Dict("roads" => roads, "cardismx" => cardismx,"roadskeys"=>roadskeys,"timecardismx"=>timecardismx,"timecardismxct"=>timecardismxct))
            return (roads,cardismx,roadskeys,timecardismx,timecardismxct)
        end
    end


    function findroad(roads, targetlat1,targetlon1,targetlat2,targetlon2)
        first = zeros(length(roads))
        second = zeros(length(roads))
        for i in 1:length(roads)
            first[i] = sqrt( (targetlat1-roads[i].firstlat)^2 + (targetlon1-roads[i].firstlon)^2 )
            second[i] = sqrt( (targetlat2-roads[i].secondlat)^2 + (targetlon2-roads[i].secondlon)^2 )
        end
        return first .+ second
    end



end
