module Structs

##########################################################################################
	mutable struct road
		length::Float64 # m
		carqueue::Vector{Int}
		class::Int

		maxqueuesize::Int
		speed::Float64 # m/s
		carspersec::Int # number of cars allowed per second

		firstlat::Float64
		firstlon::Float64
		secondlat::Float64
		secondlon::Float64

		firstid::Int
		secondid::Int
		slopepercent::Float64 # slope in %
		slopeheight::Float64 # actual climb of slope
		delay::Tuple{Int,Int} # range of values that agent will wait; stop light or stop sign or none
	end

	mutable struct agent
		id::Int #agent id
		subroute::Int
		destinations::Vector{Tuple{Int,Int}} #list of destinations for day (2,-) LG nodes
		####
		departuretimes::Vector{Int} # given in seconds from midnight so [1,86400] # can be departure or arrival priority; CAN change; only dep times
		####
		route::Vector{Vector{Int}} # subroute for that specific route. changes as routenumber changes; node values
	
		pos::Int # current position in subroute

		timespentinloc::Int # current time spent on a single road
		running::Bool # whether the agent is currently moving. Can be turned on and off multiple times per day
		roadtoplace::Int # (car=1,ped=2,bike=3,pt=4)
		extratime::Int # delay that is given before proceeding
		extratimect::Int
		expectedtime::Int # expected total day time
		actualtime::Int # actual total day time
	end



end 