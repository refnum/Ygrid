#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		node.rb
#
#	DESCRIPTION:
#		Node object.
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
require 'ipaddr';
require 'rbconfig';
require 'socket';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class Node

	attr_reader :name;
	attr_reader :address;
	attr_reader :tags;





#==============================================================================
#		Node::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize(theName=nil, theAddress=nil, theTags=nil)

	# Local node
	if (theName == nil)
		@name    = Node.local_name;
		@address = Node.local_address;
		@tags    = Hash.new();

		@tags["os"]   = Node.local_os;
		@tags["cpu"]  = Node.local_cpus;
		@tags["ghz"]  = Node.local_speed;
		@tags["mem"]  = Node.local_memory;
		@tags["load"] = Node.local_load;


	# Specified node
	else
		@name    = theName;
		@address = IPAddr.new(theAddress.split(":")[0]);
		@tags    = theTags;
	end

end





#==============================================================================
#		Node::to_s : Convert to a string.
#------------------------------------------------------------------------------
def to_s

	return("{ name: \"#{@name}\", address: \"#{@address}\", tags: #{@tags} }");

end





#==============================================================================
#		Node::pretty_name : Get the prettified name.
#------------------------------------------------------------------------------
def pretty_name

	return(@name.sub(".local", ""));

end





#==============================================================================
#		Node::os : Get the OS.
#------------------------------------------------------------------------------
def os

	return(@tags["os"]);

end





#==============================================================================
#		Node::cpus : Get the CPU count.
#------------------------------------------------------------------------------
def cpus

	return(@tags["cpu"]);

end





#==============================================================================
#		Node::speed : Get the CPU speed in Ghz.
#------------------------------------------------------------------------------
def speed

	return(@tags["ghz"]);

end





#==============================================================================
#		Node::memory : Get the memory in Gb.
#------------------------------------------------------------------------------
def memory

	return(@tags["mem"]);

end





#==============================================================================
#		Node::load : Get the system load.
#------------------------------------------------------------------------------
def load

	return(@tags["load"]);

end





#==============================================================================
#		Node::score : Get the scheduling score.
#------------------------------------------------------------------------------
def score

	# Get the score
	#
	# For now our heuristics are:
	#
	#    o Local node is preferred
	#    o More CPUs are better
	#    o More memory is better
	#    o Higher load is worse
	#
	# As we don't apply any weighting then free CPU dominates over memory,
	# very high loads drop a node's CPU power to 0, and the local node is
	# fully utilised before any remote nodes.
	theLoad  = ((load > 0.9) ? 1.0 : load);
	theScore = ((cpus * speed) * (1.0 - theLoad)) + memory;

	if (address == local_address())
		theScore = theScore + 9000;
	end

	return(theScore);

end





#============================================================================
#		Node::<=> : Comparator.
#----------------------------------------------------------------------------
def <=> (other)

	# Compare by score
	return(self.score <=> other.score);

end





#============================================================================
#		Node.local_os : Get the local OS.
#----------------------------------------------------------------------------
def self.local_os

	case RbConfig::CONFIG['host_os']
		when /darwin|mac os/
			return("mac");
		
		when /linux/
			return("linux");

		when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
			return("windows");
	end

	raise("UNKNOWN OS");

end





#============================================================================
#		Node.local_cpus : Get the local CPU count.
#----------------------------------------------------------------------------
def self.local_cpus

	case local_os()
		when "mac", "linux"
			return(`sysctl -n hw.ncpu`.to_i);
	end

	raise("UNKNOWN OS");

end





#============================================================================
#		Node.local_speed : Get the local CPU speed in Ghz.
#----------------------------------------------------------------------------
def self.local_speed

	case local_os()
		when "mac", "linux"
			return(`sysctl -n hw.cpufrequency`.chomp.to_f / 1000000000.0);
	end

	raise("UNKNOWN PLATFORM");

end





#============================================================================
#		Node.local_memory : Get the local memory in Gb.
#----------------------------------------------------------------------------
def self.local_memory

	case local_os()
		when "mac", "linux"
			return(`sysctl -n hw.memsize`.chomp.to_i / 1073741824);
	end

	raise("UNKNOWN PLATFORM");

end





#============================================================================
#		Node.local_load : Get the local load.
#----------------------------------------------------------------------------
def self.local_load

	case local_os()
		when "mac", "linux"
			loadTotal = `sysctl -n vm.loadavg | cut -f 2 -d ' '`.chomp.to_f;
			numCPUs   = local_cpus().to_f;

			return((loadTotal / numCPUs).round(2));
	end

	raise("UNKNOWN PLATFORM");

end





#============================================================================
#		Node.local_name : Get the local name.
#----------------------------------------------------------------------------
def self.local_name

	return(Socket.gethostname());

end





#============================================================================
#		Node.local_address : Get the local IP address.
#----------------------------------------------------------------------------
def self.local_address

	# Get the first IPv4 address
	theList = Socket.ip_address_list;
	theInfo = theList.detect{ |info|	info.ipv4?            and
										!info.ipv4_loopback?  and
										!info.ipv4_multicast? };

	return(IPAddr.new(theInfo.ip_address));

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end


