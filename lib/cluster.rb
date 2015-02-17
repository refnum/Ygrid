#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		serf.rb
#
#	DESCRIPTION:
#		Serf module.
#
#	COPYRIGHT:
#		Copyright (c) 2012, refNum Software
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
require 'json';

require_relative 'utils';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Serf

# Paths
PATH_CONF = "/tmp/ygrid_serf.conf";
PATH_LOG  = "/tmp/ygrid_serf.log";
PATH_PID  = "/tmp/ygrid_serf.pid";


# Config
CONFIG_FILE = <<CONFIG_FILE
{
    "discover" : "ygrid",

    "tags" : {
        "os"    : "TOKEN_HOST_OS",
        "cpu"   : "TOKEN_HOST_CPUS",
        "ghz"   : "TOKEN_HOST_SPEED",
        "mem"   : "TOKEN_HOST_MEM",
        "load"  : "TOKEN_HOST_LOAD",
        "grids" : "TOKEN_GRIDS"
    }
}
CONFIG_FILE





#============================================================================
#		Serf.running? : Is serf running?
#----------------------------------------------------------------------------
def Serf.running?

	return(Utils.cmdRunning?(PATH_PID));

end





#============================================================================
#		Serf.start : Start serf.
#----------------------------------------------------------------------------
def Serf.start(theArgs)

	# Get the state we need
	theConfig = CONFIG_FILE.dup;
	theGrids  = theArgs["grids"].split(",").sort.uniq.join(",");

	theConfig.gsub!("TOKEN_HOST_OS",    Utils.hostOS());
	theConfig.gsub!("TOKEN_HOST_CPUS",  Utils.cpuCount());
	theConfig.gsub!("TOKEN_HOST_SPEED", Utils.cpuGHz());
	theConfig.gsub!("TOKEN_HOST_MEM",   Utils.memGB());
	theConfig.gsub!("TOKEN_HOST_LOAD",  Utils.sysLoad());
	theConfig.gsub!("TOKEN_GRIDS",      theGrids);

	abort("serf already running!") if (Serf.running?);



	# Start the server
	IO.write(PATH_CONF, theConfig);

	thePID = Process.spawn("serf agent -config-file=\"#{PATH_CONF}\"", [:out, :err]=>[PATH_LOG, "w"])
	Process.detach(thePID);

	IO.write(PATH_PID, thePID);
	
	return(true);

end





#============================================================================
#		Serf.stop : Stop serf.
#----------------------------------------------------------------------------
def Serf.stop()

	# Stop the server
	if (Serf.running?)
	
		Process.kill("SIGTERM", IO.read(PATH_PID).to_i);

		FileUtils.rm(PATH_CONF);
		FileUtils.rm(PATH_PID);

	end

end





#============================================================================
#		Serf.joinGrids : Join some grids.
#----------------------------------------------------------------------------
def Serf.joinGrids(theGrids)

	# Calculate the new grids
	newGrids = getGrids().concat(theGrids);



	# Update our state	
	setGrids(newGrids);

end





#============================================================================
#		Serf.leaveGrids : Leave some grids.
#----------------------------------------------------------------------------
def Serf.leaveGrids(theGrids)

	# Calculate the new grids
	newGrids = getGrids();
	
	theGrids.each do |theGrid|
		newGrids.delete(theGrid);
	end



	# Update our state	
	setGrids(newGrids);

end





#============================================================================
#		Serf.gridStatus : Get the status of a grid.
#----------------------------------------------------------------------------
def Serf.gridStatus(theGrid)

	# Get the state we need
	if (!theGrid.empty?)
		theGrid = "-tag grid=\btheGrid\b";
	end



	# Get the status
	theStatus = JSON.parse(`serf members #{theGrid} -format=json`);

	return(theStatus);

end





#============================================================================
#		Serf.getGrids : Get the grids we particpate in.
#----------------------------------------------------------------------------
def Serf.getGrids()

	theInfo  = JSON.parse(`serf info -format=json`);
	theGrids = theInfo["tags"]["grids"].split(",");

	return(theGrids);

end





#============================================================================
#		Serf.setGrids : Set the grids we particpate in.
#----------------------------------------------------------------------------
def Serf.setGrids(theGrids)

	theGrids = theGrids.sort.uniq.join(",");
	theLog   = `serf tags -set grids=#{theGrids}`.chomp;

	if (theLog != "Successfully updated agent tags")
		puts "ERROR - Unable to set tags: #{theLog}";
	end

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
