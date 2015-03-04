#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		system.rb
#
#	DESCRIPTION:
#		System support.
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
# Module
#------------------------------------------------------------------------------
module System





#============================================================================
#		System.os : Get the OS.
#----------------------------------------------------------------------------
def System.os

	case RbConfig::CONFIG['host_os']
		when /darwin|mac os/
			return("mac");
		
		when /linux/
			return("linux");

		when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
			return("windows");

		else
			raise("UNKNOWN PLATFORM");
	end

end





#============================================================================
#		System.cpus : Get the CPU count.
#----------------------------------------------------------------------------
def System.cpus

	case System.os
		when "mac"
			return(`sysctl -n hw.ncpu`.to_i);
		
		when "linux"
			return(`cat /proc/cpuinfo | grep processor | wc -l`.to_i);

		else
			raise("UNKNOWN PLATFORM");
	end

end





#============================================================================
#		System.speed : Get the CPU speed in Ghz.
#----------------------------------------------------------------------------
def System.speed

	case System.os
		when "mac"
			return(`sysctl -n hw.cpufrequency`.to_f / 1000000000.0);
		
		when "linux"
			maxSpeed = `cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null`.to_f;
			return(maxSpeed / 1000000000.0) if (maxSpeed != 0.0);

			currSpeed = `cat /proc/cpuinfo | grep MHz | cut -f2 -d: | head -n 1`.to_f;
			return(currSpeed / 1000.0);

		else
			raise("UNKNOWN PLATFORM");
	end

end





#============================================================================
#		System.memory : Get the memory in Gb.
#----------------------------------------------------------------------------
def System.memory

	case System.os
		when "mac"
			return(`sysctl -n hw.memsize`.to_i / 1073741824);
		
		when "linux"
			return(`cat /proc/meminfo | grep MemTotal | cut -f2 -d:`.to_i / 1000000);

		else
			raise("UNKNOWN PLATFORM");
	end

end





#============================================================================
#		System.load : Get the system load.
#----------------------------------------------------------------------------
def System.load

	numCPUs   = System.cpus.to_f;
	loadTotal = numCPUs;

	case System.os
		when "mac"
			loadTotal = `sysctl -n vm.loadavg | cut -f2 -d' '`.to_f;
		
		when "linux"
			loadTotal = `cat /proc/loadavg | cut -f1 -d' '`.to_f;

		else
			raise("UNKNOWN PLATFORM");
	end

	return((loadTotal / numCPUs).round(2));

end





#============================================================================
#		System.name : Get the system name.
#----------------------------------------------------------------------------
def System.name

	return(Socket.gethostname());

end





#============================================================================
#		System.address : Get the system IP address.
#----------------------------------------------------------------------------
def System.address

	# Get the first IPv4 address
	theList = Socket.ip_address_list;
	theInfo = theList.detect{ |info|	info.ipv4?            and
										!info.ipv4_loopback?  and
										!info.ipv4_multicast? };

	return(IPAddr.new(theInfo.ip_address));

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end


