#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		cluster_event.rb
#
#	DESCRIPTION:
#		Serf event handler.
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
require_relative 'agent';
require_relative 'daemon';
require_relative 'job_status';
require_relative 'node';





#==============================================================================
#		memberLeave : Handle a member-leave event.
#------------------------------------------------------------------------------
def memberLeave(theNodes)
end





#==============================================================================
#		memberFailed : Handle a member-failed event.
#------------------------------------------------------------------------------
def memberFailed(theNodes)
end





#==============================================================================
#		readNodes : Read the nodes in the event.
#------------------------------------------------------------------------------
def readNodes

	# Read the nodes
	theNodes = Array.new();
	
	STDIN.each_line do |theLine|
		# Parse the line
		#
		# Our input is a tab-delimited list of the members involved in the event,
		# where each line is {name, address, role, tags}.
		#
		# Tags are comma-delimited key=value pairs, so we split the whole string
		# into an array then build a hash by taking each slice as a pair.
		theTokens = theLine.split("\t");
		theName    = theTokens[0];
		theAddress = theTokens[1];
		theTags    = Hash[theTokens[3].chomp.split(/[,=]/).each_slice(2).to_a];



		# Create the node
		theNodes << Node.new(theName, theAddress, theTags);
	end

	return(theNodes);

end





#==============================================================================
#		cluster_event : Cluster event handler.
#------------------------------------------------------------------------------
def cluster_event

	# Get the state we need
	theNodes = readNodes();



	# Handle the event
	case ENV["SERF_EVENT"]
		when "member-leave"
			memberLeave(theNodes);

		when "member-failed"
			memberFailed(theNodes);
	end

end

cluster_event();



