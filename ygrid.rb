#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		ygrid.rb
#
#	DESCRIPTION:
#		ygrid - simple clustering.
#
#	COPYRIGHT:
#		Copyright (c) 2015, refNum Software
#		<http://www.refnum.com/>
#
#		All rights reserved.
#
#		Redistribution and use in source and binary forms, with or without
#		modification, are permitted provided that the following conditions
#		are met:
#
#			o Redistributions of source code must retain the above
#			copyright notice, this list of conditions and the following
#			disclaimer.
#
#			o Redistributions in binary form must reproduce the above
#			copyright notice, this list of conditions and the following
#			disclaimer in the documentation and/or other materials
#			provided with the distribution.
#
#			o Neither the name of refNum Software nor the names of its
#			contributors may be used to endorse or promote products derived
#			from this software without specific prior written permission.
#
#		THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#		"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#		LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#		A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#		OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#		SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#		LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#		DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#		THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#		(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#		OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#==============================================================================
# Imports
#------------------------------------------------------------------------------
require 'optparse';

require_relative 'lib/controller';
require_relative 'lib/status';
require_relative 'lib/utils';





#==============================================================================
#		cmdStart : Start the server.
#------------------------------------------------------------------------------
def cmdStart(theArgs)

	# Start the server
	puts "#{Controller.running? ? "Restarting" : "Starting"} ygrid server...";
	theErrors = Controller.start(theArgs);



	# Handle failure
	if (!theErrors.empty?)
		puts "Unable to start server!";

		theErrors.each do |theError|
			puts theError
		end

		exit(-1);
	end

end





#==============================================================================
#		cmdStop : Stop the server.
#------------------------------------------------------------------------------
def cmdStop(theArgs)

	# Stop the server
	puts "Stopping ygrid server...";

	Controller.stop();

end





#==============================================================================
#		cmdJoin : Join some grids.
#------------------------------------------------------------------------------
def cmdJoin(theArgs)

	# Get the state we need
	theGrids = theArgs["grid"].split(",");
	numGrids = Utils.getCount(theGrids, "grid");



	# Join the grids
	puts "Joining #{numGrids}...";
	
	Controller.joinGrids(theGrids);

end





#==============================================================================
#		cmdLeave : Leave some grids.
#------------------------------------------------------------------------------
def cmdLeave(theArgs)

	# Get the state we need
	theGrids = theArgs["grid"].split(",");
	numGrids = Utils.getCount(theGrids, "grid");



	# Leave the grids
	puts "Leaving #{numGrids}...";

	Controller.leaveGrids(theGrids);

end





#==============================================================================
#		cmdSubmit : Submit a job.
#------------------------------------------------------------------------------
def cmdSubmit(theArgs)

	raise("cmdSubmit -- not implemented");

end





#==============================================================================
#		cmdCancel : Cancel a job.
#------------------------------------------------------------------------------
def cmdCancel(theArgs)

	raise("cmdCancel -- not implemented");

end





#==============================================================================
#		cmdStatus : Show the status.
#------------------------------------------------------------------------------
def cmdStatus(theArgs)

	# Get the state we need
	theGrids = theArgs["grid"].split(",");

	if (theGrids.empty?)
		theGrids << "";
	end



	# Show the status
	Utils.sleepLoop(2) do

		theGrids.each do |theGrid|
			gridStatus = Cluster.gridStatus(theGrid);
			Status.putStdout(theGrid, gridStatus);
		end

	end

end





#==============================================================================
#		cmdHelp : Display the help.
#------------------------------------------------------------------------------
def cmdHelp

	puts "ygrid: simple grid clustering";
	puts "";
	puts "Available commands are:";
	puts "";
	puts "    ygrid start --root=/path/to/root [--grid=grid1,grid2,gridN]";
	puts "";
	puts "        Start the ygrid server. The server must be supplied with a path";
	puts "        to the root filesystem area for incoming jobs.";
	puts "";
	puts "        Servers may also be given a list of grids to particpate in.";
	puts "";
	puts "";
	puts "    ygrid stop";
	puts "";
	puts "        Stop the ygrid server.";
	puts "";
	puts "";
	puts "    ygrid join --grid=grid1,grid2,gridN";
	puts "";
	puts "        Joins the specified grids. This server will now particpate in jobs";
	puts "        distribtued to those grids.";
	puts "";
	puts "";
	puts "    ygrid leave --grid=grid1,grid2,gridN";
	puts "";
	puts "        Leaves the specified grids. This server will no longer particpate in";
	puts "        jobs distribtued to those grids.";
	puts "";
	puts "";
	puts "";
	puts "    ygrid status [--grid=name]";
	puts "";
	puts "        Displays the status of a grid, or all grids if no grids are selected.";
	puts "";
	exit(0);

end





#==============================================================================
#		checkStatus : Check the status.
#------------------------------------------------------------------------------
def checkStatus(theCmd)
	
	if (!["start", "stop", "help"].include?(theCmd) && !Controller.running?)
		puts "No ygrid server running!";
		exit(-1);
	end

end





#==============================================================================
#		ygrid : Simple clustering.
#------------------------------------------------------------------------------
def ygrid

	# Initialise ourselves
	theArgs = Utils.getArguments();
	theCmd  = theArgs["cmd"];

	Utils.checkInstall();
	checkStatus(theCmd);



	# Perform the command
	case theCmd
		when "start"
			cmdStart(theArgs);

		when "stop"
			cmdStop(theArgs);
		
		when "join"
			cmdJoin(theArgs);
		
		when "leave"
			cmdLeave(theArgs);
		
		when "submit"
			cmdSubmit(theArgs);
		
		when "cancel"
			cmdCancel(theArgs);
		
		when "status"
			cmdStatus(theArgs);
		
		else
			cmdHelp();

	end

end

ygrid();

