#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		cluster.rb
#
#	DESCRIPTION:
#		Serf-based cluster.
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
require 'json';

require_relative 'daemon';
require_relative 'node';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Cluster

# Network
VERSION = 1;


# Config
CONFIG = {
	"discover" => "ygrid",
	"tags"     => {
		"ver"  => Cluster::VERSION.to_s,
		"os"   => Node.local_os,
		"cpu"  => Node.local_cpus.to_s,
		"ghz"  => Node.local_speed.to_s,
		"mem"  => Node.local_memory.to_s,
		"load" => Node.local_load.to_s
	}
};





#============================================================================
#		Cluster.start : Start the cluster.
#----------------------------------------------------------------------------
def Cluster.start(theGrids)

	# Get the state we need
	pathConfig = Workspace.pathConfig("cluster");
	pathLog    = Workspace.pathLog(   "cluster");

	theConfig                  = CONFIG.dup();
	theConfig["tags"]["grids"] = theGrids.join(",") if (!theGrids.empty?);

	abort("Cluster already running!") if (Daemon.running?("cluster"));



	# Start the server
	IO.write(pathConfig, JSON.pretty_generate(theConfig));

	thePID = Process.spawn("serf agent -config-file=\"#{pathConfig}\"", [:out, :err]=>[pathLog, "w"])
	Process.detach(thePID);

	Daemon.started("cluster", thePID);

end





#============================================================================
#		Cluster.joinGrids : Join some grids.
#----------------------------------------------------------------------------
def Cluster.joinGrids(theGrids)

	# Join the grids
	addToTag("grids", theGrids.join(","));

end





#============================================================================
#		Cluster.leaveGrids : Leave some grids.
#----------------------------------------------------------------------------
def Cluster.leaveGrids(theGrids)

	# Leave the grids
	removeFromTag("grids", theGrids.join(","));

end





#============================================================================
#		Cluster.grids : Get the grids in this cluster.
#----------------------------------------------------------------------------
def Cluster.grids

	# Get the state we need
	#
	# The empty default grid is always present.
	theMembers = getMembers();
	theGrids   = [ "" ];



	# Get the grids
	theMembers.each do |theMember|
		theGrids.concat(theMember["tags"].fetch("grids", "").split(","));
	end

	return(theGrids.sort.uniq);

end





#============================================================================
#		Cluster.nodes : Get the nodes in a grid.
#----------------------------------------------------------------------------
def Cluster.nodes(theGrid)

	# Get the state we ned
	theMembers = getMembers();
	theNodes   = [];



	# Get the matching nodes
	#
	# Nodes that are not in any named grid are in the default empty grid.
	theMembers.each do |theMember|

		theGrids = theMember["tags"].fetch("grids", "").split(",");
		theGrids << "" if (theGrids.empty?);

		if (theGrids.include?(theGrid))
			theNodes << Node.new(theMember["name"], theMember["addr"], theMember["tags"]);
		end

	end

	return(theNodes);

end





#============================================================================
#		Cluster.addToTag : Add a value to a tag list
#----------------------------------------------------------------------------
def Cluster.addToTag(theTag, theValue)

	theValues = getTag(theTag).split(",") << theValue;
	theValue  = theValues.sort.uniq.join(",");
	
	setTag(theTag, theValue);

end





#============================================================================
#		Cluster.removeFromTag : Remove a value from a tag list.
#----------------------------------------------------------------------------
def Cluster.removeFromTag(theTag, theValue)

	theValues = getTag(theTag).split(",");
	theValues.delete(theValue);

	theValue = theValues.sort.uniq.join(",");

	setTag(theTag, theValue);

end





#============================================================================
#		Cluster.getTag : Get a tag.
#----------------------------------------------------------------------------
def Cluster.getTag(theTag, defaultValue="")

	theInfo  = JSON.parse(`serf info -format=json`);
	theValue = theInfo["tags"].fetch(theTag, defaultValue);

	return(theValue);

end





#============================================================================
#		Cluster.setTag : Set a tag.
#----------------------------------------------------------------------------
def Cluster.setTag(theTag, theValue)

	theCmd = (theValue.empty?) ? "-delete #{theTag}" : "-set #{theTag}=\"#{theValue}\"";
	theLog  = `serf tags #{theCmd}`.chomp;

	if (theLog != "Successfully updated agent tags")
		puts "ERROR - Unable to set '#{theTag}' to '#{theValue}': #{theLog}";
	end

end





#============================================================================
#		Cluster.getMembers : Get the cluster members.
#----------------------------------------------------------------------------
def Cluster.getMembers

	# Get the members
	#
	# Only alive members with a matching version can be talked to.
	return(JSON.parse(`serf members -format=json -status alive -tag ver=#{Cluster::VERSION}`).fetch("members", {}));

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end

