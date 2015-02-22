#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		host.rb
#
#	DESCRIPTION:
#		ygrid host.
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
class Host

	attr_reader :os;
	attr_reader :cpus;
	attr_reader :speed;
	attr_reader :memory;
	attr_reader :load;
	attr_reader :address;





#==============================================================================
#		Host::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize(theInfo={})

	# Initialise ourselves
	@os      = theInfo.fetch("os",      local_os);
	@cpus    = theInfo.fetch("cpus",    local_cpus);
	@speed   = theInfo.fetch("speed",   local_speed);
	@memory  = theInfo.fetch("memory",  local_memory);
	@load    = theInfo.fetch("load",    local_load);
	@address = theInfo.fetch("address", local_address);
	
end





#==============================================================================
#		Host::to_h : Get the host as a hash.
#------------------------------------------------------------------------------
def to_h

	# Get the info
	theInfo = Hash.new();

	theInfo["os"]      = @os;
	theInfo["cpus"]    = @cpus;
	theInfo["speed"]   = @speed;
	theInfo["memory"]  = @memory;
	theInfo["load"]    = @load;
	theInfo["address"] = @address;

	return(theInfo);
	
end





#============================================================================
#		Host::local_os : Get the local OS.
#----------------------------------------------------------------------------
def local_os

	case RbConfig::CONFIG['host_os']
		when /darwin|mac os/
			return("mac");
		
		when /linux/
			return("linux");

		when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
			return("windows");
	end

	abort("UNKNOWN OS");

end





#============================================================================
#		Host::local_cpus : Get the local CPU count.
#----------------------------------------------------------------------------
def local_cpus

	case local_os()
		when "mac", "linux"
			return(`sysctl -n hw.ncpu`.to_i);
	end

	abort("UNKNOWN OS");

end





#============================================================================
#		Host::local_speed : Get the local CPU speed in Ghz.
#----------------------------------------------------------------------------
def local_speed

	case local_os()
		when "mac", "linux"
			return(`sysctl -n hw.cpufrequency`.chomp.to_f / 1000000000.0);
	end

	abort("UNKNOWN PLATFORM");

end





#============================================================================
#		Host::local_memory : Get the local memory in Gb.
#----------------------------------------------------------------------------
def local_memory

	case local_os()
		when "mac", "linux"
			return(`sysctl -n hw.memsize`.chomp.to_i / 1073741824);
	end

	abort("UNKNOWN PLATFORM");

end





#============================================================================
#		Host::local_load : Get the local load.
#----------------------------------------------------------------------------
def local_load

	case local_os()
		when "mac", "linux"
			loadTotal = `sysctl -n vm.loadavg | cut -f 2 -d ' '`.chomp.to_f;
			numCPUs   = local_cpus().to_f;

			return((loadTotal / numCPUs).round(2));
	end

	abort("UNKNOWN PLATFORM");

end





#============================================================================
#		Host::local_address : Get the local IP address.
#----------------------------------------------------------------------------
def local_address

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


