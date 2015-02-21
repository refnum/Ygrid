#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		job.rb
#
#	DESCRIPTION:
#		Job module.
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
require_relative 'utils';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Job





#============================================================================
#		Job.validate : Validate a job.
#----------------------------------------------------------------------------
def Job.validate(theJob)

	# Validate the job
	theErrors = [];
	
	if (!theJob.include?("task"))
		theErrors << "job is missing 'task'";
	
	elsif (theJob["task"].empty?)
		theErrors << "job has emtpy 'task'";
	end

	return(theErrors);

end





#============================================================================
#		Job.encodeID : Encode a host and index into an ID.
#----------------------------------------------------------------------------
def Job.encodeID(theHost, theIndex)

	# Obtain the address
	if (theHost.class != IPAddr)
		theHost = IPAddr.new(theHost);
	end



	# Encode the ID
	#
	# A job ID is a unique 16-character identifier that contains
	# a host-specific index and the IP address of its host.
	theID = "%08X%08X" % [theIndex, theHost.to_i];

	return(theID);

end





#============================================================================
#		Job.decodeID : Decode the host and index from an ID.
#----------------------------------------------------------------------------
def Job.decodeID(theID)

	# Decode the ID
	theInfo          = Hash.new();
	theInfo["index"] = theID.slice( 0, 8).hex;
	theInfo["host"]  = IPAddr.new(theID.slice(-8, 8).hex, Socket::AF_INET);

	return(theInfo);

end





#============================================================================
#		Job.packID : Pack a global ID to a shorter host-specific form.
#----------------------------------------------------------------------------
def Job.packID(theHost, theID)

	# Get the state we need
	hostIP  = IPAddr.new(theHost).to_i;
	theInfo = Job.decodeID(theID);

	theIndex = theInfo["index"];
	otherIP  = theInfo["host"].to_i;



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
#		Job.unpackID : Unpack a host-specific ID to a global ID.
#----------------------------------------------------------------------------
def Job.unpackID(theHost, packedID)

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
#		Job.getMask : Get a mask for packing.
#----------------------------------------------------------------------------
def Job.getMask(theValue)

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
