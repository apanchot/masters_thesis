using LightXML
using Unicode
import FileIO
import PolygonOps
import OpenStreetMapX
import StatsBase

function asdf()

    xdoc = parse_file("/Users/alex/Desktop/Nova/Thesis/Code/Transport_thesis/maps/a9-a40-a36.osm")
    # get the root element
    xroot = root(xdoc)
    maxx=10000
    landuse=Vector{Tuple{String,Vector{String}}}()
    println("part 0")
    ct=0

    for e in child_elements(xroot)  # c is an instance of XMLNode
        if has_children(e) && LightXML.name(e) == "way" # node has tag "tag" which are child elements
            nodes = []
            type = ""
            for c in child_elements(e) # run thru "tag" child elements  
                dic=attributes_dict(c) # each "tag" element has a list of attributes
                for (key,val) in dic    
                    if key == "ref"
                        push!(nodes, val)
                    end
                    if val in ["landuse","amenity","leisure"] # check if "tag" element has a attribute 
                        type = dic["v"]
                        if !(type in ["grass","parking","farmland","fountain","fuel","lavoir"]) # in ["residential","commerical","retail","industrial",""] 
                            if nodes[1] == nodes[end]
                                push!(landuse, (type,nodes))
                                ct+=1
                            end
                        end
                        @goto foundit
                        
                    end
                end
            end            
        end
        @label foundit
        if ct > maxx
            println("maxx")
            break
        end
    end
 

    nodelatlondict= Dict{String,Tuple{Float64,Float64}}()
    for e in child_elements(xroot) # search all values in xroot!?
        if LightXML.name(e) == "node"
            dic = attributes_dict(e) # each "tag" element has a list of attribute
            nodelatlondict[dic["id"]]=(parse(Float64,dic["lat"]),parse(Float64,dic["lon"]))
        end
    end
    landusecoords=Vector{Tuple{String,Vector{Tuple{Float64,Float64}}}}(undef, length(landuse))

    for i in 1:length(landuse)
        temp=Vector{Tuple{Float64,Float64}}(undef, length(landuse[i][2])) # find lat,lon
        for id in 1:length(landuse[i][2]) # each node of polygon
            temp[id] = (nodelatlondict[landuse[i][2][id]][1], nodelatlondict[landuse[i][2][id]][2])    
        end
        landusecoords[i] = (landuse[i][1],temp)
    end

    locmap = FileIO.load("/Users/alex/Desktop/Nova/Thesis/Code/Transport_thesis/locmapper.jld2","locmap")
    final = Dict{Int,String}()
    arry = Vector{Tuple{Int,Tuple{Float64,Float64}}}()
    
    for (key,val) in locmap
        push!(arry, (key,val))
    end
    
    Threads.@threads for j in 1:length(arry)
    
    
    labels = ""
        
        
    for i in 1:length(landusecoords)
        if PolygonOps.inpolygon(arry[j][2],landusecoords[i][2]) == 0 # outside
            continue
        else # inside

            labels = landusecoords[i][1]
            
            @goto tocont
        end
    end
    for dist in vcat(2:2:99,100:5:199,200:10:299), angle in 0:0.125:1.999
        point = ((dist*sinpi(angle)/111000)+arry[j][2][1], (dist*cospi(angle)/88000)+arry[j][2][2])
        
        for i in 1:length(landusecoords)
            

            if PolygonOps.inpolygon(point,landusecoords[i][2]) == 0 # outside
                continue
            else # inside
                
                labels = landusecoords[i][1]
                @goto tocont

            end
        end

    end
    
    @label tocont

    if labels != ""
        final[arry[j][1]] = labels
    end
       
    

    return final
end
landuse1=asdf()
locmap = FileIO.load("/Users/alex/Desktop/Nova/Thesis/Code/Transport_thesis/locmapper.jld2","locmap")
for (k,v) in locmap
    try
        landuse[k]
    catch
        landuse[k] = ""
    end
end
landuse
FileIO.save("landuse.jld2","landuse",landuse)
