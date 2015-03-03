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
CONFIG_FILE = <<CONFIG_FILE
{
    "discover" : "ygrid",

    "tags" : {
	    "ver"   : "#{Cluster::VERSION}",
        "os"    : "TOKEN_NODE_OS",
        "cpu"   : "TOKEN_NODE_CPUS",
        "ghz"   : "TOKEN_NODE_SPEED",
        "mem"   : "TOKEN_NODE_MEM",
        "load"  : "TOKEN_NODE_LOAD",
        "grids" : "TOKEN_GRIDS"
    }
}
CONFIG_FILE





#============================================================================
#		Cluster.start : Start the cluster.
#----------------------------------------------------------------------------
def Cluster.start(theGrids)

	# Get the state we need
	pathConfig = Workspace.pathConfig("cluster");
	pathLog    = Workspace.pathLog(   "cluster");

	theConfig = CONFIG_FILE.dup;
	theConfig.gsub!("TOKEN_NODE_OS",    Node.local_os);
	theConfig.gsub!("TOKEN_NODE_CPUS",  Node.local_cpus.to_s);
	theConfig.gsub!("TOKEN_NODE_SPEED", Node.local_speed.to_s);
	theConfig.gsub!("TOKEN_NODE_MEM",   Node.local_memory.to_s);
	theConfig.gsub!("TOKEN_NODE_LOAD",  Node.local_load.to_s);
	theConfig.gsub!("TOKEN_GRIDS",      theGrids.join(","));

	abort("Cluster already running!") if (Daemon.running?("cluster"));



	# Start the server
	IO.write(pathConfig, theConfig);

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
	theValue = nil if (theValue.empty?)

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

	theCmd = (theValue == nil) ? "-delete #{theTag}" : "-set #{theTag}=\"#{theValue}\"";
	theLog  = `serf tags #{theCmd}`.chomp;

	if (theLog != "Successfully updated agent tags")
		puts "ERROR - Unable to set #{theTag} to #{theValue}: #{theLog}";
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





#============================================================================
#		Cluster.packID : Pack a global ID to a shorter host-specific form.
#----------------------------------------------------------------------------
def self.packID(theHost, theID)

	# Get the state we need
	hostIP  = IPAddr.new(theHost).to_i;

	theIndex = theID.slice( 0, 8).hex;
	otherIP  = IPAddr.new(theID.slice(-8, 8).hex, Socket::AF_INET).to_i;



	# Generate the short address
	#
	# A 'short address' encodes the difference between our IP address and
	# the address in the job ID:
	#
	#		Host IP		0A000107	(10.0.1.7)
	#		Other IP	0A000117	(10.0.1.23)
	#
	#		Mask		000000FF
	#		Short IP	00000017
	#
	# The short address can then be combined with our IP address to recover
	# the original IP address in the job ID.
	theMask = getMask(otherIP ^ hostIP);
	shortIP = otherIP & theMask;



	# Pack the ID
	packedID = "%X.%X" % [theIndex, shortIP];

	return(packedID);

end





#============================================================================
#		Cluster.unpackID : Unpack a host-specific ID to a global ID.
#----------------------------------------------------------------------------
def self.unpackID(theHost, packedID)

	# Get the state we need
	hostIP            = IPAddr.new(theHost).to_i;
	theIndex, shortIP = packedID.split(".").map { |x| x.hex };



	# Generate the full address
	#
	# Given a 'short address' and the IP address it was generated relative
	# to we can reapply the mask to obtain the original IP address.
	theMask = getMask(shortIP);
	otherIP = shortIP | (hostIP & ~theMask)



	# Encode the ID
	otherHost = IPAddr.new(otherIP, Socket::AF_INET);

	return(Job.encodeID(otherHost, theIndex));

end





#============================================================================
#		Cluster.getMask : Get a mask for packing.
#----------------------------------------------------------------------------
def self.getMask(theValue)

	# Generate the mask
	mask1 = (((theValue >> 24) & 0xFF) == 0 ? 0 : 0xFF);
	mask2 = (((theValue >> 16) & 0xFF) == 0 ? 0 : 0xFF);
	mask3 = (((theValue >>  8) & 0xFF) == 0 ? 0 : 0xFF);
	mask4 = (((theValue >>  0) & 0xFF) == 0 ? 0 : 0xFF);

	theMask = (mask1 << 24) | (mask2 << 16) | (mask3 << 8) | (mask4 << 0);

	return(theMask);

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end

