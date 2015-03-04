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

require_relative 'system';





#==============================================================================
# Class
#------------------------------------------------------------------------------
class Node


# Attributes
attr_reader :name;
attr_reader :address;
attr_reader :tags;





#==============================================================================
#		Node::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize(theName=nil, theAddress=nil, theTags=nil)

	# Local node
	if (theName == nil)
		@name    = System.name;
		@address = System.address;
		@tags    = Hash.new();

		@tags["os"]   = System.os;
		@tags["cpu"]  = System.cpus;
		@tags["ghz"]  = System.speed;
		@tags["mem"]  = System.memory;
		@tags["load"] = System.load;


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
#		Node::pretty_name : Get a readable hostname.
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
#		Node::jobs : Get the job statuses.
#------------------------------------------------------------------------------
def jobs

	theJobs     = @tags.fetch("jobs", "").split(",");
	theStatuses = Array.new()

	theJobs.each do |theState|
		theStatuses << JobStatus.from_s(theState, self.address);
	end

	return(theStatuses);

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

	if (address == System.address)
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





#==============================================================================
# Class
#------------------------------------------------------------------------------
end


