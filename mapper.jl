import FileIO
import CSV
import SparseArrays
using DataFrames
include("code/structs.jl")

const daynu = [1,2,5,20]
const folder = ["0324_032212","0324_032449","0324_032624"]

function doublemx(daynum, folder)
    println(daynum," : ",folder)
    distmxtemp,  timecardismxct,  roads, roadskeys,cardismx = FileIO.load("./iters/$(folder)/1/distmxtemp.jld2", "distmxtemp","timecardismxct", "roads", "roadskeys", "cardismx");
    if daynum != 1
        distmxtemp, timecardismxct = FileIO.load("./iters/$(folder)/$(daynum)/distmxtemp.jld2", "distmxtemp","timecardismxct");
    end
################################################################
    dfgs=Vector{}(undef,length(distmxtemp))
    Threads.@threads for i in 1:length(distmxtemp) 
        val = Vector{Vector{Float64}}()
        for (x,y,v) in zip(SparseArrays.findnz(distmxtemp[i])...)
            vv=(v-cardismx[x,y])/cardismx[x,y]
            if vv > 0.01
                ln = round(Int,roads[roadskeys[x,y]].length/20)
                if ln < 2
                    ln = 2
                end
                for d in collect(zip(range(roads[roadskeys[x,y]].firstlat,roads[roadskeys[x,y]].secondlat,length=ln),range(roads[roadskeys[x,y]].firstlon,roads[roadskeys[x,y]].secondlon,length=ln),[vv for i in 1:ln] ))
                    push!(val,[d...])
                end
            end
        end
        dfgs[i]=DataFrame(hcat(val...)')
    end
    for i in 1:length(distmxtemp)
        try
            CSV.write("./iters/$(folder)/csv_time/day$(daynum)/test$(i).csv",dfgs[i] )
        catch
            
        end
    end
#
################################################################
#
    dfgs=Vector{}(undef,length(distmxtemp))
    Threads.@threads for i in 1:length(distmxtemp) 
        val = Vector{Vector{Float64}}()
        for (x,y,v) in zip(SparseArrays.findnz(distmxtemp[i])...)
            vv=timecardismxct[i][roadskeys[x,y]] 
            if vv > 0
                ln = round(Int,roads[roadskeys[x,y]].length/20)
                if ln < 2
                    ln = 2
                end
                for d in collect(zip(range(roads[roadskeys[x,y]].firstlat,roads[roadskeys[x,y]].secondlat,length=ln),range(roads[roadskeys[x,y]].firstlon,roads[roadskeys[x,y]].secondlon,length=ln),[vv for i in 1:ln] ))
                    push!(val,[d...])
                end
            end
        end
        dfgs[i]=DataFrame(hcat(val...)')
    end 
    maxxx=0.0
    for i in 1:length(dfgs)
        try
            m = maximum(dfgs[i][:,end])
            if m > maxxx
                maxxx=m
            end
        catch
        end
    end
    for i in 1:length(dfgs)
        try
            dfgs[i][:,end] ./= maxxx
        catch
        end
        try
            CSV.write("./iters/$(folder)/csv_total/day$(daynum)/test$(i).csv",dfgs[i] )
        catch
        end
    end
################################################################
    return nothing
end

for fold in folder
    if ! isdir("./iters/$(fold)/csv_total/")
        mkdir("./iters/$(fold)/csv_total/")
    end
    if ! isdir("./iters/$(fold)/csv_time/")
        mkdir("./iters/$(fold)/csv_time/")
    end
    for day in daynu
        if ! isdir("./iters/$(fold)/csv_total/day$(day)/")
            mkdir("./iters/$(fold)/csv_total/day$(day)/")
        end
        if ! isdir("./iters/$(fold)/csv_time/day$(day)/")
            mkdir("./iters/$(fold)/csv_time/day$(day)/")
        end
        doublemx(day,fold)
    end
end