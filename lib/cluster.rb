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

require_relative 'agent';
require_relative 'daemon';
require_relative 'node';
require_relative 'system';
require_relative 'utils';
require_relative 'workspace';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Cluster

# Network
VERSION = 1;


# Config
HANDLER = File.dirname(__FILE__) + "/cluster_event.rb";

CONFIG = {
	"discover"       => "ygrid",
	"log_level"      => "debug",
	"event_handlers" => ["member-leave,member-failed=#{Cluster::HANDLER}"],

	"tags"     => {
		"ver"  => Cluster::VERSION.to_s,
		"os"   => System.os,
		"cpu"  => System.cpus.to_s,
		"ghz"  => System.speed.to_s,
		"mem"  => System.memory.to_s,
		"load" => System.load.to_s
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
	FileUtils.chmod(0755, Cluster::HANDLER);

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
#		Cluster.openedJob : A job has been opened.
#----------------------------------------------------------------------------
def Cluster.openedJob

	# Update the jobs
	numJobs = getTag("jobs", "0").to_i + 1;

	setTag("jobs", numJobs.to_s);

end





#============================================================================
#		Cluster.closedJob : A job has been closed.
#----------------------------------------------------------------------------
def Cluster.closedJob

	# Update the jobs
	numJobs = getTag("jobs").to_i - 1;

	setTag("jobs", numJobs.to_s);

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

	begin
		theInfo  = JSON.parse(`serf info -format=json`);
		theValue = theInfo["tags"].fetch(theTag, defaultValue);

	rescue JSON::ParserError
		theValue = defaultValue;
	end

	return(theValue);

end





#============================================================================
#		Cluster.setTag : Set a tag.
#----------------------------------------------------------------------------
def Cluster.setTag(theTag, theValue)

	# Check for duplicates
	#
	# Serf invokes our event handler even if nothing has changed so we check
	# the existing value before issuing an update.
	return if (theValue == getTag(theTag))


	# Set the tag
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
	# Only live members with a matching version can be talked to.
	begin
		theMembers = JSON.parse(`serf members -format=json -status alive -tag ver=#{Cluster::VERSION}`).fetch("members", {});

	rescue JSON::ParserError
		theMembers = {};
	end
	
	return(theMembers);

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end

