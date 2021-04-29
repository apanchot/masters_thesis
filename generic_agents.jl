using LightXML
using Unicode
import FileIO
import PolygonOps
import OpenStreetMapX
import StatsBase

function lnduse()
    latdown, latup, lonleft, lonright = 38.696876446994956,38.757351536001174, -9.177099411497256, -9.085766710587855 # 38.691, 38.787, -9.2369999, -9.0869999
    xdoc = parse_file("/Users/alex/Desktop/Nova/Thesis/Code/Transport_thesis/maps/a9-a40-a36.osm")
    xroot = root(xdoc)
    maxx=10000
    landuse=Vector{Tuple{String,Vector{String}}}()
    println("part 0")
    ct=0
    # @time begin
    for e in child_elements(xroot)  # c is an instance of XMLNode
        if has_children(e) && LightXML.name(e) == "way" # node has tag "tag" which are child elements
            nodes = []
            usetype = ""
            for c in child_elements(e) # run thru "tag" child elements  
                dic=attributes_dict(c) # each "tag" element has a list of attributes
                for (key,val) in dic    
                    if key == "ref"
                        push!(nodes, val)
                    end
                    if val in ["landuse","leisure","amenity"] # check if "tag" element has a attribute  
                        usetype = dic["v"]
                        if !(usetype in ["grass","parking","farmland","fountain","fuel","lavoir"]) # in ["residential","commerical","retail","industrial",""] 
#                             if type in ["residential","commercial","industrial","school","university","retail","college"]
                            if nodes[1] == nodes[end]
                                push!(landuse, (usetype,nodes))
                                ct+=1
                            end
                        end
#                             @goto foundit

                    end
                end
            end         
        end
#             @label foundit
        if ct > maxx
            println("maxx")
            break
        end
    end
    landuse2=[]
    # end
#     return landuse
    println("num landuse ",length(landuse))
    println("part 1")
    # @time begin
    nodelatlondict= Dict{String,Tuple{Float64,Float64}}()
    for e in child_elements(xroot) # search all values in xroot!?
        if LightXML.name(e) == "node"
            dic = attributes_dict(e) # each "tag" element has a list of attribute
            nodelatlondict[dic["id"]]=(parse(Float64,dic["lat"]),parse(Float64,dic["lon"]))
            latlon=(parse(Float64,dic["lat"]),parse(Float64,dic["lon"]))
            if has_children(e)
                for c in child_elements(e)
                    dic=attributes_dict(c) # each "tag" element has a list of attributes
                    for (key,val) in dic    
                        if val in ["landuse","leisure","amenity"] # check if "tag" element has a attribute  
                            usetype = dic["v"]
                            if !(usetype in ["grass","parking","farmland","fountain","fuel","lavoir"]) # in ["residential","commerical","retail","industrial",""] 
                                push!(landuse2,( usetype, latlon ))
                            end
                        end
                    end
                end
            end
        end
    end
    landusecoords=Vector{Tuple{String,Bool,Vector{Tuple{Float64,Float64}}}}()
    landusecoords2=Vector{Tuple{String,Bool,Vector{Tuple{Float64,Float64}}}}()
    # Threads.@threads 
    
    for i in 1:length(landuse) # 38.68980006546885 

        temp=Vector{Tuple{Float64,Float64}}(undef, length(landuse[i][2])) # find lat,lon
        for id in 1:length(landuse[i][2]) # each node of polygon
            temp[id] = (nodelatlondict[landuse[i][2][id]][1], nodelatlondict[landuse[i][2][id]][2])    
        end
        if temp[1][1] > 38.68980006546885 
            push!(landusecoords, (landuse[i][1],latdown < temp[1][1] < latup && lonleft < temp[1][2] < lonright ? true : false,temp) )
        end
    end
    
    for i in 1:length(landuse2)
        if landuse2[i][2][1] > 38.68980006546885 
            push!(landusecoords2, (landuse2[i][1],latdown < landuse2[i][2][1] < latup && lonleft < landuse2[i][2][2] < lonright ? true : false,[landuse2[i][2]]) )
        end
    end
    
    # end
    # println(length(landusecoords))
    println("part 2")
    
    return vcat(landusecoords,landusecoords2)
end
        

landuse=lnduse();

landdict=Dict()
landdict["in"]=Dict()
landdict["out"]=Dict()
for i in 1:length(landuse)
    if landuse[i][2] # true ; inside lisbon
        try
            landdict["in"][landuse[i][1]] 
            push!(landdict["in"][landuse[i][1]], i)
        catch
            landdict["in"][landuse[i][1]] = Vector{Int}()
            push!(landdict["in"][landuse[i][1]], i)
        end
    else
        try
            landdict["out"][landuse[i][1]] 
            push!(landdict["out"][landuse[i][1]], i)
        catch
            landdict["out"][landuse[i][1]] = Vector{Int}()
            push!(landdict["out"][landuse[i][1]], i)
        end
    end
end
maxx=2
todel=[]
for (k,v) in landdict["in"]
    if length(v)<maxx
        push!(todel, k)
    end
end
for k in todel
    delete!(landdict["in"], k)
end
todel=[]
for (k,v) in landdict["out"]
    if length(v)<maxx
        push!(todel, k)
    end
end
for k in todel
    delete!(landdict["out"], k)
end

function genpoint(id)
    malat,malon = landuse[id][3][1]
    milat,milon = landuse[id][3][1]
    if length(landuse[id][3]) == 1
        return (round(milat,digits=7),round(milon,digits=7))
    end
    
    for i in 2:length(landuse[id][3])
        
        if landuse[id][3][i][1]<milat
            milat=landuse[id][3][i][1]
        elseif landuse[id][3][i][1]>malat
            malat=landuse[id][3][i][1]
        end
        if landuse[id][3][i][2]<milon
            milon=landuse[id][3][i][2]
        elseif landuse[id][3][i][2]>malon
            malon=landuse[id][3][i][2]
        end
    end
    it = 0
    while true
        
        lat = rand(milat:0.0000001:malat)
        lon = rand(milon:0.0000001:malon)
        if PolygonOps.inpolygon((lat,lon),landuse[id][3]) == 1 # 0 is outside
            return (round(lat,digits=7),round(lon,digits=7))
        end
        it +=1
        if it > 5
            return (round(milat,digits=7),round(milon,digits=7))
        end
    end
end
function findschool(lat,lon,inout)
    
    dist = []
    ids=[]
    closestid = -1
    for id in landdict[inout]["school"]
        push!(dist,sqrt( ((lat-landuse[id][3][1][1])*111000.)^2+((lon-landuse[id][3][1][2])*88000.)^2 ))
        push!(ids,id)
    end
    
    for d in sortperm(dist)
        if dist[d] > 1000
            return ids[d]
        end
    end
end

function generateagent(agenttype,inout)
    jobsin=[]
    jobsout=[]
    jobsd=Dict()
    jobs = ["commercial","industrial","retail","construction","restaurant","cafe"]
    for j in jobs
        try
            push!(jobsout, landdict["out"][j])
        catch
        end
        try
            push!(jobsin, landdict["in"][j])
        catch
        end
    end
    jobsin=vcat(jobsin...)
    jobsout=vcat(jobsout...)
    jobsd["in"]=jobsin
    jobsd["out"]=jobsout
    path = []
    
    resid = rand(landdict[inout]["residential"])
    reslat, reslon = genpoint(resid)
    push!(path, (resid, reslat,reslon, 0))
    
    if agenttype == "worker"
        workid = rand(jobsd["in"])
        worklat,worklon = genpoint(workid)
        iii=0
        while true
            if 1000 < sqrt( ((worklat-reslat)*111000.)^2+((worklon-reslon)*88000.)^2 )
                break
            end
            workid = rand(jobsd["in"])
            worklat,worklon = genpoint(workid)
            iii +=1
            if iii>10
                println(asdfadsf)
            end
        end
        
        push!(path, (workid, worklat,worklon, rand(6*3600:9*3600)))
        push!(path, (resid, reslat,reslon, path[2][end]+rand(7*3600:9*3600)))
        
    elseif agenttype == "parent"
        schoolid = findschool(reslat, reslon, inout) # rand(landdict[inout][rand(["school"])])
        workid = rand(jobsd["in"])
        worklat,worklon = genpoint(workid)
        schoollat,schoollon = genpoint(schoolid)
        iii=0
        while true
            if 1000 < sqrt( ((worklat-schoollat)*111000.)^2+((worklon-schoollon)*88000.)^2 )
                break
            end
            workid = rand(jobsd["in"])
            worklat,worklon = genpoint(workid)
            iii +=1
            if iii>10
                println(asdfadsf)
            end
        end
        
        
        push!(path, (schoolid, schoollat,schoollon, rand(6*3600:8*3600)))
        push!(path, (workid, worklat,worklon, path[2][end]+rand(0.5*3600:1*3600)))
        push!(path, (schoolid, schoollat,schoollon, path[3][end]+rand(7*3600:9*3600)))
        push!(path, (resid, reslat,reslon, path[4][end]+rand(0.5*3600:1*3600)))
        
    elseif agenttype == "student"
        schoolid = rand(landdict["in"]["university"])
        schoollat,schoollon = genpoint(schoolid)
        iii=0
        while true
            if 1000 < sqrt( ((schoollat-reslat)*111000.)^2+((schoollon-reslon)*88000.)^2 )
                break
            end
            schoolid = rand(landdict["in"]["university"])
            schoollat,schoollon = genpoint(schoolid)
            iii +=1
            if iii>10
                println(asdfadsf)
            end
        end
        push!(path, (schoolid, schoollat,schoollon, rand(6*3600:8*3600)))
        push!(path, (resid, reslat,reslon, path[2][end]+rand(7*3600:9*3600)))
        
    end
    
    return path
end


agents=Vector{Vector{Tuple{Int,Float64,Float64,Int}}}(undef,590000)
weig = pweights([0.845, 0.15, 0.005]) # worker, parent, student

Threads.@threads for i in 1:590
    if i %20000==0
        println(i)
    end
    if i < 220_000
        agents[i] = generateagent(sample(["worker", "parent", "student"], weig),"in")
    else
        agents[i] = generateagent(sample(["worker", "parent", "student"], weig),"out")
    end
end

FileIO.save("/Users/alex/Desktop/Nova/Thesis/Code/carsim/590agents.jld2","agents",agents)